const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

declare const Deno: {
  env: { get(key: string): string | undefined };
  serve(handler: (req: Request) => Response | Promise<Response>): void;
};

/// Merchant credentials are deliberately absent here. Each office collects its own
/// money, so integration_id / iframe_id are resolved server-side from the booking's
/// office (see fetchOfficePaymentConfig). A client that still sends them is ignored:
/// trusting a caller-supplied integration id would let a rider route another office's
/// payment — or their own — to a merchant account of their choosing.
type CheckoutRequest = {
  booking_id?: string;
  amount?: number | string;
  currency?: string;
  route?: string;
  trip_id?: string;
  seat?: string;
  customer?: {
    email?: string;
    name?: string;
    phone?: string;
  };
};

type PaymobAuthResponse = {
  token?: string;
};

type PaymobOrderResponse = {
  id?: number;
};

type PaymobPaymentKeyResponse = {
  token?: string;
};

const paymobBaseUrl = "https://accept.paymob.com";
const defaultPaymobCardIntegrationId = "4923808";
const defaultPaymobIframeId = "893140";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const config = readPaymobConfig();
    const payload = await req.json() as CheckoutRequest;
    const normalized = normalizeCheckoutRequest(payload);

    // Which office is being paid decides which merchant account receives the money.
    const officeConfig = await fetchOfficePaymentConfig(normalized.bookingId);
    const checkoutConfig = resolveCheckoutConfig(config, officeConfig);

    const authToken = await getAuthToken(checkoutConfig.apiKey);
    const orderId = await createPaymobOrder({
      authToken,
      amountCents: normalized.amountCents,
      currency: normalized.currency,
      bookingId: normalized.bookingId,
      route: normalized.route,
      tripId: normalized.tripId,
      seat: normalized.seat,
    });
    const paymentKey = await createPaymentKey({
      authToken,
      orderId,
      amountCents: normalized.amountCents,
      currency: normalized.currency,
      integrationId: checkoutConfig.integrationId,
      customer: normalized.customer,
    });

    // Record the order against the booking before handing the rider over.
    // The transaction callback knows only the Paymob order id, so without
    // this link a successful payment has no booking to settle.
    await linkOrderToBooking(normalized.bookingId, orderId);

    const checkoutUrl =
      `${paymobBaseUrl}/api/acceptance/iframes/${checkoutConfig.iframeId}` +
      `?payment_token=${encodeURIComponent(paymentKey)}`;

    return jsonResponse({
      checkout_url: checkoutUrl,
      gateway_reference: orderId.toString(),
      order_id: orderId,
    });
  } catch (error) {
    return jsonResponse(
      { error: error instanceof Error ? error.message : String(error) },
      400,
    );
  }
});

/// Stamps the Paymob order id onto the booking's payment row via the
/// service-role-only RPC. A failure here is fatal on purpose: sending the
/// rider to a checkout whose result could never be matched back to their
/// booking would take their money and lose their seat.
async function linkOrderToBooking(bookingId: string, orderId: number) {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    throw new Error(
      "SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are not available to this function.",
    );
  }

  const response = await fetch(
    `${supabaseUrl}/rest/v1/rpc/link_paymob_order`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
      body: JSON.stringify({
        p_booking_id: bookingId,
        p_order_id: orderId.toString(),
      }),
    },
  );

  if (!response.ok) {
    const detail = await response.text();
    throw new Error(
      `Could not link Paymob order to booking (${response.status}): ${detail}`,
    );
  }
}

