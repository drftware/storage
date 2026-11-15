# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 182 (S3-02a, D-206; S3-02 split for size) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-02a done (D-206): Brix pinned at `5cdb8c2`; the save is at version 2 (`purchases`, `recipients`,
  `bought`); `src/shared/Products.luau` is the product table (only the owner's "Test purchase" so far);
  `tests/products.spec.luau` proves Brix's Purchases over the game's save. Nothing on the server yet.
- The place is published (place 113250085204323, universe 10775008617, owner UserId 11785587236, a
  user). No developer products yet: `GetDeveloperProductsAsync` answers an empty page.

## Next task: S3-02b The server takes receipts
ROADMAP S3-02b. The moment: a player pays and gets it at once, exactly once. Nothing goes on sale.
1. Read Brix's `docs/modules/PlayerPurchases.md` and the "In a place" part of `LiveConfig.md` in
   `vendor/brix` (Purchases.md only if a rule is unclear; it's long). Don't re-read the GDD.
2. `Saving`: expose the Brix `Saves` it makes (`began` signal plus `saves()`: made in `begin`, which
   runs late in Studio after the DataStore probe). In its `logged` store, a write fails with a warning
   while Workspace's `DevSaveFails` attribute is true (only server code can set it: Studio, or the
   owner in the Developer Console's server command line).
3. `src/server/Live.luau` (slot `live`): `Brix.LiveConfig` with `Products.switches()` as defaults and
   `Brix.Schema.boolean()` per key, over `Brix.Roblox.ConfigSource.configService()`, kept current by
   `Brix.Roblox.ConfigRefresher`; `current()`.
4. `src/server/Purchasing.luau`, after `recording` in init.server's list (it needs Recording's
   Analytics: expose `analytics()` there, made in its start). Find ids: `MarketplaceService:
   GetDeveloperProductsAsync()` pages, each entry's `Name` against `Products.Rows[*].title`, its
   `ProductId` (not `DeveloperProductId`; check the field names once a product exists). In Studio,
   a row not found gets a made-up id (1, 2 ... by sorted name). Then `Brix.Purchases.new` (ledger
   `data.purchases`, recipients `data.recipients`, `Products.offers(ids)`, marketplace
   `Brix.Roblox.Marketplace.services()`, `switchedOn` from Live) and `Brix.Roblox.PlayerPurchases`
   with `keyFor = Save.key(player.UserId)`, `start()`. Expose `prompt(player, offer, recipient?)`
   (refuses `ownerOnly` rows for others) and a `granted` signal (Purchases' `onGranted`) for S3-03.
   Print each grant: `[Purchasing] granted <offer> to <name> (bought N)`.
5. Record `offerShown` (field `offer`) for each prompt put up: Recording listens to a `shown` signal.
6. Dev: Studio-only `ServerStorage.DevReceipt` BindableFunction handing a made-up receipt table to
   `playerPurchases:process` and answering the decision's name; Workspace `DevPrompt` (offer name)
   prompts the owner (anyone in Studio) and clears itself. Dev = Studio, or `game.CreatorType` is User
   and the player's UserId is `game.CreatorId`.
7. Prove in Studio Play (Server `execute_luau` invoking `DevReceipt`): granted once, the same id again
   ignored, `DevSaveFails` on refused and then granted once when off. Stop Play.
**Acceptance:** checks green; made-up receipts seen in Output as above; `OWNER.md`: make "Test
purchase" on the Dashboard at the lowest price, then the phone test, numbered and exact: a purchase
with `DevSaveFails` on, then a server hop, the price in the prompt, `sellTestPurchase` off in the
experience's configs (Brix's ENG-23e; tell Brix's HANDOFF when it passes).
**Read first:** ROADMAP S3-02b; `src/shared/Products.luau`; `src/server/Saving.luau`; Recording's
`start` (lines 100-145); `vendor/brix/docs/modules/PlayerPurchases.md`; LiveConfig.md "In a place".

## Queue (next sessions per ROADMAP Phase 2)
0. **The box you open, B-01 to B-05** (ROADMAP, D-205), then S3-03 Cut Free (it owns Studio's
   "CutFree" let-in; it adds its rows to `Products`) and S3-04 the counter's shop.
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. L-08e3c, L-14b2d wait on `OWNER.md`; R-01 later. A GDD section costs ~15k context: `view`
   with `outline: true` and `from` the heading's id, then `search` with `blocks` on just the part needed.
4. Small, from earlier (ROADMAP and `git log` hold the detail): a dropped find bumps a walking
   player (D-182); a take could show the arm first (KeeperView Kit); rbxassethash warnings in Play;
   the Packrat's dead Slots entry and S2-06b1's way home; move the Mannequin's pose onto `Rig.luau`
   (D-176); the watch bar's empty panel; S3-01b's wipe after the bring unseen; S1-07a, S2-02b to d4,
   S2-03b, S2-05a, S2-07a1 to b2 leftovers; unseen S1-10d1 to d3, S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
