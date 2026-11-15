# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 169 (evening run, session 11: S2-06b1) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- The Packrat's trip home is on the keepers' brain (S2-06b1, D-178). `KeeperRows.Packrat` with a
  new optional `collects` (grab 4, reach 0.8 s, take 0.5 s, put down 1.2 s, laden 0.72); light
  does nothing to it; its tell is the Mannequin's until S2-06e. `Keeper.lying(k, finds)` tells it
  what lies loose (`Keeper.Finds`); it fetches the nearest it can walk to (never from its own
  unit), reaches (`hands`), takes (`took`), walks home full deaf and blind, lays it (`laid`),
  comes out again. `shown`: Reaching, Taking, PuttingDown, Carrying. `nest(k, at, pile)`.
- `tests/collect.spec.luau` passes on 18 floors; Mannequin specs unchanged; both modules load
  in Studio (Edit). No floor deals a Packrat yet.

## Next task: S2-06b2 Into the game
ROADMAP S2-06b2. Big: if it won't fit, split it first (b2a the server, the deal and a body
standing in Play; b2b the screens' frames and the hall lights) and do b2a well.
1. Read ROADMAP S2-06b2, D-177 and D-178. Grep how the server holds finds (the Take prompt,
   `Slots`' drop) and how `Keepers` stands a body (`KITS`, `stand`, `offer`, `threw`).
2. The server's `Finds` per floor: every find lying loose (in a unit or a hall, not on the pile
   or in anyone's slots), the floor under each; `Keeper.lying` on each change (a find taken,
   dropped, lifted or laid; a door up or down).
3. On `took`: the find leaves the floor's list and players' prompts and rides at the Packrat's
   carry point (`Packrat.carry`; the body is at rest on the server, so decide where it sits).
   On `laid`: it lies on the pile, takeable again only in S2-06d (or now, if trivial).
4. A Kit row for the Packrat (server `KITS` and `KeeperView`): Carrying walks the full walk,
   else the empty one; Reaching, Taking, PuttingDown hold `Pose.held` frames; reset `along`
   when the walk switches (D-177). Its Kit plays no beats until S2-06e.
5. The deal (`Deal.luau`): one on floors 3 and up, asleep in a unit holding finds, `nest`
   facing them. Hall lights come on as it walks, as for a player (default in `OWNER.md`).
6. Verify in Play: stand one (dev corridor), drop a find, watch it fetch, carry and lay it.
**Acceptance:** checks green; in Play a Packrat walks to a dropped find, reaches, takes, carries
it home full-armed past a player, lays it and comes out; screens show full vs empty walks.
**Read first:** ROADMAP S2-06b2; D-177, D-178; `src/server/Keepers.luau` (grep `KITS`,
`offer`, `threw`); `src/client/KeeperView.luau` (grep `Kit`); `src/shared/Packrat/init.luau`;
`src/shared/Deal.luau` around line 141.

## Queue (next sessions per ROADMAP Phase 2)
1. S2-06b2 (next), S2-06c to e, then S3-01. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later.
2. S2-06b1 left unspecced: a full Packrat trapped and let out (goes home), and its way home shut
   (roams carrying). Both are short paths in `roam`/`lookOut`; spec them when b2 touches them.
3. For S2-06b2: deeper finds (the television) meet the forearms at the carry point, so seat
   each by its depth or accept it. `grab` (4) was set from D-177's numbers, not measured on
   the rig: tune it so its fingertips meet a find on the floor and on a shelf.
4. For S2-06c: the take is three held frames (Reach, Take, then the full walk); a few frames
   easing reach into take into the hug would make the snatch land harder. The empty Packrat
   hunts and catches as the Mannequin does today; c turns the catch into the take.
5. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
6. S4-04 "Trapping pays" was never agreed by the owner (`OWNER.md` asks); don't build it.
7. Move the Mannequin's pose math onto `Rig.luau` when next touched; fold its and the Packrat's
   prepare and pose into one body module when a third jointed monster comes (D-176).
8. Left: S1-07a 16 in 100 units hold nothing; S2-02c only a wandering Mannequin takes the
   errand; S2-02b nobody can throw the breaker by hand; S2-03b loose keepers look at a pounding
   door. S2-07a2: a monster keeps looking at a pounding door until it stops; one let out by a
   wrong code or a missed tap, or bursting out, can pass the floor's limit. S2-02d4: the first
   clunk through the camera may come 0.3 s late. S2-05a: a sleeper woken by a missed tap isn't
   in `woken`. S2-07a1: a feed copies every monster at the start. S2-07b1: a light coming back
   over a still player fires `woke`. S2-07b2: 89260803894903 (the coin's TexturePack) wasn't
   brought back (`OWNER.md` asks). Unseen: S1-10d1 to d3, S1-06, S1-05. The Packrat's look,
   once judged: a lumpier bundle, a lower head, longer fingers.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
