# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 92 (overnight run, 7 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08b done (D-104): the next floor.** `Climbs` (server) runs the climb: each floor from its
  own seed (`Climb.seedOf`), laid 1000 studs on along -Z, in every floor system, armed. The next
  floor lays as the right code opens the gate. Mid-ride the new car takes the ride over
  (`Elevators:takeOver`, riders' screens lay a second shaft outside it); on the cable's second
  knock (6.1 s) riders move to the same spot in it and the floor below is cleared in that frame,
  whoever's still on it sent to `away` (the spawn). An empty car comes back and re-arms.
  DevCorridor starts the climb (`DevFloorSeed`, `DevFloorNumber`) and dresses each floor.
- Verified in Studio on seeds 7 and 23 (ROADMAP's L-08b has the log). By phone and with a friend:
  `OWNER.md`. Recipe: docs/STUDIO.md, "Testing the climb from the MCP".
- Studio: nothing imported; left in Edit, seed 7, floor 1; `DevRideHold` unset. Two `caffeinate`
  timers (display awake, about an hour) end on their own; see STUDIO.md if Studio stops drawing.

## Next task: L-08c Left behind
The moment: the gate shuts with you outside or kept, and you watch your friends go on without
you, as Lethal Company's crew watch from the ship once they're dead.
1. Owner test results first, if pasted.
2. Read ROADMAP L-08c (its hand-off notes), then the GDD's "Left behind" section (docs tools, not
   WebFetch). Check `docs/FRAMEWORK.md` and Brix's ROADMAP for a spectate piece before building.
3. Who's left: `Elevators.departed`'s `left` (on the floor within the clock's reach) as the car
   leaves, plus anyone kept on the floor. Today `Climbs`' `clear` sends whoever is still on the
   floor below to `away` at the move; replace that with watching.
4. Watching: a camera that follows a living friend on the floor above (switch friend by a
   button), the friend's name shown, the HUD for play hidden, your character parked where it
   can't be hurt or seen. Every action answers: motion, sound, short copy.
5. The GDD's "Cut Free to the next floor" for the left: build what the GDD says; anything it
   leaves open gets a sensible default and an `OWNER.md` line.
6. No lobby (L-08e waits on the owner), no new keepers. The whole team gone is L-08d's.
**Acceptance:** checks green; in Studio (one player can't ride and stay at once: stand in for
the friend as in STUDIO.md's Cut free recipe, or check the server's view of who's left and the
camera's subject on the Client): a player left on floor 1 watches the rider on floor 2 from the
move on, switching between friends works, Output clean; two-player feel goes to `OWNER.md`.
**Read first:** ROADMAP L-08c; the GDD's "Left behind"; D-104; `src/server/Climbs.luau`
(`clear`, `ride`); `src/server/Elevators.luau` (`leave`); `src/server/KeptPlayers.luau`
(`letGo`, the floor's `Destroying`).

## Queue (the next run's order, from ROADMAP)
1. L-08d the climb ends. L-08e (the start, in the lobby) waits for the owner's lobby plan (Nov 11).
2. L-15 keepers hear the keypad, dropped tools, the saw, crawls, the ladder and drop-ins.
3. L-16a and L-16b, the fix pass before friends play; L-16c the roof crawl made smooth.
4. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
5. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.
6. Seen this session: a ladder stood on a floor when it's cleared should go with it (untested);
   anyone still in the car 6 s after it opens is shut in (`OWNER.md`'s L-08a decision 2).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
