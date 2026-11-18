# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 282 (S5-03h2, Medium for cash, D-341) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` drftware/storage); Brix pinned at `7f25310`,
NOT on Brix's `origin` yet.

## State
- The home (D-259; Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools only)
  is built a ROADMAP piece a session. S5-03h is h1 to h6: h1 (sizes in the save) and h2 done.
- h2 done (D-341): `Home/Grow` (pure, `tests/grow.spec.luau`): Medium 2,500 cash; refusals
  unknown, had, robux, cash; `buy`/`unbuy` in one step. `Growing` (server): `GrowHome` validated
  and rate-limited, the save written first, then `Arranging:relay` lays the home at its new size,
  then `HomeGrown` answers. The counter's shop has a third tab, Units (`UnitsTab`): a card per
  size from yours up, a plan from above that opens out, the furniture's purse shared.
- Seen on the A16 in Studio Play: a failed save undone, a sale, its answer. Large, XL: "robux".
- Rojo connected. A16, capture, opening the shop from a script: STUDIO.md. Studio hooks:
  `GrowTest` (a size; "cash", n), `ArrangeTest` "size", `FurnitureTest`.
- Test save: Small, nothing set out, cash 188; the string lights, the neon moon, 2 MilkCrate,
  1 Pallet, 1 CampBed in the box; Unit1. Stage only your own paths.

## Next task: S5-03h3a Large and XL for Robux, your own home
The moment: you want the big unit now, and Large or XL is a Robux buy at the same counter, as
Adopt Me sells its bigger houses. Split h3 in ROADMAP first: h3a your own (this), h3b the gift
versions (a friend grows your home; the recipient picked on the server).
1. Read ROADMAP S5-03h3, D-341, and S3-02's decision (grep DECISIONS for "S3-02"). Read how
   `Purchasing.luau` grants a developer product only after the save, never lost on a failed
   save or a hop (the purchase ledger, Brix Purchases), and how `Products.luau` lists offers,
   switches them off and reads prices from Roblox.
2. Spec first (failing): Robux rows in `Grow` (Large, XL; a product id per size, an off switch
   each in Config); "never smaller than you have" for a receipt as for a prompt; `ladder` adds
   them. Decide what a late receipt for a size you already have does (my default: the server
   never prompts then; a late one is recorded granted and logged; OWNER.md line).
3. The server: the prompt only after the server's check; the grant writes `homeSize` in the
   save before the receipt is marked granted; then `Arranging:relay`, then `HomeGrown` "".
4. `UnitsTab`: Large and XL cards with Roblox's own price (the Robux mark, as ShopView's wraps
   show it), Buy putting Roblox's prompt up from the server; the same answer as Medium's.
**Acceptance:** check green; the spec fails first then passes; in Studio Play a test purchase of
Large grows the home (its `HomeSize`, the card says Yours); a failed save never grants it.
**Read first:** ROADMAP S5-03h3; D-341; DECISIONS' S3-02 entry; `src/server/Purchasing.luau`;
`src/shared/Products.luau`; `src/shared/Home/Grow.luau`.

## Queue (next sessions, the owner's ticket order)
1. S5-03h3b (gifts), h4 to h6 (ROADMAP). S5-03g3c a card's style, h; S5-03d4; S5-03a2d the cars'
   hidden triangles; F-G1b4a2 the headlamp's beam; F-G1b4b the hat spent.
2. Sitting on a crate, the cushion or the camp bed (Seats); the steel shelf's lower tiers. In
   Arrange the job box's "Open" shows over the room; the starter shelf hides a piece behind it
   from Arrange's corner camera and from the doorway. A lifted lit piece's light stays where it
   was until it's set down. The looks' polish (g2b2, g2b3, g3b). A size change while Arrange is
   open doesn't rebuild the screen's judge (h6 should). The Units cards' plans are small (the XL
   box frames them); a closer frame if the owner finds them hard to read.
3. The home's warm fill (D-290): faces turned from the bulb go near black. F-G1b5 waits for its
   art. Brix (in `../engine`): ENG-25b's two-client run; Driving's stick read (D-254); a
   PlayerSaves hook before a leaving save's last write. S4-02 to S4-05.
4. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-341.
5. Once the owner's real purchase passes, mark Brix's ENG-23e done. Late arrivals off
   `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error; the front office's
   steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the hat's first-Wear dark
   screen; the body after a respawn (D-282); a Gold's own textures.
6. One `CaughtSeized` string; S5-03d4's climb server restamps its lights (`Use.leave`). The HUD
   coin count reads 0 in Play (Nov 17, ten times now). Lobby sheets: no plates. Cash spent at
   the counter (furniture, Medium) and sold from the job box isn't sent to analytics.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
