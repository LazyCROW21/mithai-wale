export type HttpStatus = 400 | 401 | 403 | 404 | 409 | 422 | 500 | 501;

export class HttpError extends Error {
  constructor(
    public status: HttpStatus,
    message: string,
    public details?: unknown,
  ) {
    super(message);
  }
}

export const notImplemented = (what: string) =>
  new HttpError(501, `${what} is not implemented yet`);
export const notFound = (what: string) => new HttpError(404, `${what} not found`);
export const forbidden = (msg = "Forbidden") => new HttpError(403, msg);
export const unauthorized = (msg = "Unauthorized") => new HttpError(401, msg);

export function isDuplicateKey(err: unknown): boolean {
  return typeof err === "object" && err !== null && (err as { code?: number }).code === 11000;
}
