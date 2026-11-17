# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 266 (S5-03g1c2, the counter's furniture, part two) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). Its looks' art, S5-03g1, is done: floors and
  papers (D-321), name cards (D-322), furniture parts one (D-323) and two (D-324).
- g1c2: blanket, camp bed, string lights, neon moon in `furnish.py`; `Home.Specs.Glows` (tested).
  Home.fbx 33,534 triangles, 63 parts; sheet `art/sheets/home-furniture.png` judged. Not uploaded.
- An export rewrites Home.fbx byte-different with the same parts: `git checkout` it unless parts
  changed; bake one set with `--stage textures --sets Name` (the maps are tracked).
- Studio (Rojo unconnected) holds HEAD's code to S5-03f4b3, patched by hand, not saved; test save:
  a HardHat on the rail, cash 478, Green worn; Device Simulator: Galaxy A16.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03g2a The home's wall and floor panels (art)
The moment: in Arrange you tap a paper and the walls round you change, so a home needs its own
floor and wall panels for a look to land on, and each look's set has to reach Studio.
1. Read the Read-first list; a home's inside size is in `art/lobby/spec.py` (`SLOT_*`,
   `UNIT_WALL`); Grep how `Lobby.lay` dresses a unit's walls.
2. In `art/home/` (a new `panels.py`, the unit's way): one floor panel and one wall panel per
   partition, the back wall and the front wall's inside, UVs in studs over the tile (8 for
   floors, 4 for papers) so a set's pattern lines up across panels; a hair proud of the lobby's
   merged walls, which stay under them. Size them for the XL slot now; S5-03h moves them.
3. A small swatch part per look set in Home.fbx, wearing that set, so its SurfaceAppearance
   reaches Studio (game scripts can't write a SurfaceAppearance's maps, `docs/STUDIO.md`).
4. Numbers in `home_spec.py`; the panels and swatches in `Specs` (a `Panels` table: each panel's
   part, middle and turn in the unit's frame; `Swatches`: set to part); a Lune test that every
   look's set has a swatch and the panels cover the floor and walls.
5. Export; a sheet panel or `--stage looks` showing a unit dressed in panels; README; ROADMAP.
**Acceptance:** check green; the panels and swatches in Home.fbx with `Specs` naming them, every
look's set swatched, the sheet judged at phone size, under 20,000 triangles a part.
**Read first:** ROADMAP S5-03g2; `art/home/README.md` (the looks); `art/home/looks.py` (`TINTED`,
the set list); `art/home/home_spec.py` (`FLOORS` to `luau_looks`); `art/home/build.py`
(`stage_export`, `look_room`); `docs/STUDIO.md` (SurfaceAppearance).

## Queue (next sessions, the owner's ticket order)
1. Then g2b (the Arrange screen's paint and floor picker, saved per home), g3 (doors and name
   cards: ROADMAP says how the plates replace the lobby's), g4 (furniture at the counter, the
   glows near only), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-324.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures, the Packrat wanting a Gold; a crack on a cracked card (ROADMAP polish).
8. `CaughtSeized`: CaughtLunge, ArrangeView, FlashlightView each use their own string; share one.
9. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.
10. The catch's film comes from `Film.make`: watch a catch in Play once Rojo is connected.
11. The HUD coin count read 0 in Play again (S5-03f4b3) with the save's cash at 478: find why.
12. Neon cards (g3) and the furniture's glows (g4): check the light budget on the A16, homes lit.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
