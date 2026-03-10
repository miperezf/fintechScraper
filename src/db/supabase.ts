import { createClient, SupabaseClient } from "@supabase/supabase-js";
import { env } from "../config/env";

// Singleton — se crea una sola vez y se reutiliza en toda la app
let client: SupabaseClient | null = null;

export function getSupabaseClient(): SupabaseClient {
  if (!client) {
    client = createClient(env.supabaseUrl, env.supabaseServiceRoleKey, {
      auth: {
        // En un servicio backend no necesitamos persistencia de sesión
        persistSession: false,
        autoRefreshToken: false,
      },
    });
  }
  return client;
}