# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 171 (evening run, session 13: S2-06b2b) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-06b is done (D-178 to D-180). From floor 3 every floor deals one Packrat, asleep at the back
  of a medium unit (never a note's, padlocked or another sleeper's) among two or three different
  finds of its own at its feet (`Deal.packratIn`, `DealSpot.inUnit`'s `near`, `Deals` `layPile`,
  `Keeper.nest` on the pile). Laid finds go beside the pile. Its root trips hall lights
  (`KeeperRows.tripsLights`). Screens hold a taken find where it lay until they show the hands
  close, then ease it into them, to its chest, and down into the crouch (KeeperView `hold`,
  `Packrat.Grip`, `Held`, `Ease`, the weld's `From`).
- Seen in Play: floor 3 dealt it in medium Unit 314; the dev post's fetch took, carried and
  laid with no errors, four hall lights lit. Not watched: its pile, the ease (`OWNER.md`).

## Next task: S2-06c It takes from you, or wraps you
ROADMAP S2-06c. If it won't fit, split it (the take first; the dropped find in its path after).
1. Read ROADMAP S2-06c, D-178 to D-180 and the GDD's Packrat section ("takes from you").
2. The brain (`Keeper.luau`, Lune spec first, `tests/collect.spec.luau`): with empty arms it
   hunts a player it sees at just under walking speed, light doing nothing to it; reaching one
   it takes rather than catches when they carry a find (or a tool when they carry no find),
   then goes home full as after a fetch. Empty slots: an ordinary catch. A find dropped in its
   path is fetched instead of the player.
3. The server (`Keepers`, `Slots`): which slot it takes (the most valuable find; a tool only
   with no find; never the flashlight; the big find doesn't count), out of the player's hand
   into its arms (`lift`'s weld, `From` where the player held it).
4. The answer on the robbed player's screen: its reach, the thing leaving your slot on the
   wheel, a sound (the Mannequin's catch beat until S2-06e), a kick of the view. Queue 2:
   `CaughtLunge` must not clone the Mannequin for a Packrat.
5. Verify in Play on floor 3 (Workspace `DevFloorNumber` 3) or with the dev post.
**Acceptance:** checks green; an empty Packrat that reaches you takes your best find and walks
home with it; with nothing to take it catches you; the robbed screen answers; spec'd in Lune.
**Read first:** ROADMAP S2-06c; D-180; GDD Packrat section; `src/shared/Keeper.luau` grep
`collects`, `caught`, `hands`; `src/server/Keepers.luau` grep `tookFind`, `catch`;
`src/server/Slots.luau` grep `lift`, `carried`.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06c (next), S2-06d, S2-06e, then S3-01. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
2. A Packrat that catches someone throws the Mannequin's face at them: `CaughtLunge` clones the
   Mannequin. S2-06c turns that catch into the take; until then it's wrong but rare.
3. A Packrat carrying a find when its floor is dropped takes the find with its body; Slots keeps
   a dead entry for it (tiny). `remove` sets it down first; the floor drop doesn't.
4. S2-06b1 left unspecced: a full Packrat trapped and let out (goes home), and its way home shut
   (roams carrying). Short paths in `roam`/`lookOut`; spec them when next touched.
5. The television meets the forearms at the carry point: seat finds by depth or accept it.
6. For S2-06c: the find eases now, but the arms still snap from Reach to Take; a few frames
   between would make the snatch land. `grab` (4) not measured on the rig.
7. No medium unit open (never in 600 floors): a small unit, a pile of one. Woken shut in, it
   faces its door, its pile behind (unwatched).
8. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms so Brix can build it in its own sessions.
9. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it. Any
   ticket that adds finds starts from the catalog doc the GDD's finds section links (not agreed).
10. Move the Mannequin's pose math onto `Rig.luau` when next touched; fold its and the Packrat's
   prepare and pose into one body module when a third jointed monster comes (D-176).
11. Left from earlier: S1-07a 16 in 100 units hold nothing; S2-02c only a wandering Mannequin
   takes the errand; S2-02b nobody can throw the breaker by hand; S2-03b loose keepers look at a
   pounding door; S2-07a2 a monster let out by a wrong code, a missed tap or bursting out can
   pass the floor's limit; S2-02d4 the first clunk may come 0.3 s late; S2-05a a sleeper woken by
   a missed tap isn't in `woken`; S2-07a1 a feed copies every monster at the start; S2-07b1 a
   light coming back over a still player fires `woke`; S2-07b2 the coin's TexturePack
   (`OWNER.md` asks). Unseen: S1-10d1 to d3, S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
