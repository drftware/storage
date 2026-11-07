# Storage horror (working title): agent guide

Loaded at the start of every session (CLAUDE.md imports it), so it holds only stable rules and
stays under 150 lines. Current state lives in HANDOFF.md; history lives in `git log`.

## The project

- A co-op Roblox horror game: friends climb ten floors of a living self-storage building after
  hours. On each floor they open units to find that floor's code, punch it into the freight
  elevator and get everyone aboard before the gate shuts, while the building's keepers hunt them.
  Rojo + strict Luau. No title is picked yet.
- **Design source of truth:** the GDD, https://claude.ai/artifact/UtmFtWGEMRQkNmWmCEhFWN (a Claude
  Doc; read it with the docs tools, never WebFetch). Pull only the section your ticket names.
- **Build state:** HANDOFF.md (now) · `docs/ROADMAP.md` (tickets) · `docs/DECISIONS.md` (why) ·
  `docs/CODEMAP.md` (where code lives) · `docs/FRAMEWORK.md` (what comes from Brix) ·
  `docs/STUDIO.md` (Studio, API and tool notes) · `art/unit/README.md` (the unit, how art is made).
- **OWNER.md is the one list of what waits on the owner:** actions, tests, decisions, in required
  order. Never put these in HANDOFF, ROADMAP or any new doc; those say "Waits on `OWNER.md`".

## Talk like a person (owner, 2026-11-04)

Every reply, doc, ticket, comment and commit message reads like one person explaining it to
another across a desk: plain words, full sentences, things named the way a player sees them.
- No invented shorthand. If the owner wouldn't say it and a gamer wouldn't either, rewrite it.
- Say what happens in the game first. Name code (`RollUpDoor.play`) only when the reader needs to
  find it, and say what it is the first time.

## Design rules

- **Proven mechanics only** (owner, 2026-11-02). Every mechanic names the hit game it comes from
  ("the gate shuts on a timer, as Dandy's World's elevator does"). Design from the gameplay loop,
  not from what a storage building would literally contain. Anything without a precedent is
  flagged as an untested bet and goes to OWNER.md, never built quietly.
- Every keeper has a reason to be alive that fits the lore (owner, 2026-11-02).
- New design is the owner's: build what the GDD says. Gaps get a sensible default and an OWNER.md
  line.

## Quality bar

The owner's standard: extremely high quality and polish, because the game has to earn.
Working code whose moment feels flat is not done.
- **Fun first.** Name the player moment a ticket serves (the slow, loud open; the instant slam;
  freezing under a motion light; the last friend sprinting for the gate) and build so it lands.
- **Every action answers.** Each player action and server event ships with its feedback in the
  same ticket: motion, sound, and short copy. No silent state changes, no UI that snaps.
- **Real assets.** The loop is built and honed with the real art, not greybox (owner,
  2026-11-05). An asset a ticket needs is built first, the unit's way (below).
- **Phone first.** Judge every screen and scene at phone size. Low-end Android is a target:
  cap awake keepers and real light instances (GDD tech plan).
- **Few words.** A prompt is one verb ("Open"), a refusal names the fix ("Need bolt cutters"),
  a toast is a short headline. Nothing from our planning reaches the screen.
- **Hooked by fun, never by tricks.** Replay comes from tension, mastery, collection and friends.
  Roblox policy (paid random items, honest odds, young players) is a hard limit.
- **Polish is never dropped.** Juice that doesn't fit the ticket goes in ROADMAP by name.
- **Loop before atmosphere** (owner, 2026-11-07): effects that only set the mood (the haze, more
  particles, ambience) wait until the gameplay loop is solid; list them in ROADMAP's polish
  section and move on. An action's own feedback still ships with it.

## Context budget

Long sessions get slower, costlier and sloppier, so every session is small and hands off to a
fresh one.
- **One ROADMAP ticket per session.** If a ticket won't fit, split it in ROADMAP before starting.
- **Hand off at the nearest green point** when the ticket is done, the conversation has been
  compacted, you have read about 15 files or made about 60 tool calls, or you are about to start a
  second ticket.
- **Read narrowly.** Start from the Read-first list, then Grep and line ranges. Don't survey the
  repo or re-read a file already in context.
- **One agent** (owner, 2026-11-03). Do every search, read and review yourself: no subagents
  (Agent, Explore, the roblox-reviewer, workflows) unless the owner asks for one that session.
