const BASE = import.meta.env.VITE_API_URL ?? 'http://localhost:3000/api/v1'
const KEY = 'mithai_admin_session'

/** Fired when the super admin session ends (expired or rejected by the server). */
export const SESSION_EXPIRED_EVENT = 'admin-session-expired'

/**
 * Super admin session: a short-lived access token (default 5 min) with no refresh
 * token — the admin signs in again when it expires. Kept in sessionStorage so it
 * is scoped to the tab and gone when the tab closes.
 */
export interface Session {
  accessToken: string
  /** epoch ms */
  expiresAt: number
}

export interface Tenant {
  _id: string
  name: string
  slug: string
  active: boolean
  createdAt: string
}

export interface CreateTenantInput {
  name: string
  slug: string
  owner: { name: string; username: string; password: string }
}

export class ApiError extends Error {
  status: number
  constructor(status: number, message: string) {
    super(message)
    this.status = status
  }
}

export const session = {
  get(): Session | null {
    try {
      const s: Session | null = JSON.parse(sessionStorage.getItem(KEY) ?? 'null')
      return s && s.expiresAt > Date.now() ? s : null
    } catch {
      return null
    }
  },
  set(s: Session | null) {
    try {
      if (s) sessionStorage.setItem(KEY, JSON.stringify(s))
      else sessionStorage.removeItem(KEY)
    } catch {
      /* storage unavailable */
    }
  },
}

function expire() {
  session.set(null)
  window.dispatchEvent(new Event(SESSION_EXPIRED_EVENT))
}

async function raw(path: string, init: RequestInit, access?: string): Promise<Response> {
  return fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(access ? { Authorization: `Bearer ${access}` } : {}),
    },
  })
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  const s = session.get()
  if (!s) {
    expire()
    throw new ApiError(401, 'Session expired')
  }
  const res = await raw(path, init, s.accessToken)
  if (res.status === 401) {
    expire()
    throw new ApiError(401, 'Session expired')
  }
  if (!res.ok) {
    const body = await res.json().catch(() => null)
    throw new ApiError(res.status, body?.error?.message ?? res.statusText)
  }
  return res.status === 204 ? (undefined as T) : res.json()
}

export const api = {
  async login(username: string, password: string) {
    const res = await raw('/admin/auth/login', {
      method: 'POST',
      body: JSON.stringify({ username, password }),
    })
    const body = await res.json().catch(() => null)
    if (!res.ok) throw new ApiError(res.status, body?.error?.message ?? 'Login failed')
    session.set({ accessToken: body.accessToken, expiresAt: Date.now() + body.expiresIn * 1000 })
  },
  logout() {
    session.set(null)
  },
  listTenants: () => request<Tenant[]>('/admin/tenants'),
  createTenant: (input: CreateTenantInput) =>
    request<Tenant>('/admin/tenants', { method: 'POST', body: JSON.stringify(input) }),
  setTenantActive: (id: string, active: boolean) =>
    request<Tenant>(`/admin/tenants/${id}`, { method: 'PATCH', body: JSON.stringify({ active }) }),
}
