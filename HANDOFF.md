# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 174 (evening run, session 16: S2-06d) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-06d is done (D-183). A Packrat going for a find turns for one that turns up 4 studs nearer
  (`Keeper.Nearer`, in `Keeper.lying`), so bait draws it as it passes. Bait at the back of a
  unit, the slam trapping it reaching or holding, pounding, out at 90 s, home with what it
  holds, and shut in its own unit with its pile were already true and are now spec'd in
  `tests/collect.spec.luau`.
- Seen in Play on floor 3: it laid the boombox, walked into Unit 308 for a teddy at the back,
  reached, the slam trapped it, it pounded, burst out at 90 s and caught the player standing at
  the door. Taking back from its pile not watched (`OWNER.md`).

## Next task: S2-06e How it sounds
ROADMAP S2-06e. One sound while it carries and another while its arms are empty, each heard
before it's seen, made the way the Mannequin's were (L-06c). Real recordings, primed.
1. Read ROADMAP S2-06e and the GDD's Packrat "Sound and lights" paragraph (docs tools: search
   "Sound and lights", that block only).
2. Read how the Mannequin's tell works: its row's `tell` (`KeeperRows`), `KeeperTell.luau`,
   and the screen that plays it (grep `tell` in `src/client`). The Packrat's row borrows the
   Mannequin's `tell` and its Kit plays no beats yet.
3. Pick two recordings on the Creator Store (empty arms: something dragging, cloth and tape;
   full: the find's own rattle under a heavier tread), each loading in Play with no permission
   line in Output, primed (`SoundPrimer`). Measure them as STUDIO.md's sound notes do.
4. Give the Packrat its own `tell`, full and empty, switched on `Keeper.shown` (Carrying vs the
   rest); spec the switch in Lune if it's pure.
5. Verify in Play on floor 3 with the dev post: hear it empty, then carrying the boombox home.
**Acceptance:** checks green; full and empty sound apart and are heard before it's seen; real
recordings, primed, no permission lines; seen (heard) in Play.
**Read first:** ROADMAP S2-06e; D-101 (L-06c1) in DECISIONS; `src/shared/KeeperRows.luau` grep
`tell`; `src/shared/KeeperTell.luau`; `src/client` grep `KeeperTell`; STUDIO.md grep `SoundPrimer`.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06e (next), then S3-01. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
2. A dropped find is solid: dropped standing, it lands 2.2 studs ahead and a player walking on
   bumps it. The heels drop fixes running only (D-182). Consider finds not colliding with players.
3. On other screens a take goes from the hunt's walk straight to Take, as a fetch snaps from
   Reach to Take: a few frames of the arm coming out first would make the snatch land (KeeperView
   Kit). `grab` (4) not measured on the rig.
4. Output at floor 3's load: "ContentId rbxassetid://203785492 failed due to: Asset type does
   not match requested type" lines, before any Packrat stood (seen again this session). Find what
   asks for that id.
5. A Packrat carrying a find when its floor is dropped takes the find with its body; Slots keeps
   a dead entry for it (tiny). `remove` sets it down first; the floor drop doesn't.
6. S2-06b1 left unspecced: its way home shut (roams carrying). The TV meets the forearms at the
   carry point: seat finds by depth or accept.
7. No medium unit open (never in 600 floors): a small unit, a pile of one. Woken shut in, it
   faces its door, its pile behind (unwatched).
8. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms so Brix can build it in its own sessions.
9. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it. Any
   ticket that adds finds starts from the catalog doc the GDD's finds section links (not agreed).
   When finds get a worth, `Carry.worth` should read it instead of heft.
10. Move the Mannequin's pose math onto `Rig.luau` when next touched; fold its and the Packrat's
   prepare and pose into one body module when a third jointed monster comes (D-176).
11. Shut in with the bait while its arm was out, it stands empty-handed at the door and fetches
   the bait once out (D-183). Taking it while shut in would read the same from outside; leave it.
12. Left from earlier: S1-07a 16 in 100 units hold nothing; S2-02c only a wandering Mannequin
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
