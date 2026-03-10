// ============================================================
// TIPOS CENTRALES DEL SISTEMA
// Estos tipos reflejan exactamente el modelo de la base de datos
// ============================================================

/**
 * Representa una fila de la tabla `sources`
 */
export interface Source {
  id: string;
  name: string;
  country: string;
  base_url: string;
  is_active: boolean;
}

/**
 * Datos necesarios para insertar en `currency_rates`
 * No incluye `id` ni `timestamp` — los genera la BD automáticamente
 */
export interface CurrencyRateInsert {
  source_id: string;
  currency_code: string;
  buy_rate: number;
  sell_rate: number;
}

/**
 * Resultado normalizado que devuelve cualquier scraper.
 * Es independiente de la BD — el servicio se encarga de mapearlo.
 */
export interface ScrapedRate {
  currencyCode: string;   // Ej: "USD", "EUR"
  buyRate: number;        // Tasa de compra
  sellRate: number;       // Tasa de venta
  sourceName: string;     // Nombre de la institución
}

/**
 * Contrato que TODOS los scrapers deben cumplir.
 * Cualquier scraper nuevo debe implementar esta interfaz.
 */
export interface IScraper {
  /**
   * Ejecuta el scraping y retorna las tasas encontradas.
   * Nunca lanza excepciones — devuelve array vacío si falla.
   */
  scrape(): Promise<ScrapedRate[]>;
}

/**
 * Resultado de una operación de inserción en la BD
 */
export interface InsertResult {
  success: boolean;
  insertedCount: number;
  errors: string[];
}