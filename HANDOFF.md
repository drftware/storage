# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 278 (S5-03g4c2, bought furniture out of the job box into
Arrange, D-337) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin`
drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). Bought furniture now comes out on screen (D-337):
  the job box deals it first (wood rims, the counter card's art, `FurnitureTab.picture`); Set out
  shuts the lid and opens Arrange holding it (`hold`, from ArrangeView, wired in init), risen out
  of the box onto the nearest free spot, green; it lands with a deeper knock. Arrange's tray lists
  floor pieces first; a set-out piece lifts by a tap, Put away sends it back. Seen in Studio Play
  on the A16: a pallet bought (counter remote), set out on the rug, there after a rejoin, put
  back; the camp bed arriving green (`docs/art/S5-03g4c2-*.jpg`). Nothing stands on a piece yet.
- Rojo connected. A16: STUDIO.md (click at gui x + 47; prompts need Studio drawing, caffeinate).
- Test save: cash 188; owns 2 MilkCrate, 1 Pallet, 1 CampBed, all in the box; set out Boombox,
  CampLantern, Capybara, MoonLamp (4/25); Unit1. Stage only your own paths (the find run's stay).

## Next task: S5-03g4c3 A find on a piece's top
The moment: the pallet set down on the rug as a coffee table, you lift your moon lamp out of the
tray and it glows green on the pallet's top, sets down there with a knock; slide the pallet and
the lamp rides with it; put the pallet away and the lamp goes back to the box with it. Bloxburg's
tabletop items, Animal Crossing's things on tables.
1. Read ROADMAP S5-03g4c3 and D-336/D-337. `Spots.shape` gives a find with a top a `top` area
   (Brix Placements' riders); a piece gets none yet (it skips `Spots.Rows`).
2. Give a floor piece with `Specs.Tops` its highest top as `shape.top` (width, depth from the
   top's Size). Check the top's height is the art box's height (`Spots.pieceBox`; the pallet
   1.2, the crate 1.65, the table 2.8, the shelf's top tier 5.9) and its middle the box's; if
   not, carry the offset where riders are drawn (server `Arranged`, screen `r.heights`). Lune
   spec first (tests/spots or arrange spec).
3. Server (`Arranging`): riders on a piece drawn at its top, follow it, go back with it (the
   finds' `standingOn` already does both; check the drawn height).
4. Screen (`ArrangeView`): `tops[id]` for a piece with a top, as `build` and `answered` do for
   finds; a find aimed over the pallet goes green on its top.
5. Studio Play on the A16: set the pallet out, stand the moon lamp on it, slide the pallet (the
   lamp rides), put it away (both back in the box); pictures. OWNER.md steps for two clients.
**Acceptance:** check green; a find set on the pallet's, crate's and table's top, saved, riding
and put away with it; nothing snaps; reads at A16 size.
**Read first:** ROADMAP S5-03g4c3; D-337; `src/shared/Home/Spots.luau` (`shape`, 150 to 200);
`src/shared/Home/Specs.luau` (`Tops`, 118 to 140); `src/client/ArrangeView.luau` (`build`,
`answered`, by ranges); `src/server/Arranging.luau` (`shapeOf`, `apply`, by ranges).

## Queue (next sessions, the owner's ticket order)
1. S5-03g4d (the lit pieces on walls and ceilings, their lights near only; the server refuses
   them "notYet", the panel lists them without Set out); then S5-03g3c a card's style, h; S5-03d4;
   S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. Sitting on a crate or the camp bed (Seats); the steel shelf's lower tiers. In Arrange the job
   box's "Open" button shows over the room (seen Nov 17). The looks' polish (g2b2, g2b3, g3b).
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-337.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
6. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, seven times now). Lobby sheets: no plates. Cash spent at
   the counter and sold from the job box aren't sent to analytics (Recording has coins only).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
