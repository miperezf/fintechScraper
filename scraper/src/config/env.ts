import dotenv from "dotenv";

// Carga el archivo .env antes de cualquier otra cosa
dotenv.config();

function requireEnv(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`Variable de entorno faltante: ${key}`);
  }
  return value;
}

export const env = {
  supabaseUrl:            requireEnv("SUPABASE_URL"),
  supabaseServiceRoleKey: requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
};