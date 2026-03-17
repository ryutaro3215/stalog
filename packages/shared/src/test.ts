import { z } from "zod";
export const testScheme = z.object({
  id: z.number().int().nonnegative(),
  title: z.string().min(1),
});
