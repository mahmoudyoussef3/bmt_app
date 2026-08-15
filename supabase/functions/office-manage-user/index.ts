// =====================================================================================
// EWT office administration — staff accounts
// -------------------------------------------------------------------------------------
// Lets the OWNER of an office create a dashboard login for a colleague, and reset that
// colleague's password when it is lost. The same split as platform-create-office, for
// the same reason:
//
//   SQL  (office_create_staff, office_staff_reset_target)
//        everything about membership and authorization — which office, which role,
//        which username, and whether this caller may touch this row at all. Called with
//        the CALLER's JWT, and every one of those functions re-checks
//        dashboard_admin-of-this-office itself.
//   HERE (Auth Admin API)
//        the one step SQL cannot do: writing auth.users. Creating the row, resetting a
//        password, and deleting the row again when the transaction below it fails.
//
// So this function grants no authority. A support agent who reached it is refused by
// Postgres; a caller who names another office's staff row is refused by
// office_staff_reset_target. The service-role key is used for exactly three calls —
// create user, update password, delete user — and never to write business data.
//
// Secrets discipline: a generated password is returned to the caller exactly once, in
// the response body. It is never logged, never persisted, and never echoed back when
// the caller supplied their own.
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
/// convention migration 20260721090100 documents and platform-create-office follows.
/// An office's staff must land on the same domain, or resolve_office_user_login would
/// hand the sign-in screen an address nobody can receive mail at anyway, with the extra
/// cost of looking like a real one.
const loginEmailDomain = "office.ewt.internal";

type ManageRequest = {
  action?: string;
  username?: string;
  full_name?: string;
  role?: string;
  password?: string;
  office_user_id?: string;
};

class StaffError extends Error {
  constructor(
    readonly code: string,
    readonly status: number,
    message?: string,
    /// Postgres' `DETAIL:` payload, forwarded verbatim when there is one.
    ///
    /// Only licensing refusals carry it: `enforce_office_quota` raises
    /// `quota_exceeded` with the whole verdict (plan, limit, used) attached, and the
    /// Dashboard turns that into "12 من 12 مستخدماً على الأساسية" rather than a bare
    /// error string. Dropping it here would silently downgrade every quota refusal
    /// reaching this function into a generic failure.
    readonly detail?: string,
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
      throw new StaffError("method_not_allowed", 405);
    }

    const callerJwt = readCallerJwt(req);
    const payload = await readPayload(req);

    if (payload.action === "reset_password") {
      return await resetPassword(callerJwt, payload);
    }
    if (payload.action !== undefined && payload.action !== "create") {
      throw new StaffError("invalid_action", 400);
    }

    const input = validateCreate(payload);

    // Fails fast on the common mistake — a name already in use — before an auth user
    // exists to compensate for. It also fails fast for a caller who is not this
    // office's owner, since the RPC gates on that. The RPC below re-checks both; this
    // is the cheap door, not the lock.
    const availability = await rpc<{ username_available?: boolean }>(
      callerJwt,
      "office_staff_username_available",
      { p_username: input.username },
    );
    if (availability?.username_available === false) {
      throw new StaffError("username_taken", 409);
    }

    const generatedPassword = input.password ? null : generatePassword();
    const password = input.password ?? generatedPassword!;

    createdUserId = await createAuthUser({
      email: `${input.username}@${loginEmailDomain}`,
      password,
      fullName: input.fullName,
    });

    const staff = await rpc<Record<string, unknown>>(
      callerJwt,
      "office_create_staff",
      {
        p_user_id: createdUserId,
        p_username: input.username,
        p_role: input.role,
        p_full_name: input.fullName,
      },
    );

    // Past this point the membership row is committed; the auth user is spoken for.
    createdUserId = null;

    return jsonResponse({
      staff,
      login_username: input.username,
      // Present only when this function generated it. When the owner chose the
      // password, echoing it back would put a known secret on the wire for no reason.
      ...(generatedPassword ? { temporary_password: generatedPassword } : {}),
    }, 201);
  } catch (error) {
    // Compensate: the auth user exists but the membership it was created for does not.
    if (createdUserId) {
      await deleteAuthUser(createdUserId);
    }

    if (error instanceof StaffError) {
      return jsonResponse({
        error: error.code,
        message: error.message,
        ...(error.detail ? { detail: error.detail } : {}),
      }, error.status);
    }
    // Deliberately opaque: an unexpected failure here can carry Postgres detail, and
    // this endpoint answers to a browser.
    console.error("office-manage-user failed", String(error));
    return jsonResponse({ error: "staff_action_failed" }, 500);
  }
});

// ── Password reset ───────────────────────────────────────────────────────────────────

/// Resets a colleague's password to a freshly generated one, or to the one the owner
/// typed.
///
/// The target is named by its `office_users.id`, never by an auth user id: the RPC maps
/// one to the other and refuses any row outside the caller's office, so the only ids
/// this function ever hands to the Admin API are ids Postgres just authorized.
///
/// There is no compensating write to make. The Admin API call is the whole operation,
/// and nothing in `public` changes.
async function resetPassword(
  callerJwt: string,
  payload: ManageRequest,
): Promise<Response> {
  const officeUserId = str(payload.office_user_id);
  if (!officeUserId) {
    throw new StaffError("staff_not_found", 400);
  }

  const chosen = str(payload.password);
  if (chosen && chosen.length < 10) {
    throw new StaffError("weak_password", 400);
  }

  const target = await rpc<{ user_id?: string; username?: string }>(
    callerJwt,
    "office_staff_reset_target",
    { p_office_user_id: officeUserId },
  );
  const userId = str(target?.user_id);
  if (!userId) {
    throw new StaffError("staff_not_found", 404);
  }

  const generatedPassword = chosen ? null : generatePassword();
  await updateAuthPassword(userId, chosen || generatedPassword!);

  return jsonResponse({
    login_username: target?.username ?? "",
    ...(generatedPassword ? { temporary_password: generatedPassword } : {}),
  });
}

