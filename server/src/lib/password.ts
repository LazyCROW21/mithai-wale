export const hashPassword = (plain: string) => Bun.password.hash(plain);
export const verifyPassword = (plain: string, hash: string) => Bun.password.verify(plain, hash);

/** Strips secrets before returning a user document to a client. */
export function publicUser<T extends { passwordHash: string }>(u: T): Omit<T, "passwordHash"> {
  const { passwordHash: _omit, ...rest } = u;
  return rest;
}
