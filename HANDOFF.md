# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 175 (evening run, session 17: S2-06e) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S2-06e is built (D-184): empty, padded steps and a tape screech once a stride; full, heavier
  steps with the find rattling (`KeeperRows`, `Packrat.Pose.tell`, `KeeperTell.full`/`of`),
  switched by the How each screen shows. Spec'd (`tests/tell.spec.luau`); recordings measured.
- Not heard in Play (Queue 1).

## Next task: S3-01 Stay wrapped, carried up
ROADMAP S3-01. Nobody is out of the climb: wrapped or late when the gate shuts, you watch the
ride and turn up wrapped in a unit on the next floor, empty-handed, until a friend cuts you
free. The climb ends only when everyone is wrapped at once. Changes L-08c's and L-08d's rules.
1. Read ROADMAP S3-01 and the GDD's "Getting caught" section (docs tools: search "Getting
   caught", that section only). Name the moment: the dread of the ride up wrapped, and the
   friend who comes back for you.
2. Read how a wrapped player and a late one end today: grep `L-08c` and `L-08d` in DECISIONS,
   then `src/server` grep `Kept` / `left behind` for where they're taken out of the climb.
3. Split S3-01 in ROADMAP if it won't fit (the carry up and the next-floor unit first; the
   everyone-wrapped end second). Do the first piece well.
4. Wrapped on the ride you watch it (the car's view); on arrival you stand wrapped in a unit on
   the new floor, hands empty (finds stay where they were); banging and watching only.
5. Lune-spec the pure rules (who rides, who's out, when the climb ends); verify in Play with
   the dev floor what you can, and write the multi-player steps into `OWNER.md`.
**Acceptance:** checks green; a wrapped player turns up wrapped on the next floor; the climb
goes on while anyone is free; spec'd; seen in Play as far as one player can.
**Read first:** ROADMAP S3-01; GDD "Getting caught"; DECISIONS grep `L-08c`, `L-08d`; CODEMAP grep `Kept`.

## Queue (next sessions per ROADMAP Phase 2)
1. **The Packrat was silent in Play** (D-184; STUDIO.md "Hearing a keeper from the MCP"): no
   Sounds made on it live, though test copies of KeeperView and KeeperSounds worked. If the
   owner hears nothing, fix this before S3-01; check the Mannequin too.
2. S3-01 (next). L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
3. A dropped find is solid: dropped standing, it lands 2.2 studs ahead and a player walking on
   bumps it. The heels drop fixes running only (D-182). Consider finds not colliding with players.
4. On other screens a take goes from the hunt's walk straight to Take, as a fetch snaps from
   Reach to Take: a few frames of the arm coming out first would make the snatch land (KeeperView
   Kit). `grab` (4) not measured on the rig.
5. Output at floor 3's load: "ContentId rbxassetid://203785492 failed due to: Asset type does
   not match requested type" lines before any Packrat stood; this session also 23 "rbxassethash
   ... Requester does not have permission" lines in the client log. Find what asks for them.
6. A Packrat carrying a find when its floor is dropped takes the find with its body; Slots keeps
   a dead entry for it (tiny). `remove` sets it down first; the floor drop doesn't.
7. S2-06b1 left unspecced: its way home shut (roams carrying). The TV meets the forearms at the
   carry point: seat finds by depth or accept.
8. No medium unit open (never in 600 floors): a small unit, a pile of one. Woken shut in, it
   faces its door, its pile behind (unwatched).
9. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms so Brix can build it in its own sessions.
10. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it. Any
   ticket that adds finds starts from the catalog doc the GDD's finds section links (not agreed).
   When finds get a worth, `Carry.worth` should read it instead of heft.
11. Move the Mannequin's pose math onto `Rig.luau` when next touched; fold its and the Packrat's
   prepare and pose into one body module when a third jointed monster comes (D-176).
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
