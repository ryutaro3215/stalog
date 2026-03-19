-- ============================================================
-- Table: public.profiles
-- auth.users と 1対1 で紐づくプロフィールテーブル
-- ============================================================

CREATE TABLE "public"."profiles" (
  -- auth.users.id と同一値を PK として使う（1対1）
  "id"           uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  "display_name" text        NOT NULL DEFAULT '',
  "updated_at"   timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT "profiles_pkey" PRIMARY KEY ("id")
);

-- RLS
ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles: owner read"
  ON "public"."profiles"
  FOR SELECT
  USING (auth.uid() = id);
 
CREATE POLICY "profiles: owner update"
  ON "public"."profiles"
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);
 
-- ---- トリガー: ユーザー登録時に profiles を自動作成 ----
CREATE OR REPLACE FUNCTION "public"."handle_new_user"()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', '')
  );
  RETURN NEW;
END;
$$;
 
CREATE TRIGGER "on_auth_user_created"
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION "public"."handle_new_user"();

