# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 270 (S5-03g2b3, the paint tab on the Arrange screen) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). Paint, paper and floor are done (S5-03g2): picked
  on the Arrange screen's paint tab (`LooksTab`, D-328), saved, wiped round the room, seen in
  Play on the A16 simulator. Pictures `docs/art/S5-03g2b3-*.jpg`.
- Rojo is connected: Studio's scripts are the working tree's. The A16 is set from the shell now
  (STUDIO.md, "Picking the A16 from the shell"); if taps time out, the display slept:
  `caffeinate -u -t 3`.
- Test save: cash 478, HardHat on the rail, Green worn; Unit1 (frame at 60, 0, 478) in Sage,
  Daisies and a Rose carpet.
- Stage only your own paths (the find run's `art/finds/`, `src/shared/Finds/` and hunks stay).

## Next task: S5-03g3a The door's colour
The moment: in the paint tab you tap Mustard and your roll-up door turns from clay to mustard as
you watch, slat by slat; friends see your door from the lobby and know it's yours. Animal
Crossing's house exterior; Bloxburg's paint on any surface.
1. Read how a home's door is drawn (`Home` init's top, `HomeDoor`, the clay `Door` colour) and
   where the save's `looks` gets its version (grep `looks` in `src/shared`, `tests/save.spec`).
2. Add `door` to `Looks.Chosen` (ids from `Specs.Looks.Doors`, the start's Clay): `tidy`,
   `pick` (a fifth kind, "door"), `encode`/`decode`, a save migration; failing tests first in
   `tests/homepick.spec` and `tests/save.spec`.
3. Server (`Decorating`): a door pick paints that home's door slats at once on the server (the
   door is the lobby's, seen by all); the stamp and wipe stay for walls and floor only.
4. Screens: the slats take the new colour top to bottom over about half a second (a tween per
   slat, staggered), with the roller's squish; seen from inside and from the lobby.
5. LooksTab: a third row would push the tray past 120 points; put the door dots in a row only
   if they fit at 685 wide, else judge a third row at phone size.
6. Play on the A16: tap a door colour from inside, then walk out and see it. Capture to
   `docs/art/`.
**Acceptance:** check green; the door takes every colour and keeps it over a rejoin; it rolls,
doesn't snap; the tab still fits the A16 (capture at 668 wide); no text.
**Read first:** ROADMAP S5-03g3; `src/shared/Home/Looks.luau`; `src/server/Decorating.luau`;
`src/client/LooksTab.luau`; `src/shared/Home/init.luau` (top 60 lines); D-321, D-328.

## Queue (next sessions, the owner's ticket order)
1. S5-03g3b name card plates, g3c choosing a card's style (the store's rules: not-owned marked,
   never a popup), g4 (furniture at the counter, the glows near only; neon's light budget on the
   A16), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden triangles; F-G1b4a2
   the headlamp's beam; F-G1b4b the hat spent.
2. The looks' polish (ROADMAP under g2b2 and g2b3): the sheet a shade darker than the panel at the
   hand-over; the mirror keeping the room's old look (re-copy on `LookWorn`); the floor's wipe
   half under the looks tray.
3. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
4. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
5. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
6. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-328.
7. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
8. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures, the Packrat wanting a Gold; a crack on a cracked card (ROADMAP polish).
9. Share one `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`).
10. The HUD coin count read 0 in Play again (Nov 17, three times) with the save's cash at 478.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
