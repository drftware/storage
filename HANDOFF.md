# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 201 (Free Everyone) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-03 is done: S3-03c (D-223) adds Free Everyone. Once everyone's caught and the offer is on
  sale, the results wait (`ClimbWaits` on Workspace, `ClimbEnd.OfferFor` 12 s from the catch,
  longer while a purchase box is open); every caught pill (caught screen, watch bar) grows into
  "Free Everyone"; a press (`Remotes.FreeEveryone`) spends a spare or prompts; the grant frees
  every caught player (cut by the buyer) or is kept. Alone the pill stays Cut Free and the end
  waits on it. Nobody is freed once the end's black has begun (Cut Free and Free a Friend too).
- Seen in Studio Play: the remote on; a made-up receipt with nobody caught kept ("waits in their
  save for their next wipe"); a stand-in catch (`Kept` set by hand) held the results 12.1 s,
  then the end. Not run: a real catch (CatchTest says `NoKeeper` while floor 3's monsters sleep,
  STUDIO.md), the pill's swap on screen, one press freeing everyone. All in `OWNER.md`. Play
  stopped; nothing put into the place by hand.
- No "Cut Free", "Free a Friend" or "Free Everyone" product exists yet (OWNER.md).

## Next task: S3-04 The counter's shop, and wrap colours
ROADMAP S3-04. The moment: back in the lobby after a climb, you walk up to the front office's
counter and the shop opens on its first shelf, wrap colours: the film that wraps you when you're
caught, in colours your friends see. A Shop button in the lobby and Roblox's own open it too.
Gifts wait on `OWNER.md` (Brix's E-075 to E-078): build the shelf without them.
1. GDD "Monetization": docs `read` on `UtmFtWGEMRQkNmWmCEhFWN`, then `{kind:"search", text:
   "wrap colour"}` with `ref {object:"node", id:"15cf0df0-0c6f"}` and the project container,
   then `{kind:"view", parentId:"<hit's row or list id>"}` for just those blocks. Prices are in
   table `m8vzrrctamm.107863` (the row view the same way). Gaps: a default and an OWNER.md line.
2. Too big for one session (a shop screen, a counter, owned colours in the save, the wrap drawn
   in colour): split in ROADMAP first, e.g. S3-04a colours owned and worn (save, product rows,
   the film's colour on every screen), S3-04b the counter's shop screen. Do S3-04a properly.
3. Check Brix (`../engine`, `docs/FRAMEWORK.md`) for a shop or catalog export before building one.
4. Products: one row per colour or a pass that unlocks; nothing random, ever (policy). Owned
   things are permanent purchases: a ledger entry, never a spare.
5. The wrap: grep `Wraps.luau` (server) for how the film is made, so a colour reaches it.
**Acceptance:** checks green; a colour bought with a made-up receipt (Studio's `DevReceipt`,
`offer` = the row) is owned in the save and worn on the next catch (stand-in catch: the server's
`player:SetAttribute("Kept", true)` won't draw the film; see STUDIO.md "Catching yourself");
OWNER.md steps for the real purchase.
**Read first:** ROADMAP S3-04 (line ~2055); DECISIONS D-112 (grep `^## D-112`) and D-206;
GDD "Monetization" (search only); `src/shared/Products.luau`; `src/server/Wraps.luau` (grep
`Color`); `src/shared/Lobby/init.luau` (grep -i `counter`).

## Queue (next sessions, the owner's ten-ticket order)
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. A Studio hook to catch yourself for real (CatchTest finds no keeper while all sleep; a
   Workspace attribute that wakes the nearest sleeper or catches by the nearest one).
5. B-05b2b polish: a guard's box hides round the bend. L-08e3c, L-14b2d wait; R-01 later.
6. Small: Free Everyone's swap sound (Cut Free's click pitched down for now); Free a Friend's
   pills don't follow the map off screen; coin count and corner map up while wrapped;
   "rbxassetid://203785492 failed"; `ConfigService: Config value not found` (the `sell*`
   switches); "Stand one" never shows from the MCP; two-player reveal/coins/notes; a dropped find
   bumps a walker (D-182); rbxassethash warnings; Packrat's dead Slots entry; Mannequin pose onto
   `Rig.luau` (D-176); the watch bar's empty panel; S1-07a, S2-02b-d4, S2-03b, S2-05a, S2-07a1-b2
   leftovers; S1-10d1-3; box words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
