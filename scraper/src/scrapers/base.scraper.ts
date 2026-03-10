import { IScraper, ScrapedRate } from "../types";

// ============================================================
// BASE SCRAPER
// Clase abstracta que implementa el contrato IScraper.
// Todos los scrapers concretos deben extender esta clase.
// Provee logging y manejo de errores centralizado.
// ============================================================
export abstract class BaseScraper implements IScraper {
  protected readonly sourceName: string;

  constructor(sourceName: string) {
    this.sourceName = sourceName;
  }

  /**
   * Método público — orquesta el scraping con manejo de errores.
   * Los scrapers concretos implementan `fetchRates()`, no este método.
   */
  async scrape(): Promise<ScrapedRate[]> {
    console.log(`[${this.sourceName}] Iniciando scraping...`);
    const startTime = Date.now();

    try {
      const rates = await this.fetchRates();
      const elapsed = Date.now() - startTime;
      console.log(`[${this.sourceName}] ✅ ${rates.length} tasa(s) obtenida(s) en ${elapsed}ms`);
      return rates;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(`[${this.sourceName}] ❌ Error en scraping: ${message}`);
      // Nunca propagamos el error — retornamos array vacío
      // para no bloquear otros scrapers en el pipeline
      return [];
    }
  }

  /**
   * Cada scraper concreto implementa su lógica aquí.
   * Si falla, el error es capturado por scrape() arriba.
   */
  protected abstract fetchRates(): Promise<ScrapedRate[]>;
}