# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 161 (evening run, session 3: S2-05b) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-05 is done (D-169, D-170). Pulling a door down over a sleeper: a metal tick and the bar rises
  in just under the Close button; the door's buttons (and any door's within 20 studs) are hidden
  and every other button steps aside; the marker runs with a glow behind it; a tap freezes it with
  a flick. A hit goes green, pops and sinks while the door lands with a quiet thump and a soft
  latch; a miss goes red, shakes and drops as the door bangs and the monster pounds. Seen in
  Studio Play both ways (327 hit, 335 and 307 missed); Output clean of new lines.
- Not seen: the screen's own tap path (a test can't press keys, STUDIO.md), and the brighter zone
  and 2 px thicker bar, changed after the Play run. Phone steps are in `OWNER.md`.
- The order ahead (ROADMAP): S2-07a, S2-07b, S2-06a to S2-06e, S3-01.

## Next task: S2-07a Monsters and the camera
ROADMAP S2-07a: five fixes so Step 2 ends clean. If they won't all fit, split it in ROADMAP
first (S2-07a1 the camera's two, S2-07a2 the monsters' three) and do the first piece well.
1. Read ROADMAP S2-07a, then grep before reading: each fix names the ticket that left it.
2. The camera feed (S2-02d1): other monsters in the camera's view move in it instead of standing
   as statues copied once (`FeedView`, grep "Clone"; only what's in motion gets stepped); a
   second feed on a floor waits for the first to finish instead of cutting it off (`Feeds`).
3. The breaker errand (S2-02d2): a Mannequin on its way to the box is called off by sounds less
   often, so the throw usually happens (`Keepers`, grep "breaker"; four came to one clunk).
4. Monsters called to one spot spread round it instead of all standing on one point (S2-04b,
   `Keepers`); a wave of sleepers waking never passes the floor's limit on awake monsters
   (S2-03a, `Deal.awakeCap`, `Waking`). Pure rules first, each with a failing Lune spec.
5. Verify each in Play (STUDIO.md "Sending the Mannequin to the box", "Testing the camera feed
   in Play", "Getting frames back"); owner steps in `OWNER.md`.
**Acceptance:** checks green; in Play a monster walking through a feed moves in it, a second
feed waits, an errand reaches the box, called monsters stand apart, a wave stops at the cap.
**Read first:** ROADMAP S2-07a; `src/client/FeedView.luau` (grep "Clone", "copies");
`src/server/Feeds.luau`; `src/shared/Waking.luau`; `src/shared/Deal.luau` (grep "awakeCap");
`src/server/Keepers.luau` (grep only: "breaker", "awakeCap", the call-to-a-spot code).

## Queue (next sessions per ROADMAP Phase 2)
1. S2-07a (next), S2-07b, then the Packrat (S2-06a its art first), then S3-01.
   L-08e3c and L-14b2d wait on `OWNER.md`. R-01 is for later.
2. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
3. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
4. Left in the Queue, not in S2-07: S1-07a 16 in 100 units hold nothing (may be right);
   S2-02c only a wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by
   hand; S2-03b loose keepers go to look at a pounding door (a feature).
5. From S2-02d4: the first clunk through the camera of a session may come 0.3 s late (a Sound
   made on its first play); the fade slack (`FADE_SLACK`) wasn't replayed in Play.
6. From S2-05a: a sleeper woken by a missed tap isn't counted in its floor's `woken` (the waking
   waves only pick sleepers behind doors never opened, so nothing double-wakes); the asset
   permission and wrong-type lines in Play's Output are older than the tap (S2-07b traces them).
7. From S2-05b: the bar's place (under the Close button, not dead centre) and its silent sweep
   are defaults the owner judges (`OWNER.md`); juice left over is in ROADMAP's polish list.
8. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
   staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
