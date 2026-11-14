# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 159 (evening run, session 1: S2-02d4) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-02d4 is built (D-168): the instant a gate shuts, its riders are off that floor for its
  cameras (`Keepers.left`, called from Climbs), a feed up on their screens cuts to static and
  the map (`Feeds.cut`, a "Cut"), and a floor nobody's on sends no Mannequin to its breaker.
  In and out are two TV static recordings sliced to the snow; FeedView keeps its sounds made
  once and replays them, because a new Sound starts 0.3 s late (STUDIO.md). A feed started
  during the map's slide follows the window in. All seen in Studio Play (ROADMAP's line).
- S2-05 is split in two (S2-05a the rules and server, S2-05b the bar's feel).
- The order ahead (ROADMAP): S2-05a, S2-05b, S2-07a, S2-07b, S2-06a to S2-06e, S3-01.

## Next task: S2-05a The tap: its rules and the server
ROADMAP S2-05a (and S2-05's moment). As Dead by Daylight's skill checks: you pull a door down
on a sleeping monster, a bar comes up by itself, one tap in its zone and the door lands soft;
miss or don't tap and it bangs, and the monster wakes and pounds.
1. Read the GDD's section on the tap (docs tools, that section only). Gaps get a default and an
   `OWNER.md` line.
2. Pure rules first with a failing Lune spec: when a shut earns a tap (the unit's monster asleep,
   or awake and hasn't seen the puller), the marker's sweep, the zone, how long the bar waits,
   hit or miss from the tap's moment; feel numbers commented in shared Config.
3. Server: find where a door's shut press lands (`Doors`, `DoorAction`) and where a sleeper's
   unit is known (`Keepers.sleepers`, `onDealt`). Open a tap window for the puller only; one
   remote, checked (type, range, theirs, in its window) and rate-limited (`roblox-security`).
4. A hit: the door's last stretch slows and lands soft, nothing heard. A miss or no tap: it
   bangs, heard as a slam (`Keepers:hear`), and the monster wakes shut in and pounds
   (`Keeper.trap`, as S2-03b stands a waking sleeper).
5. A plain bar on screen to test with (S2-05b gives it its feel). Verify in Play both ways:
   count `RenderStepped` first (STUDIO.md "Getting frames back"); Output clean.
**Acceptance:** checks green; spec covers hit, miss and no tap; in Play a hit leaves the
sleeper asleep and a miss wakes it pounding; the remote refuses a tap that isn't yours.
**Read first:** ROADMAP S2-05; the GDD's tap section; `src/server/Doors.luau` (grep "Close",
"acted"); `src/server/Keepers.luau` (grep "onDealt", "sleepers", "trap"); `src/shared/Keeper.luau`
(grep "function Keeper.trap"); `docs/STUDIO.md` (grep "Testing sleepers waking").

## Queue (next sessions per ROADMAP Phase 2)
1. S2-05a (next), S2-05b, S2-07a, S2-07b, then the Packrat (S2-06a its art first), then S3-01.
   L-08e3c and L-14b2d wait on `OWNER.md`. R-01 is for later.
2. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
3. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
4. Left in the Queue, not in S2-07: S1-07a 16 in 100 units hold nothing (may be right);
   S2-02c only a wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by
   hand; S2-03b loose keepers go to look at a pounding door (a feature).
5. From S2-02d4: the moment's clunk through the camera is a Sound made on its first play, so the
   first clunk of a session may come 0.3 s late (kept after); the fade slack (`FADE_SLACK`)
   passes checks but wasn't replayed in Play.
6. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
   staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
