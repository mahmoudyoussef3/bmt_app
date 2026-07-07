# Feature Specification: Prompt 3 – BMT Brand Identity & Premium UX

**Feature Branch**: `[001-bmt-brand-identity-premium-ux]`

**Created**: 2026-07-07

**Status**: Draft

**Input**: User description: "Prompt 3 – BMT Brand Identity & Premium UX"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Premium Brand Foundation (Priority: P1)

A passenger, captain, or operations user opens any BMT app and immediately experiences a consistent, premium transportation brand that feels calm, trustworthy, and operationally precise.

**Why this priority**: Brand identity is the foundation for every screen. If the visual system is inconsistent, all downstream workflows feel fragmented.

**Independent Test**: Review the core app surfaces side by side and confirm they present a single recognizable BMT identity with no conflicting visual language.

**Acceptance Scenarios**:

1. **Given** a user opens the dashboard, client, or driver app, **When** the first screen loads, **Then** the visual system feels consistent, premium, and clearly branded as BMT.
2. **Given** the same business state appears in multiple apps, **When** the user compares them, **Then** typography, color use, spacing, and component hierarchy remain aligned.

---

### User Story 2 - Map-First Transportation Experience (Priority: P2)

A user views routes, vehicles, stations, and live movement on maps that feel custom-built for BMT rather than generic map overlays.

**Why this priority**: Transportation is the core domain. The map experience must make routes, vehicles, and stops immediately understandable.

**Independent Test**: Inspect route, station, and vehicle map states and confirm they are identifiable at a glance, with branded markers and readable hierarchy.

**Acceptance Scenarios**:

1. **Given** a live trip or route map is open, **When** the user scans the screen for three seconds, **Then** the vehicle, route, and stop states are visually distinct without extra explanation.
2. **Given** a map is shown in light or dark theme, **When** the theme changes, **Then** the BMT route identity remains clear and legible.

---

### User Story 3 - Operational Components That Scale (Priority: P3)

A user interacts with captain cards, stop cards, route summaries, sheets, dialogs, buttons, chips, and badges that all feel like part of one premium SaaS system.

**Why this priority**: The product depends on repeated UI patterns across many workflows. Reusable components must be coherent and easy to scan.

**Independent Test**: Review the reusable component set across key screens and verify consistent sizing, states, semantics, and feedback behavior.

**Acceptance Scenarios**:

1. **Given** a user opens a card, sheet, or dialog, **When** the component appears, **Then** the layout, spacing, and actions follow the same BMT design language.
2. **Given** a user performs a successful or failed action, **When** feedback appears, **Then** it uses the same tone, motion, and severity system across the application.

### Edge Cases

- What happens when route names, stop names, or captain names are unusually long and risk visual overflow?
- How does the system remain readable when a vehicle, stop, or status is simultaneously important and space is constrained?
- What happens when the map is unavailable, stale, or partially loaded but the rest of the app must still feel premium?
- How should the UI behave in reduced-motion mode or on low-end devices that cannot sustain elaborate animation?
- How does the system preserve contrast and clarity in both light and dark themes for Arabic and Latin text?

## Requirements *(mandatory)*

### Experience Specification

#### 1. Product Vision and UX Philosophy

- The product MUST present BMT as a premium transportation SaaS platform that is trustworthy, calm, precise, and operationally confident.
- The experience MUST prioritize clarity, speed of recognition, and route comprehension over decorative visual effects.
- The UI MUST feel professional and contemporary, comparable in polish to Uber, Lyft, Citymapper, Moovit, and Swvl, while remaining distinctly BMT.
- The visual system MUST support three user contexts with one shared brand language: passenger journey, driver operation, and dashboard control.
- The interface MUST make transport state obvious at a glance: where the trip is, what vehicle is active, which stop is next, and what action matters now.

#### 2. Brand Identity and Personality

- The BMT brand MUST communicate reliability, movement, precision, safety, and premium service.
- The personality MUST feel confident and composed rather than loud, playful, or overly corporate.
- The brand voice in UI copy MUST be concise, operational, and reassuring.
- The design MUST avoid generic SaaS sameness and avoid copying any competitor's signature visual treatment.
- Brand expression MUST be recognizable through color, hierarchy, motion, marker shapes, and data presentation rather than through decorative branding alone.

#### 3. Visual Language and Design Principles

