# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 275 (S5-03g4a, the furniture's stock and sale) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix
pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session (S5-03). The counter's furniture now sells on the server
  (D-333): `Home/Furniture.luau` (eight pieces, a weekly stock from the date alone, the buy's
  check), save version 12 (`furniture`, owned counts by id), and `Furnishing` (`BuyFurniture`,
  answered on `FurnitureBought` only after the save is written; a failed write undoes the buy).
  Seen in Studio Play, server and remote; no screen yet. `Saving.save` answers a failed write.
- Rojo is connected. A16 and Play captures: STUDIO.md (`sips --cropOffset 364 360 -c 306 664`).
- Test save: cash 298; owns a CampBed and a MilkCrate; Unit1 (frame at 60, 0, 478), card the
  stencil. Stock Nov 16 to 22: MilkCrate, Pallet, SteelShelf, CampBed, NeonSign. Stage only your
  own paths (the find run's stay). `art.sh home export` restamps Home.fbx: checkout if unchanged.

## Next task: S5-03g4b The furniture at the counter on screen
The moment: you walk up to the counter after a climb and flip to the furniture: this week's
pieces turn slowly in their cards, each with its price; you tap Buy on the camp bed, your coins
tick down with a thunk and the card says it's in your box. Fortnite's item shop and Animal
Crossing's Nook's Cranny (a stock that changes), Lethal Company's ship store.
1. Read ROADMAP S5-03g4b and D-333. Too big for one session? Split: g4b1 the tab and cards,
   g4b2 the buy's answer.
2. A second tab beside the wraps in ShopView (`Shop.Words` gets the tab's one word). The stock
   comes from `Furniture.stock(workspace:GetServerTimeNow())` on the screen (the same as the
   server's); what you own and your cash from the server: a small RemoteFunction, or add them to
   `ShopShelf`'s answer (`Shop.read` reads it safely).
3. Each card: the piece turning in a ViewportFrame (clone its `Specs.Pieces` parts from
   `Home.template()`, as the shelf's figures are cloned), its price, Buy. A piece you can't
   afford dims its price, no popup; one at its cap shows how many you own, no Buy.
4. Buy fires `BuyFurniture`; the card stays pressed until `FurnitureBought` answers. "": coins
   tick down with a thunk (a Roblox sound, measured in STUDIO.md) and the card says it's in
   your box; "busy", "save", "notStocked": the card settles back.
5. Studio: open the shop at the counter on the A16, flip to furniture, buy a milk crate; picture
   the tab, a card and the answer at phone size (`docs/art/S5-03g4b-*.jpg`).
**Acceptance:** check green; this week's five shown; never yours before `FurnitureBought` says "";
nothing snaps; reads at A16 size; OWNER.md has the steps.
**Read first:** ROADMAP S5-03g4b; D-333 and D-225; `src/shared/Home/Furniture.luau`;
`src/shared/Shop.luau`; `src/client/ShopView.luau` (the cards, figures and Buy; read by ranges).

## Queue (next sessions, the owner's ticket order)
1. S5-03g4c (in the job box, set out with Arrange), g4d (the lit pieces, their lights near only);
   then S5-03g3c choosing a card's style (the counter sells the Cash ones by then), h; S5-03d4
   across the trip (unblocked); S5-03a2d the cars' hidden triangles; F-G1b4a2 the headlamp's
   beam; F-G1b4b the hat spent.
2. The looks' polish (ROADMAP under g2b2, g2b3 and g3b): the sheet a shade darker than the panel
   at the hand-over; the mirror keeping the room's old look (re-copy on `LookWorn`); the floor's
   wipe half under the looks tray; a new card style swapping in plays rather than snaps.
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-333.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
6. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, six times now). Lobby sheets: no plates. Cash spent at the
   counter and sold from the job box aren't sent to analytics (Recording has coins only).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
