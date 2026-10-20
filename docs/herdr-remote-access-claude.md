# herdr remote access: research

Research snapshot: **2026-10-19**, herdr **0.9.4** on an always-on Mac.
Method: for each candidate I made a shallow clone and read the source and docs (nothing was installed or
run), took repo metadata from `gh`, and checked the full herdr plugin index (`assets.herdr.dev/plugins/index.json`, which lists 1,753 plugins).
Every project here moves very fast (some ship several releases a day), so check the numbers again before acting on them.

## TL;DR

- **Network layer:** use **Tailscale**, with optional **headscale on your VPS** so the control plane is self-hosted. Each client binds to `127.0.0.1` on the Mac. Your domain points at the Mac's tailnet IP, and TLS comes from Caddy using a DNS-01 certificate issued through your Cloudflare zone.
  - Nothing on the Mac is reachable from the internet.
  - Traffic is WireGuard end-to-end. No third party sees your keystrokes.
  - The only cost is the Tailscale iOS app. That's a widely audited VPN client, a very different trust question from installing a three-month-old app that holds shell access.
- **Fallback if you want zero apps on the phone:** **Cloudflare Tunnel + Access** on your domain. It has the best PWA fit and needs no inbound ports. But Cloudflare terminates TLS and sees everything you type, and the hostname is publicly reachable with Access as the only gate. Always keep an app-level token behind it.
- **Client:** **herdr-web-ui** fits your needs best. It's the only PWA that has all of these:
  - a real xterm.js terminal
  - agent-aware chat with approval cards
  - Web Push
  - integration through herdr's *public* socket API and CLI

  Before using it, turn telemetry off and pin a release.
  - **Runner-up: Roamgate**, a cleaner security default with no telemetry, but it hand-decodes herdr's *private* wire protocol.
  - **Choose Collie** if security posture matters more than a real terminal emulator.
- **On hackability, nobody wins.** Each of the five candidates is 100k–350k LOC, mostly agent-written, with one maintainer behind it. You can *patch* them, but you can't really *own* them. If owning it matters, the herdr socket API is good enough that a thin bridge of about 1–2k LOC is realistic (see [Build your own](#option-build-your-own-thin-bridge)). Small existing starting points are listed below.

## What you asked for

| # | Requirement | Weight |
|---|---|---|
| 1 | Don't expose the Mac publicly; reach it only through a tunnel or overlay | **Hard** |
| 2 | Self-hosted, on your own domain | Benefit |
| 3 | PWA on iOS rather than a native app | Benefit (not a blocker) |
| 4 | Maintainable and hackable: clone it and tweak it when something breaks | Benefit |

From the follow-up questions:
- **Phone use:** checking agent status, approving and answering prompts, full terminal work, and push notifications.
- **Infrastructure:** a VPS and a domain on Cloudflare; open to better options.
- **Host:** an always-on Mac.
- **Stack:** no preference.

## Building blocks herdr already gives you

These explain why the clients differ, and what a DIY client would rely on.

- **The official phone story is plain SSH.** herdr's "How to work" docs say it "works on your phone without a mobile app or web dashboard": `ssh` → `herdr`. The TUI adapts to narrow screens, and the docs suggest Moshi on iPhone. herdr has no official web UI or mobile app, and I found none on its roadmap.
- **`herdr --remote <ssh-target>` and `herdr machine …`** need a herdr client on the other end, so they don't help on iOS.
- **Socket API.** NDJSON over `~/.config/herdr/herdr.sock`, protocol version 22, schema via `herdr api schema --json`. It has no TCP listener, so every phone client needs a bridge daemon on the Mac.
  - **Read:**
    - `session.snapshot`
    - `workspace/tab/pane/agent.list|get`
    - `pane.read` and `agent.read` (visible, recent or detection, as text or ANSI)
  - **Write:**
    - `pane.send_text|send_keys|send_input`
    - `agent.prompt`
    - `agent.start`
    - `worktree.*`
    - `notification.show`
  - **Events:** `events.subscribe` streams `pane.agent_status_changed` (idle / working / blocked / done) and `pane.output_matched`. If a client falls behind it gets `events_lost` and must take a fresh snapshot.
