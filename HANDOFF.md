# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 263 (S5-03g1a, the home's floors, papers, paints and door
colours) · **Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed
(`origin` is github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03), up to g1a: the looks' art (D-321).
- g1a: carpet, checker tiles and rubber mats beside the oak boards; stripes, leaves and daisies
  beside plain plaster; eight paints, eight door colours and each floor's five colours in
  `Home.Specs.Looks` (`tests/homelooks.spec`). A look's colour is the part's (Overlay). Sheet:
  `art/sheets/home-floors.png`, judged at phone size. The sets aren't in Home.fbx or Studio yet:
  g2's panels carry them (ROADMAP g2 says how).
- `build.py --stage textures --sets A,B` bakes only those sets (the baked maps are tracked, so
  don't re-bake the rest for nothing); `--stage looks` draws the sheet in seconds. An `export`
  rewrites Home.fbx byte-different with the same parts: `git checkout` it unless parts changed.
- Studio (Rojo unconnected) holds HEAD's code to S5-03f4b3, patched by hand, not saved by me;
  the test save: a HardHat on the rail, cash 478, Green worn; Device Simulator: Galaxy A16.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03g1b The name card's four styles (art)
The moment: walking down the hall, your friends' names glow, chalk and shine over their doors;
yours is the one you chose, and neon lights the wall around it.
1. See the card now: `art/lobby/spec.py`'s `CARD` (6 by 1.4 studs), `unit_card` and `cards()`
   (a SurfaceGui face per unit), and how the game writes it (`Holding.words`, the card spray).
2. In `art/home` (a `cards.py`, the unit's way): four plates over the door, each its own part
   on the same face: stencilled steel (powder-coated, not the climb's raw steel), a hand-painted
   board, a chalkboard in an oak frame, neon tubes on a dark backing. Bake what each needs.
3. Each style's lettering: a Roblox font and colour (verify the Enum.Font names on
   create.roblox.com and note them in STUDIO.md), written to `Home.Specs` as `Cards` (Id, parts,
   font, colour; neon's glow colour). Stencil is everyone's to start; neon is for Robux.
4. `scripts/art.sh home`; a sheet from down the hall, the four over doors (`home-cards.png`),
   judged at phone size; README table; a Lune check like `tests/homelooks.spec`. Then g1c.
**Acceptance:** check green; the plates in Home.fbx (not uploaded until g3), the sheet judged,
`Home.Specs.Cards` in place.
**Read first:** ROADMAP S5-03g1b; `art/home/README.md`; `art/lobby/spec.py` (`CARD`,
`unit_card`, `cards`); `src/shared/Home/Holding.luau`; `art/home/furnish.py` (a builder, the
mirror's `ring`); `art/unit/README.md`.

## Queue (next sessions, the owner's ticket order)
1. S5-03g1c, then g2 (paint and floors on Arrange; the panels first), g3 (doors and name cards),
   g4 (furniture at the counter), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars'
   hidden triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-321.
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

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
