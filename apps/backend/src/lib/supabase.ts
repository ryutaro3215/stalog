import { createClient } from "@supabase/supabase-js";

export type Env = {
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
};

export const createSupabaseClient = (env: Env) => {
  return createClient(env.SUPABASE_URL, env.SUPABASE_ANON_KEY, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
      detectSessionInUrl: false,
    },
  });
};

export const createSupabaseClientWithAuth = (env: Env, accessToken: string) => {
  const client = createSupabaseClient(env);
  client.auth.setSession({
    access_token: accessToken,
    refresh_token: "",
  });
  return client;
};