- **Terminal streaming.** `herdr terminal session observe <pane>` (read-only) and `herdr terminal session control <pane> --takeover` (writable, one owner at a time) emit base64 ANSI `terminal.frame` NDJSON. They also accept input, resize, scroll and mouse events. This maps directly onto xterm.js. (I confirmed both subcommands exist in local 0.9.4.)
- **Plugin hooks** fire on agent state changes, which is the natural trigger for push notifications.

A client's fragility on herdr upgrades depends mostly on which of these layers it uses:

| Layer | Stability | Used by |
|---|---|---|
| Socket API (documented, versioned) | Best | herdr-web-ui, Collie, Heeler, Roamgate (control) |
| `herdr terminal …` CLI streams | Good | herdr-web-ui, Heeler, herdr-phone |
| `herdr pane …` CLI + 2 s polling | OK | herdr-remote |
| Private bincode wire protocol (`herdr-client.sock`) | **Fragile**: exact protocol match | Roamgate (terminal rendering) |
| Regex over agent TUI output | Fragile on *agent* upgrades | Collie, herdr-remote (and parts of others) |

## Comparison of the five candidates

| | **herdr-web-ui** | **Roamgate** | **Collie** | **herdr-remote** | **Heeler** |
|---|---|---|---|---|---|
| Repo | devswha/herdr-web-ui | powerfooI/roamgate | AltanS/collie | dcolinmorgan/herdr-remote | ZingerLittleBee/Heeler |
| ★ / created | 1,215 / Sep 2026 | 307 / Aug 2026 | 1,401 / Jun 2026 | 423 / Jun 2026 | 612 / Jul 2026 |
| License | MIT | MIT | MIT | **AGPL-3.0** (dual) | Apache-2.0 |
| Stack | Bun, React 19, TS | Bun, React 19, TS | Bun, React, TS | Python + vanilla JS (no build) | Swift / SwiftUI |
| Non-test LOC (approx.) | ~220k incl. tests | ~115k | ~356k | ~8k relay + 4k web (+ native apps) | ~109k |
| Bus factor | 1 (899 of ~1,176 commits) | 1 | 1 (3,206 commits) | ~2 | 1 (2,533 commits) |
| Client | **PWA** | **PWA** | **PWA** | **PWA** (+ Telegram/TUI/desktop) | **Native iOS app only** |
| Real terminal (xterm.js or similar) | ✅ xterm.js | ✅ xterm.js | ❌ ANSI text + keys pad | ❌ ANSI span mirror | ✅ libghostty |
| Approve / answer prompts | ✅ cards | ⚠️ via terminal / composer | ✅ tap buttons, can hold Claude permission prompts | ✅ (regex-detected) | ✅ |
| Web Push | ✅ VAPID | ✅ VAPID | ✅ VAPID | ✅ VAPID | APNs via author's relay |
| Default bind | `127.0.0.1:7317` | `127.0.0.1:8787` CLI, **`0.0.0.0` when installed as a service** | `127.0.0.1:8787`, refuses non-loopback | `127.0.0.1:8375` | sshd (all interfaces) |
| Intended tunnel | Tailscale Serve (installer does it) | Tailscale Serve | Tailscale Serve, CF Tunnel + Access, proxy | **Cloudflare quick tunnel** | Tailscale / ZeroTier inside the app, VPS jump host |
| Auth | Loopback, Tailscale identity header, 6-digit pairing, or token | Always-required token, password or PIN | Always-required pairing → 256-bit token; optional Tailscale user or CF Access JWT check | Optional single shared token (can be passed in the URL) | SSH key (pairing grants an **unrestricted** key) |
| Telemetry | **On by default** (author's CF Worker) | None found | None found | None found | None found |
| herdr coupling | Socket + `terminal attach` | Socket + **private protocol (exact version)** | Socket | CLI polling + screen scraping | Socket over SSH (protocol ≥17) |
| Security track record | — | — | — | **2 high-severity advisories in 4 months** | — |

Ratings against your criteria:

| | 1. Not public | 2. Own domain | 3. PWA | 4. Hackable | Fits your use case |
|---|---|---|---|---|---|
| herdr-web-ui | ✅ | ✅ (⚠️ PWA install broken behind an auth proxy, #1331) | ✅ | ⚠️ | **All four** |
| Roamgate | ⚠️ (fix the service bind) | ⚠️ (not documented end to end) | ✅ | ⚠️ | All four; approvals are less polished |
| Collie | ✅ | ✅ (documented, incl. CF Access) | ✅ | ⚠️ | Missing a real terminal |
| herdr-remote | ⚠️ (public via CF by design) | ✅ | ✅ | ⚠️ (smaller, but AGPL + 3.7k-line monolith) | Missing a real terminal |
| Heeler | ✅ | ➖ n/a | ❌ | ⚠️ (needs Xcode + Apple dev account) | All four, but it's an app |

---

## Candidate details

### devswha/herdr-web-ui: best feature fit

**Architecture.** A Bun server runs on the Mac and is installed as a herdr plugin (`min_herdr_version = 0.9.0`). It reaches herdr two ways:
- **Socket JSON API** (`server/herdr/client.ts`).
- **Live terminals:** it spawns `herdr terminal attach` in a node-pty (`server/core/terminal-process.ts`).

The "chat" view is built by parsing each agent's transcript files on disk (Claude, Codex, OpenCode and others).

**Network.**
- **Bind:** `HOST` defaults to `127.0.0.1` (`server/index.ts:210`), with warnings if you bind elsewhere without a token or over plain HTTP.
- **Tailscale:** the installer runs `tailscale serve --bg --https=<port> http://127.0.0.1:<port>`. Funnel is explicitly refused (`server/access.ts:183`).
- **Optional extras:**
  - **Public tunnel ("Portal")** through gosuda's third-party relay. Don't use it.
  - **Caddy or nginx reverse proxy.**

**Auth** (`server/access.ts`). Access is granted to:
- requests from loopback with no proxy in between
- your Tailscale login (the `Tailscale-User-Login` header, checked against 100.64/10)
- a paired device (6-digit code, 10-minute TTL, 5 tries)
- `HERDR_WEB_TOKEN`

Cookies are HttpOnly + SameSite=Strict, and the token check is constant-time.
⚠️ If you bind off loopback with no token and nothing paired, it is **open**. That's documented, intended behaviour.
⚠️ Behind your own proxy you must strip any client-sent `Tailscale-User-Login` header.

**Client.**
- **PWA:** manifest + service worker + Web Push.
- **Terminals:** xterm.js with a mobile key bar.
- **Per-agent chat:** with approval, question and plan cards.
- **Extras:** voice dictation and a file/diff viewer.
- **iOS app:** a Capacitor wrapper was merged today, with APNs through the author's relay. It's optional; the PWA is still the main client.

**Concerns.**
- **Telemetry is on by default.** It reports install ID, version, OS, settings, running agents and country to `herdr-web-ui-telemetry.devswha.workers.dev`. Turn it off with `HERDR_WEB_TELEMETRY=0`.
- **Usage strip.** It reads agent credentials (Keychain, credential files) to show provider usage.
- **Self-updater.** It builds new GitHub tags in place. Auto-update is opt-in; leave it off.
- **Churn.** There have been 68 releases in a month, and the server is being refactored right now (PRs #1365–#1393).

**Verdict.** It's the only candidate that covers status, approvals, full terminal and push in a PWA, built on herdr's public interfaces. Run it pinned, with telemetry off, behind Tailscale.

### powerfooI/roamgate: runner-up, cleaner defaults

**Architecture.** A single Bun binary on the Mac (`server/src/index.ts`). It talks NDJSON to `herdr.sock`, and for terminals it **re-implements herdr's private bincode client protocol** against `herdr-client.sock` (`bridge/thin-client.ts`: "must match wire.rs enum order"). It accepts only protocols 14–20 and exactly 22 (`bridge/protocol-compat.ts`). Any herdr release that bumps the protocol breaks it until Roamgate ships a matching release.

**Network.** The CLI binds `127.0.0.1:8787`, but **`roamgate service install` writes `HOST=0.0.0.0`** (`config/service-definitions.ts:19`). Override that. The docs recommend Tailscale Serve and say "never use funnel".

**Auth.** Login is always required, even on loopback.
- **Credentials:** a 256-bit token, a password, or a PIN.
- **Cookies:** HMAC-signed, 30-day.
- **Login rate limit:** per IP.

There are gaps:
- No Origin or Host checking (stated in `SECURITY.md`).
- The `Secure` cookie flag is set only when Roamgate itself terminates TLS.
- Rate limiting is shared across all clients behind a proxy.

**Client.**
- PWA with Web Push, xterm.js with mobile shortcuts and a composer bar.
- Transcripts.
- File explorer, git diffs with annotations, worktrees.
- An optional LLM assistant ("Ranger"), off by default.

**Outbound traffic.** GitHub update checks (disable with `ROAMGATE_DISABLE_UPDATE_CHECK=1`) and Web Push to an allowlist of push services. No telemetry.

**Verdict.** Roughly the same feature set as herdr-web-ui with more conservative auth and no telemetry. The private-protocol coupling is the main thing that conflicts with "I can fix it when something breaks".

### AltanS/collie: security-first, but no real terminal

**Architecture.** A Bun bridge runs as a launchd agent and uses the herdr socket only (`session.snapshot`, `pane.read`, `send_text/keys`, `events.subscribe`). The browser polls `/api/snapshot`, nudged by events. Agent state comes from parsing agent screens (`bridge/surface/`, ~19k LOC).

**Network.** Loopback by default, and it **refuses** to start on a non-loopback address unless `COLLIE_ALLOW_NON_LOOPBACK_BIND=1`. `docs/deployment.md` documents Tailscale Serve, a reverse proxy, a remote proxy over the tailnet, and Cloudflare Tunnel / NetBird / ZeroTier. For a custom host, set `COLLIE_PUBLIC_HOSTS` / `COLLIE_ALLOWED_ORIGINS`.

**Auth** (the strongest of the five):
- **Pairing:** always required. An 8-character code becomes a 256-bit token, stored hashed, compared in constant time and rate-limited.
- **Optional checks:** `COLLIE_TRUSTED_USER` (the Tailscale identity) and `COLLIE_ACCESS_TEAM/AUD` (**verifies Cloudflare Access JWTs**).
- **Request hardening:** Host-header validation, same-origin checks and a CSP.
- **Logging:** an audit log, and secrets are masked in pane text.
- **Outbound traffic:** no telemetry.

**Client.**
- PWA with Web Push.
- Dashboard sorted by which agent needs you.
- Reply box, special-keys pad, permission prompts as tap buttons, and it can hold Claude permission requests until you answer on the phone.
- Files and diffs, voice input, and launching agents or worktrees.
- **No xterm.js:** panes are rendered as ANSI-coloured text.

**Concerns.**
- **Updates are not signed.** They're checked against a sha256 published in the same GitHub release.
- **Regressions from screen parsing:** #485, #468, #505, #507.
- **Biggest codebase of the five.** ~2k commits in the last 30 days.

**Verdict.** If "full terminal work" really means "send replies and keys" rather than "run vim on the phone", this is the most carefully secured option. It also has first-class support for your Cloudflare domain.

### dcolinmorgan/herdr-remote: simplest stack, weakest security

**Architecture.** One Python relay (`relay/herdr_relay.py`, 3.7k lines) **shells out to the herdr CLI every 2 s** and screen-scrapes prompts with regex. Clients:
- a vanilla-JS PWA (no build, served by the relay)
- a Telegram bot
- a Textual TUI
- macOS and Windows tray apps
- a SwiftUI iOS app you build yourself

**Network.**
- **Ports:** binds `127.0.0.1:8375`, plus UDP `127.0.0.1:8376` with no auth. It also advertises itself over mDNS.
- **Remote access** is a Cloudflare tunnel, either a quick `trycloudflare.com` one or a named hostname. Your traffic doesn't pass through an author-run relay.

**Auth.** One optional shared token, accepted as a Bearer header, `?token=` or a cookie, and compared with `!=`. Without a token, **clients that send no Origin header are always allowed**.

**Concerns.**
- **Footgun:** `relay/start.sh` loads `config.env` but not `secrets.env`, where the token lives. It also launches a quick tunnel automatically if `cloudflared` is installed. The result is a public relay with **no token**.
- **Two high-severity advisories since August:**
  - GHSA-g3j4-9q35-7623: cross-site WebSocket hijacking.
  - GHSA-cxfh-cwv7-wvwm: XSS that leaked the token.
- **Licence:** AGPL.

**Verdict.** The relay core is the easiest of the five to read, and there are no npm dependencies, but the design and track record count against it. Not recommended.

### ZingerLittleBee/Heeler: best native experience, not a PWA

**Architecture.** A native SwiftUI app connects over **SSH** (vendored libssh2):
- **JSON API:** via `direct-streamlocal` to `herdr.sock`.
- **Live terminals:** `herdr agent attach --takeover` in a PTY, rendered with libghostty (Metal).

Nothing new listens on the Mac, but macOS Remote Login (sshd) must be on. An optional Node plugin handles QR pairing and push.

**Reachability.** Tailscale, ZeroTier or EasyTier running *inside* the app, a userspace `tailscaled` LaunchAgent, or a VPS jump host with a reverse SSH tunnel bound to loopback (`docs/guides/vps-jump-host.md`). Cloudflare Tunnel is only an open issue (#470).

**Concerns.**
- **Pairing grants an unrestricted `authorized_keys` line**, so a lost phone means shell access.
- **Push relay:** pushes go through the author's APNs relay (E2E-encrypted, but it sees metadata). Self-hosting the relay requires your own signed build with your own APNs key.
- **Unpinned plugin:** it installs from `main` and runs `npm ci`.
- **App Store / TestFlight only.**

**Verdict.** Technically excellent and fits the hard requirement well, but it's exactly the "trust an app" scenario you wanted to avoid.

---

## Other plugins worth knowing (from the herdr.dev plugin index)

These are smaller or newer projects. They're relevant mainly because **some are small enough to actually own**.

| Repo | ★ | Stack / licence | What it is | Why it matters for you |
|---|---|---|---|---|
| [matheus3301/herdr-phone](https://github.com/matheus3301/herdr-phone) | 4 | Go + React PWA, MIT | Phone console over **Cloudflare Tunnel + Access**. Origin bound to loopback, supervises `cloudflared`, **re-verifies the Access JWT on every request**, terminal via `herdr terminal session control` | Closest match to the "Cloudflare domain + PWA + small codebase" idea. Very young. |
| [barnuri/herdr-web](https://github.com/barnuri/herdr-web) | 13 | TS, MIT | Full herdr TUI in xterm.js plus a PWA with Web Push, loopback-bound, no auth (expects `tailscale serve`) | Thin and easy to fork as the base for a DIY build |
| [lamngockhuong/termote](https://github.com/lamngockhuong/termote) | 62 | Go, MIT | xterm.js PWA in a single binary; tmux/zellij/herdr backends, basic auth, `--tailscale` flag | The most mature generic web terminal with a herdr backend |
| [arcnessai/arcdr](https://github.com/arcnessai/arcdr), [frizynn/nenu](https://github.com/frizynn/nenu), [bartholomewtj/sightr](https://github.com/bartholomewtj/sightr) | 1–4 | TS, MIT | Tailnet-only PWAs that allowlist the `Tailscale-User-Login` header | Small; the same pattern you'd write yourself |
| [afloury/wherdr](https://github.com/afloury/wherdr) | 7 | MIT | PWA over Tailscale with a **passkey** lock and push | Passkeys are bound to the origin, so changing hostname means enrolling again |
| [0cv/herdr-mobile-relay](https://github.com/0cv/herdr-mobile-relay) | 300 | Go, **no clear licence** | E2E-encrypted mobile web app with relay options: community gateway, your CF tunnel, or **your own gateway on a VPS** | Good design, but the missing licence blocks forking |
| [arronKler/pairfob](https://github.com/arronKler/pairfob) | 168 | Apache-2.0 | PWA over WebRTC with an E2E relay (hosted CF Worker by default; Worker code is in the repo) | Self-hosting the relay is untested |
| [Tomyail/herdr-connect](https://github.com/Tomyail/herdr-connect), zenodea/shepherd | — | Expo | Native apps | Ruled out by your PWA preference |
| permgps/herdr-telegram-agents, natori-hrj/herdr-hail, herdr-ntfy, herdr-bark-notify | — | — | Chat bridges and notification-only plugins | The chat services see everything; notifications-only could pair with SSH |

Outside the herdr ecosystem:
- **Claude Code Remote Control** (`claude rc`): Claude-only, works per session, routes through Anthropic, and the client is closed source.
- **slopus/happy**: MIT, with a self-hostable E2E relay, but it wraps the agent process rather than herdr panes.

Both work alongside herdr, but neither is a herdr remote.

---

## Tunnel / network layer

You have a VPS and a Cloudflare domain, so these are the realistic options:

| Option | Mac exposed? | Own domain | iOS needs an app? | Who can see plaintext | Self-hosted | Notes |
|---|---|---|---|---|---|---|
| **Tailscale + Caddy DNS-01** | No | ✅ (`herdr.example.com` → tailnet IP) | Tailscale app | Nobody (WireGuard E2E) | Control plane is SaaS | **Recommended.** Your own domain plus a real certificate, reachable only on the tailnet |
| **headscale on VPS** + the above | No | ✅ | Tailscale app (custom coordination server in iOS Settings) | Nobody | ✅ fully | Upgrade path. Lose `tailscale serve` certificates and identity headers, so bring your own TLS and app auth |
| Tailscale Serve (`*.ts.net`) | No | ❌ ts.net name | Tailscale app | Nobody | SaaS | Zero-config; you get the `Tailscale-User-Login` identity header for free |
| **Cloudflare Tunnel + Access** | No inbound ports, but the **hostname is public** behind Access | ✅ | **None** | **Cloudflare** (it terminates TLS) | No | Best PWA experience. Origin must check the Access JWT (Collie and herdr-phone do this) and keep its own token |
| Pangolin / WireGuard hub on VPS | No (the VPS is) | ✅ | WireGuard app, or none for Pangolin's web auth | You only | ✅ | You run and patch an internet-facing VPS |
| frp / rathole via VPS | Port is public on the VPS | ✅ | None | You | ✅ | No identity layer: **weakest fit** for criterion 1 |
| Tailscale **Funnel**, `trycloudflare` quick tunnels, gosuda Portal | **Yes**, effectively | — | — | — | — | **Don't.** |

Notes:
- **Tailscale Serve can't use your own domain.** The usual workaround is to bind Caddy on the Mac to its tailnet IP (or loopback + `tailscale serve`), create a Cloudflare DNS A record `herdr.example.com → 100.x.y.z` (publicly resolvable, unroutable off the tailnet), and get the certificate by DNS-01 using a scoped Cloudflare API token. Caddy needs the `caddy-dns/cloudflare` module, so the plain Homebrew build won't do; use `xcaddy` or the download builder.
- **Tailscale identity header.** It's only added by `tailscale serve`. If Caddy fronts the app instead, rely on the app's pairing or token. For herdr-web-ui, make Caddy strip `Tailscale-User-Login` from requests.
- **Why Tailscale wins on criterion 1.** With Cloudflare Access the Mac isn't exposed, but *a URL that drives a shell on your Mac* is publicly reachable, protected by Access policy plus whatever the app adds, and Cloudflare sees every keystroke in cleartext. With Tailscale, nothing is reachable at all unless the device is on your tailnet.
- **Push still works over Tailscale.** The Mac sends Web Push *outbound* to Apple's push service, so the PWA doesn't need public reachability for notifications.

## iOS PWA realities

- **Web Push:** works only for PWAs installed to the home screen (iOS 16.4+), and needs a permission prompt triggered by a tap. Subscriptions sometimes disappear silently, so a good client re-subscribes.
- **HTTPS is required** for service workers, install and push. Tailscale Serve, Caddy DNS-01 and Cloudflare all provide it.
- **Terminal input is the weak spot** in iOS Safari:
  - no Esc, Ctrl or Tab without an on-screen key bar
  - autocorrect and capitalisation fight you
  - xterm.js has IME and dictation quirks
  - the viewport jumps when the keyboard opens

  This is why the better clients pair the terminal with a chat or composer input and one-tap approve/deny. Expect to use the terminal for inspection, quick commands and the occasional TUI, not for long editing sessions.
- **Any VPN-style tunnel (Tailscale, WireGuard, headscale) needs its App Store app.** Only Cloudflare Access or a Pangolin-style web identity proxy avoids that. A VPN app from a major vendor is a much smaller trust ask than a young app that holds a shell on your Mac.

---

## Recommended setup

1. **Tunnel.** Put the Mac and iPhone on Tailscale.
   - Optional, later: move the control plane to **headscale on your VPS** so the whole thing is self-hosted.
2. **Client.** Install **herdr-web-ui** at a pinned tag.
   - Set `HERDR_WEB_TELEMETRY=0` (or `DO_NOT_TRACK=1`).
   - Leave `HERDR_WEB_AUTO_UPDATE` unset.
   - Keep `HOST=127.0.0.1`.
   - Turn off the usage strip if you don't want it reading agent credentials. Whether it can be turned off is unclear; check the settings.
3. **Domain.**
   - **Quick start:** `tailscale serve` → `https://<mac>.<tailnet>.ts.net`.
   - **Own domain:** Caddy with Cloudflare DNS-01 → `herdr.example.com` resolving to the Mac's tailnet IP → `reverse_proxy 127.0.0.1:7317`. Set `HERDR_WEB_TOKEN` and pair the phone, and strip `Tailscale-User-Login` in Caddy.
4. **Phone.** Open the site in Safari, use Add to Home Screen, then grant notifications from inside the installed app.
5. **Hardening.**
   - Turn macOS Remote Login off unless you also want SSH.
   - Don't add Funnel or a quick tunnel.
   - Read the changelog before each upgrade, and re-test after every `herdr update`.
6. **Escape hatch.** Install Moshi or Blink on the phone and SSH over the tailnet to run `herdr` directly. This is the officially supported path, needs no extra server component, and keeps working when a third-party client breaks on a herdr upgrade.

**Variant: Cloudflare-only, no app on the phone.** Use **Collie**, because it verifies Access JWTs natively, or **herdr-phone**, which is small and built for exactly this, behind a named Cloudflare Tunnel with an Access policy (passkey or SSO, short session). Keep the app's own pairing token as a second factor, and accept that Cloudflare sees the traffic.

## Option: build your own thin bridge

If you want to fully own the hackability criterion, herdr's public API makes a small client realistic:

- **Daemon** (Go, Bun or Rust; roughly 1–2k LOC), bound to `127.0.0.1`:
  - `events.subscribe` → server-sent events / WebSocket to the browser; on `blocked` or `done`, send Web Push (VAPID).
  - `session.snapshot` and `agent.list` → the status dashboard.
  - `agent.prompt`, `pane.send_keys` → reply box and approve/deny buttons (send `y`, `1`, `Enter`, and so on).
  - `herdr terminal session control <pane> --takeover` → pipe `terminal.frame` NDJSON into xterm.js over a WebSocket, and send input and resize back.
  - Auth: pairing code → hashed bearer token, plus a Host/Origin allowlist. Optionally check the Tailscale header or the CF Access JWT.
- **PWA:** manifest, service worker for push, xterm.js, and a key bar.
- **Starting points to read or fork:**
  - **barnuri/herdr-web:** thin xterm.js + push.
  - **matheus3301/herdr-phone:** Go, CF Access JWT checks, uses `terminal session control`.
  - Collie's `HERDR_API.md` and `bridge/mux/herdr/client.ts`: good worked examples of the socket protocol.

That gives you a few thousand lines you understand completely, depending only on herdr's documented surface.

## Unverified / open questions

- herdr-web-ui: whether the usage strip, which reads credentials, can be disabled, and whether PWA install works through Caddy (not an auth proxy) on a custom domain. #1331 concerns auth proxies only.
- Roamgate: how quickly it follows herdr protocol bumps (past response time not measured).
- Pangolin's licence (gh reports NOASSERTION), pairfob's self-hosted relay path, and current EU status for iOS PWA push.
- No official herdr web or mobile roadmap item was found. The closest is the closed issue #4438 (mobile attach layout).

## Sources

- herdr: [herdr.dev](https://herdr.dev), [llms.txt](https://herdr.dev/llms.txt), [herdrdev/herdr](https://github.com/herdrdev/herdr), plugin index `https://assets.herdr.dev/plugins/index.json`, plus local `herdr --help` / `herdr terminal session --help` (0.9.4)
- Candidates: [AltanS/collie](https://github.com/AltanS/collie), [devswha/herdr-web-ui](https://github.com/devswha/herdr-web-ui), [ZingerLittleBee/Heeler](https://github.com/ZingerLittleBee/Heeler), [dcolinmorgan/herdr-remote](https://github.com/dcolinmorgan/herdr-remote), [powerfooI/roamgate](https://github.com/powerfooI/roamgate)
- Tunnels: [Tailscale Serve](https://tailscale.com/kb/1312/serve), [headscale](https://github.com/juanfont/headscale), [Cloudflare Zero Trust plans](https://www.cloudflare.com/plans/zero-trust-services/), [Pangolin](https://github.com/fosrl/pangolin), [frp](https://github.com/fatedier/frp), [rathole](https://github.com/rathole-org/rathole)
- Web terminals: [ttyd](https://github.com/tsl0922/ttyd), [Wetty](https://github.com/butlerx/wetty), [gotty fork](https://github.com/sorenisanerd/gotty)
