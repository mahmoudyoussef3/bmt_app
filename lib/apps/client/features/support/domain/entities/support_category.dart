/// The topics a client can file a ticket under.
///
/// Single source of truth for the create-ticket dropdown. The Support Center
/// itself no longer browses by category — a ticket is always opened from the
/// one CTA, and the topic is picked inside the form.
const List<String> supportTicketCategories = [
  'Booking Issue',
  'Payment Issue',
  'Trip Delay',
  'Driver or Vehicle Issue',
  'Subscription Issue',
  'Lost Item',
  'Other',
];

/// Fallback used when no category has been picked yet.
const String defaultSupportCategory = 'Other';
