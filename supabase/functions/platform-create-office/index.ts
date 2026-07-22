// =====================================================================================
// EWT platform administration — office onboarding
// -------------------------------------------------------------------------------------
// Creates a transportation office and its first dashboard administrator.
//
// The work is split in two, along the only line that matters:
//
//   SQL  (platform_create_office)  everything transactional — the office row, its
//                                  marketplace identity, its join code and its
//                                  office_users row, committed together or not at all.
//   HERE (Auth Admin API)          the one step SQL cannot do: creating the auth.users
//                                  row. Writing encrypted_password and auth.identities
//                                  by hand from a migration is fragile and coupled to
//                                  GoTrue's internals.
//
// Authorization is NOT this function's judgement to make. The RPC is called with the
// CALLER's JWT and re-checks is_platform_admin() itself, so the office is created by
// the platform admin's own identity and this function holds no authority it could leak.
// The service-role key is used for exactly two calls — create the auth user, and delete
// it again if the transaction fails — and never to write business data.
//
// Ordering and compensation: the auth user must exist before the RPC can reference it,
// and the two cannot share a transaction. So the collidable names are checked first
// (precheck), the auth user is created, and if the RPC still fails the auth user is
// deleted. A leaked auth user with no office_users row can sign in to nothing —
// resolve_office_user_login finds no username for it — but it would hold the login
// address hostage, so the compensating delete is not optional.
//
// Secrets discipline: the generated password is returned to the caller exactly once, in
// the response body. It is never logged, never persisted, and never echoed back when the
// caller supplied their own.
// =====================================================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

declare const Deno: {
  env: { get(key: string): string | undefined };
  serve(handler: (req: Request) => Response | Promise<Response>): void;
};

/// Dashboard login is name + password. Supabase Auth needs an email internally, so the
/// account is provisioned on a synthetic domain that receives no mail — the same
/// convention migration 20260721090100 documents, and the reason
/// resolve_office_user_login can return a login address without exposing anything
/// personal.
const loginEmailDomain = "office.ewt.internal";

type OnboardRequest = {
  name?: string;
  slug?: string;
  description?: string;
  logo_url?: string;
  phone?: string;
  email?: string;
  service_areas?: unknown;
  admin_username?: string;
  admin_full_name?: string;
  admin_password?: string;
};

class OnboardError extends Error {
  constructor(
    readonly code: string,
    readonly status: number,
    message?: string,
  ) {
    super(message ?? code);
  }
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  let createdUserId: string | null = null;

  try {
    if (req.method !== "POST") {
      throw new OnboardError("method_not_allowed", 405);
    }

    const callerJwt = readCallerJwt(req);
    const payload = await readPayload(req);
    const input = validate(payload);

    // Fails fast for the caller that is not a platform admin, before anything is
    // created. The RPC below re-checks; this is the cheap door, not the lock.
    await assertPlatformAdmin(callerJwt);

    const availability = await rpc<
      { slug_available?: boolean; username_available?: boolean }
    >(callerJwt, "platform_office_onboarding_precheck", {
      p_slug: input.slug,
      p_username: input.adminUsername,
    });

    if (input.slug && availability?.slug_available === false) {
      throw new OnboardError("slug_taken", 409);
    }
    if (availability?.username_available === false) {
      throw new OnboardError("username_taken", 409);
    }

    const generatedPassword = input.adminPassword ? null : generatePassword();
    const password = input.adminPassword ?? generatedPassword!;

    createdUserId = await createAuthUser({
      email: `${input.adminUsername}@${loginEmailDomain}`,
      password,
      fullName: input.adminFullName,
    });

    const office = await rpc<Record<string, unknown>>(
      callerJwt,
      "platform_create_office",
      {
        p_name: input.name,
        p_admin_user_id: createdUserId,
        p_admin_username: input.adminUsername,
        p_slug: input.slug,
        p_description: input.description,
        p_logo_url: input.logoUrl,
        p_phone: input.phone,
        p_email: input.email,
        p_service_areas: input.serviceAreas,
        p_admin_full_name: input.adminFullName,
      },
    );

    // Past this point the transaction is committed; the auth user is spoken for.
    createdUserId = null;

    return jsonResponse({
      office,
      login_username: input.adminUsername,
      // Present only when this function generated it. When the platform admin chose the
      // password, echoing it back would put a known secret on the wire for no reason.
      ...(generatedPassword ? { temporary_password: generatedPassword } : {}),
    }, 201);
  } catch (error) {
    // Compensate: the auth user exists but the office it was created for does not.
    if (createdUserId) {
      await deleteAuthUser(createdUserId);
    }

    if (error instanceof OnboardError) {
      return jsonResponse({ error: error.code, message: error.message }, error.status);
    }
    // Deliberately opaque: an unexpected failure here can carry Postgres detail, and
    // this endpoint answers to a browser.
    console.error("platform-create-office failed", String(error));
    return jsonResponse({ error: "onboarding_failed" }, 500);
  }
});

