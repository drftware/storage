# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 264 (S5-03g1b, the name card's four styles) · **Checks:** green
in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03), up to g1b: the looks' art (D-321) and the
  name card's styles (D-322).
- g1b: stencilled steel, a painted board, a chalkboard in oak and pink neon, each its own parts in
  Home.fbx (`art/home/cards.py`, 9 parts, 16,748 triangles in all), `Home.Specs.Cards` and
  `CardLight` (`tests/homecards.spec`). Sheet `art/sheets/home-cards.png` (`scripts/art.sh home
  cards`, 30 s, lettered from Studio's own font files), judged at phone size. Not uploaded: g3.
- `build.py --stage textures --sets A,B` bakes only those sets (the maps are tracked); an export
  rewrites Home.fbx byte-different with the same parts: `git checkout` it unless parts changed.
- Studio (Rojo unconnected) holds HEAD's code to S5-03f4b3, patched by hand, not saved by me;
  the test save: a HardHat on the rail, cash 478, Green worn; Device Simulator: Galaxy A16.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03g1c1 The counter's furniture, part one (art)
The moment: at the counter you see things you'd put in your own unit and want them: a milk crate
to sit on, a pallet coffee table, a folding table, a powder-coated steel shelf.
1. Read idea 19 in the home plan doc (docs tools, search the heading "furniture"), and how
   `furnish.py` builds a piece (the job box's `jobbox`, `band`; `wood_box`, `plaster_uv`).
2. In `furnish.py`, the unit's way: a milk crate (plastic, its grid of holes, the game paints it;
   you sit on it), a pallet (rough pine boards on three stringers, a coffee table), a folding table
   (a pale top, graphite legs), a steel shelf (powder-coated, Plaster like the job box, four tiers
   on angle posts). Numbers in `home_spec.py`, each a piece in `PIECES` with its parts in `TEXSET`.
   Bake only what a new look needs (`--sets`); a rough pine set if the oak won't do.
3. `scripts/art.sh home`; a sheet of the four at the counter and in a unit, judged at phone size
   (`stage_looks` or `stage_cards` in `build.py` show how); README table; ROADMAP. Then g1c2.
**Acceptance:** check green; the four pieces in Home.fbx (not uploaded until g4), the sheet
judged, `Home.Specs.Pieces` naming them.
**Read first:** ROADMAP S5-03g1c; `art/home/README.md`; `art/home/furnish.py` (head,
`jobbox`, `band`, `shelf`); `art/home/home_spec.py` (`PIECES`, `JOBBOX`); `art/home/carpentry.py`;
`art/unit/README.md`.

## Queue (next sessions, the owner's ticket order)
1. S5-03g1c2, then g2 (paint and floors on Arrange; the panels first), g3 (doors and name cards:
   ROADMAP says how the plates replace the lobby's), g4 (furniture at the counter), h; S5-03d4
   across the trip (unblocked); S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's
   beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-322.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is set by CaughtLunge and ArrangeView and read by FlashlightView, each with its
   own string: share one constant (a "camera held" attribute) when next in those files.
9. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.
10. The catch's film now comes from `Film.make`: watch a catch in Play once Rojo is connected.
11. The HUD coin count read 0 in Play again (S5-03f4b3) with the save's cash at 478: find why.
12. Twelve neon cards are twelve lights on the floor (g3): check the light budget on the A16.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
