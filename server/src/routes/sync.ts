import { Hono } from "hono";
import { z } from "zod";
import { collection } from "../db/mongo";
import { Collections } from "../db/collections";
import { HttpError } from "../lib/errors";
import { parseBody } from "../lib/validate";
import { userOf } from "../middleware/auth";
import { processPull, pullQuery } from "../sync/pull";
import { processPush, pushRequest } from "../sync/push";
import type { AppEnv, Device } from "../types/models";

/** 1 → A, 26 → Z, 27 → AA … */
function codeFor(n: number): string {
  let s = "";
  for (let x = n; x > 0; x = Math.floor((x - 1) / 26)) s = String.fromCharCode(65 + ((x - 1) % 26)) + s;
  return s;
}

/** Mounted under /sync behind authenticate + requireUser. */
export const syncRouter = new Hono<AppEnv>()
  /**
   * Registers this device and returns its tenant-unique code, used to prefix
   * daily order tokens (A-12) so devices in the same shop never clash offline.
   * Idempotent: the same deviceId always gets the same code.
   */
  .post("/devices", async (c) => {
    const p = userOf(c);
    const { deviceId, name } = await parseBody(
      c,
      z.object({ deviceId: z.string().min(1).max(100), name: z.string().max(100).optional() }),
    );
    const devices = collection<Device>(Collections.devices);
    const key = `${p.tenantId}:${deviceId}`;
    const now = new Date();

    const existing = await devices.findOneAndUpdate(
      { _id: key },
      { $set: { lastSeenAt: now, lastUserId: p.id, ...(name ? { name } : {}) } },
      { returnDocument: "after" },
    );
    if (existing) return c.json({ deviceId, code: existing.code });

    const counter = await collection<{ _id: string; seq: number }>(Collections.counters).findOneAndUpdate(
      { _id: `device:${p.tenantId}` },
      { $inc: { seq: 1 } },
      { upsert: true, returnDocument: "after" },
    );
    const code = codeFor(counter!.seq);
    try {
      await devices.insertOne({
        _id: key, tenantId: p.tenantId, deviceId, code, name, lastUserId: p.id, createdAt: now, lastSeenAt: now,
      });
      return c.json({ deviceId, code }, 201);
    } catch {
      // Lost a race with a concurrent registration of the same device.
      const d = await devices.findOne({ _id: key });
      if (!d) throw new HttpError(500, "Device registration failed");
      return c.json({ deviceId, code: d.code });
    }
  })
  .post("/push", async (c) => {
    const p = userOf(c);
    const body = await parseBody(c, pushRequest);
    const results = await processPush(p, body.deviceId, body.ops);
    return c.json({ serverTime: new Date(), results });
  })
  .get("/pull", async (c) => {
    const q = pullQuery.parse(c.req.query());
    return c.json(await processPull(userOf(c), q));
  });
