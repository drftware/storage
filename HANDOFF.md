# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 268 (S5-03g2b1, a home's look saved, worn and wiped in) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). Its looks are in the code (D-326): the save's
  `looks` (v9), `Home.Looks`, `Decorating`, `LooksView`. Passes checks; nothing of it has run yet.
- Home.fbx is uploaded (asset 110439035194989, 18.8 MB taken) but NOT inserted in Studio:
  Studio's `ReplicatedStorage.Props.Home` is still the old one, without panels or swatches.
- Studio (Rojo unconnected) holds the code of 4e0fa92, patched by hand, not saved; since then only
  Home/Specs (+415 lines), Save, the inits and the three new modules changed. Test save: a
  HardHat on the rail, cash 478, Green worn; Device Simulator: Galaxy A16.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03g2b2 The wipe seen in Play
The moment: you pick a paper and it rolls out from the middle of the back wall, round both back
corners to the door, with a roller's wet squish; a floor unrolls from the back wall to your feet.
1. Get the code into Studio: Rojo if the owner connects it, else by hand (STUDIO.md "Patching
   Studio by hand, cheaply"): Specs whole without comments (~15 KB), Save's hunks, the new
   `Home/Looks`, `server/Decorating`, `client/LooksView`, and both init scripts' lines.
2. Insert the uploaded Home (README "Into Studio": a fresh copy of Shared, `prepare`, `worst`
   under 0.01), replacing `ReplicatedStorage.Props.Home`; check the eight Swatch parts carry
   their SurfaceAppearances and the five Panel parts are there.
3. Play; `ServerStorage.LookTest:Invoke(player, "paper", "Stripes")` (then "Leaves", a paint, a
   floor "Checker", a floorColour "Cherry"). Watch from inside the home on the A16: the panels
   cover the walls and floor (else fix `Decorating.panel`'s CFrame); the sheets' stripes meet the
   panels' with no jump when they go (else flip `LooksView.SHIFT` to -1); the roller loads
   (`PreloadAsync`; else a Pro Sound Effects scrub); the door's hole stays open.
4. Stop, Play again: the look is still up (save v9). STUDIO.md: the Texture's offset direction;
   OWNER.md: steps for a friend watching.
**Acceptance:** check green; a pick wipes round the room and the panels take it with no jump,
seen at phone size; it survives a rejoin; nothing snaps; no text.
**Read first:** ROADMAP S5-03g2b; `src/client/LooksView.luau`; `src/server/Decorating.luau`;
`Home/Looks.luau` (its top); `art/home/README.md` "Into Studio"; STUDIO.md "Patching Studio by hand".

## Queue (next sessions, the owner's ticket order)
1. S5-03g2b3 the paint tab on the Arrange screen (ROADMAP); then g3 (doors and name cards:
   ROADMAP says how the plates replace the lobby's), g4 (furniture at the counter, the glows near
   only), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden triangles; F-G1b4a2
   the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-326.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures, the Packrat wanting a Gold; a crack on a cracked card (ROADMAP polish).
8. `CaughtSeized`: CaughtLunge, ArrangeView, FlashlightView each use their own string; share one.
9. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.
10. The catch's film comes from `Film.make`: watch a catch in Play once Rojo is connected.
11. The HUD coin count read 0 in Play again (S5-03f4b3) with the save's cash at 478: find why.
12. Neon cards (g3), the furniture's glows (g4): the light budget on the A16. A first wipe may
    show plain colour till its map loads: preload the sets' maps if it pops on the A16.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