- The visual language MUST use clear hierarchy, strong alignment, generous breathing room, and consistent rhythm.
- The design MUST favor crisp surfaces, subtle depth, and controlled contrast over heavy shadows or busy textures.
- Operational information MUST be more prominent than ornamentation.
- Status, movement, and urgency MUST be encoded with restrained color and shape signals instead of excessive visual noise.
- Repeated patterns across the app MUST use the same spacing logic, corner treatment, and emphasis model.

#### 4. Complete Design System

- The design system MUST define reusable tokens for color, typography, spacing, sizing, radius, elevation, borders, and motion.
- The system MUST support light and dark themes from the same semantic token set.
- The system MUST provide explicit semantic states for neutral, success, warning, danger, info, active, selected, disabled, and loading.
- The system MUST define density rules for compact operational screens and more spacious discovery or detail screens.
- The system MUST keep surfaces, actions, and informational hierarchy consistent across dashboard, client, and driver contexts.

#### 5. Color Palette and Usage Guidelines

- The palette MUST be built around a premium transport identity with a deep primary base, a clear accent, and disciplined semantic colors.
- Primary color role: deep midnight blue for trust, structure, navigation, and major brand anchors.
- Secondary color role: transit teal for live movement, route emphasis, active states, and operational freshness.
- Accent color role: signal amber for highlights, calls to attention, and premium emphasis without overwhelming the interface.
- Neutral surfaces MUST remain soft, balanced, and high-contrast enough for dense information display.
- Semantic colors MUST be used sparingly and consistently; no color role may be overloaded for unrelated meanings.
- Light theme MUST keep surfaces bright without becoming stark white; dark theme MUST remain legible without flattening the brand identity.
- Route lines, live indicators, and vehicle states MUST have dedicated color treatment that remains visible on top of map and card surfaces.

#### 6. Typography Hierarchy

- Typography MUST feel premium, highly legible, and suitable for both Arabic and Latin content.
- The hierarchy MUST clearly distinguish display titles, page titles, section titles, body text, metadata, labels, and supporting captions.
- Large headings MUST be confident and condensed only where legibility is not reduced.
- Body copy MUST remain easy to scan in fast-moving operational contexts.
- Numeric content, times, route codes, seat counts, and status values MUST be visually prominent enough for rapid reading.
- Typography MUST support bidirectional layout without breaking rhythm, line length, or alignment.

#### 7. Spacing, Sizing, and Layout System

- The layout system MUST be based on a consistent spacing rhythm so cards, sheets, forms, and map overlays feel part of one product.
- Dense operational screens MUST use tighter spacing than discovery surfaces, but never collapse into clutter.
- Touch targets MUST remain comfortably sized even when the visual layout is compact.
- Content blocks MUST align to a predictable grid so repeated data structures are easy to compare.
- The system MUST support mobile, tablet, and desktop presentation without changing the underlying visual language.

#### 8. Iconography Guidelines

- Icons MUST be simple, recognizable, and consistent in stroke, corner language, and optical weight.
- Icons MUST communicate transport semantics clearly: route, bus, station, stop, location, seat, driver, alert, success, and navigation.
- Filled icons, outline icons, and badge icons MUST be used with clear rules so the interface does not feel mixed or noisy.
- Important operational icons MUST remain legible at small sizes and in reduced contrast scenarios.
- Decorative icon use MUST be limited; every icon should carry meaning.

#### 9. Map Styling and Branded Map Experience

- The map MUST feel native to BMT rather than a default utility map with generic pins.
- The map MUST reduce irrelevant visual clutter and elevate transportation-specific information such as routes, stations, live vehicles, and trip direction.
- Route overlays MUST be visually dominant enough to understand movement while still allowing surrounding geography to remain readable.
- Live trip indicators MUST have clear motion, halo, or emphasis treatment that communicates current state without flashing aggressively.
- Station labels, stop labels, and vehicle markers MUST remain readable in both light and dark modes.
- Map styling MUST support route discovery, trip monitoring, and stop planning without changing the core visual identity.

#### 10. Vehicle Markers and Custom Transportation Icons

- Vehicle markers MUST use a custom BMT transport identity rather than generic map pins.
- Marker design MUST communicate direction, status, and live motion.
- Active vehicles MUST be more visually prominent than inactive or scheduled ones.
- Markers MUST be recognizable at a glance in dense map situations and remain distinguishable from station and stop markers.
- Custom transportation icons MUST align with the rest of the iconography system and avoid mismatched illustration styles.

