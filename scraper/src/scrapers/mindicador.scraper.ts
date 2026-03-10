// Este scraper será reemplazado por los scrapers de tasas de interés
// Lo mantenemos vacío temporalmente para que compile

import { ScrapedRate } from "../types";
import { BaseScraper } from "./base.scraper";

export class MindicadorScraper extends BaseScraper {
  constructor() {
    super("Placeholder");
  }

  protected async fetchRates(): Promise<ScrapedRate[]> {
    return [];
  }
}