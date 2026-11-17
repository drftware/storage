# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 249 (placements built in Brix, D-306) · **Checks:** green in a
throwaway worktree at HEAD plus this session's change; the shared checkout may be red only from the
find run's uncommitted `src/shared/Finds/Rows.luau` and `tests/stuffdeal.spec.luau` · **Git:** `main`,
committed, not pushed (`origin` is github.com/drftware/storage); Brix pinned at `7f25310`, NOT on
Brix's `origin` yet (nor 482368f and 6574e0c before it).

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03): ground floor, fronts, starter sets, switch,
  a home each, hard hat, mirror, oak shelf with finds, job box, its panel, taking out, selling,
  Golds, cracked finds at half, and taking finds up into a climb, seen in Studio (S5-03d3).
- Arrange (S5-03e) has its judge: Brix's `Placements` (ENG-26a, D-306), pure, with grid and free
  snaps and a saved form. Nothing here uses it yet; the pin moved and checks are green.
- On a live server the climb is on its own server and the teleport carries nothing yet (S5-03d4).
- Studio: watch the save with a Server `GetAsync` on "Saves.studio" (STUDIO.md "Taking finds up,
  seen"). The test save: cash 476, 37 finds (no Blob lamp, Skates 1, Boombox 9), Gold Teddies.
- Stage only your own paths; the find run commits its own `art/finds/` and `src/shared/Finds/`.

## Next task: S5-03e2 Arranged, saved and checked
The moment it serves: you set your lava lamp on the job box and it stays there, for you and for
every friend who walks in, after a rejoin too; a cheat can't drop it in a wall or a friend's unit.
Server and save only; the screen is e3.
1. Read Brix's `docs/modules/Placements.md` (`../engine`) and D-306. A home file of its own
   (say `src/shared/Home/Spots.luau`, never the find run's `Rows.luau`): each find kind's spot
   (floor, tabletop, wall, ceiling) and footprint in studs from its art, a sensible default for a
   kind not listed; the shelf's and job box's tops; the unit's areas by size from its XL slot.
2. A new save version in `src/shared/Save.luau` holding the saved form (`placed`), with its
   migration (empty) and specs; a find placed is still the player's, just out of the chest.
3. Server: one `Brix.Placements` per held unit as it's claimed (limit 25, 50, 100, 150 by size),
   loaded from the save; rows left out go back to the chest. Remotes Place and PutAway, each
   checked (type, range, the unit's holder only, a find they own) and rate-limited with
   `Brix.RateLimit.bucket`; each change saved and told to every client, drawn at its spot.
4. A Studio dev command that places a find, then a Play pass: placed, refused in a wall, kept on
   rejoin. `scripts/check.sh` green (in a throwaway worktree if the find run has it red).
**Acceptance:** check green; specs for spots, the save migration and the server's checks; seen in
Studio Play, or steps in OWNER.md.
**Read first:** ROADMAP S5-03e2; D-306; `../engine/docs/modules/Placements.md`;
`src/shared/Save.luau`; `src/server/FrontOffice.luau`; `../engine/docs/modules/Remotes.md` (RateLimit).

## Queue (next sessions, the owner's ticket order)
1. S5-03e2, e3, then S5-03f-h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
