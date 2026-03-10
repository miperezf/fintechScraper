import { getSupabaseClient } from "../db/supabase";
import { ScrapedRate, CurrencyRateInsert, InsertResult, Source } from "../types";

// ============================================================
// RATE SERVICE
// Responsabilidad única: persistir y consultar tasas en Supabase
// ============================================================

/**
 * Busca una fuente activa por nombre exacto.
 * Retorna null si no existe o está inactiva.
 */
export async function getSourceByName(name: string): Promise<Source | null> {
  const supabase = getSupabaseClient();

  const { data, error } = await supabase
    .from("sources")
    .select("id, name, country, base_url, is_active")
    .eq("name", name)
    .eq("is_active", true)
    .single();

  if (error) {
    console.error(`[RateService] Error buscando source "${name}":`, error.message);
    return null;
  }

  return data as Source;
}

/**
 * Inserta múltiples tasas scrapeadas en currency_rates.
 * - Resuelve el source_id a partir del nombre de la fuente
 * - Normaliza de ScrapedRate a CurrencyRateInsert
 * - Retorna un resumen del resultado
 */
export async function insertRates(rates: ScrapedRate[]): Promise<InsertResult> {
  const supabase = getSupabaseClient();
  const result: InsertResult = {
    success: false,
    insertedCount: 0,
    errors: [],
  };

  if (rates.length === 0) {
    result.errors.push("No hay tasas para insertar");
    return result;
  }

  // --------------------------------------------------------
  // PASO 1: Resolver source_id para cada nombre único de fuente
  // Usamos un Map para evitar consultas duplicadas si hay
  // múltiples monedas del mismo banco
  // --------------------------------------------------------
  const sourceCache = new Map<string, string>(); // name → id

  for (const rate of rates) {
    if (!sourceCache.has(rate.sourceName)) {
      const source = await getSourceByName(rate.sourceName);
      if (!source) {
        result.errors.push(`Fuente no encontrada o inactiva: "${rate.sourceName}"`);
        continue;
      }
      sourceCache.set(rate.sourceName, source.id);
    }
  }

  if (sourceCache.size === 0) {
    result.errors.push("No se pudo resolver ninguna fuente válida");
    return result;
  }

  // --------------------------------------------------------
  // PASO 2: Mapear ScrapedRate[] → CurrencyRateInsert[]
  // Solo incluimos tasas cuya fuente fue resuelta correctamente
  // --------------------------------------------------------
  const toInsert: CurrencyRateInsert[] = rates
    .filter((rate) => sourceCache.has(rate.sourceName))
    .map((rate) => ({
      source_id:     sourceCache.get(rate.sourceName)!,
      currency_code: rate.currencyCode.toUpperCase(),
      buy_rate:      rate.buyRate,
      sell_rate:     rate.sellRate,
    }));

  // --------------------------------------------------------
  // PASO 3: Insertar en Supabase
  // El trigger de la BD detectará automáticamente los cambios
  // --------------------------------------------------------
  const { error } = await supabase
    .from("currency_rates")
    .insert(toInsert);

  if (error) {
    result.errors.push(`Error insertando tasas: ${error.message}`);
    return result;
  }

  result.success = true;
  result.insertedCount = toInsert.length;
  return result;
}