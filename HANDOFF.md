# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-18, S5-03g3d1 (D-360) · **Checks:** green · **Git:** `main`, not pushed; Brix `7f25310`.

## State
- **The home (S5-03) is built** apart from S5-03g3d2 (the card styles' cards at the counter) and
  its polish lines. Every other S5-03 parent is ticked in ROADMAP.
- S5-03g3d1 is done (D-360), seen in Studio Play at A16 size from the server and the real
  remotes: save v15 `cards`, `Home.CardSale` (board 120, chalk 200, the neon as "Neon Name
  Card"), `CardSales` on the server, the paint tab's marks reading `CardStyles` on your Player.
  Only a script buys a style so far (`CardTest`, STUDIO.md). Prices and the product: OWNER.md.
- Arrange's own button still won't open from the MCP's clicks; build the real LooksTab in a test
  screen instead (STUDIO.md). S5-03g3c's dip and swing and h6's other grows: OWNER.md.
- Studio hooks: `CardTest`; `ShelfTest` "take"; `ArrangeTest` "take", "own", "place", "rows",
  "fromShelf", "shelfAway", "size"; `GrowTest` "cash"; Trips' `DevTripFinds`. Home doc:
  https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww. Test save: Medium, card Stencil (Unit1),
  cash 38, no card styles owned, Boombox 10, Skates 1.
- **Climb run:** done: the fix pass (D-400), S4-02, S4-04, S4-03 the next-floor cards (D-403
  to D-413), S4-05a the jukebox's art (D-414), S4-05b1 its deal and door (D-415: imported, the
  code rolls up a unit with it inside), S4-05b2a its haul (D-416: held low, walk 9, a thud a
  step). Next: S4-05b2b its mark on the corner map (MinimapView's bang ring; follows the find).

## Next task: S5-03g3d2 The styles' cards at the counter
The last open piece of S5-03 before its polish.
The moment: you see a friend's neon card glowing over their door, walk to the counter, flip to
Furniture, and past this week's pieces there's your own name on a neon plate; you buy it, and
the next time you open Arrange its chip is yours.
1. On FurnitureTab, after this week's pieces, a card per `CardSale.Sold` style: its plate with
   your name (LooksTab's `plate` draws one; or the plate's art in a viewport, as the pieces are),
   the cash price, or the neon's Roblox price with the Robux mark (`CardShelf`'s `robux`).
2. Owned states from `CardShelf` each time the tab shows; Owned on a style you have.
3. Buy fires `BuyCard` and holds pressed until `CardBought` answers: "" spends the shared purse
   (`Wallet`) with the coins' falling tick and a plate's clack, then Owned; "cash" nudges the
   purse; "closed", "off" and "had" settle; no answer in 8 s settles and asks again.
4. Seen in Studio Play at A16 size: open the shop from a script (STUDIO.md), give cash with
   `GrowTest`, buy the board through the screen, then the neon (Studio's made-up receipt).
**Acceptance:** a cash style bought on the screen saves, survives a rejoin and picks; the neon's
press runs the prompt path; a new decision (D-361, below D-400); check green.
**Read first:** ROADMAP S5-03g3d2; D-360; D-334; `src/shared/Home/CardSale.luau`;
`src/client/FurnitureTab.luau`; `src/client/LooksTab.luau` (`plate`).

## Queue (next sessions, the owner's ticket order)
0. After S5-03g3d2, the home's polish, one ticket a session: ROADMAP's three "Polish:" lines
   under S5-03g2b (the hand-over's shade, the mirror keeping the old look, the floor's wipe
   under the tray), then g3b's plate swapping in instead of snapping.
1. Small's doorway's inside boards are oak, not the
   picked paint (D-355, my call). Sitting's leftovers (D-353): cross-legged on the blanket needs
   an animation of our own; lying on the bed.
2. Home leftovers: a lamp left on kept through a rejoin (D-351); a lit find taken comes unlit
   (on a trip too: the trip carries no lit state); the cubby finds' own buttons; a friend's take
   shows before the flying copy lands; the steel shelf's lower tiers; Arrange shows the job box's
   "Open" and the door's buttons; a lifted lit piece's light; a grow while Arrange is open closes
   it (D-356); Robux unit and gift cards unseen; the XL limit bar; Take through a wall; a refused
   cubby place (D-352). A taken-out find comes out whole even when the save has it cracked.
3. The home's warm fill (D-290): faces turned from the bulb go near black. Brix (in
   `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a PlayerSaves hook
   before a leaving save's last write.
4. The item catalog and design docs' finds need D-250, D-251, D-259, D-277, D-297, D-299 to 358.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. A spare home unpadlocked
   (D-275); the hat's first-Wear dark screen; the body after a respawn (D-282); late arrivals
   off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error. Counter and job
   box cash isn't sent to analytics. One `CaughtSeized` string. Lobby sheets: no plates.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
