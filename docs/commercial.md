# REM — Commercial readiness

**Owner:** Lead (product), with PO decisions · **Status:** Discovered (P0 r1, 2026-11-24) · **Inputs:** [PROJECT_SPEC §4.3](../PROJECT_SPEC.md#43-commercial-architecture), PDF discovery pp. 8–10 and 24. This file records hypotheses and the gates for them, not commitments.

## 1. Positioning hypothesis (to validate with customers)

A private enterprise messenger with Telegram-like UX, built in Rust and self-hosted. Buyers pay for data control, reliable operation, admin policy and accountable support, not for speed alone (PDF p. 9). The final brand is TBD (PO-Q4). The working title REM must not imply any Telegram affiliation.

## 2. Edition hypothesis (from discovery; not decided)

| Edition | Hypothesized content | Gate |
|---|---|---|
| Community | basic self-hosted messaging | license model decision (open source or not) is the PO's |
| Business | SSO, RBAC, backup, audit | P3 features (ID-009, ENT-003/004) |
| Enterprise | dedicated deployment, SLA, data policy, integrations | support organization exists (CMP-004) |
| White-label | branding, domain, client builds | ENT-008, BIZ-008 |

## 3. Readiness checklist (tracked per phase)

| Item | Phase | Status |
|---|---|---|
| Single-tenant package, upgrade and rollback, restore rehearsal | P1 | Specified ([operations.md](operations.md)) |
| Dependency license inventory, attribution, SBOM (`cargo-deny` and `cargo about` or equivalent, plus npm license check) | P1 for tooling, P3 for the CMP-002 deliverable | Specified (OPS-008) |
| Brand and trademark clearance, no Telegram assets | before any pilot | PO-Q4 |
| Offline, air-gap capable licensing (signed license file; no always-online check) | P3 (ENT-009) | Hypothesis |
| Security questionnaire and DPA pack | P3 (CMP-001) | Not started |
| Pilot onboarding docs, disclosed limitations | P3 (CMP-008); a limited pilot may come earlier with disclosed limits and the required security and recovery gates (PROJECT_SPEC §6) | Not started |
| Customer discovery interviews (who buys, must-have features, deployment realities) | **start during P1**, well before P4 | PO-owned; P0-RES-03 proposal |

## 4. Constraints carried into design now

- No phone-home: licensing, updates and telemetry must work offline (operations §7).
- White-label needs token-based theming and no hard-coded brand strings (ux.md §5).
- Feature entitlements (ENT-009) later gate features server-side. P1 code keeps feature checks behind a single policy interface so that entitlements can plug in without changes scattered through the code.
- Reusing any third-party code (including Telegram open-source clients) requires a license review first (PROJECT_SPEC §1). P1 reuses none.
