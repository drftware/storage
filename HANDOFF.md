# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 267 (S5-03g2a, the home's wall and floor panels) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03). Its looks' art is done (S5-03g1, D-321 to
  D-324) and now its panels (D-325): `art/home/panels.py`, `Specs.Panels` and `Specs.Swatches`.
- Home.fbx 33,714 triangles, 76 parts, 18.8 MB (the looks' maps now embedded via the swatches).
  Not uploaded. An export rewrites Home.fbx byte-different with the same parts: `git checkout` it
  unless parts changed; bake one set with `--stage textures --sets Name` (the maps are tracked).
- Studio (Rojo unconnected) holds HEAD's code to S5-03f4b3, patched by hand, not saved; test save:
  a HardHat on the rail, cash 478, Green worn; Device Simulator: Galaxy A16.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03g2b The paint, paper and floor picker, saved per home
The moment: in Arrange you tap a paper and the walls round you change with a soft brush sound;
tap a floor and it rolls out under your feet. Your friends see it the moment you pick.
1. Upload Home.fbx (`lune run scripts/upload_art Home`, README "Into Studio": fresh Home copy,
   `prepare`, check `worst`). If 18.8 MB is refused, move the swatches to their own FBX.
2. Save: a home's `looks` (paint, paper, floor, floor colour; ids from `Specs.Looks`, the first of
   each list by default) in `src/shared/Save.luau`, versioned with a migration; a Lune test.
3. Server: lay each home's five panels from `Specs.Panels` (CastShadow off), clone the chosen
   set's SurfaceAppearance from `Specs.Swatches`' part, Color the paint or floor colour; a remote
   to pick, validated (ids in Looks, your own home), rate-limited, saved.
4. Client: a paint tab on the Arrange screen (ArrangeView): paper and floor chips (each swatch in
   a ViewportFrame, tinted), paint and floor colour dots; a pick shows at once, with sound.
5. Studio: Play, pick, watch the walls change at phone size (A16); OWNER.md steps for a friend.
**Acceptance:** check green; a pick changes the home's walls or floor for everyone and survives a
rejoin; no text explains it; under 60 extra parts for twelve homes.
**Read first:** ROADMAP S5-03g2b; `art/home/README.md` (the panels, Into Studio);
`src/shared/Home/Specs.luau` (`Looks`, `Panels`, `Swatches`); `src/shared/Save.luau`;
`src/server/Arranging.luau`; `src/client/ArrangeView.luau` (Grep its tabs).

## Queue (next sessions, the owner's ticket order)
1. Then g3 (doors and name
   cards: ROADMAP says how the plates replace the lobby's), g4 (furniture at the counter, the
   glows near only), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-325.
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
