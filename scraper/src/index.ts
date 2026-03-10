import { MindicadorScraper } from "./scrapers/mindicador.scraper";
import { insertRates } from "./services/rate.service";
import { ScrapedRate } from "./types";

// ============================================================
// ORQUESTADOR PRINCIPAL
// Punto de entrada del scraping service.
// GitHub Actions ejecuta este archivo cada 10 minutos.
// ============================================================

async function main(): Promise<void> {
  console.log("=".repeat(50));
  console.log(`🚀 Scraping iniciado: ${new Date().toISOString()}`);
  console.log("=".repeat(50));

  // --------------------------------------------------------
  // PASO 1: Ejecutar todos los scrapers registrados
  // Para agregar un nuevo scraper en el futuro,
  // solo hay que añadirlo a este array
  // --------------------------------------------------------
  const scrapers = [
    new MindicadorScraper(),
  ];

  const allRates: ScrapedRate[] = [];

  for (const scraper of scrapers) {
    const rates = await scraper.scrape();
    allRates.push(...rates);
  }

  console.log(`\n📦 Total tasas recolectadas: ${allRates.length}`);

  // --------------------------------------------------------
  // PASO 2: Persistir en Supabase
  // El trigger de PostgreSQL detectará cambios automáticamente
  // --------------------------------------------------------
  if (allRates.length === 0) {
    console.warn("⚠️  No hay tasas para insertar. Finalizando.");
    process.exit(0);
  }

  const result = await insertRates(allRates);

  // --------------------------------------------------------
  // PASO 3: Reporte final
  // --------------------------------------------------------
  console.log("\n" + "=".repeat(50));

  if (result.success) {
    console.log(`✅ Pipeline completado exitosamente`);
    console.log(`   Insertados: ${result.insertedCount} registro(s)`);
  } else {
    console.error(`❌ Pipeline completado con errores`);
    console.error(`   Errores: ${result.errors.join(", ")}`);
  }

  if (result.errors.length > 0) {
    console.warn(`⚠️  Advertencias: ${result.errors.join(", ")}`);
  }

  console.log(`🏁 Finalizado: ${new Date().toISOString()}`);
  console.log("=".repeat(50));

  // Exit code 1 si falló — GitHub Actions detectará el fallo
  if (!result.success) process.exit(1);
}

main();