function readPaymobConfig() {
  const apiKey =
    Deno.env.get("PAYMOB_API_KEY") ?? Deno.env.get("PAYMOB_SECRET_KEY");
  const integrationId =
    Deno.env.get("PAYMOB_CARD_INTEGRATION_ID") ??
      Deno.env.get("PAYMOB_INTEGRATION_ID") ??
      defaultPaymobCardIntegrationId;
  const iframeId = Deno.env.get("PAYMOB_IFRAME_ID") ?? defaultPaymobIframeId;

  if (!apiKey) {
    throw new Error(
      "Paymob env is missing. Configure PAYMOB_API_KEY as a Supabase secret.",
    );
  }

  const parsedIntegrationId = Number(integrationId);
  if (!Number.isFinite(parsedIntegrationId) || parsedIntegrationId <= 0) {
    throw new Error("Paymob card integration id must be a valid number.");
  }

  return {
    apiKey,
    integrationId: parsedIntegrationId,
    iframeId,
  };
}

type OfficePaymentConfig = {
  office_id?: string;
  office_name?: string;
  integration_id?: string | null;
  iframe_id?: string | null;
  api_key?: string | null;
  configured?: boolean;
};

/// Reads the owning office's merchant wiring with the service-role key. The RPC has
/// EXECUTE granted to nobody — service_role bypasses that, so this is the only path.
async function fetchOfficePaymentConfig(
  bookingId: string,
): Promise<OfficePaymentConfig> {
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceKey) {
    throw new Error(
      "SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY are not available to this function.",
    );
  }

  const response = await fetch(
    `${supabaseUrl}/rest/v1/rpc/resolve_booking_payment_config`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
      },
      body: JSON.stringify({ p_booking_id: bookingId }),
    },
  );

  if (!response.ok) {
    const detail = await response.text();
    throw new Error(
      `Could not resolve the office payment configuration (${response.status}): ${detail}`,
    );
  }

  return await response.json() as OfficePaymentConfig;
}

/// Office configuration wins; the platform env vars are the fallback so the incumbent
/// office keeps working before anyone fills in office_payment_configs.
function resolveCheckoutConfig(
  config: { apiKey: string; integrationId: number; iframeId: string },
  office: OfficePaymentConfig,
) {
  const rawIntegration = office.integration_id;
  const integrationId = rawIntegration == null ||
      String(rawIntegration).trim().length === 0
    ? config.integrationId
    : Number(rawIntegration);
  if (!Number.isFinite(integrationId) || integrationId <= 0) {
    throw new Error(
      `Paymob card integration id is invalid for office ${
        office.office_name ?? office.office_id ?? "unknown"
      }.`,
    );
  }

  const iframeId = sanitizeText(office.iframe_id, config.iframeId);
  const apiKey = sanitizeText(office.api_key, config.apiKey);

  return { integrationId, iframeId, apiKey };
}

function normalizeCheckoutRequest(payload: CheckoutRequest) {
  const amount = Number(payload.amount);
  const bookingId = String(payload.booking_id ?? "").trim();
  if (!bookingId) throw new Error("booking_id is required.");
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error("amount must be a positive number.");
  }

  const customer = payload.customer ?? {};
  const name = sanitizeText(customer.name, "BMT Passenger");
  const nameParts = name.split(/\s+/).filter(Boolean);

  return {
    bookingId,
    amountCents: Math.round(amount * 100),
    currency: sanitizeText(payload.currency, "EGP"),
    route: sanitizeText(payload.route, "BMT trip booking"),
    tripId: sanitizeText(payload.trip_id, ""),
    seat: sanitizeText(payload.seat, ""),
    customer: {
      email: sanitizeEmail(customer.email),
      firstName: nameParts[0] ?? "BMT",
      lastName: nameParts.length > 1 ? nameParts.slice(1).join(" ") : "User",
      phone: sanitizePhone(customer.phone),
    },
  };
}

async function getAuthToken(apiKey: string) {
  const response = await postPaymob<PaymobAuthResponse>("/api/auth/tokens", {
    api_key: apiKey,
  });
  if (!response.token) throw new Error("Paymob auth token was not returned.");
  return response.token;
}

