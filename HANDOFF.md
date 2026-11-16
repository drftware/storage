# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 202 (wrap colours) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-04 is split (ROADMAP): S3-04a done (D-224), S3-04b the shop screen next, S3-04c patterns
  later. Six wrap colours (`WrapColours`: Blue, Red, Green, Pink, Orange, Black), each a product
  "<Colour> Wrap"; bought, owned for good (save version 4: `wraps`, `wornWrap`) and worn at once;
  `Purchasing.prompt` refuses an owned one (`notBuyable`). `Wearing` (server) mirrors the worn
  colour onto the Player (`WrapColour`); KeptPlayers tints the film's SurfaceAppearance `Color`
  from it at the catch; the cut-free shreds take the tint.
- Seen in Studio Play: a version 3 save migrated and saved at version 4; `DevReceipt {offer =
  "wrapBlue"}` granted, worn at once; DevPrompt wrapBlue refused ("already owns"); six stand-in
  films in the six tints read as coloured film at phone size. Not run: a real catch in a colour
  (no keeper awake for CatchTest). `OWNER.md` has the steps. Play stopped; nothing left in the place.
- No wrap product exists on the Dashboard yet. Studio holds doubled modules (STUDIO.md, OWNER.md).

## Next task: S3-04b The counter's shop screen
ROADMAP S3-04b. The moment: back in the lobby after a climb, you walk up to the front office's
counter and the shop slides up on wrap colours: each a figure turning in its film, its price,
Buy; you buy and the film snaps tight round the figure with a squeal and the card says Worn.
1. Look first: `src/shared/Lobby/init.luau` (grep -i `counter`) for where the counter stands;
   ROADMAP's L-08e notes on the lobby; Brix: `Purchases:viewShop(player, key)` answers every
   offer on sale with its price and records `shopViewed` (ENG-23b2; `../engine/src/Contracts/
   Purchases.luau`). Purchasing doesn't expose it yet: add `shelf(player)` there.
2. Server: a `WearWrap` remote in `Wearing` (checked: rate, a string, `WrapColours.wear`'s
   answer) putting on an owned colour or the plain film, then the attribute and `saving:save`.
   A `ShopShelf` RemoteFunction (rate-limited) answering each colour's price, owned, worn.
   Buying goes through `Purchasing.prompt`, never the client's own prompt.
3. Client: the shop screen (phone first, roblox-ui skill): one row of cards, a ViewportFrame
   figure in each colour's film (`Props.KeptWrap` tinted `WrapColours.tint`; ViewportFrames
   draw SurfaceAppearance, STUDIO.md), price on Buy; owned shows Wear or Worn. Opens at the
   counter (a ProximityPrompt "Shop"), from a Shop button in the lobby and from Roblox's own.
   Every press answers (motion, sound); a refused buy with nothing to fix is just ignored.
4. Gifts wait on `OWNER.md` (Brix's E-075 to E-078): no gift buttons.
**Acceptance:** checks green; in Studio Play the counter's prompt opens the shop at phone size
(one small capture); a made-up receipt flips a card to Worn; Wear switches colours and the
attribute follows; OWNER.md steps for the real shop on a phone.
**Read first:** ROADMAP S3-04 (grep `S3-04b`); D-224 and D-112 (grep `^## D-224`);
`src/shared/WrapColours.luau`; `src/server/Wearing.luau`; `src/server/Purchasing.luau` (grep
`function system.prompt`); `src/shared/Lobby/init.luau` (grep -i `counter`).

## Queue (next sessions, the owner's ten-ticket order)
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
5. B-05b2b polish: a guard's box hides round the bend. L-08e3c, L-14b2d wait; R-01 later.
6. Small: Free Everyone's swap sound (Cut Free's click pitched down for now); Free a Friend's
   pills don't follow the map off screen; coin count and corner map up while wrapped;
   "rbxassetid://203785492 failed"; `ConfigService: Config value not found` (the `sell*`
   switches, now ten); "Stand one" never shows from the MCP; two-player reveal/coins/notes; a
   dropped find bumps a walker (D-182); rbxassethash warnings; Packrat's dead Slots entry;
   Mannequin pose onto `Rig.luau` (D-176); the watch bar's empty panel; S1-07a, S2-02b-d4,
   S2-03b, S2-05a, S2-07a1-b2 leftovers; S1-10d1-3; box words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
