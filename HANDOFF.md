# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 163 (evening run, session 5: S2-07a2) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-07a is done (D-171, D-172). S2-07a2's three monster fixes, each a pure rule with specs:
  a Mannequin on its way to the breaker hears a third as far (`Keeper.ErrandHearing`) and a
  sound that calls it off ends the errand at once; monsters called to one spot take their own
  places round it (`KeeperMap.spread`, `Keeper.spread`, `tests/spread.spec.luau`); one a wave
  woke breaks out only under `Deal.awakeCap` (`Waking.free`, server `holdWoken`), held ones
  going quiet at their time (`Keeper.hold`).
- Seen in Studio Play: floor 3 (limit two) woke three, the third held at once, two loose 110 s
  in; two wrong codes brought three to the keypad at once, closest two 4.3 studs apart; no error
  lines. Not seen in Play: the busy Mannequin ignoring a far sound (Lune only, `OWNER.md`); the
  quiet held door re-run after the change from pounding (Lune only).
- The order ahead (ROADMAP): S2-07b, S2-06a to S2-06e, S3-01.

## Next task: S2-07b Screens and things
ROADMAP S2-07b: six small fixes left from earlier tickets. If they won't all fit with Play
checks, split it in ROADMAP first (S2-07b1, S2-07b2) and do the first piece well.
1. Read ROADMAP S2-07b; each fix names the ticket that left it: grep that ticket in ROADMAP
   and DECISIONS for the detail before opening code.
2. A player standing still at the keypad lights up again when the lights come back (S2-04c,
   `MotionLights:out`, `src/server/MotionLights.luau`).
3. Take doesn't show through a shut door (S1-07b: grep "Take" in `src/client`).
4. A torch left on as you're wrapped switches off instead of draining (S1-09,
   `src/server/Flashlights.luau`).
5. A friend's beam shows the faint mark as yours does (S1-11, `FaintMark.luau`,
   `src/client/FaintMarkView.luau`).
6. A saw no longer pokes past the machine's glass (S1-10d2, `src/server/Machines.luau`; art is
   code: if the fix is in the model, change its script and rebuild).
7. The permission and wrong-type asset lines in Output at Play start: trace each to the asset id
   and the script that loads it, then fix (a Creator Store sound swap, or a type check).
8. Verify each in Play (STUDIO.md "Getting frames back"; "Read Output small"); owner steps in
   `OWNER.md`.
**Acceptance:** checks green; in Play each fix shows as described; Play start's Output has no
permission or wrong-type lines.
**Read first:** ROADMAP S2-07b; then only grep and line ranges in the files named above.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-07b (next), then the Packrat (S2-06a its art first), then S3-01.
   L-08e3c and L-14b2d wait on `OWNER.md`. R-01 is for later.
2. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
3. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
4. Left in the Queue, not in S2-07: S1-07a 16 in 100 units hold nothing (may be right);
   S2-02c only a wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by
   hand; S2-03b loose keepers go to look at a pounding door (a feature).
5. From S2-07a2: each blow of a pounding door is the same noise going on, so a loose monster
   looking at it keeps looking until the pounding stops (seen in Play). Before 90 s that's the
   S2-03b feature; it also pulls monsters off a wrong code's alarm while doors still pound.
6. From S2-07a2: a monster let out by a wrong code or a missed tap isn't held by the floor's
   limit (the players' doing); one trapped by players and bursting out can still pass it.
7. From S2-02d4: the first clunk through the camera of a session may come 0.3 s late (a Sound
   made on its first play); the fade slack (`FADE_SLACK`) wasn't replayed in Play.
8. From S2-05a: a sleeper woken by a missed tap isn't counted in its floor's `woken`.
9. From S2-07a1: a feed copies every monster on its floor at the start (about 15 parts each);
   fine for a few, worth a look if a floor ever holds dozens.
10. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
    staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
