# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 164 (evening run, session 6: S2-07b1) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-07b was split in its session (six fixes with Play checks didn't fit one): S2-07b1 is done
  (D-173). A hall light coming back from a wrong code's alarm sees whoever stands under it, still
  or not (`MotionLight` `watch:look`); a battery's Take hides while its unit's shut door keeps
  you apart (`Battery.UnitValue`, BatteryView); caught, your torch lights the lunge and goes out
  at `Caught.Dark` on the server and your screen, and can't be switched on while wrapped.
- Seen in Studio Play: a still player under Straight2's light, Out at 6.96 s, Lit at 10.48 s; a
  lit torch on at 0.5 s into a catch, off at 0.97 s, charge kept, your own torch's lights off; a
  dying torch's Take hidden outside shut Unit301, shown inside, hidden outside again. Not seen:
  a right click while wrapped (the climb ended first; the server refuses it anyway).
- The keypad is in the lobby, which no hall light reaches: a light there is the owner's call.
- The order ahead (ROADMAP): S2-07b2, S2-06a to S2-06e, S3-01.

## Next task: S2-07b2 The screen's three
ROADMAP S2-07b2: three small fixes left from earlier tickets.
1. Read ROADMAP S2-07b2; grep each named ticket in ROADMAP and DECISIONS for its detail.
2. A friend's beam shows the faint mark as yours does (S1-11, D-150 "your own beam":
   `src/client/FaintMarkView.luau`; DECISIONS line ~1081 says a friend's beam is checked from
   their head). Find why a friend's lit torch doesn't reveal it, fix, and say what Play can show
   with one player (likely only a stand-in friend torch; real two-player in `OWNER.md`).
3. A saw no longer pokes past the machine's glass (S1-10d2, D-162: a tumbling saw's box corner
   up to 0.05 past the glass as it tips; a gentler `TIP` in `src/server/Machines.luau` or the
   vend's client view). Art is code: if the fix is in the model, change its script and rebuild.
4. The permission and wrong-type asset lines in Output at Play start: about 46 `rbxassethash
   ... Requester does not have permission`, `rbxassetid://89260803894903` ×27 as a dealt unit
   rolls up (STUDIO.md "Unchecked Output line"), `203785492` (wrong type). Trace each id to the
   script or instance that loads it (grep the repo; in Play, search `ContentProvider` /
   descendants on both sides), then fix: a Creator Store swap that loads in Play, or a type
   check. Sounds must load with no permission line, primed (`SoundPrimer`).
5. Verify each in Play (STUDIO.md "Getting frames back"; "Read Output small"); owner steps in
   `OWNER.md`.
**Acceptance:** checks green; in Play a stand-in friend's beam shows the mark, the saw's box
stays inside the glass, and Play start's Output has no permission or wrong-type lines.
**Read first:** ROADMAP S2-07b2; STUDIO.md "Read Output small" and "Unchecked Output line";
then only grep and line ranges in the files named above.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-07b2 (next), then the Packrat (S2-06a its art first), then S3-01.
   L-08e3c and L-14b2d wait on `OWNER.md`. R-01 is for later.
2. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
3. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
4. Left in the Queue: S1-07a 16 in 100 units hold nothing (may be right); S2-02c only a
   wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by hand; S2-03b
   loose keepers go to look at a pounding door (a feature).
5. From S2-07a2: each blow of a pounding door is the same noise going on, so a loose monster
   looking at it keeps looking until the pounding stops. Before 90 s that's the S2-03b
   feature; it also pulls monsters off a wrong code's alarm while doors still pound.
6. From S2-07a2: a monster let out by a wrong code or a missed tap isn't held by the floor's
   limit; one trapped by players and bursting out can still pass it.
7. From S2-02d4: the first clunk through the camera of a session may come 0.3 s late.
8. From S2-05a: a sleeper woken by a missed tap isn't counted in its floor's `woken`.
9. From S2-07a1: a feed copies every monster on its floor at the start (about 15 parts each).
10. From S2-07b1: a light coming back over a still player fires `woke` like any sighting
    (watch whether it sends a keeper to look too often after alarms).
11. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
    staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
