import type { MiddlewareHandler } from "hono";
import type { Env } from "../lib/supabase";
import { createSupabaseClient } from "../lib/supabase";

type Variables = {
  userId: string;
  accessToken: string;
};

/**
 * JWT を検証して userId と accessToken を context にセットするミドルウェア。
 * 認証が必要なルートにのみ適用する。
 *
 * 使い方:
 *   app.use("/categories/*", authMiddleware);
 *   app.use("/sessions/*", authMiddleware);
 */

export const authMiddleware: MiddlewareHandler<{
  Bindings: Env;
  Variables: Variables;
}> = async (c, next) => {
  const authHeader = c.req.header("Authorization");

  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return c.json({ code: "UNAUTHORIZED", message: "認証が必要です" }, 401);
  }

  const accessToken = authHeader.replace("Bearer ", "");
  const supabase = createSupabaseClient(c.env);

  const { data, error } = await supabase.auth.getUser(accessToken);
  if (error || !data.user) {
    return c.json(
      { code: "UNAUTHORIZED", message: "tokenが無効または期限切れです" },
      401,
    );
  }

  c.set("userId", data.user.id);
  c.set("accessToken", accessToken);

  await next();
};
