import { ScrapedRate } from "../types";
import { BaseScraper } from "./base.scraper";

// ============================================================
// MINDICADOR SCRAPER
// Fuente: https://mindicador.cl/api/dolar
// Dato: Dólar observado oficial publicado por el BCCh
// Método: HTTP fetch sobre API JSON pública
// Nota: El dólar observado no tiene compra/venta separados —
//       es un valor único oficial. Usamos el mismo valor para
//       buy y sell, que es la convención para este indicador.
// ============================================================

const MINDICADOR_URL = "https://mindicador.cl/api/dolar";
const SOURCE_NAME    = "Banco Central de Chile";

interface MindicadorResponse {
  codigo:  string;
  nombre:  string;
  serie: Array<{
    fecha: string;   // ISO date string
    valor: number;   // Valor del dólar observado
  }>;
}

export class MindicadorScraper extends BaseScraper {
  constructor() {
    super(SOURCE_NAME);
  }

  protected async fetchRates(): Promise<ScrapedRate[]> {
    // --------------------------------------------------------
    // PASO 1: Fetch a la API de Mindicador
    // --------------------------------------------------------
    const response = await fetch(MINDICADOR_URL);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status} al consultar Mindicador`);
    }

    const data = (await response.json()) as MindicadorResponse;

    // --------------------------------------------------------
    // PASO 2: Validar que la respuesta tiene datos
    // --------------------------------------------------------
    if (!data.serie || data.serie.length === 0) {
      throw new Error("Respuesta de Mindicador sin datos en serie");
    }

    // --------------------------------------------------------
    // PASO 3: Tomar el valor más reciente (primer elemento)
    // La API retorna la serie ordenada de más reciente a más antiguo
    // --------------------------------------------------------
    const latest = data.serie[0];

    if (!latest.valor || latest.valor <= 0) {
      throw new Error(`Valor inválido recibido: ${latest.valor}`);
    }

    console.log(`[${this.sourceName}] Dólar observado: $${latest.valor} (${latest.fecha})`);

    // --------------------------------------------------------
    // PASO 4: Retornar en formato ScrapedRate normalizado
    // --------------------------------------------------------
    return [
      {
        currencyCode: "USD",
        buyRate:      latest.valor,
        sellRate:     latest.valor,
        sourceName:   this.sourceName,
      },
    ];
  }
}