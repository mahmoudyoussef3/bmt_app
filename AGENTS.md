# Universal AI Agent Instructions

**CRITICAL INSTRUCTION:** Every AI agent (including Codex, Claude Code, Cursor Agent, Gemini CLI, Copilot Agent, and others) **MUST** read `PROJECT_INDEX.md` before starting any task, performing analysis, or modifying code. `PROJECT_INDEX.md` is the authoritative source of knowledge for this project.

When interacting with this repository, you must adhere to the following directives:

1. **Read `PROJECT_INDEX.md` First:** Do not guess the architecture, folder structure, or database schema. Read the index to ground your context.
2. **Understand Entities Before Editing:** Review how entities relate to each other (e.g., how a Trip connects a Route, Vehicle, Driver, and Passengers) before making any modifications.
3. **Follow Architecture:** This project strictly uses Flutter Clean Architecture. Do not bypass layers. Presentation calls Domain (UseCases), Domain calls Data (Repositories). Dependency Injection is strictly handled via GetIt.
4. **Preserve Integrations:** Maintain the integrity of the Supabase backend connections and the interactions between the `dashboard`, `client`, and `driver` applications.
5. **Remove Mock Data:** This project enforces a strict "No Mock Data" policy. If you encounter any `Mock*Datasource`, local JSON files, or hardcoded UI data, you must remove them and replace them with real Supabase integrations. Never introduce new mock data.
6. **Validate Business Rules:** Ensure you validate operational constraints and business logic before implementing features or fixing bugs. Do not override established validation rules without explicit permission.
