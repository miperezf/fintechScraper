import { chromium } from "playwright";
import { ScrapedRate } from "../types";
import { BaseScraper } from "./base.scraper";

// ============================================================
// TENPO SCRAPER
// Fuente: https://www.tenpo.cl/productos/cuenta-remunerada
// Dato: tasa diaria en FAQ → convertida a tasa anual
// Método: Playwright (página con contenido dinámico)
// ============================================================

const TENPO_URL     = "https://www.tenpo.cl/productos/cuenta-remunerada";
const INSTITUTION   = "Tenpo";
const PRODUCT       = "Cuenta Remunerada";

export class TenpoScraper extends BaseScraper {
  constructor() {
    super(INSTITUTION);
  }

  protected async fetchRates(): Promise<ScrapedRate[]> {
    const browser = await chromium.launch({ headless: true });
    const page    = await browser.newPage();

    try {
      // --------------------------------------------------------
      // PASO 1: Navegar a la página
      // --------------------------------------------------------
      await page.goto(TENPO_URL, {
        waitUntil: "domcontentloaded",
        timeout: 30000,
      });

      // --------------------------------------------------------
      // PASO 2: Buscar el párrafo que contiene la tasa diaria
      // --------------------------------------------------------
      const paragraphs = await page.$$eval(
        "p.cf-faq-content",
        (els) => els.map((el) => el.textContent ?? "")
      );

      // Filtrar el párrafo que menciona la tasa diaria
      const targetParagraph = paragraphs.find((text) =>
        text.includes("tasa diaria aproximada de")
      );

      if (!targetParagraph) {
        throw new Error("No se encontró el párrafo con la tasa diaria en Tenpo");
      }

      // --------------------------------------------------------
      // PASO 3: Extraer el número con regex
      // Busca patrones como "0.011961%"
      // --------------------------------------------------------
      const match = targetParagraph.match(/([\d.]+)%/);

      if (!match || !match[1]) {
        throw new Error(`No se pudo extraer la tasa del texto: "${targetParagraph}"`);
      }

      const dailyRate  = parseFloat(match[1]);

      if (isNaN(dailyRate) || dailyRate <= 0) {
        throw new Error(`Tasa diaria inválida: ${match[1]}`);
      }

      // --------------------------------------------------------
      // PASO 4: Convertir tasa diaria → tasa anual
      // Multiplicamos por 365 y redondeamos a 4 decimales
      // --------------------------------------------------------
      const annualRate = parseFloat((dailyRate * 365).toFixed(4));

      console.log(
        `[${INSTITUTION}] Tasa diaria: ${dailyRate}% → Tasa anual: ${annualRate}%`
      );

      return [
        {
          institutionName: INSTITUTION,
          productName:     PRODUCT,
          rate:            annualRate,
        },
      ];

    } finally {
      // Siempre cerrar el browser aunque falle
      await browser.close();
    }
  }
}