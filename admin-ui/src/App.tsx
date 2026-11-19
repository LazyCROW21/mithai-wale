import { useCallback, useEffect, useState, type FormEvent } from 'react'
import { api, session, SESSION_EXPIRED_EVENT, type Tenant } from './api'
import './App.css'

/** mm:ss until the session token expires; ends the session at zero. */
function SessionTimer({ onExpire }: { onExpire: () => void }) {
  const [left, setLeft] = useState(() => Math.max(0, (session.get()?.expiresAt ?? 0) - Date.now()))
  useEffect(() => {
    const id = setInterval(() => {
      const ms = Math.max(0, (session.get()?.expiresAt ?? 0) - Date.now())
      setLeft(ms)
      if (ms === 0) onExpire()
    }, 1000)
    return () => clearInterval(id)
  }, [onExpire])
  const s = Math.ceil(left / 1000)
  return (
    <span className="muted" title="Session time left">
      {Math.floor(s / 60)}:{String(s % 60).padStart(2, '0')}
    </span>
  )
}

function Login({ onDone, notice }: { onDone: () => void; notice?: string }) {
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  async function submit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const f = new FormData(e.currentTarget)
    setBusy(true)
    setError('')
    try {
      await api.login(String(f.get('username')), String(f.get('password')))
      onDone()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed')
    } finally {
      setBusy(false)
    }
  }

  return (
    <form className="card narrow" onSubmit={submit}>
      <h1>Mithai Wale Admin</h1>
      <label>
        Username
        <input name="username" required autoFocus />
      </label>
      <label>
        Password
        <input name="password" type="password" required />
      </label>
      {notice && !error && <p className="muted">{notice}</p>}
      {error && <p className="error">{error}</p>}
      <button disabled={busy}>{busy ? 'Signing in…' : 'Sign in'}</button>
    </form>
  )
}

function Tenants({ onLogout, onExpire }: { onLogout: () => void; onExpire: () => void }) {
  const [tenants, setTenants] = useState<Tenant[]>([])
  const [error, setError] = useState('')
  const [showForm, setShowForm] = useState(false)

  const load = useCallback(async () => {
    try {
      setTenants(await api.listTenants())
      setError('')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load')
    }
  }, [])

  useEffect(() => {
    let cancelled = false
    api
      .listTenants()
      .then((list) => !cancelled && setTenants(list))
      .catch((err) => !cancelled && setError(err instanceof Error ? err.message : 'Failed to load'))
    return () => {
      cancelled = true
    }
  }, [])

  async function create(e: FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const form = e.currentTarget
    const f = new FormData(form)
    try {
      await api.createTenant({
        name: String(f.get('name')),
        slug: String(f.get('slug')).toLowerCase(),
        owner: {
          name: String(f.get('ownerName')),
          username: String(f.get('ownerUsername')),
          password: String(f.get('ownerPassword')),
        },
      })
      form.reset()
      setShowForm(false)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to create tenant')
    }
  }

  async function toggle(t: Tenant) {
    try {
      await api.setTenantActive(t._id, !t.active)
      await load()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update tenant')
    }
  }

  return (
    <div className="card">
      <header>
        <h1>Tenants</h1>
        <div className="row">
          <SessionTimer onExpire={onExpire} />
          <button onClick={() => setShowForm((v) => !v)}>{showForm ? 'Cancel' : 'New tenant'}</button>
          <button onClick={onLogout}>Sign out</button>
        </div>
      </header>
      {error && <p className="error">{error}</p>}
      {showForm && (
        <form className="grid" onSubmit={create}>
          <label>Franchise name<input name="name" required /></label>
          <label>Slug (login code)<input name="slug" required pattern="[a-z0-9]+(-[a-z0-9]+)*" /></label>
          <label>Owner name<input name="ownerName" required /></label>
          <label>Owner username<input name="ownerUsername" required minLength={3} /></label>
          <label>Owner password<input name="ownerPassword" type="password" required minLength={8} /></label>
          <button>Create tenant</button>
        </form>
      )}
      <table>
        <thead>
          <tr><th>Name</th><th>Slug</th><th>Status</th><th>Created</th><th /></tr>
        </thead>
        <tbody>
          {tenants.map((t) => (
            <tr key={t._id}>
              <td>{t.name}</td>
              <td>{t.slug}</td>
              <td>{t.active ? 'Active' : 'Disabled'}</td>
              <td>{new Date(t.createdAt).toLocaleDateString()}</td>
              <td><button onClick={() => toggle(t)}>{t.active ? 'Disable' : 'Enable'}</button></td>
            </tr>
          ))}
          {tenants.length === 0 && (
            <tr><td colSpan={5}>No tenants yet.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  )
}

export default function App() {
  const [authed, setAuthed] = useState(() => session.get() !== null)
  const [notice, setNotice] = useState('')

  const expire = useCallback(() => {
    api.logout()
    setAuthed(false)
    setNotice('Session expired. Please sign in again.')
  }, [])

  useEffect(() => {
    window.addEventListener(SESSION_EXPIRED_EVENT, expire)
    return () => window.removeEventListener(SESSION_EXPIRED_EVENT, expire)
  }, [expire])

  return authed ? (
    <Tenants
      onExpire={expire}
      onLogout={() => {
        api.logout()
        setAuthed(false)
        setNotice('')
      }}
    />
  ) : (
    <Login
      notice={notice}
      onDone={() => {
        setNotice('')
        setAuthed(true)
      }}
    />
  )
}
