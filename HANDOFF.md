# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 273 (S5-03g3b1, the card's style saved and its plate hung) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). Your name card is on the plate you chose (D-331):
  `looks.card` (save version 11), the server hangs it (`src/shared/Home/CardPlate.luau`) from
  the unit's `Looks.CardAttribute`; a spare home wears the blank stencilled steel. The lobby's
  plain plates are gone (Lobby.fbx re-uploaded in place and swapped into `Props.Lobby` in Edit:
  the place isn't saved). Seen in Play on the A16 (pictures `docs/art/S5-03g3b1-*.jpg`).
- Rojo is connected. The A16 is set from the shell (STUDIO.md, "Picking the A16 from the shell");
  if taps time out, `caffeinate -u -t 3`; `screen_capture` times out in Play: use the macOS
  window capture (STUDIO.md) and crop the phone with `sips --cropOffset 364 360 -c 306 664`.
- Test save: cash 478, HardHat on the rail, Green worn; Unit1 (frame at 60, 0, 478) in Sage,
  Daisies, a Rose carpet, its door Mint, its card the stencil. To see other styles, set
  `LookCard` on a held unit from a Server execute_luau (FrontOffice re-hangs; deferred signal).
- Stage only your own paths (the find run's `art/finds/`, `src/shared/Finds/` and hunks stay).

## Next task: S5-03g3b2 The neon lit
The moment: down the calm ground floor one name glows pink over its door, the first thing you
see from across the floor, the one you'd buy. Bloxburg's and Adopt Me's neon house signs.
1. Read ROADMAP S5-03g3b2, D-322 (the neon), D-331 and D-271 (the floor lamps' near-only light).
2. In `CardPlate.hang` for a style with `Glow`: the label's LightInfluence 0 and a UIStroke in
   `Glow` (thickness from a Config number with a comment), the tube already Neon; any other style
   puts the label back to `Lobby.InkLight` with no stroke.
3. The light: a PointLight in `Glow` on the wall in front of the plate (`Specs.CardLight`), made
   by the client only near you as `Home.FloorLamp.Near` does (find how the floor lamps do it), so
   twelve neon cards never throw twelve lights on the A16; it fades in and out, never snaps.
4. HomeCards' spray: the neon's settle lands on LightInfluence 0 (it reads the gui's own now).
5. Play on the A16: hang Neon on Unit1 from the server; judge it from the far wall, mid-floor
   and close up with the hall's lights on; capture to `docs/art/`.
**Acceptance:** check green; the neon name glows and reads from mid-floor at A16 size; at most
the near cards' lights exist on a client; the other styles unchanged; no text explains a rule.
**Read first:** ROADMAP S5-03g3b2; D-331; `src/shared/Home/CardPlate.luau`;
`src/client/HomeCards.luau`; `Home.FloorLamp` in `src/shared/Home/init.luau` and its client
user (grep `FloorLamp.Near`); `Specs.CardLight` in `src/shared/Home/Specs.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03g3c choosing a card's style (the front tab's second row; the store's rules: not-owned
   marked, never a popup), g4 (furniture at the counter, the glows near only; neon's light budget
   on the A16), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars'
   hidden triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. The looks' polish (ROADMAP under g2b2, g2b3 and g3b): the sheet a shade darker than the panel
   at the hand-over; the mirror keeping the room's old look (re-copy on `LookWorn`); the floor's
   wipe half under the looks tray; a new card style swapping in plays rather than snaps.
3. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
4. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
5. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
6. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-331.
7. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
8. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures, the Packrat wanting a Gold; a crack on a cracked card (ROADMAP polish).
9. Share one `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`).
10. The HUD coin count read 0 in Play (Nov 17, five times, cash 478). Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