- **Keep output small.** Scripts print problems plus one summary line; trim long output.
- **Keep this file lean.** Detail belongs in `docs/`, linked from here.

## Engineering bar

- **Systems come from Brix first** (`../engine`, its own repository; `docs/FRAMEWORK.md`; owner,
  2026-11-05). Before building any system, check what Brix exports or has planned; this game
  supplies only its policies, adapters, data and art. Use only Brix's exports at a pinned version,
  never edit it from here, and put a missing piece in Brix's ROADMAP in neutral terms.
- **Reusable systems over shortcuts.** Build each feature as the system the next floor or keeper
  reuses: keepers are data rows on one pursuit system, doors one state machine (GDD tech plan).
- **The server owns every value that matters:** door state, codes, keepers, finds, cash. Validate
  every client→server remote (type, then range, then ownership) and rate-limit it. Dev commands
  work only in Studio or for the owner's UserId.
- **Player data is sacred:** session-locked profiles, autosave, a flush on shutdown, versioned
  schemas with migrations. Grant purchases only after the profile saves.
- `--!strict` everywhere. `any` only at real boundaries, each with a comment.
- **Feel numbers live in shared Config**, each with a comment on what it does to the player.
- **Test the pure core** with Lune specs. A bug in pure code gets a failing test first.
- **Performance:** StreamingEnabled on; no per-frame allocation in hot loops; disconnect what you
  connect; only things in motion get stepped (see `RollUpDoor`).
- **Verify new Roblox APIs** (anything 2025–26) on create.roblox.com or in Studio before relying on
  them, and write what you learned in `docs/STUDIO.md`. Never invent an API.
- Use the roblox-dev skills when they fit (security, datastores, performance, UI, testing).

## Art is code

Every model is a Python script run in Blender 5.2 headless, the way `art/unit/` builds the storage
unit: one spec for the numbers, parts UV-mapped to shared texture sets, procedural materials baked
to PBR maps, an FBX for Studio's 3D Importer, a generated `Specs` module for the game, and look
sheets. Never hand-edit generated files (`src/shared/StorageUnit/Specs/*.luau`, textures, FBX);
change the script and rebuild with `scripts/art.sh`. Judge every asset at phone size in Studio.

## Verification

- `scripts/check.sh` formats, lints, strict-type-checks, builds and runs the Lune tests. It must
  pass before every handoff.
- Lune tests prove pure logic only. Feel, networking, multiple clients and real phones are the
  owner's to verify: they go in OWNER.md as exact steps and what to look for.
- Say "verified in Studio" only for what you ran and checked in Output. Everything else is
  "passes checks, untested in Studio".

## Session protocol

The owner opens each session with the kickoff block from the last one.

1. **Start.** This file and HANDOFF.md are already loaded; don't re-read them. If the owner pasted
   test results, act on them first. Then read only the Next task's Read-first list.
2. **Work.** Stay inside the ticket. Anything else you discover goes in HANDOFF's Queue. For a
   question only the owner can answer, pick a sensible default, keep going, and list it in OWNER.md.
3. **End** (any turn that changed files). The Stop hook reminds you; the owner's `/wrap` forces it.
   1. `scripts/check.sh` passes. Never hand off red; revert to green if needed.
   2. Tick the ticket in `docs/ROADMAP.md` and reshape what follows. Record durable choices in
      `docs/DECISIONS.md`, new code in `docs/CODEMAP.md`, lasting gotchas in `docs/STUDIO.md`.
      Update OWNER.md: slot new items in by required order, remove what's done or moot.
   3. **Overwrite** HANDOFF.md in its section layout: current state only, at most 70 lines.
      Promote the next ticket with ordered steps, acceptance checks, and a Read-first list of at
      most 6 files or doc sections.
   4. Commit to the current branch: an imperative subject of 72 characters or fewer saying what
      changed for the game, plus the attribution trailer. Don't push unless asked.
   5. End the reply with **Done** (2–5 bullets), **Your testing** (what you added to OWNER.md, or
      "None this session"), and the **Kickoff block** copied from HANDOFF.md.

## Gotchas

- CLAUDE.md imports this file and HANDOFF.md. Edits to either take effect in the next session or
  after `/clear`. Don't add a SessionStart hook that prints them: that double-loads.
- Tool traps (Blender 5.2, luau-lsp, the FBX recipe) are in `docs/STUDIO.md`.