// ── Request handling ─────────────────────────────────────────────────────────────────

function readCallerJwt(req: Request): string {
  const header = req.headers.get("Authorization") ?? "";
  const token = header.toLowerCase().startsWith("bearer ")
    ? header.slice(7).trim()
    : "";
  if (!token) {
    throw new OnboardError("not_authenticated", 401);
  }
  return token;
}

async function readPayload(req: Request): Promise<OnboardRequest> {
  try {
    const body = await req.json();
    if (!body || typeof body !== "object") throw new Error("not an object");
    return body as OnboardRequest;
  } catch {
    throw new OnboardError("invalid_payload", 400);
  }
}

type ValidatedInput = {
  name: string;
  slug: string | null;
  description: string;
  logoUrl: string | null;
  phone: string | null;
  email: string | null;
  serviceAreas: string[];
  adminUsername: string;
  adminFullName: string;
  adminPassword: string | null;
};

/// Server-side validation of everything the caller sends.
///
/// The RPC validates the same fields again — it has to, since it is directly callable
/// by any platform admin. Doing it here as well is what lets the UI show a specific
/// message instead of a Postgres error string, and keeps a malformed payload from
/// reaching the Auth Admin API at all.
function validate(body: OnboardRequest): ValidatedInput {
  const name = str(body.name);
  if (name.length < 3 || name.length > 120) {
    throw new OnboardError("invalid_office_name", 400);
  }

  const slug = str(body.slug).toLowerCase();
  if (slug && (!/^[a-z0-9]+(-[a-z0-9]+)*$/.test(slug) || slug.length < 3 || slug.length > 48)) {
    throw new OnboardError("invalid_slug", 400);
  }

  const description = str(body.description);
  if (description.length > 500) {
    throw new OnboardError("description_too_long", 400);
  }

  const logoUrl = str(body.logo_url);
  if (logoUrl && !/^https:\/\//i.test(logoUrl)) {
    throw new OnboardError("invalid_logo_url", 400);
  }

  const phone = str(body.phone);
  if (phone && (phone.length < 7 || phone.length > 20)) {
    throw new OnboardError("invalid_phone", 400);
  }

  const email = str(body.email).toLowerCase();
  if (email && !/^[^@\s]+@[^@\s]+\.[a-z]{2,}$/i.test(email)) {
    throw new OnboardError("invalid_email", 400);
  }

  const serviceAreas = Array.isArray(body.service_areas)
    ? Array.from(
      new Set(
        body.service_areas
          .map((area) => str(area))
          .filter((area) => area.length > 0),
      ),
    )
    : [];
  if (serviceAreas.length > 30) {
    throw new OnboardError("too_many_service_areas", 400);
  }
  if (serviceAreas.some((area) => area.length > 60)) {
    throw new OnboardError("invalid_service_area", 400);
  }

  const adminUsername = str(body.admin_username).toLowerCase();
  if (
    !/^[a-z0-9][a-z0-9._-]*$/.test(adminUsername) ||
    adminUsername.length < 3 || adminUsername.length > 32
  ) {
    throw new OnboardError("invalid_username", 400);
  }

  const adminFullName = str(body.admin_full_name);
  if (adminFullName.length > 120) {
    throw new OnboardError("invalid_admin_name", 400);
  }

  const adminPassword = str(body.admin_password);
  if (adminPassword && adminPassword.length < 10) {
    throw new OnboardError("weak_password", 400);
  }

  return {
    name,
    slug: slug || null,
    description,
    logoUrl: logoUrl || null,
    phone: phone || null,
    email: email || null,
    serviceAreas,
    adminUsername,
    adminFullName,
    adminPassword: adminPassword || null,
  };
}

function str(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

// ── Supabase access ──────────────────────────────────────────────────────────────────

function projectUrl(): string {
  const url = Deno.env.get("SUPABASE_URL");
  if (!url) {
    throw new Error("SUPABASE_URL is not available to this function.");
  }
  return url;
}

function serviceKey(): string {
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!key) {
    throw new Error(
      "SUPABASE_SERVICE_ROLE_KEY is not available to this function.",
    );
  }
  return key;
}

/// The gateway wants an `apikey` on every request; the role is decided by the
/// Authorization bearer, so a user-scoped call pairs the publishable key with the
/// caller's JWT rather than presenting the service key it does not need.
function publishableKey(): string {
  return Deno.env.get("SUPABASE_ANON_KEY") ?? serviceKey();
}

