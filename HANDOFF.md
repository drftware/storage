# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 162 (evening run, session 4: S2-07a1) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-07a was split in ROADMAP (five fixes with Play checks didn't fit one session): S2-07a1 the
  camera's two is done (D-171), S2-07a2 the monsters' three is next.
- The camera feed now follows every monster on its floor, not only the one it's for, stepping
  only parts that moved; a second feed from the same camera joins the picture, from another it
  waits its turn (`Feed.arrive`, `Feed.kept`, Lune specs). Seen in Studio Play: a wandering
  Mannequin the server never named walked in staged feeds (and in a capture); a join kept one
  picture; a third camera waited and cut in; a Cut ended it; the real errand feed ran as before.
  Output clean of new lines. Not seen: two real Mannequins at the box at once (`OWNER.md`).
- The order ahead (ROADMAP): S2-07a2, S2-07b, S2-06a to S2-06e, S3-01.

## Next task: S2-07a2 The monsters' three
ROADMAP S2-07a2: three fixes to the monsters, each a pure rule first with a failing Lune spec.
1. Read ROADMAP S2-07a2, then grep before reading: each fix names the ticket that left it.
2. The breaker errand (S2-02d2): a Mannequin on its way to the box is called off by sounds less
   often, so the throw usually happens (four came to one clunk). Find where an errand is
   dropped on hearing (`Keeper.hear`, `Keeper.offer` in `src/shared/Keeper.luau`; `Keepers`
   grep "breaker", "hearAt"): e.g. an errand ignores sounds below some loudness or past some
   distance, a slam close by still calls it. Name the precedent; default in `OWNER.md`.
3. Monsters called to one spot spread round it instead of all standing on one point (S2-04b, a
   wrong code's alarm calls every keeper awake: `Keepers` grep "Wrong", "hearAt"): a pure
   spread rule (each takes its own place in a ring round the spot, reachable on the floor's map).
4. A wave of sleepers waking never passes the floor's limit on awake monsters (S2-03a,
   `Deal.awakeCap`, `Waking`). Read `Waking.luau`'s comment at line 44 first: it says pounding
   ones are left out on purpose; keep that and cap only the ones a wave sets loose.
5. Verify each in Play (STUDIO.md "Sending the Mannequin to the box", "Testing sleepers
   waking", "Getting frames back"; S2-04b's wrong-code recipe, grep STUDIO.md "wrong code");
   owner steps in `OWNER.md`.
**Acceptance:** checks green; in Play an errand reaches the box despite a far sound, called
monsters stand apart round the keypad, a wave stops at the cap.
**Read first:** ROADMAP S2-07a2; `src/shared/Waking.luau`; `src/shared/Deal.luau` (grep
"awakeCap"); `src/shared/Keeper.luau` (grep "function Keeper.hear", "offer");
`src/server/Keepers.luau` (grep only: "breaker", "Wrong", "hearAt", "awakeCap").

## Queue (next sessions per ROADMAP Phase 2)
1. S2-07a2 (next), S2-07b, then the Packrat (S2-06a its art first), then S3-01.
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
8. From S2-07a1: a feed copies every monster on its floor at the start (about 15 parts each);
   fine for a few, worth a look if a floor ever holds dozens.
9. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
   staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
