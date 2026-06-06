# Client Product Boundary

This folder is the future home of the passenger-facing product.

During the UI prototype stage, existing screens remain in their current
locations. New client-only architecture scaffolding can be added here without
moving feature implementations yet.

Allowed dependencies:

- `apps/client/**` may depend on `shared/**`.
- `apps/client/**` must not depend on `apps/captain/**`.
- `apps/client/**` must not depend on `apps/dashboard/**`.

Future feature modules belong in `features/`, each with:

```text
feature_name/
  presentation/
  domain/
  data/
```

