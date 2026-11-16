# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 199 (the Cut Free button) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- S3-03a1 and S3-03a2 done (D-220, D-221). Caught, Bang comes up and a beat later a warm "Cut
  Free" pill eases in left of it (F on a computer, Y on a gamepad, on Bang's key line; a thumb's
  width clear on a phone), only while `Remotes.CutFree`'s `On` is true. A press clicks, springs,
  fires the remote and dims it for `CutFree.AskEvery`; freed, both fade. The watch bar's button is
  the same pill on the same flag (no longer Studio only). Feel numbers in `src/shared/CutFree.luau`.
- Seen in Studio Play: a catch freed by F spending the save's spare (no prompt; the save now
  holds 0), a second freed by a click (Studio's free path) with no bang sent, the unit's door
  rising, a 7-stud walk out, the phone layout at 844 by 390. Not run: the real purchase, the
  watch bar's press. Play stopped. Nothing put into the place by hand.
- Catch in Studio from the MCP: Workspace `WakeSleepers` true on the Server, then
  `ServerStorage.CatchTest:Invoke(player)` every 0.5 s until "Caught" (STUDIO.md). Put a stand-in
  friend in first (tagged `StandInFriend`) so the catch isn't a wipe.
- No "Cut Free" product exists yet (OWNER.md). Rojo still syncs `CutFrees` twice (known gotcha).

## Next task: S3-03b Free a Friend
ROADMAP S3-03b. The moment: a friend wrapped across the floor; you pay, their film rips, door up.
1. Read the GDD's "Getting caught" for where Free a Friend is offered and who pays (docs `read`
   with `kind: "search"`, `text: "Free a Friend"`, then `blocks` on just that part). Anything it
   doesn't settle: a sensible default and an OWNER.md line.
2. `src/shared/Products.luau`: a `freeFriend` row (title `Free a Friend`, a switch), bought for a
   recipient. Purchasing's `prompt(player, offer, recipient)` takes the friend's save key (lines
   60-75, 250-265; the save's `recipients`, D-206). The grant must never be lost: if the friend
   is free by the time it lands, give the buyer something kept (default: a spare Cut Free).
3. CutFrees: a remote (or the Cut Free remote with a friend's UserId) validated type, then range,
   then that the friend is in this server, caught and not you; rate-limited (`CutFree.AskEvery`).
   On the grant, free the friend as Cut Free does (KeptPlayers' `cutFree`, else Watching's).
4. The button where the GDD puts it, built as CaughtView's pill (D-221): one word, no price,
   every press answered (click, spring, dim), feel numbers in Config.
5. Prove in Play with a stand-in friend as the one caught (STUDIO.md's stand-in recipes;
   CatchTest takes only players). First count Client `RenderStepped` frames (0: not drawing).
**Acceptance:** checks green; a recipient purchase validated on the server; a friend freed by a
made-up receipt (`DevReceipt:Invoke({ offer = "freeFriend", ... })`) in Play; a grant that lands
late kept; OWNER.md steps for the real two-player purchase.
**Read first:** ROADMAP S3-03; DECISIONS D-206, D-220, D-221 (grep `^## D-2`); GDD "Getting
caught" (search only); `src/server/CutFrees.luau`; `src/server/Purchasing.luau` (grep
`recipient`); `src/shared/Products.luau` (grep `cutFree`).

## Queue (next sessions, the owner's ten-ticket order)
0. S3-03c Free Everyone before the results (and playing alone: one catch ends the climb before
   Cut Free can be bought, ClimbEnd.over), then S3-04 The counter's shop and wrap colours (gifts
   wait on `OWNER.md`).
1. **S4-01 Floors made by rules.** Split first: S4-01a the rules table and the top gone, S4-01b
   what changes floor to floor. Read the GDD's "Floor rules", D-106, D-128, `Climb.luau`,
   `Deal.luau`; grep `Climb.Top`, `Climb.Building`, `topped`. The escape ("Made it") has no trigger
   once the top goes: keep its code, note it. The climb goes past floor 3 in Studio (DevFloorNumber 3).
2. **F-G1b Using a find plays what it does** (ROADMAP F-G1); then S4-02 to S4-05 (5 coins a trapped
   monster, D-188). Any ticket that adds finds starts from the catalog doc the GDD's finds section links.
3. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
4. B-05b2b polish: a guard's box still hides wholly round the bend. L-08e3c, L-14b2d wait on
   `OWNER.md`; R-01 later. A GDD section costs ~15k context: docs `read` with `kind: "search"`,
   `text`, then `blocks` on just the part needed.
5. Small: coin count and corner map still up while wrapped; "rbxassetid://203785492 failed";
   `ConfigService: Config value not found` (`sellCutFree`); "Stand one" never shows from the MCP;
   two-player reveal/coins/notes; a dropped find bumps a walker (D-182); rbxassethash warnings;
   Packrat's dead Slots entry; Mannequin pose onto `Rig.luau` (D-176); the watch bar's empty
   panel; S1-07a, S2-02b-d4, S2-03b, S2-05a, S2-07a1-b2 leftovers; S1-10d1-3; box words (D-215).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
