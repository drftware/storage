# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 160 (evening run, session 2: S2-05a) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-05a is built (D-169): pulling a door down over a monster asleep (or awake and not hunting
  you) eases it to hang a foot up (Motion "Ease", 1.85 s) while a bar runs on the puller's screen
  (`ShutTap` rules, `Taps` server, `TapView` plain bar, one remote `Remotes.ShutTap`). A hit
  settles it soft ("Settle"); a miss or no tap drops it with a slam's bang ("Drop") and the
  monster wakes shut in and pounds (`Keeper.wakeShut`). Seen in Studio Play both ways; taps not
  yours, nonsense and late were ignored. The bar is plain: no look, no sounds of its own yet.
- The order ahead (ROADMAP): S2-05b, S2-07a, S2-07b, S2-06a to S2-06e, S3-01.

## Next task: S2-05b The bar's feel
ROADMAP S2-05b. The moment: your thumb hovering while the door hangs a foot over something that
might open its eyes, then a soft latch, or the bang and the pounding.
1. Read ROADMAP S2-05b (its "From S2-05a" list) and `src/client/TapView.luau` (the plain bar).
2. The bar at phone size where a thumb already is (UI skill), rising in with motion, the marker's
   sweep and the zone drawn so they read at a glance; no words (AGENTS.md).
3. Hide the door's Open and Slam buttons on the puller's screen while the bar is up
   (`DoorSpotView` or `ButtonView`; grep "DoorAction"), so a thumb can't land on Slam.
4. Sounds: a warning tick as the bar rises (Dead by Daylight's), a soft latch on a hit (the
   "Settle" cue in `DoorSound.cues`), the miss's bang already plays as a slam's. Real recordings
   from the Creator Store, primed (`SoundPrimer`), each loading in Play with no permission line.
5. Verify in Play (STUDIO.md "Testing the tap" drives it; count `RenderStepped` first); phone
   steps in `OWNER.md`, replacing S2-05a's plain-bar note.
**Acceptance:** checks green; in Play the bar rises in, sweeps, answers a hit and a miss with
its sounds; the door's buttons are hidden while it's up; Output clean of new warnings.
**Read first:** ROADMAP S2-05b; `src/client/TapView.luau`; `src/shared/StorageUnit/ShutTap.luau`
(top half); `src/shared/StorageUnit/DoorSound.luau` (grep "Settle"); `docs/STUDIO.md` (grep
"Testing the tap", "Getting frames back"); the `roblox-dev:roblox-ui` skill.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-05b (next), S2-07a, S2-07b, then the Packrat (S2-06a its art first), then S3-01.
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
   permission warnings in Play's Output are older than this change.
7. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
   staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
