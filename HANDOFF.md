# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 177 (evening run, session 19: S3-01a) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-01a (D-186): nobody is out of the climb. Left on a floor (late or wrapped), you watch the
  ride; 1.4 s after the gate opens on the new floor the view dips to black with the film's
  squeal and a door slam, and you wake wrapped in one of its units, empty-handed.
- Seen in Studio Play: everything starts clean; the carried wake (black, no "Caught", the eyes'
  keys, the Bang button). The carry across a real ride waits on `OWNER.md` (two players).

## Next task: S3-01b Everyone wrapped at once
ROADMAP S3-01b. The climb ends only when every player is wrapped at the same moment. Most of it
is there already (`ClimbEnd.over`: nobody left climbing); check it under S3-01a's rules.
1. Read ROADMAP S3-01b and D-186. Name the moment: the last friend caught, and the black.
2. Grep `ClimbEnds.luau` for `over` and `ClimbFate`: a carried player's fate should name the
   floor they're kept on now, not the one they were left on.
3. The gap: between `Watching:bring` and `KeptPlayers:store` (up to 4 s while the unit streams
   in) a carried player has a character and no kept mark, so they count as climbing. Decide
   whether a wipe should wait for them (default: count a player being carried as wrapped;
   Climbs knows who's in `carryUp`).
4. Spec the rules in `tests/climbend.spec.luau`; one player can check a wipe with a stand-in
   friend (STUDIO.md "Testing left behind" and "Testing the end").
**Acceptance:** checks green; a wipe lands only when everyone is wrapped; fates name the right
floor; spec'd; seen in Play as far as one player can.
**Read first:** ROADMAP S3-01b; DECISIONS D-186 and D-106; `ClimbEnd.over` (grep);
`src/server/ClimbEnds.luau` (grep `ClimbFate`); STUDIO.md grep "Testing left behind".

## Queue (next sessions per ROADMAP Phase 2)
1. S3-01b (next). Then S3-02 needs a Brix purchases piece: file it in Brix's ROADMAP in neutral
   terms first. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
2. A dropped find is solid: dropped standing, it lands 2.2 studs ahead and a player walking on
   bumps it (D-182). Consider finds not colliding with players.
3. On other screens a take goes from the hunt's walk straight to Take: a few frames of the arm
   coming out first would make the snatch land (KeeperView Kit). `grab` (4) not measured.
4. Output at floor 3's load: "ContentId rbxassetid://203785492 failed due to: Asset type does
   not match requested type", and "rbxassethash ... Requester does not have permission" lines in
   the client log. Find what asks for them.
5. A Packrat carrying a find when its floor is dropped takes the find with its body; Slots keeps
   a dead entry for it (tiny). `remove` sets it down first; the floor drop doesn't.
6. S2-06b1 left unspecced: its way home shut (roams carrying). The TV meets the forearms at the
   carry point: seat finds by depth or accept.
7. No medium unit open (never in 600 floors): a small unit, a pile of one. Woken shut in, it
   faces its door, its pile behind (unwatched).
8. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it. Any
   ticket that adds finds starts from the catalog doc the GDD's finds section links (not agreed).
9. Move the Mannequin's pose math onto `Rig.luau` when next touched; fold its and the Packrat's
   prepare and pose into one body module when a third jointed monster comes (D-176).
10. The watch bar keeps an empty panel's height now its rule line is hidden (S3-01a): trim it
   when the bar is next touched.
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
