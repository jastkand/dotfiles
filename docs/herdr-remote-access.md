# Remote access to herdr from iOS — research

*Researched 2026-10-17. Method: six parallel deep-dives — one per candidate repo (READMEs, docs, shallow
clones of the actual code, GitHub API metadata) plus one scan of the whole herdr plugin ecosystem.
Stars/activity figures are as of that date. Local herdr version at the time: **0.9.4**.*

## Requirements

Hard:

- **No public exposure of the Mac.** Access via tunnel/VPN only.
- **Self-hosted**, reachable on my own domain.
- **Maintainable**: clean enough to clone and tweak when something breaks.

Soft / context:

- **PWA over App Store app** (distrust of store apps; not a hard "no").
- **Usage**: full control ideally (send prompts, approve permissions); monitor + nudges at minimum.
- **Hosting**: small service on the Mac itself, fronted by a tunnel — no separate server.
- **Tunnel/VPN**: none in place yet — the chosen option should fit whatever tunnel I pick.
- **Push notifications**: nice to have.
- herdr is a terminal TUI: **no first-party web UI, HTTP server, or mobile client exists**
  (see [Background](#background-what-herdr-gives-you-natively)), so everything below is a third-party
  bridge + web app stack.

## TL;DR

**Pick: `devswha/herdr-web-ui`, fronted by a Cloudflare Tunnel + Cloudflare Access.**
**Co-favorite worth trialing the same evening: `AltanS/collie`** — it has the single best tunnel-security
design of the bunch (in-app Cloudflare Access JWT validation). Both install as herdr plugins, both default
to loopback, both are MIT TypeScript PWAs with iOS web push, and they listen on different ports (7317 vs
8787), so they can coexist for a head-to-head trial. Keep whichever UX you prefer; drop the other.

`ZingerLittleBee/Heeler` is objectively the most polished and security-serious option in the ecosystem, but
it is a native App Store iOS app with no web surface at all — it fails the PWA preference and makes "my own
domain" irrelevant. Worth knowing about; not the fit here.

| | herdr-web-ui | collie | herdr-remote | roamgate | Heeler |
|---|---|---|---|---|---|
| Form factor | PWA (chat + terminal) | PWA (terminal-first) | PWA (vanilla JS) + TUI/menu bar | PWA (terminal-first) | **Native iOS app** |
| Default bind | 127.0.0.1:7317 | 127.0.0.1:8787 | 127.0.0.1:8375 | 127.0.0.1:8787 | none (SSH only) |
| CF Tunnel story | Supported (docs give Caddy/nginx; Access named) | **First-class: in-app Access-JWT validation** | **First-class: installer scripts the named tunnel** | Undocumented, likely works | N/A — no HTTP exists |
| Own domain | ✔ | ✔ | ✔ | ✔ | ✖ (no domain involved) |
| Auth | pairing / Tailscale identity / bearer token | device pairing + optional Access-JWT + proxy header | bearer token + origin check | password/token + HMAC cookie | SSH Ed25519, pinned host keys |
| iOS web push | ✔ (16.4+, installed PWA) | ✔ (16.4+, installed PWA) | ✔ (16.4+) | ✔ (16.4+) | ✔ (native APNs + Live Activities) |
| herdr 0.9.4 compat | ✔ requires ≥0.9.0 | ✔ (API doc re-probed on 0.9.0, 2026-10-03) | ✔ (0.9 compat added) | ✔ (explicit matrix to 0.9.4) | ✔ (needs ≥0.7.5) |
| License | MIT | MIT | AGPL-3.0 + commercial | MIT | Apache-2.0 |
| Stars / age | 1,119 / ~1 mo | 1,374 / ~3.5 mo | 421 / ~4 mo | 299 / ~10 wk | 593 / ~3 mo |
| Stack | TS/Bun/React 19, xterm.js | TS/Bun/React Router | Python + vanilla JS, no build step | TS/Bun/React, single binary | Swift 6 / SwiftUI |
| Tweakability | good (147k LOC, 361 test files) | good but huge (325k src LOC) | **best** (small, no build step; one 3.7k-line relay file) | good (112k LOC, 284 test files) | Swift-only |
| Main risk | 1 month old, extreme churn, bus factor 1 | huge codebase, bus factor 1, churn | monolith file; had one XSS-class bug (fixed same-day, +regression test) | 0.x churn; service install binds 0.0.0.0 (footgun); phones home by default | native app; push relay is dev-hosted |

## Background: what herdr gives you natively

- herdr (github.com/herdrdev/herdr, Apache-2.0) exposes **NDJSON over a local Unix socket**
  (`~/.config/herdr/herdr.sock`), schema via `herdr api schema --json`. The socket has **no auth layer** —
  safety is "local process only". Everything remote-access-shaped below is a bridge that adds transport +
  auth and dials that socket.
- Built-in remote = **SSH only** (`herdr machine add …`, `herdr --remote …`); auth is delegated to OpenSSH.
  Docs: herdr.dev/docs/connecting-machines, /docs/persistence-remote. Using the herdr TUI from an SSH app
  on the phone is the zero-dependency fallback, just not a pleasant iOS experience.
- **Herdr Cloud** (hosted relay) exists only as a waitlist page — no product, no timeline.
- Consequence: **never port-forward or directly expose anything that touches the socket.** All five
  candidates understand this and default to loopback; the exposure question is entirely about the front
  door you put in front of them.

## The five candidates

### 1. devswha/herdr-web-ui — PWA, chat-style — **recommended pick**

<https://github.com/devswha/herdr-web-ui> · site: herdrweb.dev · MIT · v0.4.11 · **requires herdr ≥ 0.9.0**

Renders each herdr pane as a chat built from the agent's own transcript (Claude Code, Codex, opencode,
pi, …), with the live xterm.js terminal one tap away. herdr stays the owner of agents; the app attaches
without taking over.

- **Architecture**: Bun HTTP+WebSocket server on `127.0.0.1:7317`, installed as a herdr plugin; serves a
  React 19 PWA; dials herdr's Unix socket. No hosted relay, no accounts ("the app brings no tunnel").
- **Security**: loopback by default; warns if bound wider without auth. Three doors: Tailscale identity
  (`tailscale serve` login header), **device pairing** (6-digit code, 10-min TTL, 5 tries, revocable,
  kills live connections), or `HERDR_WEB_TOKEN` bearer/cookie (once set, required even on loopback).
  Fail-closed corner cases (corrupt device state ⇒ external clients locked out). Reverse-proxy contract is
  explicitly documented — preserve `Host`, send `X-Forwarded-For`/`-Proto: https`, pass the `/ws` upgrade —
  with copy-paste Caddy/nginx configs, and **Cloudflare Access is named as a supported front door**.
  No turnkey cloudflared example exists; you'll likely need `httpHostHeader` set to your domain in the
  tunnel config (verify on first setup).
- **iOS**: full PWA (`manifest.webmanifest` + service worker); **web push works with the app closed**
  (iOS 16.4+, installed to Home Screen); keyboard key bar (Esc/Ctrl/arrows/custom), approval/plan cards,
  screenshot attach, start worktrees from the phone. Best "full control from the couch" UX of the five.
- **Maintainability**: ~147k LOC TS, 361 test files, 5 CI workflows, MIT, clean focused auth modules,
  excellent docs (guide/INSTALL/SECURITY/DESIGN, 4-language READMEs).
- **Risks**: one month old (Sept 2026), ~814 of ~1,070 commits from one maintainer at extreme
  (AI-assisted-looking) velocity — expect churn; pin a release. 108 open issues. Opt-out anonymous
  telemetry (disable in Settings). SECURITY.md itself says "one maintainer, no guaranteed response time."

### 2. AltanS/collie — PWA, terminal-first — **co-favorite**

<https://github.com/AltanS/collie> · site: colliepwa.dev · MIT · v1.22.0 · min herdr 0.7.0,
HERDR_API.md re-probed on herdr 0.9.0 (2026-10-03) — works with 0.9.4

The most "Cloudflare-native" option: **the bridge itself validates `Cf-Access-Jwt-Assertion` on every
remote request** (set `COLLIE_ACCESS_TEAM` + `COLLIE_ACCESS_AUD`; fails closed 503/401). Even if the
tunnel is misconfigured, the app refuses unauthenticated traffic — defense in depth nobody else has.

- **Architecture**: one Bun binary on the Mac (launchd agent), loopback :8787, serves the PWA + JSON API;
  herdr is the primary supported backend (first-class plugin, `HERDR_API.md` documents the socket protocol
  it probed). Polling, not WebSockets — maximally proxy-friendly.
- **Security**: loopback-only bind (refuses 0.0.0.0 without an escape hatch); **device pairing on every
  route including reads** (QR, 10-min expiry, 5 strikes, hashed tokens, live revocation); documented
  Cloudflare Tunnel + Zero Trust Access setup; DNS-rebinding protection; strict CSP/HSTS; honest threat
  model doc ("this is remote shell access by design; a stolen unlocked phone is a shell").
  Caveats: "one front door at a time" (enabling Access blocks the tailscale-serve door); point cloudflared
  directly at the bridge (an nginx hop in between defeats the JWT check).
- **iOS**: textbook PWA (vite-plugin-pwa + Workbox), self-hosted **VAPID web push** (`collie push-keys`),
  alerts for needs-input/finished, voice dictation, special-keys pad, 12 UI languages.
- **Maintainability**: the big one — ~325k source LOC (275k more in tests), 100+ ADRs, immaculate docs.
  Easy to *understand*, heavy to *tweak*; one maintainer doing 3,175 commits in 3.5 months means local
  patches will conflict often.
- **Risks**: fast-breaking majors; tmux/zellij backends lightly tested (irrelevant for you); herdr 0.9.4 is
  newer than the doc's newest probe (0.9.0) — the plugin will surface breakage immediately if the socket
  protocol moved.

### 3. dcolinmorgan/herdr-remote — Python relay + vanilla-JS PWA

<https://github.com/dcolinmorgan/herdr-remote> · v0.8.1 · AGPL-3.0-or-later + commercial · herdr 0.7+

- **Architecture**: single Python relay (`herdr_relay.py`, 3.7k lines) on `127.0.0.1:8375` serving the web
  dashboard + WebSocket API; reads herdr via CLI + companion `herdr-push` plugin. Optional Telegram bot,
  TUI, macOS menu-bar app (DMG), build-it-yourself SwiftUI app.
- **Security**: refuses to start bound beyond loopback without `HERDR_RELAY_TOKEN`; token via Bearer/query/
  cookie checked before the WS handshake; origin validation; `HERDR_TRUSTED_ORIGINS` anticipates
  Cloudflare Access; CSP; JSONL audit log of writes; transcript-shipping kill switch (`HERDR_TRANSCRIPT=0`).
  **The named Cloudflare Tunnel to your own domain is the scripted default install path**
  (`install-service.sh`: prompts for `relay.yourdomain.com`, runs `cloudflared tunnel route dns`, installs
  launchd services for relay + tunnel). Easiest "tunnel + own domain" setup of all five.
- **iOS**: iOS-tuned standalone PWA with web push (6h TTL, collapse keys, iOS-specific VAPID workaround).
- **Maintainability**: the most tweakable codebase here — Python + ~3.4k lines of framework-free vanilla
  JS, no build step, 19 test files, CI, 20 contributors (the most distributed of the five).
- **Risks**: the 3.7k-line monolith; AGPL (irrelevant for personal use); one real XSS-class bug shipped and
  fixed same-day in Oct 2026 with a regression test — responsive, but it shows the pace; single dominant
  maintainer.

### 4. powerfooI/roamgate — single-binary Bun bridge + React PWA

<https://github.com/powerfooI/roamgate> · MIT · v0.8.5 · explicit herdr 0.7.0–0.9.4 compat matrix
(protocol negotiation fails closed)

- **Architecture**: one Bun-compiled static binary (web UI embedded), launchd user service, loopback :8787,
  HTTP + one `/ws` WebSocket; dials herdr's control + terminal sockets. No cloud component anywhere.
  Unusually polished ops: `roamgate service/doctor/update/rollback/auth rotate`.
- **Security**: auth always on (even loopback): password or 256-bit token, HMAC-SHA256 HttpOnly session
  cookie, rate limits, `timingSafeEqual`, state-change marker headers. Docs: "Do not expose Roamgate
  directly to the public internet — use HTTPS, a proxy, or a trusted VPN"; `roamgate doctor` flags
  exposure. **Recommended path is Tailscale + `tailscale serve`; Cloudflare Tunnel is never mentioned** —
  it should work (plain HTTP+WS, no Host/Origin pinning) but is undocumented/untested by the project.
  ⚠️ Footgun: `roamgate service install` defaults to **0.0.0.0:8787** — set `HOST=127.0.0.1` in
  `~/.config/roamgate/roamgate.env`. Phones home for update checks by default
  (`ROAMGATE_DISABLE_UPDATE_CHECK=1`).
- **iOS**: real PWA with a dedicated mobile layout, floating touch key bar, long-press selection, iOS web
  push (16.4+). Two of its two open PRs are mobile-UX work — actively investing here.
- **Maintainability**: ~112k LOC TS, 284 test files, Biome/oxlint/CodeQL. Clean, but young (10 weeks),
  0.x churn (renamed from a predecessor with "no automatic upgrades"), bus factor ≈ 1.

### 5. ZingerLittleBee/Heeler — native iOS app — best product, wrong shape here

<https://github.com/ZingerLittleBee/Heeler> · Apache-2.0 · v0.1.14 · App Store + TestFlight · herdr ≥ 0.7.5

SwiftUI iOS 18+ console: dashboard, **real libghostty terminal attach**, E2E-encrypted APNs push + Live
Activities when an agent blocks/finishes. Speaks herdr's socket over **SSH** (`direct-streamlocal` onto
`herdr.sock`) — there is **no HTTP endpoint anywhere**, so tunnels/domains/reverse proxies simply don't
apply. Reachability: LAN, or in-app **Tailscale/ZeroTier/EasyTier** (recommended), or an outbound
loopback-bound reverse SSH tunnel to your own VPS. Auth is best-in-class: on-device Ed25519 keys in the
Keychain, host-key pinning via pairing QR, restricted self-revoking bootstrap key. ~97k LOC Swift with
~83k LOC of tests, 23 ADRs.

