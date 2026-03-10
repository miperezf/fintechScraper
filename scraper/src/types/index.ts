// ============================================================
// TIPOS CENTRALES — Dominio: tasas de interés
// ============================================================

/**
 * Representa una fila de la tabla `institutions`
 */
export interface Institution {
  id: string;
  name: string;
  country: string;
  website: string;
  type: "banco" | "fintech" | "cooperativa" | "caja_compensacion";
  is_active: boolean;
}

/**
 * Representa una fila de la tabla `products`
 */
export interface Product {
  id: string;
  institution_id: string;
  name: string;
  product_type: "cuenta_remunerada" | "cuenta_ahorro" | "cuenta_vista" | "deposito_plazo";
  currency: string;
  is_active: boolean;
}

/**
 * Resultado normalizado que devuelve cualquier scraper.
 * Independiente de la BD — el servicio hace el mapeo.
 */
export interface ScrapedRate {
  institutionName: string;  // Ej: "Mercado Pago"
  productName: string;      // Ej: "Cuenta Remunerada"
  rate: number;             // Ej: 13.5 (significa 13.5%)
}

/**
 * Datos para insertar en `interest_rates`
 */
export interface InterestRateInsert {
  product_id: string;
  rate: number;
}

/**
 * Contrato que todos los scrapers deben cumplir
 */
export interface IScraper {
  scrape(): Promise<ScrapedRate[]>;
}

/**
 * Resultado de una operación de inserción
 */
export interface InsertResult {
  success: boolean;
  insertedCount: number;
  errors: string[];
}