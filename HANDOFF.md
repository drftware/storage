# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 172 (evening run, session 14: S2-06c1) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-06c1 is done (D-181). An empty-armed Packrat that reaches you takes the best thing you
  carry instead of wrapping you, and walks home with it; with empty slots it wraps you. The
  server fills each step's `Players.loot` (Slots `prize`, the pure `Carry.prize`: heaviest find,
  else a tool, never the ladder); the brain sets `took` and `robbed`; Slots `snatch` moves it
  from the hand to its chest, eased from where it was held. The robbed screen (ToolView
  `snatched`, ToolSnatched): a view kick, the Lunge beat and the thing's own sound, the thing
  torn from your grip toward it, its picture pulled off the wheel.
- Seen in Play: it took the TV over the teddy in hand, laid it, took the teddy, then wrapped the
  empty-handed player. No errors. The robbed screen wasn't watched (`OWNER.md`).

## Next task: S2-06c2 A find dropped in its path, and its own catch
ROADMAP S2-06c2.
1. Read ROADMAP S2-06c2, D-181 and the GDD's Packrat list item 7 ("Drop a cheap find in its
   path").
2. The brain first, Lune spec first (`tests/collect.spec.luau`): hunting with empty arms, a
   loose find it sees (in its sight and cone, a clear line) nearer than the one it hunts is
   fetched instead (`fetch`, the grab and reach as ever), never one on its own pile (its unit).
   A drop lands 2.2 studs ahead of you (`Slots` DROP_AHEAD): check a runner's drop is passed.
   Keep it cheap per step (a distance cut before any `KeeperMap.clear`).
3. Its catch of an empty-handed player: `CaughtLunge` clones the Mannequin for any keeper.
   Throw the Packrat's own body (its Reach pose, `Packrat.clone`) when the catch is its, or
   skip the lunge for it and keep the black; pick what lands best at phone size.
4. Verify in Play on floor 3 with the dev post and `GiveFind`: drop a find while it hunts you.
**Acceptance:** checks green; a find dropped in front of a hunting Packrat is fetched and you
walk away; its catch never shows the Mannequin; spec'd in Lune.
**Read first:** ROADMAP S2-06c2; D-181; `src/shared/Keeper.luau` grep `nearestFind`,
`catches`, `if hunting then`; `src/client/CaughtLunge.luau` grep `Mannequin`;
`tests/collect.spec.luau` grep `robber`.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06c2 (next), S2-06d, S2-06e, then S3-01. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
2. On other screens a take goes from the hunt's walk straight to Take, as a fetch snaps from
   Reach to Take: a few frames of the arm coming out first would make the snatch land (KeeperView
   Kit). `grab` (4) not measured on the rig.
3. Output at floor 3's load: six "ContentId rbxassetid://203785492 failed due to: Asset type does
   not match requested type" lines, before any Packrat stood (not from S2-06c1). Find what asks
   for that id and fix or replace it.
4. A Packrat carrying a find when its floor is dropped takes the find with its body; Slots keeps
   a dead entry for it (tiny). `remove` sets it down first; the floor drop doesn't.
5. S2-06b1 left unspecced: a full Packrat trapped and let out (goes home), its way home shut
   (roams carrying). The TV meets the forearms at the carry point: seat finds by depth or accept.
6. No medium unit open (never in 600 floors): a small unit, a pile of one. Woken shut in, it
   faces its door, its pile behind (unwatched).
7. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms so Brix can build it in its own sessions.
8. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it. Any
   ticket that adds finds starts from the catalog doc the GDD's finds section links (not agreed).
   When finds get a worth, `Carry.worth` should read it instead of heft.
9. Move the Mannequin's pose math onto `Rig.luau` when next touched; fold its and the Packrat's
   prepare and pose into one body module when a third jointed monster comes (D-176).
10. Left from earlier: S1-07a 16 in 100 units hold nothing; S2-02c only a wandering Mannequin
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
