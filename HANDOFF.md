# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 269 (S5-03g2b2, a home's new look seen in Play) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). Its looks run (D-326, D-327): picked through
  `ServerStorage.LookTest` in Play, a paper rolls round the room and a floor under the rug, the
  panels take it with no jump, the save keeps it. No screen picks yet: that's this ticket.
- Rojo IS connected now (the owner connected it, Nov 17 afternoon): Studio's scripts are HEAD's,
  so no hand patching. Studio's `ReplicatedStorage.Props.Home` is the uploaded Home.fbx (panels,
  swatches, cards, furniture), inserted by me, the place not saved by me.
- Test save: cash 478, a HardHat on the rail, Green worn, the home in Butter, Leaves and a Sage
  checker. Studio's Device menu says "Current device" (it reset; only the owner can pick the A16:
  the shell can't click Studio's menus). Judge downscaled window captures meanwhile.
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03g2b3 The paint tab on the Arrange screen
The moment: you open Arrange, tap the paint tab and your home's papers and floors sit there as
little swatches; tap Leaves and it rolls round the room as the chip presses in. Animal Crossing's
wallpaper and flooring; Bloxburg's paint dots.
1. Read how ArrangeView builds its bar and tray (1744 lines: grep `bar`, `tray`, `press`, `tick`;
   read only those ranges). Put the tab's own code in a new client module (say `LooksTab`) that
   ArrangeView hosts, rather than growing ArrangeView.
2. A tab beside the finds: four rows, each scrolling sideways if it must. Papers and floors as
   chips: each set's swatch (`Specs.Swatches`, from `Home.template()`) in a ViewportFrame, a paper
   tinted the home's paint, a floor its colour; paints and the chosen floor's colours as dots.
   What the home wears is ringed (read the unit's `Look` attribute; `Looks.decode`).
3. A tap fires `PickLook(kind, id)` (`Spots.RemoteFolder`/`Looks.Remote`), the chip presses in
   with ArrangeView's soft click (`press`, `tick`); the wipe is the answer, the ring moves when
   `Look` changes. No words but the tab's icon; chips at least 44 px on the phone.
4. Play: open Arrange in your home, tap through a paper, a floor, a paint, a floor colour; watch
   each wipe. Capture the tab and a wipe into `docs/art/`.
**Acceptance:** check green; every chip picks and rings, the wipe answers each tap, nothing snaps,
no text; the tray fits a phone (judge a capture at 693 wide; the A16 when the owner sets it).
**Read first:** ROADMAP S5-03g2b3; `src/client/ArrangeView.luau` (its bar and tray only);
`src/shared/Home/Looks.luau` (top); `src/client/LooksView.luau` (preload, `mapsOf`); D-326, D-327.

## Queue (next sessions, the owner's ticket order)
1. S5-03g3 door colours and name cards (ROADMAP says how the plates replace the lobby's), g4
   (furniture at the counter, the glows near only; neon's light budget on the A16), h; S5-03d4 across the trip (unblocked);
   S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. The looks' polish (ROADMAP under g2b2): the sheet a shade darker than the panel at the
   hand-over; the mirror keeping the room's old look (re-copy on `LookWorn`).
3. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
4. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
5. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
6. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-327.
7. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
8. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures, the Packrat wanting a Gold; a crack on a cracked card (ROADMAP polish).
9. `CaughtSeized`: CaughtLunge, ArrangeView, FlashlightView each use their own string; share one.
10. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.
11. The HUD coin count read 0 in Play again (Nov 17, twice) with the save's cash at 478: find why.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
