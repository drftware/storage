# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 274 (S5-03g3b2, the neon lit; g4 split) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). Name cards hang on the plate each home chose
  (D-331); the neon's name now glows in a pink halo and the two neon cards nearest you wash their
  wall pink with a light made on your screen only (D-332, HomeCards). Seen in Play on the A16
  (pictures `docs/art/S5-03g3b2-neon-*.jpg`). S5-03g4 is split into a to d in ROADMAP.
- The counter already sells the wrap colours for Robux (`Shop.luau`, `ShopView.luau`, D-225).
- Rojo is connected. Set the A16 from the shell and capture Play with macOS (STUDIO.md), the
  phone cropped `sips --cropOffset 364 360 -c 306 664`; aim with the camera's CFrame.
- Test save: cash 478; Unit1 (frame at 60, 0, 478), its card the stencil. Stage only your own
  paths (the find run's `art/finds/`, `src/shared/Finds/` and hunks stay).
- `art.sh home export` restamps Home.fbx: if only Specs changed, `git checkout` the FBX.

## Next task: S5-03g4a The stock and the sale, server and save
The moment: back from a climb with cash, this week's pieces are at the counter and you buy the
camp bed; it's yours, saved, waiting in your job box. Animal Crossing's Nook's Cranny and
Fortnite's item shop (a stock that changes), Lethal Company's ship store (bought with the run's pay).
1. Read ROADMAP S5-03g4 and D-323, D-324 (the eight pieces; their parts in `Specs.Parts`).
2. A pure `src/shared/Home/Furniture.luau`: a row per piece (id, parts, price, Stands floor,
   wall or ceiling, Cap owned); `stock(time)`, this week's pieces from the date alone (weeks
   start Monday UTC; the same in every server; each piece back at least every other week);
   `check(data, id, time)`, why a buy can't happen or nil. Prices are defaults scaled from a
   floor's pay (Pay.forFloor), each with a comment; the list goes in OWNER.md.
3. Save version 12: `furniture` (owned counts by id), its migration and a save.spec sample.
4. Server (beside JobBoxes' sale, which shows the cash change and the save write): a
   `BuyFurniture` remote, checked (a short string id, then the stock, cap and cash) and
   rate-limited; takes the cash, adds the piece, writes the save, and only after the write
   answers the buyer (`FurnitureBought`: the id, the new cash, how many you own).
5. Lune specs: the stock's rotation and determinism, the check's refusals, the migration.
6. Studio: from a Server execute_luau, buy one for the test save; see the save's `furniture`
   and the cash change in Output. No screen yet (g4b).
**Acceptance:** check green; a buy never gives the piece before the save is written; the same
week gives the same stock in two runs; nothing random is sold; OWNER.md lists the prices.
**Read first:** ROADMAP S5-03g4; D-323 and D-324; `src/shared/Save.luau` (versions, `boxed`);
`src/server/JobBoxes.luau` (the sale and its save write); `src/shared/Shop.luau` (the counter's
remote names, `AskEvery`); `src/shared/Pay.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03g4b (the counter's furniture tab), g4c (in the job box, set out with Arrange), g4d (the
   lit pieces, their lights near only); then S5-03g3c choosing a card's style (the counter sells
   the Cash ones by then), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. The looks' polish (ROADMAP under g2b2, g2b3 and g3b): the sheet a shade darker than the panel
   at the hand-over; the mirror keeping the room's old look (re-copy on `LookWorn`); the floor's
   wipe half under the looks tray; a new card style swapping in plays rather than snaps.
3. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
4. F-G1b5 waits for its art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick
   read (D-254); a PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-332.
6. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
7. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, six times now, cash 478). Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
