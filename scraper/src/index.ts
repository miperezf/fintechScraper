import { TenpoScraper } from "./scrapers/tenpo.scraper";
import { insertRates } from "./services/rate.service";
import { ScrapedRate } from "./types";

async function main(): Promise<void> {
  console.log("=".repeat(50));
  console.log(`🚀 Scraping iniciado: ${new Date().toISOString()}`);
  console.log("=".repeat(50));

  const scrapers = [
    new TenpoScraper(),
  ];

  const allRates: ScrapedRate[] = [];

  for (const scraper of scrapers) {
    const rates = await scraper.scrape();
    allRates.push(...rates);
  }

  console.log(`\n📦 Total tasas recolectadas: ${allRates.length}`);

  if (allRates.length === 0) {
    console.warn("⚠️  No hay tasas para insertar. Finalizando.");
    process.exit(0);
  }

  const result = await insertRates(allRates);

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

  if (!result.success) process.exit(1);
}

main();