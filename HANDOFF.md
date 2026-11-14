# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 166 (evening run, session 8: S2-06a1) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-06a was split in three (context): a1 the model and its two walks (done), a2 into the place,
  a3 reach, take and put down. D-175.
- Built in `art/packrat/` (`scripts/art.sh packrat`, about a minute): 7.3 studs, 15 R15 parts,
  7,020 triangles, one 1024 set; quilted grey blankets creased and pinched under tan tape, an X
  over the chest, a dark hollow in the hood, long pale arms. FBX in `art/packrat/out/`, not yet
  uploaded (`upload_art` has its `Packrat` entry; `art/packrat/assets.json` doesn't exist yet).
- Poses: `src/shared/Packrat/Pose.luau` on the new shared `src/shared/Rig.luau` (the pose math);
  `Still` and both walks' four keys, `carry(pose)`. `tests/packrat.spec.luau` checks limits,
  floor, no part through another, and the read: full hands at the find above the waist, empty
  hands below the hips past its sides.
- Judged in Blender only: `art/sheets/packrat-hall.png` (844x390, 30 studs, Roblox's 70 degree
  camera) shows the full one as a pale knot at the chest, the empty one as two pale lines wide
  of its sides. Not in Studio yet. Studio untouched this session (still in Edit).

## Next task: S2-06a2 The Packrat into the place
ROADMAP S2-06a2: the model in the place, rigged and posed, judged from a real hall's end.
1. `lune run scripts/upload_art Packrat` (writes `art/packrat/assets.json`), then insert it
   (`insert_asset`, or `InsertService:LoadAsset` in Edit if that fails: STUDIO.md "Importing kit
   pieces"); remove its `Assistant:` tag and PackageLink.
2. Write `src/shared/Packrat/init.luau` as `Mannequin/init.luau` is (prepare: root, RigAttachments,
   Motor6Ds, parts massless and queryable, CollisionFidelity Box, each part's fallback colour by
   `Specs.Parts[n].Stuff`; pose; rest; motors; transforms; clone; a `carry(model)` CFrame for
   S2-06b), on `Rig.luau` and `Pose.luau`. Don't touch the Mannequin's.
3. In Edit: `prepare`, pose it `Still`, move it to `ReplicatedStorage.Keepers.Packrat`.
4. Judge in Studio at phone size: clone two into a real hall (STUDIO.md "Judging a wall piece
   in Edit" builds one), one `EmptyStepRight`, one `FullStepRight` with a real find at its carry
   point, 30 studs from the camera under a lit fixture; capture both; save to `docs/art/`.
5. Add an OWNER.md step to judge the Studio capture next to the existing look item.
**Acceptance:** checks green; `Keepers.Packrat` in the place with its Motor6Ds; a Studio capture
at phone size where full and empty read apart; nothing deals it on a floor yet.
**Read first:** ROADMAP S2-06a2; `art/packrat/README.md`; `src/shared/Mannequin/init.luau`;
`src/shared/Packrat/Pose.luau`; STUDIO.md "Importing kit pieces"; `docs/CODEMAP.md` lines for
Rig and Packrat.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06a2 (next), S2-06a3, then S2-06b to S2-06e, then S3-01. L-08e3c and L-14b2d wait on
   `OWNER.md`. R-01 is for later.
2. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
3. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
4. From S2-06a1: the Mannequin's `Pose.luau` keeps its own copy of the pose math that `Rig.luau`
   now holds; move it onto Rig when it's next touched (its spec proves the move).
5. From S2-06a1: the Packrat's look could go further after the owner judges it: a lumpier
   bundle, the head lower between the shoulders, longer fingers that open when empty.
6. Left in the Queue: S1-07a 16 in 100 units hold nothing (may be right); S2-02c only a
   wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by hand; S2-03b
   loose keepers go to look at a pounding door (a feature).
7. From S2-07a2: a pounding door's blows are one noise going on, so a loose monster looking at
   it keeps looking until the pounding stops; a monster let out by a wrong code or a missed tap
   isn't held by the floor's limit; one trapped by players and bursting out can still pass it.
8. S2-02d4: the first clunk through the camera may come 0.3 s late. S2-05a: a sleeper woken by
   a missed tap isn't counted in `woken`. S2-07a1: a feed copies every monster at the start.
   S2-07b1: a light coming back over a still player fires `woke` like any sighting.
9. From S2-07b2: 89260803894903 (the coin import's TexturePack) wasn't brought back; if it
    shows again, find what was on screen (`OWNER.md` asks). A friend budgeted out of real light
    shows no mark: by design.
10. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
    staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
