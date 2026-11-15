# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 170 (evening run, session 12: S2-06b2a) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- The Packrat moves in Play (S2-06b2a, D-179). Slots knows each find by number (`finds`,
  `loose`, `lift`, `putDown`); `Keepers` tells each Packrat what lies loose (`tellLying`), welds
  the find to its UpperTorso at `Packrat.Chest` on `took`, and sets it on its pile on `laid`
  ("Take" again). Its body on the server (`KITS`) and screens (KeeperView's Kit: full and empty
  walks by the new Hows Carry and Hold; Reach, Take, PutDown held; no beats yet).
- Seen in Studio Play on the dev floor (the lobby's Packrat post, or Workspace `StandPackrat`):
  out of its unit, a walk to a boombox 70 studs off, reach, take, home with it at its chest
  (screens: shoulder hug steady, find at the chest), put down, out again. No floor deals one yet.

## Next task: S2-06b2b The deal, the hall lights and the find in its hands
ROADMAP S2-06b2b. If it won't fit, do the deal and the hands first; the lights can follow.
1. Read ROADMAP S2-06b2b and D-179. The deal (`Deal.luau` ~line 141, `Deal.Keepers`,
   `deck.sleepers`): one Packrat on floors 3 and up, asleep in a unit that also holds two or
   three finds of its own (a pile), never the guarded or a padlocked unit; spec it in
   `tests/deal.spec.luau`. Deals lays the pile; `Keepers.onDealt` stands it and calls
   `Keeper.nest` facing the pile (today `new` puts the pile 1.5 ahead of where it faces, and an
   awake one faces its door).
2. The find in its hands on screens: as the hands close, ease the find from where it lay into
   the Take grip (the weld's C0, set per frame in KeeperView by a Kit `carry(frame)`:
   `Pose.grip` for Take and PutDown, `Packrat.Chest` walking full). The server can set C0 to
   where the find lay (relative to the UpperTorso) so screens start the ease from there.
3. Hall lights come on as it walks, as for a player (`MotionLights`; default in `OWNER.md`).
4. Verify in Play: a floor 3 deal with a Packrat (DevFloorNumber 3), its unit opened, it
   stands among its finds; then the dev post's fetch with the find easing into its hands.
**Acceptance:** checks green; floor 3+ deals one asleep among its own finds; screens show the
find rise into its hands and sit between them, then at its chest; halls light as it walks.
**Read first:** ROADMAP S2-06b2b; D-179, D-178; `src/shared/Deal.luau` around 141 and grep
`sleepers`; `src/server/Keepers.luau` grep `onDealt`, `tookFind`; `src/client/KeeperView.luau`
grep `Packrat`; `src/shared/Packrat/Pose.luau` grep `grip`.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06b2b (next), S2-06c to e, then S3-01. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
2. A Packrat that catches someone (empty arms, hunting as the Mannequin until S2-06c) throws
   the Mannequin's face at them: `CaughtLunge` clones the Mannequin. S2-06c turns that catch
   into the take; until then it's wrong but rare.
3. A Packrat carrying a find when its floor is dropped takes the find with its body; Slots keeps
   a dead entry for it (tiny). `remove` sets it down first; the floor drop doesn't.
4. S2-06b1 left unspecced: a full Packrat trapped and let out (goes home), and its way home shut
   (roams carrying). Short paths in `roam`/`lookOut`; spec them when next touched.
5. Deeper finds (the television) meet the forearms at the carry point: seat each by its depth or
   accept it (look in b2b). `grab` (4) wasn't measured on the rig: in Play its arm reached the
   boombox; tune once judged.
6. For S2-06c: a few frames easing reach into take into the hug would make the snatch land.
7. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms so Brix can build it in its own sessions.
8. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it. Any
   ticket that adds finds starts from the catalog doc the GDD's finds section links (not agreed).
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
