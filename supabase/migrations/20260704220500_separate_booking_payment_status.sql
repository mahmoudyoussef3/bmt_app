-- migration_20_separate_booking_payment_status.sql
-- Add payment_status column to operation_bookings
ALTER TABLE public.operation_bookings
ADD COLUMN IF NOT EXISTS payment_status text not null default 'pending'
CHECK (payment_status in ('pending', 'submitted', 'underReview', 'approved', 'rejected', 'refunded', 'failed'));

-- Remove old constraint if it exists
ALTER TABLE public.operation_bookings
DROP CONSTRAINT IF EXISTS valid_booking_status;

-- Migrate existing data to the new decoupled statuses
-- Previous values might include: 'newRequest', 'paymentUploaded', 'underReview', 'approved', 'rejected', 'requestReupload', 'confirmed', 'cancelled'

UPDATE public.operation_bookings 
SET status = 'reserved', payment_status = 'pending' 
WHERE status = 'newRequest';

UPDATE public.operation_bookings 
SET status = 'reserved', payment_status = 'underReview' 
WHERE status IN ('paymentUploaded', 'underReview');

UPDATE public.operation_bookings 
SET status = 'reserved', payment_status = 'rejected' 
WHERE status = 'requestReupload';

UPDATE public.operation_bookings 
SET status = 'cancelled', payment_status = 'rejected' 
WHERE status = 'rejected';

UPDATE public.operation_bookings 
SET status = 'confirmed', payment_status = 'approved' 
WHERE status = 'approved';

-- Set new default for status
ALTER TABLE public.operation_bookings
ALTER COLUMN status SET DEFAULT 'draft';

-- Apply new constraint for booking status
ALTER TABLE public.operation_bookings
ADD CONSTRAINT valid_booking_status
CHECK (status in ('draft', 'reserved', 'confirmed', 'boarded', 'completed', 'cancelled'));