async function createPaymobOrder(input: {
  authToken: string;
  amountCents: number;
  currency: string;
  bookingId: string;
  route: string;
  tripId: string;
  seat: string;
}) {
  const response = await postPaymob<PaymobOrderResponse>(
    "/api/ecommerce/orders",
    {
      auth_token: input.authToken,
      delivery_needed: "false",
      amount_cents: input.amountCents.toString(),
      currency: input.currency,
      merchant_order_id: input.bookingId,
      items: [
        {
          name: `BMT booking ${input.bookingId}`,
          amount_cents: input.amountCents.toString(),
          description: input.route,
          quantity: "1",
        },
      ],
      data: {
        booking_id: input.bookingId,
        trip_id: input.tripId,
        seat: input.seat,
      },
    },
    input.authToken,
  );
  if (!response.id) throw new Error("Paymob order id was not returned.");
  return response.id;
}

async function createPaymentKey(input: {
  authToken: string;
  orderId: number;
  amountCents: number;
  currency: string;
  integrationId: number;
  customer: {
    email: string;
    firstName: string;
    lastName: string;
    phone: string;
  };
}) {
  const response = await postPaymob<PaymobPaymentKeyResponse>(
    "/api/acceptance/payment_keys",
    {
      auth_token: input.authToken,
      order_id: input.orderId,
      amount_cents: input.amountCents.toString(),
      currency: input.currency,
      integration_id: input.integrationId,
      lock_order_when_paid: "false",
      billing_data: {
        apartment: "NA",
        email: input.customer.email,
        floor: "NA",
        first_name: input.customer.firstName,
        street: "NA",
        building: "NA",
        phone_number: input.customer.phone,
        shipping_method: "NA",
        postal_code: "NA",
        city: "Cairo",
        country: "EG",
        last_name: input.customer.lastName,
        state: "Cairo",
      },
    },
    input.authToken,
  );
  if (!response.token) throw new Error("Paymob payment key was not returned.");
  return response.token;
}

async function postPaymob<T>(
  path: string,
  body: Record<string, unknown>,
  bearerToken?: string,
) {
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };
  if (bearerToken) {
    headers.Authorization = `Bearer ${bearerToken}`;
  }

  const response = await fetch(`${paymobBaseUrl}${path}`, {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
  const data = await response.json() as Record<string, unknown>;
  if (!response.ok) {
    throw new Error(paymobErrorMessage(data, path));
  }
  return data as T;
}

function paymobErrorMessage(data: Record<string, unknown>, path: string) {
  const detail = data.detail;
  if (typeof detail === "string" && detail.trim().length > 0) {
    return friendlyPaymobMessage(detail, path);
  }

  const message = data.message;
  if (typeof message === "string" && message.trim().length > 0) {
    return friendlyPaymobMessage(message, path);
  }

  const errors = data.errors;
  if (Array.isArray(errors) && errors.length > 0) {
    return errors.map((error) => String(error)).join(", ");
  }

  return `Paymob request failed: ${path}`;
}

function friendlyPaymobMessage(message: string, path: string) {
  const normalized = message.toLowerCase();
  if (normalized.includes("unrelated payment integration")) {
    return "Paymob configuration mismatch: the card integration_id is not related to this Paymob account/API key, or the iframe_id belongs to a different integration. Verify PAYMOB_API_KEY, PAYMOB_CARD_INTEGRATION_ID, PAYMOB_IFRAME_ID, and payment_methods.metadata.";
  }
  return message || `Paymob request failed: ${path}`;
}

function jsonResponse(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function sanitizeText(value: unknown, fallback: string) {
  const text = String(value ?? "").trim();
  return text.length === 0 ? fallback : text;
}

function sanitizeEmail(value: unknown) {
  const email = String(value ?? "").trim();
  return email.includes("@") ? email : "passenger@bmt.app";
}

function sanitizePhone(value: unknown) {
  const phone = String(value ?? "").replace(/[^\d+]/g, "");
  return phone.length >= 8 ? phone : "01000000000";
}
