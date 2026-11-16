# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 210 (two friends carried up each land in their own unit) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-05a done (D-243): on a group's own server Trips stood every new character still on the
  spawn at the car a frame on, and the carry's new character sat on the spawn while its unit
  streamed in, so two friends left behind were stood on one spot, wrapped, far from the units
  their Cut free is judged at. Now `KeptPlayers:store` moves the body in at once, and Trips
  stands no one the climb is carrying or holding (`Trip.standsLate`). The carry's fallback
  stands each on a spot of their own (`ClimbEnd.spot`). Seen in Studio on a trip server
  (`DevTrip` "Arrive"): one player left behind woke in Unit229 and stayed there, Bang button up.
  Three players wait on `OWNER.md` (its carried-up steps are three-player steps now).
- F-G1b is done but for F-G1b3c (the RC car), which waits on `OWNER.md`.
- Find art (`art/finds/WAVES.md`): the tin carousel (F-04j) is half built (modelled, baked,
  motion keyed; not rendered or judged): finish it from WAVES.md's newest note. The farm-animal
  spinner is uploaded, not imported. Stage HEAD plus your own lines only.

## Next task: S3-05b A caught friend put in the unit you're standing in
The moment: caught, you wake shut in a unit of your own, and bang until a friend comes. In the
owner's test a friend was caught and turned up wrapped in the shut unit the owner stood in.
`Kept.free` (`src/shared/Kept.luau`) asks only that a unit is shut, with no monster and no caught
player in it: a free player inside a shut unit doesn't count.
1. A failing Lune spec first (`tests/kept.spec.luau`, its `unit(x, z, changes)` builder): a
   shut unit with anyone inside (a new `Kept.Unit` field, say `someone`) is never free, and
   `Kept.choose` passes over it.
2. `KeptPlayers.luau`'s `pick` (grep "local function pick") fills each unit's fields; add
   whether any player's root stands inside, free or caught, the way `keeperIn` tests a keeper's
   feet (`face:PointToObjectSpace`, |x| < width/2, 0 < z < depth, |y| < 4). Count Studio
   stand-ins too (`Left.StandInTag`), so one player can test it. Door up or down: a unit with its
   door up is already skipped (`shut`).
3. The same pick serves the carry (`store`, D-243): a friend standing in a shut unit on the new
   floor is skipped there too. Keep `store`'s move in the same frame as the new character.
4. Studio: STUDIO.md "Testing getting kept from the MCP" (seed 7, floor 1) and "Testing Cut free
   from the MCP" (the stand-in clone): put a stand-in inside a shut unit, get caught, and read
   Output's "is wrapped and kept in UnitNNN": never the stand-in's unit, over a few catches.
**Acceptance:** checks green; the spec fails before and passes after; seen in Play that a caught
player is never stored in a unit someone stands in; `OWNER.md` gets a numbered three-player step
(a friend shuts themself in a unit, another gets caught) in the carried-up section.
**Read first:** ROADMAP S3-05b (grep "S3-05b"); `src/shared/Kept.luau` (`Unit` type, `free`,
`choose`); `src/server/KeptPlayers.luau` (`pick`, `keeperIn`, grep only); `tests/kept.spec.luau`
lines 1-45; D-243 (grep "^## D-243" docs/DECISIONS.md); STUDIO.md lines 597-660.

## Queue (next sessions, the owner's ticket order)
1. After S3-05b (the last of the owner's chain): S4-02 to S4-05 (5 coins a trapped monster).
2. F-G1b3c the RC car drives off its transmitter, if the owner says so (`OWNER.md`).
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
5. Trips stands every late arrival or respawn on the one arrival spot; two at once overlap
   until physics pushes them apart. Spread them (`ClimbEnd.spot`) as the carry's fallback does.
6. Small (ROADMAP lists them): the finds' press sounds and hand (F-G1b2 polish), the monkey and
   toy car's polish (F-G1b3a); B-05b2b's box round the bend; L-08e3c, L-14b2d wait; S3-04b's
   polish; Free Everyone's swap sound; `sell*` Config warnings, a dropped find bumps a walker
   (D-182), the save's "best floor" still 0 after a ride, S1-07a to S2-07b2 leftovers, box
   words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
