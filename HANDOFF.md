# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 200 (Free a Friend) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-03b done (D-222). A free player sees a warm pill under the corner map for each caught friend
  (their headshot and "Free", longest caught on top, at most 3), a beat after the catch. A press
  clicks, springs, dims and fires `Remotes.FreeFriend` with the friend's UserId; the server
  checks it (rate, `CutFree.friendId`, in this server, not you, caught), spends a spare Free a
  Friend or prompts with the friend's save key as recipient (Brix `forAnother`). The grant is a
  spare in the buyer's save, spent freeing the sale's recipient (KeptPlayers' `cutFree(player,
  cutter)`: cut by the buyer), else kept. Feel numbers in `src/shared/CutFree.luau` (`Friend*`).
- Seen in Studio Play: the pill drawn (Workspace `DevFreeFriend` = a UserId stands one up), its
  right edge on the map's; a made-up receipt with no friend named kept as a spare ("waits in
  their save"). Not run: freeing a real second player (one MCP player), the catch itself (below).
  Play stopped. Nothing put into the place by hand.
- **Catching from the MCP failed this session:** `WakeSleepers` true and `CatchTest` every 0.5 s
  for 45 s answered `NoKeeper`, in the lobby and pivoted to (-6, 4, -591) on DevCorridor floor 3.
  Last session it worked; find what CatchTest needs (grep `NoKeeper` in `src/server`) first.
- `DevReceipt` takes `recipient` (a save key): naming the buyer frees them by Free a Friend's
  path. No "Cut Free" or "Free a Friend" product exists yet (OWNER.md, two owner choices).

## Next task: S3-03c Free Everyone before the results
ROADMAP S3-03c. The moment: the last of you is wrapped; instead of the results, the dark holds,
and one warm "Free Everyone" waits; someone pays, every film on the floor rips at once, every
door goes up, and the climb carries on from that floor.
1. GDD "Getting caught": docs `read` on `UtmFtWGEMRQkNmWmCEhFWN`, then `{kind:"search", text:
   "Free Everyone"}` with `ref {object:"node", id:"15cf0df0-0c6f"}` and the project container;
   then `{kind:"view", parentId:"<the hit's row or list id>"}` for just that block. Its table row
   (price, where it shows) is in table `m8vzrrctamm.107863`. A gap: a default and an OWNER.md line.
2. The end: grep `over` in `src/shared/ClimbEnd.luau` and `ClimbEnds` (server). A wipe must
   wait a few seconds (Config) while the offer is up, then end as today; a solo player's one
   catch is a wipe, so solo gets the offer too.
3. `Products`: a `freeEveryone` row (title `Free Everyone`, switch `sellFreeEveryone`), granted
   as a spare in the buyer's save like `freeFriend`; `CutFrees` frees every caught player (each
   `free(p, buyer)`), cancels the wipe, and keeps the spare if nobody's left to free.
4. The button: the caught screen's pill (CaughtView's Cut Free build, D-221) swapped for "Free
   Everyone" while the wipe waits, on every caught screen; a press answered as Cut Free's.
5. Prove in Play: one player and no stand-in, catch (fix the `NoKeeper` first), see the offer
   hold the results, press (Studio's free path), walk out. Then a wipe with no press ends.
**Acceptance:** checks green; a wipe held while the offer's up, ending after; everyone freed by
one press in Play; a late grant kept; OWNER.md steps for the real purchase.
**Read first:** ROADMAP S3-03; DECISIONS D-220, D-221, D-222 (grep `^## D-22`); GDD "Free
Everyone" (search only); `src/server/CutFrees.luau`; `src/shared/ClimbEnd.luau` (grep `over`);
`src/client/CaughtView.luau` (lines 186-240, the pill).

## Queue (next sessions, the owner's ten-ticket order)
0. S3-04 The counter's shop and wrap colours (gifts wait on `OWNER.md`). 1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
   4. B-05b2b polish: a guard's box hides round the bend. L-08e3c, L-14b2d wait; R-01 later.
5. Small: Free a Friend's pills don't follow the map off screen (lobby, feed); coin count and
   corner map still up while wrapped; "rbxassetid://203785492 failed"; `ConfigService: Config
   value not found` (`sellCutFree`, `sellFreeFriend`); "Stand one" never shows from the MCP;
   two-player reveal/coins/notes; a dropped find bumps a walker (D-182); rbxassethash warnings;
   Packrat's dead Slots entry; Mannequin pose onto `Rig.luau` (D-176); the watch bar's empty
   panel; S1-07a, S2-02b-d4, S2-03b, S2-05a, S2-07a1-b2 leftovers; S1-10d1-3; box words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
