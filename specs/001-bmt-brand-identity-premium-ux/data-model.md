# Data Model: Prompt 3 – BMT Brand Identity & Premium UX

This feature does not introduce new business entities. It defines a shared UX model made of reusable presentation primitives and semantic states that the future implementation should standardize.

## Entities

### Brand Token System

Represents the shared semantic design vocabulary for the BMT platform.

**Key attributes**:
- Color roles
- Typography roles
- Spacing scale
- Radius scale
- Elevation roles
- Motion durations and easing intent
- Semantic states

**Relationships**:
- Drives all reusable visual components
- Applies across dashboard, client, and driver apps

**Validation rules**:
- Every interactive or informational surface should map back to a named semantic token.
- Light and dark variants must preserve the same meaning.

### Transportation Marker

Represents branded map symbols for live vehicles, stops, route progress, and route direction.

**Key attributes**:
- Marker type
- Operational state
- Directional emphasis
- Relative priority
- Readability level at small scale

**Relationships**:
- Used by route maps and live monitoring surfaces
- Must remain visually distinct from station and stop markers

**Validation rules**:
- Active vehicles must be more prominent than scheduled or inactive vehicles.
- Marker meaning must remain distinguishable in light and dark modes.

### Captain Card

Represents a reusable operational identity card for drivers/captains.

**Key attributes**:
- Name
- Identity signal
- Status
- Assignment context
- Primary action

**Relationships**:
- Appears in fleet, assignment, and trip management views

**Validation rules**:
- Identity and status must appear before decorative treatment.
- Compact and expanded versions must preserve the same meaning.

### Station / Stop Card

Represents a route stop or station summary component.

**Key attributes**:
- Stop name
- Sequence position
- Timing context
- Visit state
- Operational hints

**Relationships**:
- Used in route timelines, trip detail views, and map-linked panels

**Validation rules**:
- The card must support upcoming, arriving, arrived, departed, skipped, and delayed states.
- Time information must remain subordinate to stop identity and visit state.

### Route Information Component

Represents the reusable summary for a route or trip path.

**Key attributes**:
- Route identity
- Origin and destination
- Duration
- Distance
- Service level
- Operational status
- Progress state

**Relationships**:
- Used in discovery, details, and live monitoring contexts

**Validation rules**:
- The same component family must work in compact and expansive layouts.
- Route progress must be visually legible without extra explanation.

### Feedback State

Represents the system’s response during loading, empty, error, and success moments.

**Key attributes**:
- State type
- Message clarity
- Visual priority
- Recovery cue
- Motion intent

**Relationships**:
- Appears across every major flow in the platform

**Validation rules**:
- No major screen should use a blank default state.
- Error and success messages must be specific to the action that triggered them.