// ── Request handling ─────────────────────────────────────────────────────────────────

function readCallerJwt(req: Request): string {
  const header = req.headers.get("Authorization") ?? "";
  const token = header.toLowerCase().startsWith("bearer ")
    ? header.slice(7).trim()
    : "";
  if (!token) {
    throw new StaffError("not_authenticated", 401);
  }
  return token;
}

async function readPayload(req: Request): Promise<ManageRequest> {
  try {
    const body = await req.json();
    if (!body || typeof body !== "object") throw new Error("not an object");
    return body as ManageRequest;
  } catch {
    throw new StaffError("invalid_payload", 400);
  }
}

type ValidatedCreate = {
  username: string;
  fullName: string;
  role: string;
  password: string | null;
};

/// Server-side validation of everything the caller sends.
///
/// `office_create_staff` validates the same fields again — it has to, since it is
/// directly callable by any office owner. Doing it here as well is what lets the UI
/// show a specific message instead of a Postgres error string, and keeps a malformed
/// payload from reaching the Auth Admin API at all.
function validateCreate(body: ManageRequest): ValidatedCreate {
  const username = str(body.username).toLowerCase();
  if (
    !/^[a-z0-9][a-z0-9._-]*$/.test(username) ||
    username.length < 3 || username.length > 32
  ) {
    throw new StaffError("invalid_username", 400);
  }

  const fullName = str(body.full_name);
  if (fullName.length > 120) {
    throw new StaffError("invalid_full_name", 400);
  }

  // Defaults to the least privileged of the two roles. An absent `role` must never
  // mean "owner".
  const role = str(body.role) || "support_agent";
  if (role !== "dashboard_admin" && role !== "support_agent") {
    throw new StaffError("invalid_role", 400);
  }

  const password = str(body.password);
  if (password && password.length < 10) {
    throw new StaffError("weak_password", 400);
  }

  return { username, fullName, role, password: password || null };
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
/// PostgREST before the function body runs, and assert_office_staff_admin() inside each
/// RPC then decides whether the caller may proceed.
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
    throw new StaffError("not_authenticated", 401);
  }

  const text = await response.text();
  if (!response.ok) {
    const { code, detail } = postgresError(text);
    throw new StaffError(code, statusForCode(code), undefined, detail);
  }

  return (text ? JSON.parse(text) : null) as T;
}

/// `raise exception 'username_taken'` surfaces as {"message":"username_taken", ...}.
/// Lifting the bare code out keeps the machine-readable contract the Dashboard maps to
/// Arabic, and keeps Postgres internals (hints, positions, SQL text) out of the
/// response.
///
/// `details` is the one field worth passing through: it is empty for every error above,
/// and carries the licensing verdict for the quota refusals `office_create_staff` can
/// hit through `trg_quota_office_users`.
function postgresError(body: string): { code: string; detail?: string } {
  try {
    const parsed = JSON.parse(body) as {
      message?: string;
      code?: string;
      details?: unknown;
    };
    const detail = typeof parsed.details === "string" ? parsed.details : undefined;
    const message = (parsed.message ?? "").trim();
    if (/^[a-z0-9_]+$/.test(message)) return { code: message, detail };
    if (parsed.code === "23505") return { code: "username_taken" };
    return { code: "staff_action_rejected" };
  } catch {
    return { code: "staff_action_rejected" };
  }
}

function statusForCode(code: string): number {
  if (code === "dashboard_admin_required" || code === "not_an_office_user") return 403;
  if (code === "staff_not_found") return 404;
  if (code === "username_taken" || code === "staff_user_already_assigned") return 409;
  return 400;
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
      throw new StaffError("username_taken", 409);
    }
    // The request body carried the password; the response must not be logged verbatim
    // in case GoTrue echoes any of it back.
    console.error("admin createUser failed", response.status);
    throw new StaffError("auth_user_creation_failed", 502);
  }

  const user = JSON.parse(text) as { id?: string };
  if (!user.id) {
    throw new StaffError("auth_user_creation_failed", 502);
  }
  return user.id;
}

async function updateAuthPassword(userId: string, password: string): Promise<void> {
  const response = await fetch(
    `${projectUrl()}/auth/v1/admin/users/${userId}`,
    {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceKey(),
        Authorization: `Bearer ${serviceKey()}`,
      },
      body: JSON.stringify({ password }),
    },
  );

  if (!response.ok) {
    console.error("admin updateUser failed", response.status);
    throw new StaffError("password_reset_failed", 502);
  }
}

/// Compensating delete. Never throws: it runs on the failure path, and masking the
/// original error with a cleanup error would hide why provisioning failed.
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
/// Returned to the owner once, in the response body, and nowhere else: it is not
/// logged, not written to the database, and not recoverable afterwards. If it is lost,
/// the account's password is reset — not looked up.
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
