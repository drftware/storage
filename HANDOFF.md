# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 168 (evening run, session 10: S2-06a3) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- The Packrat's art is done (S2-06a). New in `Packrat/Pose.luau`: `Reach` (one long arm out at a
  player's chest, the find at its fingertips), `Take` (both hands on it, halfway in), `PutDown`
  (crouched, the find low), `grip(pose, hands)` for where a find sits in its hands; the walks as
  a smooth cycle (`Walk.Step` 1.6 empty, 1.15 full), 68 numbered frames (`held(name)`,
  `frame(walk, travelled)`, `ofFrame`); `Packrat.transforms(frame)` (D-177). Spec checks all.
- Checked in Studio: all 68 frames build on the real rig, hands where the spec says. Sheets
  `packrat-take` and `-reach-hall`. Nothing deals it on a floor yet. Studio in Edit, untouched.

## Next task: S2-06b1 The trip home, on the brain
ROADMAP S2-06b (split in two): b1 is the pure rules on the keepers' brain, with Lune specs.
1. Read GDD "The Packrat collects things, not people" (only that section) and ROADMAP S2-06b.
2. Add the Packrat's row to `KeeperRows`, roaming out from its own unit (how it hunts players
   is S2-06c). What a row can't say yet is a new field, defaulted off for the Mannequin.
3. On `Keeper.luau`, a new errand as the Mannequin's breaker errand is shaped (grep `errand`):
   it picks the next find it can reach (nearest first is a sensible default; list it in
   `OWNER.md`), walks there, stands for the reach and take, walks home full, stands to put it
   down, comes out again. While full it ignores players (no chase, no hearing). The brain only
   says where it goes and what it holds; which find is lying where comes in from outside, as
   the breaker's place does (`offer`-style), so the server can own it in b2.
4. States a screen will need (Reaching, Taking, PuttingDown, and carrying while walking) named
   so `KeeperMotion.how` can map them in b2 (D-177: the Kit doesn't yet say which walk).
5. Lune specs first: which find it picks, a full trip home and back, ignoring a player while
   full, a find taken before it gets there (it picks another), no finds left (it roams).
**Acceptance:** checks green; the specs above pass; the Mannequin's specs unchanged; nothing
in the game deals a Packrat yet (that's b2).
**Read first:** ROADMAP S2-06b; GDD "The Packrat collects things, not people";
`src/shared/KeeperRows.luau`; `src/shared/Keeper.luau` lines 170 to 200, 420 to 530 and 1020
to 1085 (the errand); `tests/keeper.spec.luau` (grep `errand` for how it's tested); D-177.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06b1 (next), then S2-06b2, S2-06c to S2-06e, then S3-01. L-08e3c and L-14b2d wait on
   `OWNER.md`. R-01 is for later.
2. For S2-06b2: on the server the body stays at rest, so b2 decides where the server keeps a
   carried find; deeper finds (the television) meet the forearms at the carry point, so seat
   each by its depth or accept it. The Kit's `along(travelled, how)`/`frameAt(along)` don't say
   which walk: give the Packrat a How for carrying and reset a view's `along` when it switches.
3. For S2-06c: the take is three held frames (Reach, Take, then the full walk); a few frames
   easing reach into take into the hug would make the snatch land harder. `Pose.grip` says
   where the find is in each.
4. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
5. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
6. The Mannequin's `Pose.luau` keeps its own copy of the pose math `Rig.luau` holds; move it
   onto Rig when next touched. The Packrat's `init.luau` repeats the Mannequin's prepare and
   pose; fold both into one body module when a third jointed monster comes (D-176).
7. The Packrat's look, once the owner judges it: a lumpier bundle, a lower head, longer fingers.
8. Left in the Queue: S1-07a 16 in 100 units hold nothing (may be right); S2-02c only a
   wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by hand; S2-03b
   loose keepers go to look at a pounding door (a feature).
9. From S2-07a2: a pounding door's blows are one noise going on, so a loose monster looking at
   it keeps looking until the pounding stops; a monster let out by a wrong code or a missed tap
   isn't held by the floor's limit; one trapped by players and bursting out can still pass it.
10. S2-02d4: the first clunk through the camera may come 0.3 s late. S2-05a: a sleeper woken by
    a missed tap isn't counted in `woken`. S2-07a1: a feed copies every monster at the start.
    S2-07b1: a light coming back over a still player fires `woke`. S2-07b2: 89260803894903 (the
    coin's TexturePack) wasn't brought back (`OWNER.md` asks). Unseen: S1-10d1 to d3, S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
