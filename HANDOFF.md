# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 173 (evening run, session 15: S2-06c2) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-06c is done (c1 D-181, c2 D-182). A Packrat with empty arms chasing you goes instead for a
  find it sees lying nearer than you (`bait`, `goForSeen` in `Keeper.luau`), never one on its own
  pile; the find's own landing clank no longer calls it off (`Keeper.Landing`); a tool dropped at
  a run falls at your heels (Slots `DROP_BEHIND`), between you and it. Its catch throws its own
  body (CaughtLunge `BODIES`; the Packrat's `Lunge` pose: reared up, pale hands either side of
  its hood).
- Seen in Play on floor 3: hunting the player, it turned off them for the dropped teddy, took it
  and went home. Not watched: the runner's heels drop and the catch's frames (`OWNER.md`).

## Next task: S2-06d Its pile, and trapping it
ROADMAP S2-06d. Split it in ROADMAP first if it won't fit one session (the pile, then trapping).
1. Read ROADMAP S2-06d and the GDD's Packrat list (its pile, bait, trapped in its own unit;
   docs tools, that section only).
2. The pile: check what already works (finds laid on its pile are "Take" again, D-180, `Slots`
   `putDown`), and what doesn't: taking one back while it's home, or while it's out.
3. Bait, Lune spec first (`tests/collect.spec.luau`): a find at the back of a unit draws it in
   (`nearestFind`, the walk), and a door brought down behind it traps it (`Keeper.trap`), as any
   monster. Check a trapped Packrat holding a find, and one shut in its own unit with its pile.
4. Shut in, it pounds and breaks out as any monster does: confirm its row's break-out numbers.
5. Verify in Play on floor 3 with the dev post: lead it into a unit with a find, shut the door.
**Acceptance:** checks green; a find at the back of a unit draws it in and the door traps it;
its pile is takeable; spec'd in Lune; seen in Play.
**Read first:** ROADMAP S2-06d; D-180 and D-182; `src/shared/Keeper.luau` grep `function
Keeper.trap`, `onPile`, `nearestFind`; `src/server/Keepers.luau` grep `laid`, `trapped`;
`tests/collect.spec.luau` grep `own pile`.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06d (next), S2-06e, then S3-01. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
2. A dropped find is solid: dropped standing, it lands 2.2 studs ahead and a player walking on
   bumps it. The heels drop fixes running only (D-182). Consider finds not colliding with players.
3. On other screens a take goes from the hunt's walk straight to Take, as a fetch snaps from
   Reach to Take: a few frames of the arm coming out first would make the snatch land (KeeperView
   Kit). `grab` (4) not measured on the rig.
4. Output at floor 3's load: "ContentId rbxassetid://203785492 failed due to: Asset type does
   not match requested type" lines, before any Packrat stood. Find what asks for that id.
5. A Packrat carrying a find when its floor is dropped takes the find with its body; Slots keeps
   a dead entry for it (tiny). `remove` sets it down first; the floor drop doesn't.
6. S2-06b1 left unspecced: a full Packrat trapped and let out (goes home), its way home shut
   (roams carrying). The TV meets the forearms at the carry point: seat finds by depth or accept.
7. No medium unit open (never in 600 floors): a small unit, a pile of one. Woken shut in, it
   faces its door, its pile behind (unwatched).
8. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms so Brix can build it in its own sessions.
9. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it. Any
   ticket that adds finds starts from the catalog doc the GDD's finds section links (not agreed).
   When finds get a worth, `Carry.worth` should read it instead of heft.
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
