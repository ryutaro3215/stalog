import { zValidator } from "@hono/zod-validator";
import { Hono } from "hono";
import { z } from "zod";
import type { Env } from "../lib/supabase";
import { createSupabaseClient } from "../lib/supabase";
import type { Variables } from "../middleware/auth";

const auth = new Hono<{ Bindings: Env; Variables: Variables }>();

//---------------------------------------------------------------
// POST /auth/signup
//---------------------------------------------------------------

auth.post(
  "/sighup",
  zValidator(
    "json",
    z.object({
      email: z.email(),
      password: z.string().min(8),
      display_name: z.string().min(1).max(50),
    }),
  ),
  async (c) => {
    const { email, password, display_name } = c.req.valid("json");
    const supabase = createSupabaseClient(c.env);

    const { data, error } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { display_name } },
    });

    if (error) {
      if (error.status === 422) {
        return c.json(
          {
            code: "CONFLICT",
            message: "このメールアドレスはすでに利用されています",
          },
          409,
        );
      }
      return c.json(
        {
          code: "BAD_REQUEST",
          message: "ユーザー登録に失敗しました",
        },
        400,
      );
    }

    if (!data.session || !data.user) {
      return c.json(
        {
          code: "BAD_REQUEST",
          message: "ユーザー登録に失敗しました",
        },
        400,
      );
    }

    return c.json(
      {
        access_token: data.session.access_token,
        token_type: "bearer",
        expires_in: data.session.expires_in,
        user: {
          id: data.user.id,
          email: data.user.email,
          display_name,
        },
      },
      201,
    );
  },
);

//---------------------------------------------------------------
// POST /auth/login
//---------------------------------------------------------------

auth.post(
  "/login",
  zValidator(
    "json",
    z.object({ email: z.email(), password: z.string().min(8) }),
  ),
  async (_c) => {},
);
