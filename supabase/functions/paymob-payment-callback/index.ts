// Paymob transaction callback.
//
// This is the only thing in the system allowed to decide that a card booking
// was paid. The app cannot: it sees the gateway through a WebView whose
// redirect URL any rider can edit, so "success=true" on the way back is a
// claim, not a fact. Paymob signs each callback with an HMAC over a fixed
// field list; verifying that signature is what turns the claim into a fact.
//
// Configure in Supabase:
//   supabase secrets set PAYMOB_HMAC_SECRET=...   (Paymob dashboard -> HMAC)
//   supabase functions deploy paymob-payment-callback --no-verify-jwt
//
// `--no-verify-jwt` is required: Paymob calls this with no Supabase JWT. The
// HMAC is the authentication, which is why an unverified body is never acted
// on and the secret is never optional.
//
// Register the deployed URL in Paymob as the *Transaction processed callback*.

declare const Deno: {
  env: { get(key: string): string | undefined };
  serve(handler: (req: Request) => Response | Promise<Response>): void;
};

/// The exact fields Paymob concatenates, in the exact order, to build the
/// HMAC for a TRANSACTION callback. Order is part of the contract — sorting
/// or reordering this list silently breaks every verification.
const HMAC_FIELDS = [
  "amount_cents",
  "created_at",
  "currency",
  "error_occured",
  "has_parent_transaction",
  "id",
  "integration_id",
  "is_3d_secure",
  "is_auth",
  "is_capture",
  "is_refunded",
  "is_standalone_payment",
  "is_voided",
  "order.id",
  "owner",
  "pending",
  "source_data.pan",
  "source_data.sub_type",
  "source_data.type",
  "success",
];

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  try {
    const hmacSecret = requireEnv("PAYMOB_HMAC_SECRET");
    const supabaseUrl = requireEnv("SUPABASE_URL");
    const serviceKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");

    const url = new URL(req.url);
    const body = await req.json() as Record<string, unknown>;

    // Paymob sends the hmac as a query parameter on the callback URL, and
    // (depending on account configuration) inside the body as well.
    const providedHmac = String(
      url.searchParams.get("hmac") ?? body.hmac ?? "",
    ).trim().toLowerCase();
    if (!providedHmac) return json({ error: "hmac_missing" }, 401);

    const transaction = extractTransaction(body);
    if (!transaction) return json({ error: "unsupported_callback" }, 400);

    const expectedHmac = await computeHmac(transaction, hmacSecret);
    if (!timingSafeEqual(providedHmac, expectedHmac)) {
      return json({ error: "hmac_mismatch" }, 401);
    }

    const orderId = readPath(transaction, "order.id");
    if (orderId == null || String(orderId).trim().length === 0) {
      return json({ error: "order_id_missing" }, 400);
    }

    // Paymob marks a still-running 3-D Secure step as pending. Settling on it
    // would confirm a seat for money that has not moved, so it is acknowledged
    // and left alone — the final callback carries the real verdict.
    const pending = readBool(transaction.pending);
    const success = readBool(transaction.success);
    if (pending && !success) {
      return json({ received: true, ignored: "pending" });
    }

    const settled = await callRpc({
      supabaseUrl,
      serviceKey,
      fn: "settle_paymob_payment",
      args: {
        p_order_id: String(orderId),
        p_transaction_id: transaction.id == null
          ? null
          : String(transaction.id),
        p_amount_cents: toInt(transaction.amount_cents),
        p_success: success && !readBool(transaction.error_occured),
        p_raw: transaction,
      },
    });

    return json({ received: true, result: settled });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    // A 500 makes Paymob retry, which is what we want for a transient
    // failure — settle_paymob_payment is idempotent, so a redelivery is safe.
    return json({ error: message }, 500);
  }
});

/// Paymob wraps the transaction under `obj` for webhooks and sends it flat for
/// some integrations; both shapes are accepted.
function extractTransaction(
  body: Record<string, unknown>,
): Record<string, unknown> | null {
  const type = String(body.type ?? "").toUpperCase();
  if (type && type !== "TRANSACTION") return null;

  const obj = body.obj;
  if (obj && typeof obj === "object") return obj as Record<string, unknown>;
  if (body.id != null && body.order != null) return body;
  return null;
}

/// HMAC-SHA512 over the concatenated field values, in Paymob's fixed order.
async function computeHmac(
  transaction: Record<string, unknown>,
  secret: string,
) {
  const payload = HMAC_FIELDS
    .map((field) => normalizeHmacValue(readPath(transaction, field)))
    .join("");

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-512" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(payload),
  );

  return Array.from(new Uint8Array(signature))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

/// Paymob builds its own digest from Python-serialised values: booleans are
/// lowercase, and a missing value contributes an empty string.
function normalizeHmacValue(value: unknown) {
  if (value === null || value === undefined) return "";
  if (typeof value === "boolean") return value ? "true" : "false";
  return String(value);
}

function readPath(source: Record<string, unknown>, path: string) {
  return path.split(".").reduce<unknown>((current, segment) => {
    if (current == null || typeof current !== "object") return undefined;
    return (current as Record<string, unknown>)[segment];
  }, source);
}

function readBool(value: unknown) {
  if (typeof value === "boolean") return value;
  return String(value ?? "").trim().toLowerCase() === "true";
}

function toInt(value: unknown) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? Math.round(parsed) : null;
}

/// Comparison that does not leak how much of the digest matched.
function timingSafeEqual(a: string, b: string) {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

async function callRpc(input: {
  supabaseUrl: string;
  serviceKey: string;
  fn: string;
  args: Record<string, unknown>;
}) {
  const response = await fetch(
    `${input.supabaseUrl}/rest/v1/rpc/${input.fn}`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: input.serviceKey,
        Authorization: `Bearer ${input.serviceKey}`,
      },
      body: JSON.stringify(input.args),
    },
  );

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`${input.fn} failed (${response.status}): ${text}`);
  }
  return text.length === 0 ? null : JSON.parse(text);
}

function requireEnv(name: string) {
  const value = Deno.env.get(name);
  if (!value || value.trim().length === 0) {
    throw new Error(`${name} is not configured.`);
  }
  return value;
}

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
