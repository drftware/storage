# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-16, session 211 (nobody is stored in a unit someone stands in) · **Checks:** green at this commit (the find-art run's uncommitted carousel files fail `findpose.spec` until it commits them) · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-05 is done, and with it the owner's overnight chain. S3-05b (D-244): the pick that stores a
  caught or carried player (`Kept.choose`) now skips any shut unit a player's body stands in,
  free or caught (`Kept.Unit.someone`, filled by `KeptPlayers`' `someoneIn`); Studio stand-ins
  count too. Seen in Studio Play: with stand-ins in 20 of floor 1's 23 free units, six catches
  all went into the empty three; with 24 of floor 2's filled, a carry did too. Three real
  players wait on `OWNER.md` ("Never put in with a friend", in the carried-up section).
- `ServerStorage.CatchTest` works again once you stand on the floor (STUDIO.md "Testing where a
  catch stores you"): from the front office it says "NoKeeper".
- F-G1b is done but for F-G1b3c (the RC car), which waits on `OWNER.md`.
- Find art (`art/finds/WAVES.md`): F-05c2 done: the squishy capybara, a foam loaf with a
  mandarin on its head that sinks in a contented sigh, uploaded and imported. Next F-05c3
  (step 12): the paper squishy with a drawn face, then step 13, the goo balls.

## Next task: S4-02 Monsters by lowest floor
The moment: a climb that keeps changing under you. Floor 1 teaches the Mannequin alone; higher
up, monsters you've met before turn up mixed together, so no two climbs feel the same.
Much of it exists: `Deal.Keepers` lists each dealt monster with the floor it joins (`from`) and
`keeperFrom` (Deal.luau, grep "local function keeperFrom") draws at random among those joined;
the Packrat is one a floor from 3 (`Deal.Packrat`, grep "Deal.Packrat.from"). D-226 left both
for this ticket.
1. Read ROADMAP S4-02 and the GDD's "The monsters" and "Floor rules" sections (docs tools, only
   those). Write down what the GDD asks that today's code doesn't do.
2. Move each monster's lowest floor onto its row in `KeeperRows` (one row says everything about
   a monster, D-064), and have `Deal` read it there; `Deal.Keepers` and `Deal.Packrat.from` go.
3. "Above it the game mixes it in at random": if the GDD gives a rule for how often each
   monster appears past its floor, build it into `FloorRules` (a named step or a curve, as
   S4-01 did); if not, keep today's draw, pick a sensible default and add an `OWNER.md` line.
4. Lune specs first (`tests/deal.spec.luau` or `tests/floorrules.spec.luau`): no monster ever
   appears below its lowest floor, from floor 1 to 300; above it each comes up.
5. Studio: lay floors 1, 3 and 8 (`DevFloorNumber` in Edit) and read Output's "asleep behind
   shut doors" lines for which monsters each floor got.
**Acceptance:** checks green; the spec fails before and passes after any change to the draw;
Output in Play shows the right monsters per floor; anything without a precedent in a hit game
goes to `OWNER.md`, not built.
**Read first:** ROADMAP S4-02 (grep "S4-02"); `src/shared/KeeperRows.luau` (the `Row` type,
lines 1-80); `src/shared/Deal.luau` (grep "Deal.Keepers", "keeperFrom", "Deal.Packrat");
`src/shared/FloorRules.luau` lines 1-60; D-226 (grep "^## D-226" docs/DECISIONS.md); the GDD's
"The monsters".

## Queue (next sessions, the owner's ticket order)
1. After S4-02: S4-03 the choice on the elevator's buttons, S4-04 trapping pays (5 coins a
   trapped monster), S4-05 the big find.
2. F-G1b3c the RC car drives off its transmitter, if the owner says so (`OWNER.md`).
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. Trips stands every late arrival or respawn on the one arrival spot; two at once overlap
   until physics pushes them apart. Spread them (`ClimbEnd.spot`) as the carry's fallback does.
5. Small (ROADMAP lists them): the finds' press sounds and hand (F-G1b2 polish), the monkey and
   toy car's polish (F-G1b3a); B-05b2b's box round the bend; L-08e3c, L-14b2d wait; S3-04b's
   polish; Free Everyone's swap sound; `sell*` Config warnings, a dropped find bumps a walker
   (D-182), the save's "best floor" still 0 after a ride, S1-07a to S2-07b2 leftovers, box
   words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
