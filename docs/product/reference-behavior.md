# REM — Telegram reference behavior (P1 evidence log)

**Owner:** Research (packet P0-RES-01, independent research agent; lead-reviewed 2026-11-24) · **Status:** Discovered · **Scope:** the 33 P1 IDs with user-visible reference behavior. Engineering-only P1 IDs (SYN except SYN-011, SEC, OPS, CLI, ENT, most UX) are REM-native designs with no Telegram reference.

Evidence rules: [FEATURE_REGISTRY §How the AI agent must extend this registry](../../FEATURE_REGISTRY.md#how-the-ai-agent-must-extend-this-registry). Acceptance criteria and adopted deviations live in [requirements.md](requirements.md). A deviation candidate below is a research suggestion, not a decision. Adopted ones are DEV-01..07 in [requirements §4](requirements.md#4-enterprise-deviations-register). No row is `OBSERVED`: no running client was inspected. The next research step is [backlog P0-RES-02](../plan/backlog.md#1-p0-packets).


Telegram is a **behavioral reference only** for REM. REM does not aim for protocol compatibility. Everything below is paraphrased. No source text over 15 words is quoted.

- **Retrieved:** 2026-11-24, from official pages only (telegram.org FAQ and blog, core.telegram.org API docs). 26 fetches in total.
- **Strength key:**
  - **OFFICIAL:** the official page states it.
  - **OFFICIAL (partial):** some requested aspects are sourced, and the rest are marked inline as `[UNKNOWN]` or `[INFERRED]`.
  - **INFERRED:** derived by us, not stated by Telegram.
  - **UNKNOWN:** no official source found within the budget.
- **Platform/version:** Telegram rarely states one. The API docs describe current server behavior and carry no dates. Blog posts are dated.
- **Outdated-page flag:** `telegram.org/faq` warns that it may contain outdated information. Re-check its numbers in the app before turning them into acceptance criteria.
- **Broken link:** `https://core.telegram.org/api/invite-links` returns 404. The live page is `https://core.telegram.org/api/invites`.

## Source index

| Key | URL | Date on page |
|---|---|---|
| FAQ | https://telegram.org/faq | undated; carries the "may be outdated" warning |
| CFG | https://core.telegram.org/api/config | undated (current) |
| CCFG | https://core.telegram.org/constructor/config | undated; gives no default values |
| AUTH | https://core.telegram.org/api/auth | undated |
| INV | https://core.telegram.org/api/invites | undated |
| RIGHTS | https://core.telegram.org/api/rights | undated |
| CHAN | https://core.telegram.org/api/channel | undated |
| EDITCR | https://core.telegram.org/method/channels.editCreator | undated |
| ENT | https://core.telegram.org/api/entities | undated |
| MENT | https://core.telegram.org/api/mentions | undated |
| PIN | https://core.telegram.org/api/pin | undated |
| FWD | https://core.telegram.org/method/messages.forwardMessages | undated |
| TYPE | https://core.telegram.org/method/messages.setTyping | undated |
| UTYPE | https://core.telegram.org/constructor/updateUserTyping | undated |
| FOLD | https://core.telegram.org/api/folders | undated |
| SRCH | https://core.telegram.org/api/search | undated |
| FILES | https://core.telegram.org/api/files | undated |
| TAKE | https://core.telegram.org/api/takeout | undated |
| LINKS | https://core.telegram.org/api/links | undated |
| B-EDIT | https://telegram.org/blog/edit | 2016-05-15 |
| B-UNSEND | https://telegram.org/blog/unsend-privacy-emoji | 2019-03-24 |
| B-PROT | https://telegram.org/blog/protected-content-delete-by-date-and-more | 2021-12-07 |

## Reference table

| ID | Reference behavior (1-2 sentences, your own words, no long quotes) | Source URL | Retrieved (2026-11-24) | Platform/version if stated | Strength: OFFICIAL / OBSERVED / INFERRED / UNKNOWN | Enterprise deviation candidate (or '-') |
|---|---|---|---|---|---|---|
| ID-001 | A new account starts from a phone number. A one-time code arrives in the app on other logged-in sessions, or by SMS, call, email or Fragment SMS. An unknown number must then give basic details, accept the ToS and complete sign-up. There is no account-level invitation; invite links exist only for chats. | https://core.telegram.org/api/auth ; https://telegram.org/faq | 2026-11-24 | Firebase SMS only in official mobile apps | OFFICIAL | Use admin invitations or SSO/SCIM provisioning instead of open phone self-registration. Do not use the phone number as the identity. |
| ID-002 | Login is a one-time code. If 2-step verification is on, an SRP password is required after the code. An optional recovery email and a passkey alternative exist. Logout keeps cloud chats but deletes secret chats. It can return future-auth tokens (client keeps at most 20) that let a later re-login skip the code. Per-number daily login attempts are limited (5 is the doc's example). `[UNKNOWN]` 2FA password reset waiting period. | https://core.telegram.org/api/auth ; https://telegram.org/faq | 2026-11-24 | - | OFFICIAL (partial) | Password or SSO login with MFA required by org policy. Admin-mediated recovery. Code-skipping re-login tokens only if policy allows. |
| ID-003 | Settings > Devices (Active Sessions) lists sessions, and any other session can be terminated. Other sessions are told about a new login and can log out an unconfirmed one. A new session auto-confirms after a server period (value not stated). The Dec 2021 update added automatic logout of inactive devices. The API exposes an authorization TTL in days. `[UNKNOWN]` the offered TTL choices. | https://telegram.org/faq ; https://core.telegram.org/api/auth ; https://telegram.org/blog/protected-content-delete-by-date-and-more | 2026-11-24 | Blog dated 2021-12-07 | OFFICIAL (partial) | Admins can revoke any user's sessions remotely. Org sets a maximum inactivity TTL that users cannot lengthen. Session events are audit-logged. |
| ID-004 | Usernames are optional and can be removed. They allow a-z, 0-9 and underscore, and are case-insensitive. Bio is limited to 70 UTF-8 chars (140 Premium) per CFG. Profile photos can be deleted. Animated avatars go up to 1080x1080 (FILES). `[UNKNOWN]` display-name rules. | https://telegram.org/faq ; https://core.telegram.org/api/config ; https://core.telegram.org/api/files | 2026-11-24 | Premium vs free tiers | OFFICIAL (partial) | Display name and title may come from the directory and be locked. No paid length tiers. No collectible or tradeable usernames. |
| ID-005 | N/A. Telegram has no organization or tenant concept. The nearest analogues are groups and channels with invite links and join requests (see GRP-002, GRP-006). | - | 2026-11-24 | - | UNKNOWN (N/A) | REM-native capability (org membership, domain or directory join rules, admin approval); no Telegram reference applies. |
| ID-006 | Deletion runs through telegram.org/deactivate, confirmed with a code sent via Telegram. It is permanent and removes messages and contacts. Groups and channels the user created lose their creator, but admins keep their rights. Inactive accounts self-destruct after a settable period; the FAQ gives 18 months as the default (check in app; options `[UNKNOWN]`). Export uses the Takeout API (contacts, chats, media, per-file size cap); the FAQ also offers a data request via @EURegulation. | https://telegram.org/faq ; https://core.telegram.org/api/takeout | 2026-11-24 | FAQ may be outdated | OFFICIAL (partial) | No self-destruct: retention follows org policy and legal hold. Deletion means admin deprovisioning, with no orphaned groups. Org-owned messages stay. Export is governed by policy or eDiscovery. |
| DM-001 | Text carries an entity array, with offsets and lengths in UTF-16 code units. The sender sets bold, italic, underline, strike, inline code, pre with language, blockquote, spoiler, mention-by-ID, custom emoji and formatted date. Pre and date entities cannot be nested. The server auto-detects @mention, #hashtag, $cashtag, /command, URL, email and bank card (except in secret chats). Caption limit is 1024 (4096 Premium). The message-length config value is not published. | https://core.telegram.org/api/entities ; https://core.telegram.org/api/config ; https://core.telegram.org/constructor/config | 2026-11-24 | - | OFFICIAL | Same entity model, without server auto-detection of bank-card numbers (DLP should flag them instead). One limit for everyone, no paid tiers. |
| DM-002 | One check means the message reached the cloud and the recipient was notified. Two checks mean it was read. Telegram has no "delivered to device" state. `[UNKNOWN]` the clock (pending) icon: no fetched official page describes it. | https://telegram.org/faq | 2026-11-24 | - | OFFICIAL (partial) | REM may add explicit "delivered to device" and "failed, retry" states that Telegram does not show. |
| DM-003 | Own messages can be edited in any chat. Edited messages show an "edited" label with the last edit time; the feature shipped 2016-05-15. A server edit window exists (`edit_time_limit` in config), but no official page fetched states its value `[UNKNOWN]`; the often-cited 48h is unverified. Only the latest version is shown. `[UNKNOWN]` reply and quote behavior. | https://telegram.org/faq ; https://telegram.org/blog/edit ; https://core.telegram.org/constructor/config | 2026-11-24 | Blog dated 2016-05-15 | OFFICIAL (partial) | Org-configurable edit window. Keep the full edit history for audit and compliance; others still see the "edited" label. |
| DM-004 | In private chats, either side can delete sent **or received** messages for both sides, or clear the whole chat for both. There has been no time limit since 2019-03-24 (it was 48h before). In groups, users delete only their own messages; admins with `delete_messages` can delete others'. Deletion leaves no trace. Config has revoke windows for supergroups and private chats; values are unpublished `[UNKNOWN]`. Auto-delete timers are 24h, 7d or 1 month. Delete-by-date-range works in 1:1 chats only (Dec 2021). | https://telegram.org/blog/unsend-privacy-emoji ; https://telegram.org/faq ; https://core.telegram.org/constructor/config ; https://core.telegram.org/api/rights ; https://telegram.org/blog/protected-content-delete-by-date-and-more | 2026-11-24 | Blogs dated 2019-03-24 and 2021-12-07 | OFFICIAL (partial) | **Key deviation.** Delete writes a tombstone and keeps content under retention and legal hold. Users cannot delete the other party's messages. Org-configurable "delete for everyone" window. |
| DM-005 | Forwarding can drop the original author and media captions. A user privacy setting makes forwards of their messages show an unlinked name only (2019). Owners can enable "Restrict Saving Content", which blocks forwarding, saving media and screenshots in groups and channels (2021). Forwarding from a protected chat fails. Secret-chat messages cannot be forwarded. | https://core.telegram.org/method/messages.forwardMessages ; https://telegram.org/blog/unsend-privacy-emoji ; https://telegram.org/blog/protected-content-delete-by-date-and-more ; https://telegram.org/faq | 2026-11-24 | Blogs dated 2019-03-24 and 2021-12-07 | OFFICIAL | Forward and copy rules follow data-classification policy. Keep server-side provenance even when the sender is hidden. Document screenshot blocking as best-effort and client-side only. |
| DM-006 | A chat can have several pinned messages. Pins can be silent. In 1:1 chats a pin can be one-sided. One message or all can be unpinned. In groups, pinning is a `pin_messages` admin right and a member right that admins can switch off for everyone. The FAQ says pins notify all members even in muted chats. Saved Messages is a personal cloud chat for notes and forwards (pinned-dialog limit 5, or 100 Premium). | https://core.telegram.org/api/pin ; https://core.telegram.org/api/rights ; https://telegram.org/faq ; https://core.telegram.org/api/config | 2026-11-24 | - | OFFICIAL | Org setting for whether pin alerts override mute. Saved Messages falls under retention policy. |
| DM-008 | The sender sends a chat action (typing, recording, uploading) to a peer, optionally scoped to a topic. Receivers treat each update as valid for 6 seconds and clear it if no new one arrives. `[INFERRED]` senders must refresh within 6 s while still active; the resend interval is not stated. | https://core.telegram.org/method/messages.setTyping ; https://core.telegram.org/constructor/updateUserTyping | 2026-11-24 | - | OFFICIAL (partial) | Org or user switch to disable typing indicators. Server-side rate limiting. |
| DM-009 | Two checks mean read. Per-member read times are visible in 1:1 chats and in groups of 100 members or fewer. Read data is kept 7 days (604800 s) after sending. "Last seen" shows only rough buckets (recently ≈2-3 days, within a week, within a month, long ago). Hiding your own last seen hides others' from you, except for Premium users. Premium can also hide read times. Unread state shows as counters: mentions per chat, and a scroll-to-bottom unread counter (2016). | https://core.telegram.org/api/config ; https://telegram.org/faq ; https://telegram.org/blog/edit | 2026-11-24 | Premium-specific rules | OFFICIAL (partial) | Org policy decides whether read receipts are forced on or off; no paid-tier asymmetry. Group cap and 7-day expiry become org settings. Presence is precise or hidden by policy. |
| DM-012 | @username mentions are auto-entities; users without a username are mentioned by ID (since 2016). Mentioned messages raise a per-chat unread-mention counter. The @ button steps back through mentions, and viewing the last one clears them all. Tapping a hashtag or cashtag searches the chat; global hashtag search covers public channels. `[UNKNOWN]` URL preview generation and opt-out. | https://core.telegram.org/api/mentions ; https://core.telegram.org/api/entities ; https://core.telegram.org/api/search ; https://telegram.org/blog/edit | 2026-11-24 | - | OFFICIAL (partial) | URL previews are fetched server-side under org egress policy. Never preview internal or intranet URLs. Previews can be turned off. (Telegram proxies remote web files to avoid leaks, per FILES.) |
| GRP-001 | Basic groups are capped at 200 members and have fewer features. Supergroups hold up to 200,000 (the FAQ also says 200,000). A basic group upgrades to a supergroup automatically when an admin uses a supergroup-only feature; history is merged. A supergroup can be converted one way into a gigagroup with no member limit. `[UNKNOWN]` group deletion rules. | https://core.telegram.org/api/channel ; https://telegram.org/faq | 2026-11-24 | - | OFFICIAL (partial) | One group model with no basic/super migration. Org-configurable member caps. Deletion by owner or org admin follows retention. |
| GRP-002 | Each new chat gets a default invite link. Admins can add links with a title, expiry date, usage limit and approval flag. Revoking takes effect at once; revoked links can be listed and deleted. Users can preview a chat before joining. Formats are `t.me/+hash` and legacy `t.me/joinchat/hash`. If the creator leaves, a successor becomes owner after 7 days (immediately in basic groups), and the creator can rejoin within that window. No numeric caps are stated. | https://core.telegram.org/api/invites ; https://telegram.org/faq ; https://core.telegram.org/api/channel | 2026-11-24 | - | OFFICIAL | Links can be limited to org members or domains. Org can disable public links. Link creation and use are audit-logged. |
| GRP-003 | Default member rights apply to every member and use the same flag set as bans, minus "view messages". The flags cover sending text and each media type, polls, stickers and GIFs, embedding links, changing info, inviting, pinning and managing topics. Basic groups have no per-user restrictions. | https://core.telegram.org/api/rights | 2026-11-24 | - | OFFICIAL | Org policy templates set the most a group owner can grant (for example, no external links in regulated groups). |
| GRP-004 | Admin rights are granular: change info, edit, delete, ban, invite, pin, add admins, anonymous, manage calls, manage topics, stories and more. Ownership transfer requires the current owner's 2FA password. It fails if 2FA is off, the password changed less than 24h ago, or the session is under 24h old. | https://core.telegram.org/api/rights ; https://core.telegram.org/method/channels.editCreator ; https://core.telegram.org/api/channel | 2026-11-24 | - | OFFICIAL | **Key deviation.** Org admins of strictly higher org rank can reassign ownership (break-glass, audited; see [requirements GRP-004.c](requirements.md#groups-grp), [threat-model §4.2](../security/threat-model.md#42-admin-recovery-powers-po-q9)). Deprovisioning never orphans a group. Consider disallowing anonymous admins. |
| GRP-005 | One API call can ban, kick or restrict a user with a set of banned rights plus an until-date. `[UNKNOWN]` until-date semantics, minimum or maximum durations, and how permanent bans are expressed. | https://core.telegram.org/api/rights | 2026-11-24 | - | OFFICIAL (partial) | Timeouts have an explicit expiry and a reason and are audited. Org-level suspension overrides group-level state. |
| GRP-006 | Approval can be required per link or for the whole group. A joiner is told the request was sent. Admins see a pending list and approve or dismiss one at a time or in bulk. An admin can message a requester before admitting them, and since Dec 2021 bot admins can do so without prior contact. | https://core.telegram.org/api/invites ; https://telegram.org/faq ; https://telegram.org/blog/protected-content-delete-by-date-and-more | 2026-11-24 | Blog dated 2021-12-07 | OFFICIAL | Requests can be auto-approved or auto-denied from directory attributes (department, role). |
| GRP-007 | Editing group info is gated by the `change_info` admin right (and a member default right). Content protection lives under Group Type, and auto-delete timers are per chat. `[UNKNOWN]` description length and photo rules. | https://core.telegram.org/api/rights ; https://telegram.org/blog/protected-content-delete-by-date-and-more ; https://telegram.org/faq | 2026-11-24 | - | OFFICIAL (partial) | Org can lock name, photo or retention settings for official groups. |
| GRP-008 | Mentions raise the per-chat unread-mention counter. Pinned messages notify members even if they muted the group. Senders can send silently. `[UNKNOWN]` how mentions behave in muted groups and which group notification options exist. | https://core.telegram.org/api/mentions ; https://telegram.org/faq ; https://core.telegram.org/method/messages.forwardMessages | 2026-11-24 | - | OFFICIAL (partial) | Org-defined "urgent" mention that can pierce mute or DND, gated by role. |
| SYN-011 | Typing actions are sent per chat or topic. Receivers get a typing update that expires after 6 s unless it is refreshed. `[INFERRED]` fan-out mechanics in large groups are not documented. | https://core.telegram.org/method/messages.setTyping ; https://core.telegram.org/constructor/updateUserTyping | 2026-11-24 | - | OFFICIAL (partial) | Stop or summarize typing fan-out above a group-size threshold. Coalesce updates server-side. |
| ORG-001 | Chats can be pinned to the top: 5 in the main list (10 Premium), 100/200 per folder, and 5/100 in Saved Messages. Folders: 10 (30 Premium), with up to 100/200 chats each and include/exclude rules. `[INFERRED]` default sort is by last activity; not stated. | https://core.telegram.org/api/config ; https://core.telegram.org/api/folders ; https://telegram.org/faq | 2026-11-24 | Free and Premium values from CFG | OFFICIAL (partial) | One limit set, no paid tiers. Org-provisioned folders and pinned org channels. |
| ORG-002 | Swipe to archive; the archive is a special folder. Folders can exclude muted, read or archived chats. A per-chat unread-mention badge shows in the list. `[UNKNOWN]` mute durations, manual mark-as-unread, and whether muted archived chats stay archived on new messages. | https://core.telegram.org/api/folders ; https://telegram.org/faq ; https://core.telegram.org/api/mentions | 2026-11-24 | - | OFFICIAL (partial) | Mandatory org announcement chats that cannot be archived, muted or left. |
| ORG-004 | In-chat search filters by text, sender, date range, topic and media type (photos, videos, documents, links, voice, mentions, pinned and more), with per-filter counters. Global search spans all chats and can be scoped by type or folder. Public-post text search is metered daily (Premium allotment, then Stars). The FAQ mentions a universal search box and in-group search by sender. | https://core.telegram.org/api/search ; https://telegram.org/faq | 2026-11-24 | - | OFFICIAL | Results limited by ACLs and retention. Admin or eDiscovery search is separate and audited. E2EE chats are not searchable on the server. |
| NTF-001 | In-app unread signals are the per-chat unread-mention count, the @ button counter and the scroll-to-bottom unread counter. Pushes are delayed when another client is online (config value unpublished). `[INFERRED]` per-dialog unread message counts exist; not verified on a fetched page. | https://core.telegram.org/api/mentions ; https://telegram.org/blog/edit ; https://core.telegram.org/constructor/config | 2026-11-24 | - | OFFICIAL (partial) | - |
| MED-001 | Photos go as Standard, HD (4x pixels, under 0.5 MB) or an uncompressed file. Videos support covers and alternate qualities. Documents and GIFs are also supported. Albums hold up to 10 items. The server makes thumbnails and video previews. Media can be resent without re-upload unless marked no-forwards. | https://telegram.org/faq ; https://core.telegram.org/api/files | 2026-11-24 | - | OFFICIAL | Malware scan and DLP on upload. MIME allow and deny lists. |
| MED-002 | Max file size is 2 GB (4 GB Premium) per FAQ. CFG upload parts are 4000 (8000 Premium) x 524,288 bytes, about 2.10 GB / 4.19 GB decimal (`[INFERRED]` arithmetic). Files over 10 MB use the big-file upload path. Free-tier uploads may be throttled after tens of GB. No per-user storage quota was found on the fetched pages. | https://telegram.org/faq ; https://core.telegram.org/api/config ; https://core.telegram.org/api/files | 2026-11-24 | Free vs Premium; FAQ undated, may be outdated | OFFICIAL | Org-configurable per-file, per-user and per-org quotas. No paid tiers. Admin storage reporting. |
| MED-010 | A download needs the file's id, access hash and a file reference from the containing photo or document object. Expired references must be refreshed. Downloads come in 1 MB-bounded chunks and may redirect to a CDN. Cloud chats are stored encrypted, with keys split across jurisdictions (FAQ). `[INFERRED]` whether access is re-checked against chat membership is not stated. | https://core.telegram.org/api/files ; https://telegram.org/faq | 2026-11-24 | - | OFFICIAL (partial) | Every download checks membership and retention. Short-lived signed URLs. Downloads are audit-logged. No third-party CDN unless the org opts in. |
| UX-005 | Telegram added VoiceOver (iOS) and TalkBack (Android) screen-reader support in March 2019. No WCAG or other conformance statement was found. | https://telegram.org/blog/unsend-privacy-emoji | 2026-11-24 | iOS, Android; blog dated 2019-03-24 | OFFICIAL | Formal WCAG 2.x AA / Section 508 conformance target and an ACR/VPAT, often a procurement requirement. |
| UX-012 | Link types: `t.me/<user>`; message links (`t.me/<user>/<id>`, private `t.me/c/<chan>/<id>`); invites (`t.me/+<hash>` or `joinchat`); phone links (`t.me/+<phone>`); folder links (`t.me/addlist/<slug>`); share; `tg://` equivalents such as `tg://settings`. Unknown `tg:` links are resolved by asking the server; unknown `t.me` links fall back to HTTP. Share links make the user pick the chat. Bot-start links show a Start button instead of auto-starting. | https://core.telegram.org/api/links | 2026-11-24 | - | OFFICIAL | Deep links live on the org's own domain and require login plus a membership check. No phone-number or proxy links. |

### Row count by strength

| Strength | Rows |
|---|---|
| OFFICIAL (fully sourced) | 13: ID-001, DM-001, DM-005, DM-006, GRP-002, GRP-003, GRP-004, GRP-006, ORG-004, MED-001, MED-002, UX-005, UX-012 |
| OFFICIAL (partial) | 19: the remaining rows except ID-005 |
| INFERRED (whole row) | 0 (inferred sub-claims are marked inline) |
| UNKNOWN | 1: ID-005 (N/A, no org concept) |
| OBSERVED | 0 (nothing was observed in a running client) |
| **Total** | **33** |

## (a) Behaviors we could not verify

- **Clock (pending) send state** (DM-002): no official page fetched describes it.
- **Edit window value** (`edit_time_limit`): the parameter exists, but no page gives the number. The "48h" figure is unverified.
- **"Delete for everyone" window values** for supergroups and private chats (`revoke_time_limit`, `revoke_pm_time_limit`). Only the 2019 blog states there is no limit in private chats.
- **Reply and quote behavior:** partial quotes, replying across chats.
- **URL previews:** who fetches them, opt-out, privacy.
- **Ban and restrict until-date:** semantics, and minimum or maximum durations.
- **Deleting groups or channels:** who may do it and any size constraints.
- **Account choices:** the self-destruct period options (only the FAQ's "18 months" default was seen, on a page flagged as possibly outdated), the inactive-session TTL options, and the 2FA password reset waiting period.
- **Profile rules:** display-name rules; group description length and photo rules.
- **Chat list:** default sort order, mute durations, manual mark-as-unread, and whether muted archived chats stay archived.
- **Indicators and counters:** the sender's typing resend interval; per-dialog unread message counts and app badge behavior.
- **Desktop accessibility:** a desktop "screen reader mode" appeared only in a search snippet from translations.telegram.org. It was not fetched or confirmed.
- **Server internals:** how a server fans out typing, read or presence updates. This is not documented, and we did not guess.

## (b) Candidate missing capabilities

These are Telegram behaviors seen in the sources that have no obvious P1 registry ID in the list given. They are names only, with no IDs assigned.

- **Secret chats:** E2EE, bound to one device, not stored in the cloud, no forwarding, lost on logout.
- **Message lifecycle:**
  - Auto-delete timers per chat (24h, 7d, 1 month)
  - Clearing history by date range
  - Self-destructing media (TTL)
  - Scheduled messages and repeating scheduled messages
  - Silent send (no notification)
  - Live drafts (`message_typing_draft_ttl`)
- **Organizing chats:** chat folders with include/exclude rules; shareable folder links (`t.me/addlist`); folder tags and colors.
- **Groups and channels:**
  - Forum topics inside groups
  - Broadcast channels and gigagroups
  - Anonymous admins and posting as a channel
  - Slow mode
  - Paid invite links
- **Presence and privacy:** "last seen" buckets; privacy settings for forwards, profile photo and phone discovery; hide read time.
- **Account security:**
  - Login confirmation for unconfirmed new sessions, and invalidating leaked login codes
  - QR-code login, login by call, passkeys
  - Local passcode (app lock)
- **Account management:** changing the phone number or identifier; "frozen" accounts after abuse reports, with an in-app appeal.
- **Message features:** reactions, polls, stickers and custom emoji, spoilers.
- **Media:** HD vs standard photo quality choice; client Downloads list; media spoilers.
- **Bots:** bots and Mini Apps, bot admin-rights suggestions, quick-reply shortcuts (Business).
- **Data export:** full Takeout API export (covered only in part by ID-006).
