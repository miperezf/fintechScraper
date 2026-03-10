import { getSupabaseClient } from "../db/supabase";
import { ScrapedRate, InterestRateInsert, InsertResult, Product } from "../types";

// ============================================================
// INTEREST RATE SERVICE
// Responsabilidad: persistir tasas de interés en Supabase
// ============================================================

/**
 * Busca un producto activo por nombre de institución y nombre de producto.
 */
async function getProduct(
  institutionName: string,
  productName: string
): Promise<Product | null> {
  const supabase = getSupabaseClient();

  const { data, error } = await supabase
    .from("products")
    .select(`
      id,
      institution_id,
      name,
      product_type,
      currency,
      is_active,
      institutions!inner ( name, is_active )
    `)
    .eq("name", productName)
    .eq("is_active", true)
    .eq("institutions.name", institutionName)
    .eq("institutions.is_active", true)
    .single();

  if (error) {
    console.error(`[RateService] Producto no encontrado: "${institutionName} → ${productName}"`);
    return null;
  }

  return data as Product;
}

/**
 * Inserta tasas scrapeadas en interest_rates.
 * El trigger detectará cambios automáticamente.
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
  // Resolver product_id para cada tasa scrapeada
  // --------------------------------------------------------
  const toInsert: InterestRateInsert[] = [];

  for (const rate of rates) {
    const product = await getProduct(rate.institutionName, rate.productName);

    if (!product) {
      result.errors.push(`Producto no encontrado: "${rate.institutionName} → ${rate.productName}"`);
      continue;
    }

    toInsert.push({
      product_id: product.id,
      rate: rate.rate,
    });
  }

  if (toInsert.length === 0) {
    result.errors.push("No se pudo resolver ningún producto válido");
    return result;
  }

  // --------------------------------------------------------
  // Insertar en Supabase — el trigger hace el resto
  // --------------------------------------------------------
  const { error } = await supabase
    .from("interest_rates")
    .insert(toInsert);

  if (error) {
    result.errors.push(`Error insertando tasas: ${error.message}`);
    return result;
  }

  result.success = true;
  result.insertedCount = toInsert.length;
  return result;
}