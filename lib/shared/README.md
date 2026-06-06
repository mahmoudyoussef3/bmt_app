# Shared Infrastructure

This folder is the future home of code that is genuinely reused across products.

Allowed shared code:

- Theme and design system exports
- Reusable widgets
- Networking primitives
- Security primitives
- Common result/error/value types

Product-specific presentation, domain, data, routes, and DI must stay inside the
owning product under `apps/client`, `apps/captain`, or `apps/dashboard`.