#### 11. Captain Card Design

- Captain cards MUST present identity, reliability, assignment context, and action priority in a single glance.
- A captain card MUST include the captain name, visual identifier, current status, route or trip association, and the most relevant action.
- The card hierarchy MUST make the person and operational state more important than decorative profile treatment.
- Status treatment MUST clearly distinguish available, assigned, in-progress, delayed, and unavailable states.
- The card layout MUST adapt between compact list views and richer detail views without losing consistency.

#### 12. Station and Stop Card Design

- Station and stop cards MUST present stop name, sequence, ETA or schedule context, and current visitation state.
- Cards MUST support upcoming, arriving, arrived, departed, skipped, and delayed states.
- The design MUST make it easy to understand the stop's role in the route without opening extra detail screens.
- Passenger-related signals, time estimates, and operational actions MUST remain visually separated but related.
- Station and stop cards MUST behave consistently in route timelines, trip detail sheets, and map-linked panels.

#### 13. Route Information Components

- Route information components MUST show route identity, origin, destination, duration, distance, service level, and current operational status.
- Progress indicators MUST clearly reflect route completion or trip progression.
- Route components MUST support both discovery and live monitoring contexts.
- Supporting metadata such as departure time, capacity, and availability MUST be visually subordinate to the route name and current state.
- Route components MUST be usable in header summaries, full detail screens, and compact cards without changing meaning.

#### 14. Bottom Sheets and Dialogs

- Bottom sheets MUST be a primary surface for details, confirmations, quick actions, and contextual inspection.
- Sheet depth MUST be intentionally tiered so users can distinguish quick preview, medium-detail, and high-attention interactions.
- Dialogs MUST be reserved for clear decisions, destructive confirmations, and critical approvals.
- Overlay surfaces MUST preserve readability, maintain brand polish, and avoid feeling like generic system dialogs.
- Sheet and dialog transitions MUST feel smooth, grounded, and proportional to the action being taken.

#### 15. Navigation Patterns

- Navigation MUST favor fast access to operational destinations and reduce the number of steps needed for frequent tasks.
- The app MUST support map-first, list-first, and detail-first patterns where each is appropriate.
- Primary navigation MUST remain consistent across the platform even when the screen density changes.
- Back navigation MUST feel predictable and preserve context wherever possible.
- Navigation labels and affordances MUST be easy to scan and never rely on guesswork.

#### 16. Buttons, Chips, Badges, and Reusable UI Components

- Buttons MUST have clear hierarchy: primary, secondary, tertiary, and destructive.
- Chips MUST be used for filters, statuses, quick selections, and context tags only.
- Badges MUST be concise and used to emphasize counts, alerts, and state changes.
- Reusable UI components MUST share the same radius, spacing, and feedback language.
- Components MUST have defined hover, focus, pressed, selected, disabled, and loading states.
- No component may introduce a one-off style that breaks the design system.

#### 17. Motion Design Philosophy

- Motion MUST reinforce comprehension, momentum, and trust.
- Animations MUST be subtle, purposeful, and fast enough to support operational use.
- Motion MUST help users understand hierarchy changes, selections, route progress, and state transitions.
- The system MUST avoid playful or distracting motion that slows down decisions.
- Motion MUST be consistent across cards, sheets, markers, and progress indicators.

#### 18. Animations and Micro-Interactions

- Selection feedback MUST feel immediate and restrained.
- Route progression, marker movement, sheet entrance, and state changes MUST have distinct but coherent motion patterns.
- Micro-interactions MUST communicate that the system is alive without becoming decorative.
- Success and error transitions MUST be visually clear but not theatrical.
- Motion must remain understandable when reduced-motion preferences are active.

#### 19. Loading, Empty, and Error States

- Loading states MUST never be blank; skeletons or structured placeholders should preserve layout confidence.
- Empty states MUST explain why content is absent and what the user can do next.
- Error states MUST be actionable, legible, and calm, with clear recovery guidance.
- Map and route loading states MUST still preserve spatial context where possible.
- Partial data availability MUST be handled gracefully without making the screen feel broken.

#### 20. Success Feedback

