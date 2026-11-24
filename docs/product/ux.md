# REM — UX, information architecture and accessibility (P1)

**Owner:** Product/Client · **Status:** Specified (P0 r1, 2026-11-24) · **Criteria:** UX-*, CLI-011 and DM-002 in [requirements.md](requirements.md#uiux-and-accessibility-ux). Telegram supplies *behavioral* reference only. REM uses its own brand, icons, colors and copy, and no Telegram assets (PROJECT_SPEC §1).

## 1. Information architecture

| Area | Narrow (< 768 px) | Wide (≥ 768 px) | ≥ 1280 px |
|---|---|---|---|
| Chat list (search box, pinned chats, archive entry) | screen 1 | left pane | left pane |
| Conversation (header, virtualized history, composer) | screen 2 (back to list) | right pane | center pane |
| Details (members, settings, links, pins, media) | screen 3 | overlay panel | right pane |
| Settings (profile, sessions/devices, notifications, theme) | full screen | modal route | modal route |
| Admin (overview, users, invites, policies) | full screen, admins only | separate route | separate route |

Routes are deep-linkable (UX-012): `/c/{conversation_id}`, `/c/{id}/m/{message_id}`, `/join/{token}`, `/settings/devices`. An unauthorized or unknown route shows a single "not available" state, which does not confirm the object exists (XC-1).

## 2. State model shown to users

| State | Where | Presentation |
|---|---|---|
| Message `pending` | bubble | clock glyph plus an accessible label "Sending" |
| `sent` | bubble | single check, "Sent" |
| `read` | bubble | double check, "Read" (group: "Read by n", capped by policy) |
| `failed` | bubble | error glyph and reason, with **Retry** and **Discard** actions; "Needs confirmation" when the operation has expired |
| Offline | global | persistent banner "Offline: messages will send when you're back online"; the composer still works |
| Reconnecting or catching up | global | subtle progress in the header; no list flicker |
| Snapshot reset (cursor expired) | conversation | inline notice that older history was refreshed |
| Edit conflict | dialog | shows the server version and the user's draft; actions: keep editing over the server version, or discard |
| Removed from group | conversation | read-only history (local), the composer replaced by "You are no longer a member" |
| Upgrade required | blocking screen | explains the upgrade; unsent messages are preserved |

Every P1 screen defines loading (skeleton), empty, error with retry, and offline variants (UX-007).

## 3. Interaction baseline

- Composer: Enter sends and Shift+Enter adds a newline (configurable later, UX-002 P2). Paste and drag-and-drop attachments with a preview (UX-008). A formatting toolbar and markdown-like shortcuts both map to typed entities (DM-001).
- Message actions through a context menu, a long-press and the keyboard (Menu key / Shift+F10): reply, edit, delete (for me / for everyone), forward, pin, copy. Multi-select for delete and forward (UX-009).
- Virtualized lists with scroll anchoring when older pages load, a "jump to latest" button with an unread count, and jump-to-message from links or search (UX-006).
- Typing indicator in the header, expiring after 6 s (DM-008). Unread and mention badges in the list (NTF-001).

## 4. Accessibility baseline (UX-005)

- Target: **WCAG 2.2 AA** for P1 journeys, checked by automated a11y scans (zero serious or critical findings) plus a manual screen-reader pass with NVDA/Firefox, VoiceOver/Safari and Orca/Firefox on Linux, before a P1 release.
- The message history is a `feed`-like region. New incoming messages are announced through a polite live region, throttled. Focus is never stolen when messages arrive.
- All controls have accessible names. Status glyphs carry text labels. Color is never the sole signal. Visible focus ring.
- Reduced motion is respected from P1 (full animation work is UX-010, P2). Text scales to 200 % without loss.
- IME: composition events are never interrupted by send shortcuts (XC-4). RTL is P2 (UX-004), but layout uses logical CSS properties from the start, so RTL is not a rewrite later.

## 5. Theming (UX-003)

Design tokens are CSS custom properties (color, spacing, radius, type scale), with light and dark sets and an AA contrast check in CI. White-label (ENT-008, P3) later swaps the token sets and brand assets, so components must not hard-code colors.

## 6. Verification hooks

A component and visual test per screen state at the three viewports (360, 1024, 1440), with approved baselines ([testing-ci.md §2](../engineering/testing-ci.md#2-test-ladder-applied-to-rem)). The a11y scan runs in PR-fast when UI files change. The P1 journey E2E set is J1–J8 ([requirements §2](requirements.md#2-personas-and-critical-journeys)).
