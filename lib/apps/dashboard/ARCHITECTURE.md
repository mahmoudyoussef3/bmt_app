# Dashboard Product Boundary

This folder is the future home of the operations workspace.

During the UI prototype stage, existing screens remain in their current
locations. New dashboard-only architecture scaffolding can be added here without
moving feature implementations yet.

Allowed dependencies:

- `apps/dashboard/**` may depend on `shared/**`.
- `apps/dashboard/**` must not depend on `apps/client/**`.
- `apps/dashboard/**` must not depend on `apps/captain/**`.

Dashboard UX should stay Arabic, workflow-oriented, and focused on operational
queues, tables, actions, permissions, and fast navigation.

