# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 272 (S5-03g3a2, your front: a third tab on Arrange) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). Arrange has three tabs: finds, the room's looks, and
  your front (D-330): the camera swings round to face your door, one row of eight door dots, the
  roll down the slats the answer. Seen in Play on the A16 with the door open (the coil rolls); the
  shut door from the front tab and whether a door should shut as you leave wait on `OWNER.md`.
- Rojo is connected. The A16 is set from the shell (STUDIO.md, "Picking the A16 from the shell");
  if taps time out, `caffeinate -u -t 3`; bring Studio to the front before a window capture.
- Test save: cash 478, HardHat on the rail, Green worn; Unit1 (frame at 60, 0, 478) in Sage,
  Daisies, a Rose carpet, its door Mint, open when you arrive. Arrange reopens on its last tab.
- Stage only your own paths (the find run's `art/finds/`, `src/shared/Finds/` and hunks stay).

## Next task: S5-03g3b The name card plates
The moment: you walk out of your home and across the floor, and over your door is your name on
the card you picked (a stencilled steel plate to start), lit and lettered like a shop front, not
the lobby's plain plate. Animal Crossing's house sign; Bloxburg's plot name.
1. Read ROADMAP S5-03g3b and D-322; see what the lobby's plain plate is (`signs()` in
   `art/lobby/build.py`) and how HomeCards writes and sprays the name on it now.
2. Split g3b in ROADMAP if it won't fit (likely g3b1 the style saved, the Starter plate up with
   the name; g3b2 the neon's tube, glow stroke and `CardLight`).
3. Save the card's style with the looks (`looks.card`, save version 11, an older save's is the
   Starter style), its id on the unit like the door's (a `Looks` attribute apart from `encode`),
   picked through `PickLook` kind "card" (only Starter styles until g3c's store rules).
4. Every screen dresses each held home's card from `Specs.Cards`: the style's parts over the door
   in place of the plain plate, the name on `Face` in its `Font` and `Ink`; the spray
   (`Holding.Card`) still lands the name; a home let go goes back to the plain plate.
5. Play on the A16: walk out and judge it from across the floor and from the next door; capture
   to `docs/art/`.
**Acceptance:** check green; a held home's card is its style's plate with the name readable from
across the floor at A16 size; the spray still lands a new name; a save from version 10 loads
with the Starter style; no text that explains a rule.
**Read first:** ROADMAP S5-03g3b; D-322; `src/client/HomeCards.luau`; `art/lobby/build.py`
`signs()` (line 489); `src/shared/Home/Specs.luau` `Cards` (line 258); `art/home/cards.py` top.

## Queue (next sessions, the owner's ticket order)
1. S5-03g3c choosing a card's style (the front tab's second row; the store's rules: not-owned
   marked, never a popup), g4 (furniture at the counter, the glows near only; neon's light budget
   on the A16), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars'
   hidden triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. The looks' polish (ROADMAP under g2b2 and g2b3): the sheet a shade darker than the panel at the
   hand-over; the mirror keeping the room's old look (re-copy on `LookWorn`); the floor's wipe
   half under the looks tray.
3. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
4. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
5. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
6. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-329.
7. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
8. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures, the Packrat wanting a Gold; a crack on a cracked card (ROADMAP polish).
9. Share one `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`).
10. The HUD coin count read 0 in Play again (Nov 17, four times) with the save's cash at 478.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
