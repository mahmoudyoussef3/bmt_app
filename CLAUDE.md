# Claude AI Assistant Instructions

**CRITICAL INSTRUCTION:** You **MUST** read `PROJECT_INDEX.md` before starting any task, analyzing code, or making any changes to this repository. `PROJECT_INDEX.md` is the authoritative source of truth for the project.

When working on this project, adhere strictly to the following rules:

1. **Follow Architecture:** Strictly adhere to the Flutter Clean Architecture boundaries (Presentation → Domain → Data) and Dependency Injection (GetIt) rules outlined in `PROJECT_INDEX.md`. Do not bypass layers.
2. **Preserve Business Rules:** Understand the core entities and operational lifecycle (e.g., Trips, Vehicles, Bookings) before making edits. Do not alter core business logic without explicit user instruction.
3. **Preserve Relationships Between Apps:** Be mindful that changes in the `dashboard` often affect the `client` and `driver` apps. Ensure database and entity parity.
4. **Do Not Introduce Mock Data:** Refer to the "Mock Data Policy" in `PROJECT_INDEX.md`. Always integrate with the real Supabase backend. Never create hardcoded dummy responses, local JSON mocks, or use `List.generate()` to fake data. Remove existing mock datasources when you encounter them.
5. **Respect Validation Rules:** Ensure all forms, entity creations, and API requests enforce the documented system validation constraints.

By reading `PROJECT_INDEX.md` first, you will avoid violating the foundational rules of this codebase.
