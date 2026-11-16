# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 203 (the counter's shop) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-04b done (D-225): in the front office, the counter's Shop prompt (made on each screen by
  `ShopView`) or the top bar's Shop button opens the shop: seven cards (plain film, then the six
  colours), each a copy of your character turning in that film. Buy → `BuyWrap` → the server's
  `Purchasing.prompt` (Studio: a made-up receipt through `DevReceipt`); Wear → `WearWrap`; the
  `WrapColour` attribute flips the cards and the bought or worn one snaps. `ShopShelf` answers at
  once; prices (Brix's `viewShop`, via Purchasing's new `shelf`) are fetched behind it.
- Seen in Studio Play (desktop size): cards painted within 0.6 s of opening; Wear on the plain
  film and a Studio buy of Red flipped the cards and the attribute. Not seen: phone size, a real
  price, the snap's sound, the counter's prompt pressed by hand (a scripted `InputHoldBegin`
  doesn't trigger it; the top bar's button was clicked). `OWNER.md` has the steps. The owner's
  Studio save now wears Red. Play stopped; nothing left in the place.
- S3-04c (patterns) waits for art; gifts wait on `OWNER.md`. No wrap product exists on the
  Dashboard yet. Studio holds doubled modules (STUDIO.md, OWNER.md).

## Next task: S4-01a The rules table and the top gone
ROADMAP S4-01a (S4-01 split Nov 15). The moment: the climb never tops out; floor 4 is there
when the car rises, a little harder, and the team keeps going for a best floor.
1. Look first: the GDD's "Floor rules" section only (docs tools: `read` with `{kind: "search",
   text: "Floor rules"}` on node `15cf0df0-0c6f`, then a `blocks` read of that section); D-106
   and D-128 (grep `^## D-106`, `^## D-128`); `src/shared/Climb.luau` and `src/shared/Deal.luau`
   (grep `Top`, `Building`, `topped`, fixed per-floor numbers).
2. A pure `src/shared/FloorRules.luau`: for any floor number (1 to 100 and past), what `Deal` and
   `Climb` now read from fixed numbers (units, awake monsters, notes, padlocks ...), with a Lune
   spec (each value in range, steady growth, nothing breaks at 100+).
3. Wire `Deal`/`Climb` to read it; remove the top (`Climb.Top`, `topped`). The escape ("Made it")
   keeps its code but loses its trigger: say so in a comment and in DECISIONS.
4. Studio: `DevFloorNumber` 3 then 4 and 5 (Workspace attribute, DevCorridor) lay and play; a
   ride from floor 3 reaches floor 4. Read Output for warnings.
**Acceptance:** checks green; the spec proves the table; in Studio Play floor 4 lays after 3;
OWNER.md steps for a long climb with a friend. S4-01b (rows actually changing floors) follows.
**Read first:** ROADMAP S4-01 (grep `S4-01a`); GDD "Floor rules"; D-106, D-128;
`src/shared/Climb.luau`; `src/shared/Deal.luau` (grep first); `src/server/Climbs.luau` (grep `Top`).

## Queue (next sessions, the owner's ten-ticket order)
1. **S4-01b What changes floor to floor** (after S4-01a).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
5. B-05b2b polish: a guard's box hides round the bend. L-08e3c, L-14b2d wait; R-01 later.
6. Small: the shop's polish (ROADMAP S3-04b); Free Everyone's swap sound (Cut Free's click
   pitched down for now); Free a Friend's pills don't follow the map off screen; coin count and
   corner map up while wrapped; "rbxassetid://203785492 failed"; `ConfigService: Config value
   not found` (the `sell*` switches, now ten); "Stand one" never shows from the MCP;
   two-player reveal/coins/notes; a dropped find bumps a walker (D-182); rbxassethash warnings;
   Packrat's dead Slots entry; Mannequin pose onto `Rig.luau` (D-176); the watch bar's empty
   panel; S1-07a, S2-02b-d4, S2-03b, S2-05a, S2-07a1-b2 leftovers; S1-10d1-3; box words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
