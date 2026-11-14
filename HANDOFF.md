# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 165 (evening run, session 7: S2-07b2) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-07 (the fix pass) is done. S2-07b2 (D-174): a friend's lit torch shows the faint mark on
  your screen as yours does (`Beam.friends`, `FaintMark.under`); a long thing bought from the
  machine leans into the bin only as far as fits behind the glass (`Buy.tumble`: the saw 41
  degrees, 0.022 behind the glass, where it crossed it by 0.056); the Output lines are traced
  and none is the game's (D-174, STUDIO.md "The screen's three").
- Seen in Studio Play: a stand-in friend's beam (a second FaintMarkView stepped by hand) took
  the mark on floor 1 from hidden to 70% in 0.5 s, sagged with a dying light, lingered, went;
  the real saw's box run through the vend's path. Not seen: two real players, a real vend.
- Studio is in Edit, `DevFloorNumber` cleared, `LoadCharacterAppearance` back to true.
- The order ahead (ROADMAP Phase 2): S2-06a to S2-06e (the Packrat), then S3-01.

## Next task: S2-06a The Packrat's art
ROADMAP S2-06a: the second monster's model, built the unit's way in `art/packrat/`, as the
Mannequin was (L-06a, `art/mannequin/`).
1. Read ROADMAP S2-06a and S2-06 (the moment: a friend drops their lamp so the monster behind
   them picks it up and walks off), and the GDD's "The Packrat collects things, not people"
   (docs tools, never WebFetch).
2. Read `art/unit/README.md` (how art is made) and skim `art/mannequin/` for the recipe the
   keeper rig follows (spec, parts, joints, poses, Specs module, look sheets).
3. Build it: a tall, faceless bundle of grey moving blankets and packing tape with long bare
   arms. Poses: walking with arms full (a find held to its chest), walking empty, reaching,
   taking, putting down. Shared texture sets, baked PBR, FBX, a generated `Specs` module.
4. Judge the look sheets and Studio at phone size for one thing first: full arms read apart
   from empty arms from the far end of a hall (stand it 30 studs off, as L-06a did).
5. Upload by Open Cloud and `insert_asset` (STUDIO.md "Importing kit pieces"); put it where the
   keeper rows find templates (`ReplicatedStorage.Keepers`), not yet dealt on any floor.
**Acceptance:** checks green; the model in the place with its poses; a look sheet and a Studio
capture at phone size where full and empty arms read apart from a hall's end; OWNER.md asks
the owner to judge the look.
**Read first:** ROADMAP S2-06 and S2-06a; GDD "The Packrat collects things, not people";
`art/unit/README.md`; `art/mannequin/` (its spec and build script, by grep); STUDIO.md
"Importing kit pieces"; `docs/CODEMAP.md` lines for Mannequin and KeeperRows.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06a (next), then S2-06b to S2-06e, then S3-01. L-08e3c and L-14b2d wait on `OWNER.md`.
   R-01 is for later.
2. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
3. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
4. Left in the Queue: S1-07a 16 in 100 units hold nothing (may be right); S2-02c only a
   wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by hand; S2-03b
   loose keepers go to look at a pounding door (a feature).
5. From S2-07a2: a pounding door's blows are one noise going on, so a loose monster looking at
   it keeps looking until the pounding stops; a monster let out by a wrong code or a missed tap
   isn't held by the floor's limit; one trapped by players and bursting out can still pass it.
6. From S2-02d4: the first clunk through the camera of a session may come 0.3 s late.
7. From S2-05a: a sleeper woken by a missed tap isn't counted in its floor's `woken`.
8. From S2-07a1: a feed copies every monster on its floor at the start (about 15 parts each).
9. From S2-07b1: a light coming back over a still player fires `woke` like any sighting.
10. From S2-07b2: 89260803894903 (the coin import's TexturePack) wasn't brought back; if it
    shows again, find what was on screen (`OWNER.md` asks). A friend budgeted out of real light
    (four or more lit torches near you) shows no mark: by design, so the mark sits only in light.
11. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
    staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
