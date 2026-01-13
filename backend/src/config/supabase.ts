/**
 * Supabase client configuration (for storage/realtime features)
 */
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { env } from './env.js';

// Only initialize if Supabase is configured
let supabase: SupabaseClient | null = null;
let supabaseAdmin: SupabaseClient | null = null;

if (env.SUPABASE_URL && env.SUPABASE_ANON_KEY) {
  // Public client (uses anon key)
  supabase = createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY);

  // Admin client (uses service role key for backend operations)
  if (env.SUPABASE_SERVICE_ROLE_KEY) {
    supabaseAdmin = createClient(
      env.SUPABASE_URL,
      env.SUPABASE_SERVICE_ROLE_KEY,
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    );
  }
}

export { supabase, supabaseAdmin };

/**
 * Check if Supabase is configured
 */
export const isSupabaseConfigured = (): boolean => {
  return supabase !== null;
};