/// Calls a Postgres function AS THE CALLER. An invalid or expired JWT is rejected by
/// PostgREST before the function body runs, and is_platform_admin() inside each RPC
/// then decides whether the caller may proceed.
async function rpc<T>(
  jwt: string,
  name: string,
  params: Record<string, unknown>,
): Promise<T> {
  const response = await fetch(`${projectUrl()}/rest/v1/rpc/${name}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: publishableKey(),
      Authorization: `Bearer ${jwt}`,
    },
    body: JSON.stringify(params),
  });

  if (response.status === 401 || response.status === 403) {
    throw new OnboardError("not_authenticated", 401);
  }

  const text = await response.text();
  if (!response.ok) {
    const code = postgresErrorCode(text);
    throw new OnboardError(code, code === "platform_admin_required" ? 403 : 400);
  }

  return (text ? JSON.parse(text) : null) as T;
}

/// `raise exception 'slug_taken'` surfaces as {"message":"slug_taken", ...}. Lifting the
/// bare code out keeps the machine-readable contract the Dashboard maps to Arabic, and
/// keeps Postgres internals (hints, positions, SQL text) out of the response.
function postgresErrorCode(body: string): string {
  try {
    const parsed = JSON.parse(body) as { message?: string; code?: string };
    const message = (parsed.message ?? "").trim();
    if (/^[a-z0-9_]+$/.test(message)) return message;
    if (parsed.code === "23505") return "duplicate_value";
    return "onboarding_rejected";
  } catch {
    return "onboarding_rejected";
  }
}

async function assertPlatformAdmin(jwt: string): Promise<void> {
  const isAdmin = await rpc<boolean>(jwt, "is_platform_admin", {});
  if (isAdmin !== true) {
    throw new OnboardError("platform_admin_required", 403);
  }
}

/// Creates the login account with the Auth Admin API.
///
/// `email_confirm: true` because the address is synthetic and receives no mail — without
/// it the operator could never complete a confirmation they will never be sent.
/// `role: 'office_user'` is load-bearing: handle_new_client_user() fires on every
/// auth.users insert and would otherwise write a public.clients row with an empty phone,
/// which collides on the second operator ever created (see migration 20260721140000 §5).
async function createAuthUser(args: {
  email: string;
  password: string;
  fullName: string;
}): Promise<string> {
  const response = await fetch(`${projectUrl()}/auth/v1/admin/users`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      apikey: serviceKey(),
      Authorization: `Bearer ${serviceKey()}`,
    },
    body: JSON.stringify({
      email: args.email,
      password: args.password,
      email_confirm: true,
      user_metadata: {
        full_name: args.fullName,
        role: "office_user",
      },
    }),
  });

  const text = await response.text();
  if (!response.ok) {
    // 422 from GoTrue on this endpoint is almost always "email already registered",
    // which for a synthetic address means the username is spoken for — including by a
    // previously removed operator whose auth row still exists.
    if (response.status === 422) {
      throw new OnboardError("username_taken", 409);
    }
    // The request body carried the password; the response must not be logged verbatim
    // in case GoTrue echoes any of it back.
    console.error("admin createUser failed", response.status);
    throw new OnboardError("auth_user_creation_failed", 502);
  }

  const user = JSON.parse(text) as { id?: string };
  if (!user.id) {
    throw new OnboardError("auth_user_creation_failed", 502);
  }
  return user.id;
}

/// Compensating delete. Never throws: it runs on the failure path, and masking the
/// original error with a cleanup error would hide why onboarding failed.
async function deleteAuthUser(userId: string): Promise<void> {
  try {
    const response = await fetch(
      `${projectUrl()}/auth/v1/admin/users/${userId}`,
      {
        method: "DELETE",
        headers: {
          apikey: serviceKey(),
          Authorization: `Bearer ${serviceKey()}`,
        },
      },
    );
    if (!response.ok) {
      console.error(
        "orphaned auth user, delete manually",
        userId,
        response.status,
      );
    }
  } catch (error) {
    console.error("orphaned auth user, delete manually", userId, String(error));
  }
}

// ── Password ─────────────────────────────────────────────────────────────────────────

/// A 16-character password from the CSPRNG, guaranteed to carry at least one glyph from
/// each class so it satisfies any password policy GoTrue is configured with.
///
/// Returned to the platform admin once, in the response body, and nowhere else: it is
/// not logged, not written to the database, and not recoverable afterwards. If it is
/// lost, the account's password is reset — not looked up.
function generatePassword(): string {
  const lower = "abcdefghijkmnopqrstuvwxyz";
  const upper = "ABCDEFGHJKLMNPQRSTUVWXYZ";
  const digits = "23456789";
  const symbols = "!@#$%*?";
  const all = lower + upper + digits + symbols;

  const pick = (alphabet: string, count: number): string[] => {
    const bytes = new Uint32Array(count);
    crypto.getRandomValues(bytes);
    return Array.from(bytes, (b) => alphabet[b % alphabet.length]);
  };

  const chars = [
    ...pick(lower, 1),
    ...pick(upper, 1),
    ...pick(digits, 1),
    ...pick(symbols, 1),
    ...pick(all, 12),
  ];

  // Fisher-Yates over the CSPRNG, so the guaranteed glyphs do not sit in fixed slots.
  const order = new Uint32Array(chars.length);
  crypto.getRandomValues(order);
  for (let i = chars.length - 1; i > 0; i--) {
    const j = order[i] % (i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join("");
}

// ── Response ─────────────────────────────────────────────────────────────────────────

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
