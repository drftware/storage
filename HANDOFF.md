# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 207 (pressing a find, in the game) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- F-G1b2 done (D-231): `src/server/FindUses.luau` stamps a pressed find; `src/client/FindUseView.luau`
  plays it on every screen by its joints (`Finds.joints`), yours on your view's copy at once.
  Seen in Studio Play: the lantern on, off, on (keeps its battery), dropped lit stays lit; the
  jack winds 9 s, bangs, the button hides mid-tune and comes back, the bang reaches `hearHorn`;
  the tea light's match, flame and flicker. Glow stick, jar and disco ball are silent (polish).
- Studio: Rojo made FindUses and FindUseView twice too (STUDIO.md's doubled modules).
- Find art (`art/finds/WAVES.md`): the walking robot built by the art run (Nov 16, eb41e5f), in
  the place. If that run leaves edits uncommitted in a shared doc again, stage that doc as HEAD
  plus your own lines only (`git hash-object -w`, `git update-index --cacheinfo`).

## Next task: F-G1b3 The cymbal monkey's lure, the cars, found lights hold a Mannequin
Split it in ROADMAP first: **F-G1b3a** the monkey and the cars, **F-G1b3b** a lit find on the
floor counts as a light the Mannequin stops in (D-188). Do F-G1b3a.
The moment: you wind the monkey, set it down in a unit and run; it bashes its cymbals and every
monster on the floor keeps coming to it while it plays. The RC car tears off round the unit; the
die-cast car, set down, rolls away down the hall.
1. `Finds/Use.luau`: a row each for CymbalMonkey, RCCar, DiecastCar (their motions:
   `Finds.durations(key)` in a Lune fixture, `tests/fixtures/finds`). The monkey's lure needs a
   new row field (say `lure`: seconds between hearings while its step plays), with tests;
   the catalog gets the verbs by itself (`built()` reads `Use.Rows`).
2. `src/server/FindUses.luau`: while a lure plays, `keepers:hearHorn` at the find every `lure`
   seconds, stopping when the stamp changes or the model goes (one task per model, not per tick).
3. The cars move their root (x, z, yaw on the root: `Pose.solve`'s travel), which
   `Finds.joints` deliberately never does. Drive only a car on the floor: the server owns where it
   ends (a find's place matters to pickup and the Packrat), so it moves the model (eased) to the
   motion's end place; the client plays wheels and body by joints over that. A car in a hand
   only spins its wheels.
4. Sounds: the monkey's cymbals and wind, a toy motor, a die-cast roll (Pro Sound Effects,
   `search_asset` with a query ending "SFX"; "spring"/"boing" searches came back empty).
5. Studio: `DevFloorNumber` 1, `GiveFind` "CymbalMonkey", ToolUse from the Client; read the
   server's `FindUses:` line (a LogService listener into a StringValue in ServerStorage).
**Acceptance:** checks green; the monkey draws monsters for its whole play and stops with it; the
cars drive and end where every screen agrees; `OWNER.md` says how to try each (numbered steps).
**Read first:** `src/shared/Finds/Use.luau` (Rows, press, frame); `src/server/FindUses.luau`;
`src/client/FindUseView.luau`; `src/shared/Finds/Pose.luau` (`solve`'s travel); ROADMAP F-G1b3
(grep "F-G1b3"); the windups set's motion names (`Finds.durations` in a Lune script).

## Queue (next sessions, the owner's ticket order)
1. **S3-05a, then S3-05b: caught players each in an empty unit of their own** (the owner's
   playtest bugs, Nov 15), before the run ends. Then S4-02 to S4-05 (5 coins a trapped monster).
2. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
3. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
4. Small (ROADMAP lists them): the finds' press sounds and hand (F-G1b2 polish); B-05b2b's box
   round the bend; L-08e3c, L-14b2d wait; S3-04b's polish; Free Everyone's swap sound; `sell*`
   Config warnings, a dropped find bumps a walker (D-182), the save's "best floor" still 0 after
   a ride, S1-07a to S2-07b2 leftovers, box words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
