# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 167 (evening run, session 9: S2-06a2) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- The Packrat is in the place: uploaded (79124901483193, `art/packrat/assets.json`), prepared by
  the new `src/shared/Packrat/init.luau` (prepare, pose, rest, motors, `transforms(name)` by
  pose name, `carry(model)`, clone), template standing `Still` at
  `ReplicatedStorage.Keepers.Packrat`. Nothing deals it on a floor yet.
- Judged in Studio from 30 studs down a lit hall: empty reads as two pale lines wide of its
  sides, full as a pale box at its chest (`docs/art/S2-06a2-packrat-hall.jpg`, `-close.jpg`).
  The carry point moved back behind the forearms, which the find had swallowed (D-176); the
  spec checks it. Sheets rebuilt, FBX restored from git. Studio in Edit, judging hall gone.

## Next task: S2-06a3 Reach, take and put down
ROADMAP S2-06a3: the last poses, and the walks as a cycle a screen steps through.
1. In `Packrat/Pose.luau`, add `Reach` (one long arm out ahead at a find's height, hood leaning
   after it), `Take` (both hands closing on it, pulling it in toward the chest) and `PutDown`
   (bent over, the find low ahead in both hands). Each passes `check`, stands, no part through
   another; add their read to `tests/packrat.spec.luau` (reach: a hand well ahead of the chest;
   put down: hands below the hips and ahead).
2. The walks as a cycle, as the Mannequin's `Pose.at`/`Frames`/`frame`/`ofFrame`/`frameAt`/
   `along`/`held` do (read only that part of `Mannequin/Pose.luau`): blend the four keys of each
   walk over a stride by distance travelled; full steps shorter than empty. Frames numbered so a
   screen keeps a cache.
3. `Packrat.transforms` moves from pose names to frame numbers (the KeeperView `Kit` shape);
   keep a name-to-frame for the still poses.
4. Add the three poses to `scripts/packrat-poses.luau` and a sheet (`packrat-hands` or the
   lineup), `scripts/art.sh packrat renders`; then `git checkout art/packrat/out/Packrat.fbx`
   if anything rewrote it. Judge the sheet.
**Acceptance:** checks green; the three poses and both walks' frames pass the spec; a sheet of
reach, take and put down; nothing deals it on a floor yet (that's S2-06b).
**Read first:** ROADMAP S2-06a3; `src/shared/Packrat/Pose.luau`; `src/shared/Mannequin/Pose.luau`
lines 340 to 500; `src/client/KeeperView.luau` lines 55 to 80 (the Kit); `tests/packrat.spec.luau`;
`art/packrat/README.md`.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06a3 (next), then S2-06b to S2-06e, then S3-01. L-08e3c and L-14b2d wait on `OWNER.md`.
   R-01 is for later.
2. From S2-06a2: deeper finds (the television) will still meet the forearms at the carry point;
   S2-06b seats each by its depth or accepts it. On the server the body stays at rest, so S2-06b
   decides where the server keeps a carried find.
3. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
4. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
5. From S2-06a1: the Mannequin's `Pose.luau` keeps its own copy of the pose math that `Rig.luau`
   now holds; move it onto Rig when it's next touched (its spec proves the move). The Packrat's
   `init.luau` repeats the Mannequin's prepare and pose; fold both into one body module when a
   third jointed monster comes (D-176).
6. From S2-06a1: the Packrat's look could go further after the owner judges it: a lumpier
   bundle, the head lower between the shoulders, longer fingers that open when empty.
7. Left in the Queue: S1-07a 16 in 100 units hold nothing (may be right); S2-02c only a
   wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by hand; S2-03b
   loose keepers go to look at a pounding door (a feature).
8. From S2-07a2: a pounding door's blows are one noise going on, so a loose monster looking at
   it keeps looking until the pounding stops; a monster let out by a wrong code or a missed tap
   isn't held by the floor's limit; one trapped by players and bursting out can still pass it.
9. S2-02d4: the first clunk through the camera may come 0.3 s late. S2-05a: a sleeper woken by
   a missed tap isn't counted in `woken`. S2-07a1: a feed copies every monster at the start.
   S2-07b1: a light coming back over a still player fires `woke`. S2-07b2: 89260803894903 (the
   coin's TexturePack) wasn't brought back (`OWNER.md` asks). Unseen: S1-10d1 to d3, S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