- Success feedback MUST confirm the outcome clearly and quickly.
- Success messaging MUST be specific to the completed action, not generic.
- Visual confirmation MUST be consistent across the system and should not rely only on color.
- High-stakes actions should receive stronger confirmation than routine taps.
- Success feedback MUST not interrupt the user flow longer than necessary.

#### 21. Haptic Feedback Recommendations

- Haptic feedback MUST reinforce important confirmations, selections, and high-stakes actions.
- Light feedback is appropriate for selection and navigation changes.
- Stronger feedback is appropriate for success confirmations or destructive actions.
- Haptics MUST not be repeated excessively or used for every low-value tap.
- Haptic patterns MUST be consistent across the platform so they feel like part of the BMT brand.

#### 22. Accessibility Considerations

- The system MUST meet strong contrast expectations for text, icons, and status treatments.
- Every interactive element MUST have a clear accessible name and a visible focus or selection state.
- Touch targets MUST remain large enough for safe use in motion-heavy operational contexts.
- Color MUST never be the sole indicator of state.
- The interface MUST support screen readers, bidirectional text, and reduced-motion preferences.
- Information density MUST not come at the expense of readability or comprehension.

#### 23. Light and Dark Theme Behavior

- Both themes MUST preserve the same visual hierarchy, not merely invert colors.
- Surfaces, overlays, strokes, and shadows MUST be tuned for each theme individually.
- Map presentation in dark mode MUST remain polished and readable, not washed out or overly neon.
- Brand identity MUST remain obvious in both themes through the same semantic palette and hierarchy rules.
- Theme changes MUST not change meaning, only presentation.

#### 24. Responsive Design Requirements

- The experience MUST adapt cleanly across phone, tablet, and desktop class screens.
- Smaller screens MUST prioritize the essential route, vehicle, stop, and action information.
- Larger screens MUST reveal more operational context without changing the component language.
- Layout changes MUST respect the same brand identity rather than creating separate visual systems by device type.
- Long text, dense data, and live map content MUST remain usable at all supported sizes.

#### 25. Premium SaaS Experience Guidelines

- The interface MUST feel intentional, polished, and calm rather than rushed or template-driven.
- Data should be presented with editorial clarity: important information first, supporting details second, decoration last.
- Spacing, alignment, and hierarchy MUST create a sense of control and operational confidence.
- Premium feel MUST come from restraint, clarity, and coherence rather than heavy effects.
- Every screen MUST communicate that BMT is a serious transportation operation platform.

#### 26. Consistency Rules for the Entire Application

- The same status language MUST mean the same thing in every app and every screen.
- The same spacing scale, radius system, and surface hierarchy MUST be reused everywhere.
- Shared component types MUST not be restyled differently for each feature unless the context truly requires it.
- Icons, badges, chips, and route markers MUST follow one visual grammar.
- All app surfaces MUST look like they belong to one product family.

#### 27. Performance Considerations Related to UI Rendering

- Visual effects MUST never compromise operational responsiveness.
- The interface MUST remain usable when many stops, cards, badges, or live indicators are shown at once.
- Motion and map emphasis MUST be restrained enough to remain smooth in busy trip contexts.
- The layout strategy MUST avoid visual clutter that makes scanning slower or hides critical state.
- The product MUST remain visually stable during loading, state transitions, and live updates.

#### 28. Things to Avoid During Implementation

- Avoid generic enterprise blue-and-white styling that could belong to any SaaS product.
- Avoid copying recognizable patterns from Uber, Lyft, Citymapper, Moovit, or Swvl.
- Avoid decorative gradients, excessive glow, heavy blur, or shadow soup.
- Avoid inconsistent card shapes, icon styles, or mismatched spacing rules.
- Avoid low-contrast text, tiny tap targets, and color-only state communication.
- Avoid over-animating routine interactions or making the interface feel playful instead of operational.
- Avoid blank loading states, vague errors, and generic success messages.
- Avoid separate one-off visual treatments per screen that fragment the BMT identity.

### Functional Requirements

