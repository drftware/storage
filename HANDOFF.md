# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 179 (the owner's answers on finds, D-188 and D-189) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-01 is done. S3-01b (D-187): a friend being carried up counts as wrapped on the floor they're
  carried to, so "Caught" lands as the last free friend's catch cuts to black; carries then stop.
- D-188: the owner answered the catalog's 14 questions (Secret on top, a luck boost on sale,
  trapping pays 5 coins, boss floors possible). D-189: the end screen says "Caught", never "Kept". Four follow-ups wait in `OWNER.md`.
- Seen in Studio Play (one player, two stand-ins): the wipe landed 1.1 s after the car reached
  floor 3, nobody carried after it, Again clean. Two players wait on `OWNER.md`.
- **Find art** (D-190 to D-196): thirteen Lights and the RC car built, all in the place but the hard
  hat and firefly jar (not uploaded yet); next those two, then the theatre spotlight (WAVES.md).

## Next task: S4-01 Floors made by rules (the climb with no top)
ROADMAP S4-01. The owner said there's no top floor (D-128); the built climb still ends at floor 3
(`Climb.Top`, D-106). One table says, for any floor number, what it holds and how hard it is.
1. Read ROADMAP S4-01 and the GDD's "Floor rules" section only (docs tools, never WebFetch). Name
   the moment: two climbs in a row feel different, and floor 7 is scarier than floor 2.
   Leave room for boss floors and units bigger inside than they look; they come later (D-188).
2. It's big: split it in ROADMAP first (say S4-01a the rules table and the top gone, S4-01b what
   changes floor to floor), and do the first piece well.
3. Grep `Climb.Top`, `Climb.Building` and `topped` (Climbs, ClimbEnds, EndView) for what leans on
   the top; the escape ("Made it") has no trigger once the top goes: keep its code, note it.
4. Every number in shared Config-style tables with a comment on what it does to the player;
   spec the table with Lune (any floor number in, sane rows out, up to 100 and past it).
**Acceptance:** checks green; the climb goes past floor 3 in Studio Play (DevFloorNumber 3,
punch the code, ride on); the rules spec'd; `OWNER.md` lines for what the owner must judge.
**Read first:** ROADMAP S4-01; GDD "Floor rules"; DECISIONS D-106 and D-128; `src/shared/Climb.luau`;
`src/shared/Deal.luau` (grep what a floor deals); STUDIO.md grep "The dev floor's ride".

## Queue (next sessions per ROADMAP Phase 2)
1. S3-02 waits on Brix: no purchases piece is built or on Brix's ROADMAP (checked Nov 14). A
   session allowed to edit Brix files it there in neutral terms; S3-03 and S3-04 sell things and
   wait with it. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
2. A dropped find is solid: dropped standing, it lands 2.2 studs ahead and a player walking on
   bumps it (D-182). Consider finds not colliding with players.
3. On other screens a take goes from the hunt's walk straight to Take: a few frames of the arm
   coming out first would make the snatch land (KeeperView Kit). `grab` (4) not measured.
4. Output in Play: "rbxassethash ... Requester does not have permission" warnings (25 on Nov 14)
   and floor 3's "ContentId rbxassetid://203785492 ... Asset type does not match". Find what
   asks for them.
5. A Packrat carrying a find when its floor is dropped takes the find with its body; Slots keeps
   a dead entry for it (tiny). `remove` sets it down first; the floor drop doesn't.
6. S2-06b1 left unspecced: its way home shut (roams carrying). The TV meets the forearms at the
   carry point: seat finds by depth or accept.
7. Unwatched: a Packrat woken shut in faces its door; no medium-unit home in 600 floors.
8. S4-04 "Trapping pays" is agreed now (5 coins a trapped monster, D-188). Any ticket that adds
   finds starts from the catalog doc the GDD's finds section links (answered Nov 14, D-188).
9. Move the Mannequin's pose math onto `Rig.luau` when next touched; fold its and the Packrat's
   prepare and pose into one body module when a third jointed monster comes (D-176).
10. Trim the watch bar's empty panel height (S3-01a) when the bar is next touched.
11. S3-01b: a wipe after the bring (while the unit streams in, near instant in Studio) is spec'd
   and handled on screen but unseen; Studio's "CutFree" let-in still stands a watcher in the
   lobby (S3-03 owns it).
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
