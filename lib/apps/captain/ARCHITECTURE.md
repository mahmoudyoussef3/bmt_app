# Captain Product Boundary

This folder is the future home of the driver trip execution product.

During the UI prototype stage, existing screens remain in their current
locations. New captain-only architecture scaffolding can be added here without
moving feature implementations yet.

Allowed dependencies:

- `apps/captain/**` may depend on `shared/**`.
- `apps/captain/**` must not depend on `apps/client/**`.
- `apps/captain/**` must not depend on `apps/dashboard/**`.

Captain owns trip execution workflows only. Operational management such as
routes, bookings, vehicles, payments, refunds, and packages belongs to the
dashboard product.