- **FR-001**: The interface MUST present a single premium BMT brand identity across dashboard, client, and driver experiences.
- **FR-002**: The product MUST define a shared semantic design system for color, typography, spacing, sizing, radius, borders, and motion.
- **FR-003**: The product MUST provide consistent light and dark theme behavior without breaking hierarchy or readability.
- **FR-004**: The UI MUST support both Arabic and Latin content with clear hierarchy and stable layout behavior.
- **FR-005**: The design system MUST include reusable styles for buttons, chips, badges, cards, sheets, dialogs, and progress indicators.
- **FR-006**: The map experience MUST use BMT-specific styling that highlights routes, stations, and live vehicles.
- **FR-007**: Vehicle markers MUST be visually distinct from station and stop markers and MUST communicate movement or status at a glance.
- **FR-008**: Captain cards MUST surface identity, status, assignment, and action priority in a compact, premium format.
- **FR-009**: Station and stop cards MUST expose stop identity, sequence, timing, and visitation state in a clear and consistent layout.
- **FR-010**: Route information components MUST summarize route identity, service status, and trip progress without requiring extra explanation.
- **FR-011**: Bottom sheets and dialogs MUST use a consistent hierarchy for preview, detail, confirmation, and destructive action flows.
- **FR-012**: Navigation patterns MUST minimize friction for frequent operational tasks and preserve context during back navigation.
- **FR-013**: Motion and micro-interactions MUST support comprehension, feedback, and premium feel without becoming distracting.
- **FR-014**: Loading, empty, and error states MUST be designed for every major surface and MUST never leave the user with a blank or ambiguous screen.
- **FR-015**: Success feedback MUST confirm completed actions clearly and consistently across the product.
- **FR-016**: Haptic feedback MUST reinforce important selections and confirmations without becoming noisy.
- **FR-017**: The UI MUST satisfy accessibility expectations for contrast, focus visibility, touch targets, screen readers, and reduced motion.
- **FR-018**: The responsive system MUST adapt the same BMT design language across phone, tablet, and desktop layouts.
- **FR-019**: The product MUST maintain consistency rules so repeated patterns look and behave the same across all app modules.
- **FR-020**: The visual system MUST avoid generic, copycat, or overly decorative design decisions that weaken the BMT identity.

### Key Entities *(include if feature involves data)*

- **Brand Token System**: The shared set of semantic values that define BMT color, typography, spacing, motion, and surface behavior.
- **Transportation Marker**: A branded map symbol representing a live vehicle, route progress, or stop state.
- **Captain Card**: A reusable operational identity card that presents driver/captain status and assignment context.
- **Station / Stop Card**: A reusable route element that presents sequence, timing, and stop state.
- **Route Information Component**: A reusable summary element that expresses route identity, progress, and service context.
- **Feedback State**: A user-visible status response used for loading, empty, error, and success moments.

### Acceptance Criteria

- The BMT identity is recognizable on first glance across all primary app surfaces without explanation.
- Route, stop, and vehicle information can be understood at a glance in both map and list presentations.
- The same component vocabulary is used across core workflows, and no major screen introduces a conflicting visual style.
- Light and dark themes both preserve premium feel, contrast, and clarity.
- Core workflows remain readable and visually stable on small mobile screens, tablet layouts, and large desktop screens.
- Loading, empty, error, and success states are all designed and never rely on blank screens or generic system defaults.
- The design system clearly differentiates routine actions, high-priority actions, and destructive actions.
- Accessibility rules are visible in the final experience, including readable typography, touch-friendly targets, and non-color-only state signaling.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: At least 9 out of 10 reviewed core screens are judged by stakeholders to belong to the same premium BMT design system without additional explanation.
- **SC-002**: In usability review, users can identify the active vehicle, next stop, and current route state within 3 seconds on standard trip and monitoring views.
- **SC-003**: All primary surfaces maintain acceptable readability in both light and dark themes during design review, including Arabic and Latin layouts.
- **SC-004**: No core screen depends on generic system styling for its primary identity, map markers, or operational cards.
- **SC-005**: The application demonstrates consistent visual hierarchy across mobile, tablet, and desktop layouts during stakeholder review.
- **SC-006**: Accessibility review confirms that primary actions, status states, and feedback signals are distinguishable without relying on color alone.

## Assumptions

- The BMT platform will continue to use a single shared brand system across dashboard, client, and driver surfaces.
- The product will continue to support both Arabic and Latin content.
- Existing transportation workflows and data models remain the source of truth; this specification only defines the experience layer.
- No competitor visual language will be copied directly; inspiration is allowed only at the level of quality expectations.
- The implementation team can adopt approved brand fonts and icon assets or define equivalent premium assets where needed.
- Map and route experiences will continue to be driven by real operational data rather than mock content.
