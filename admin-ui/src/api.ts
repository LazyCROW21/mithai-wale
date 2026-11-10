const BASE = import.meta.env.VITE_API_URL ?? 'http://localhost:3000/api/v1'
const KEY = 'mithai_admin_tokens'

export interface Tokens {
  accessToken: string
  refreshToken: string
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

export const tokens = {
  get(): Tokens | null {
    try {
      return JSON.parse(localStorage.getItem(KEY) ?? 'null')
    } catch {
      return null
    }
  },
  set(t: Tokens | null) {
    try {
      if (t) localStorage.setItem(KEY, JSON.stringify(t))
      else localStorage.removeItem(KEY)
    } catch {
      /* storage unavailable */
    }
  },
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

async function refresh(): Promise<boolean> {
  const t = tokens.get()
  if (!t) return false
  const res = await raw('/auth/refresh', {
    method: 'POST',
    body: JSON.stringify({ refreshToken: t.refreshToken }),
  })
  if (!res.ok) {
    tokens.set(null)
    return false
  }
  tokens.set(await res.json())
  return true
}

async function request<T>(path: string, init: RequestInit = {}): Promise<T> {
  let res = await raw(path, init, tokens.get()?.accessToken)
  if (res.status === 401 && (await refresh())) {
    res = await raw(path, init, tokens.get()?.accessToken)
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
    tokens.set({ accessToken: body.accessToken, refreshToken: body.refreshToken })
  },
  logout() {
    tokens.set(null)
  },
  listTenants: () => request<Tenant[]>('/admin/tenants'),
  createTenant: (input: CreateTenantInput) =>
    request<Tenant>('/admin/tenants', { method: 'POST', body: JSON.stringify(input) }),
  setTenantActive: (id: string, active: boolean) =>
    request<Tenant>(`/admin/tenants/${id}`, { method: 'PATCH', body: JSON.stringify({ active }) }),
}
