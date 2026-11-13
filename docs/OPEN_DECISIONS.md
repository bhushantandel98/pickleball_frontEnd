# Open Business & PRD Decisions

This document tracks unresolved PRD questions and business rules discovered during implementation so they can be reviewed and finalized without blocking frontend development.

---

## Phase 3 — Coach Module

### Coach Profile — Feature 3.2

**DEC-COACH-001: Credential Verification Requirements**
- Question: Are certification document uploads, issuing-authority checks, or administrative/academy verification badges required before coach certifications are displayed?
- Current implementation: Certifications can be added, edited, and removed locally with no verification or approval workflow.
- Status: Open.

**DEC-COACH-002: Personal vs. Shared Account Profile Sync**
- Question: Should edits to name, phone, email, or profile photo on `/coach/profile` automatically synchronize with the shared Phase 1.2 `UserProfile` across other roles (e.g., Player), or remain scoped to the Coach profile?
- Current implementation: Stored in `MockCoachProfileRepository` while reusing shared `ProfileAvatarView` and `AvatarPickerDialog` widgets.
- Status: Open.

**DEC-COACH-003: Service Duration & Fee Bounds**
- Question: Do platform-wide minimum/maximum session durations or fee caps apply to personal coaching services and hourly rates?
- Current implementation: Validated only as values greater than zero (`> 0`).
- Status: Open.

---

### Coach Dashboard — Feature 3.1

**DEC-COACH-004: Pending Task Quick Actions**
- Question: Should coaches be able to accept/decline personal booking requests or academy invitations directly from dashboard cards, or should they only inspect details and navigate to dedicated screens?
- Current implementation: Pending tasks open a read-only detail dialog.
- Status: Open.

**DEC-COACH-005: Academy Payout Granularity**
- Question: Should academy coach payouts always be tracked per assigned branch, or can payouts be consolidated at academy level, such as multi-branch monthly retainers?
- Current implementation: `AcademyFinanceSummary` supports optional `branchId` scoping.
- Status: Open.

**DEC-COACH-006: Academy Invitation Visibility**
- Question: Should pending academy invitations remain visible when the coach selects the general Academy overview filter, or only under All Contexts?
- Current implementation: Invitations appear under Pending Tasks in Academy overview, but selecting a specific accepted academy hides invitations from other academies.
- Status: Open.

---

### Coach Calendar & Availability — Feature 3.3

**DEC-COACH-007: Availability Recurrence & Slot Duration Rules**
- Question: Should personal coaching availability windows support recurring weekly patterns with fixed slot durations (e.g., 30/60/90 min), or custom per-date overrides?
- Current implementation: `PersonalAvailabilityWindow` stores day-of-week labels and start/end time strings without enforcing slot-duration splits or recurrence exceptions.
- Status: Open.

**DEC-COACH-008: Booking Cutoff & Advance Window Rules**
- Question: What minimum booking notice (cutoff) and maximum advance booking horizon apply to personal coaching slots?
- Current implementation: No cutoff or advance booking horizon is enforced in the calendar UI or mock repository.
- Status: Open.

**DEC-COACH-009: Timezone & Cross-Branch Travel Buffer Thresholds**
- Question: How should session times be normalized across timezones, and should a minimum travel buffer between different venues/branches trigger a conflict warning?
- Current implementation: Overlap warnings trigger only on direct time-range intersection (`startA < endB && endA > startB`) using local device time without travel-buffer thresholds.
- Status: Open.