- **Why it fails the brief**: it *is* an App Store app (the thing you don't trust); there's no web/PWA
  surface; "self-hosted on my domain" is meaningless for it (nothing to front); tweaking requires Swift +
  Xcode + a self-signed build, and the push relay is developer-hosted (self-hosting it means building the
  app yourself with your own APNs credentials — an Apple Developer account).
- **When to revisit**: if you ever soften on native apps, this is the highest-quality remote-herdr
  experience that exists, and its security model (SSH over a tailnet) doesn't expose the Mac at all.

## Beyond the five (ecosystem scan)

The herdr.dev plugin index is just the GitHub topic `herdr-plugin` (~1,800 repos). Nothing else beats the
five above, but these are worth knowing:

- **lamngockhuong/termote** (62★, very active) — single Go binary + React PWA, drives herdr natively,
  built-in basic auth, Docker images, QR pairing. The best "small and simple" alternative if the two
  finalists feel heavy.
- **0cv/herdr-mobile-relay** (298★) — installable PWA merging all machines; per-machine relay with a
  community WebRTC gateway (dial-out, no inbound ports, no CF account). Gateway is shared infra;
  self-hosting it is undocumented.
- **barnuri/herdr-web** (12★) — streams the *real* herdr TUI to xterm.js + genuine VAPID web push. Small
  but conceptually exactly right.
- **matheus3301/herdr-phone** (4★, stale since July) — the only project purpose-built for *exactly* this
  brief (manages its own Cloudflare named tunnel + re-validates Access JWTs, loopback origin). Watch it;
  don't adopt it.
- **arronKler/pairfob** (163★) — slick QR pairing, E2EE dial-out, no ports/VPN — but the relay is
  pairfob.com's hosted infra; self-hosting unknown. Conflicts with the self-hosted requirement.
- **permgps/herdr-telegram-agents** (80★) — two-way Telegram control, zero tunnel. A complement, not a
  replacement (traffic transits Telegram).
- Notification-only complements (pair with any web client): herdr-ntfy-notify, herdr-bark-notify (Bark →
  iPhone), herdr-hail (Slack/Discord), herdr-plugin-call-me (actual phone call when blocked).
- Watch-list resource: **MIDO-ruby7/herdr-plugins-directory** auto-indexes ~1k plugins every 6h with a
  dedicated phone/remote category.

## Recommendation

**herdr-web-ui + Cloudflare Tunnel + Cloudflare Access**, with collie as the same-evening A/B trial.

Why herdr-web-ui edges collie for this setup:

1. **It's built for your herdr**: hard `min_herdr_version = 0.9.0` against your 0.9.4. collie works on
   0.9.x too (probed 0.9.0) but its verified ceiling trails more.
2. **Best full-control phone UX**: transcript-as-chat is the right reading model for agents; terminal,
   approvals, screenshots, and worktree creation are all first-class.
3. **Security model matches the brief exactly**: loopback + pairing + token, documented proxy contract,
   Access named as a supported door, fail-closed defaults, no relay.
4. Smaller than collie by half — the more realistic "clone and tweak" target — while still heavily tested.

Why keep collie in the picture: its in-app Access-JWT validation is the best security design in the
ecosystem (the app itself verifies the Cloudflare login, closing tunnel-misconfig holes), its docs for the
exact CF Tunnel + Access path are the most complete, and it's three months more mature than herdr-web-ui.

Why not the others: herdr-remote is the easiest tunnel setup and most tweakable, but the AGPL monolith and
its recent XSS give the two TypeScript PWAs the edge; roamgate is excellent but its paved road is
Tailscale, not your-domain-via-tunnel, and the 0.0.0.0 service default is a real footgun; Heeler is
 disqualified by form factor (App Store app, no web).

**On the tunnel itself** (nothing in place yet): Cloudflare (free plan) — `cloudflared` dials *out*, no
inbound ports, DNS + TLS on your domain, and Access in front gives SSO/OTP before anything reaches the
Mac. Tailscale is the credible alternative (simpler, private, and both finalists support its identity
auth) — but it doesn't satisfy the "on my own domain" benefit, so it's the fallback, not the pick. They
coexist fine later (Access for the web door, Tailscale for SSH/Heeler if ever).

### Suggested rollout

1. **Cloudflare side**: move the domain's DNS to Cloudflare (free). `brew install cloudflared`;
   `cloudflared tunnel login`; `cloudflared tunnel create herdr`; route `herdr.<domain>` to it. In the
   tunnel config, point at `http://127.0.0.1:7317` and set
   `originRequest: httpHostHeader: herdr.<domain>` (herdr-web-ui's proxy contract requires Host
   preservation — this is the one knob to verify first setup; WS on `/ws` must pass).
2. **Access**: Zero Trust → create a self-hosted app for `herdr.<domain>` with an email-OTP (or IdP)
   policy. Nothing but authenticated requests should ever reach the Mac.
3. **Install**: `herdr plugin install devswha/herdr-web-ui` (or the installer script from herdrweb.dev,
   which also installs Bun). Set `HERDR_WEB_TOKEN` so even loopback requires the token.
4. **Verify**: `curl -s https://herdr.<domain>/api/session` → 401 without token/Access; WebSocket terminal
   streams over LTE (not just Wi-Fi); push prompt appears after Add-to-Home-Screen (iOS 16.4+ required).
5. **iOS**: Safari → open the URL → Share → Add to Home Screen; launch from the icon, allow
   notifications, pair the device.
6. **Trial collie** alongside: `herdr plugin install AltanS/collie` (port 8787, no conflict), second
   tunnel hostname or same host different path; set `COLLIE_ACCESS_TEAM`/`COLLIE_ACCESS_AUD`. Keep one,
   uninstall the other.
7. **Pin versions** in the dotfiles (both projects churn daily; a pinned plugin release is the stable
   target). If patches are ever needed, expect rebase pain against upstream velocity — small enough to
   live with for either.

## Sources

- Repos: github.com/devswha/herdr-web-ui · github.com/AltanS/collie · github.com/dcolinmorgan/herdr-remote
  · github.com/powerfooI/roamgate · github.com/ZingerLittleBee/Heeler (each: README, SECURITY/deployment
  docs, shallow code inspection, GitHub API metadata on 2026-10-17)
- herdr: herdr.dev (+ /docs/socket-api, /docs/plugins, /docs/connecting-machines, /docs/persistence-remote,
  /cloud), github.com/herdrdev/herdr, github.com/topics/herdr-plugin
- Ecosystem extras: github.com/lamngockhuong/termote · github.com/0cv/herdr-mobile-relay ·
  github.com/barnuri/herdr-web · github.com/matheus3301/herdr-phone · github.com/arronKler/pairfob ·
  github.com/permgps/herdr-telegram-agents · github.com/MIDO-ruby7/herdr-plugins-directory
