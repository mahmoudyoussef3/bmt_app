-- Migration: update_existing_booking_payment
-- Description: Adds RPC to allow updating payment details for an existing 'reserved' booking instead of creating a duplicate.

create or replace function public.update_existing_booking_payment(
  p_booking_id uuid,
  p_payment_method text,
  p_receipt_url text default null,
  p_payment_reference text default null,
  p_payer_phone text default null
) returns jsonb
language plpgsql
security definer
as $$
declare
  v_client_id uuid := auth.uid();
  v_booking public.operation_bookings%rowtype;
begin
  if v_client_id is null then
    raise exception 'not_authorized';
  end if;

  if p_payment_method not in (
    'credit_card', 'instapay', 'vodafone_cash', 'bank_transfer'
  ) then
    raise exception 'payment_method_not_allowed';
  end if;

  if p_payment_method <> 'credit_card'
     and nullif(trim(coalesce(p_receipt_url, '')), '') is null then
    raise exception 'payment_receipt_required';
  end if;

  select * into v_booking
  from public.operation_bookings
  where id = p_booking_id
  for update;

  if not found then
    raise exception 'booking_not_found';
  end if;

  if v_booking.client_id <> v_client_id then
    raise exception 'not_authorized';
  end if;

  if v_booking.status <> 'reserved' then
    raise exception 'booking_not_reserved';
  end if;

  update public.operation_bookings
  set payment_method = p_payment_method,
      payment_receipt_url = p_receipt_url,
      payment_status = case when p_payment_method = 'credit_card' then 'pending' else 'submitted' end,
      payment_review_status = 'pending'
  where id = p_booking_id;

  insert into public.booking_payments (
    booking_id, client_id, method, amount, status, receipt_url,
    payment_reference, payer_phone
  ) values (
    p_booking_id, v_client_id, p_payment_method, v_booking.payment_amount,
    case when p_payment_method = 'credit_card' then 'pending' else 'submitted' end,
    p_receipt_url, nullif(trim(coalesce(p_payment_reference, '')), ''),
    nullif(trim(coalesce(p_payer_phone, '')), '')
  );

  return jsonb_build_object(
    'booking_id', v_booking.id,
    'booking_number', v_booking.booking_number
  );
end;
$$;
