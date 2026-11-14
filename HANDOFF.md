# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 136 (S1-10c2a The buy and the machine's answer) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-10c2 split** (context): c2a built, c2b next (ROADMAP).
- **S1-10c2a built (D-148):** `Machine.Buy` (pure, `tests/buy.spec.luau`): `open`, `check`,
  `allow`, `encode`/`decode` of `Bought`, `sold`, `Vend` timings and sounds. `Machines` puts a
  "Buy" prompt (named for the thing) on each `Button{i}`, armed each frame on a ride; a press is
  validated, gives the thing (`Slots:give`, new; or `Flashlights:fill`), then `Coins:spend`
  (new, with `spent` and `countOf`), lowers the count, stamps `Bought` (bay|serial|userId) and
  rewrites the stock. `src/client/MachineVend.luau` plays a sale on every screen (button sink
  and click, coil's one loop and whine, the thing off the tip into the bin with its clunk, the
  flap's knock, gone 0.15 s after); `MachineView` reads a sale off the stock (`Buy.sold`) instead
  of refilling, and a local press sinks the button, too few coins buzz and blink the price.
  Record: `spent` (reason `machine`, item) and `batteryTaken`; Recording wires both.
- **Verified in Studio Play** (STUDIO.md "Staging a buy"): bolt cutters (10) and a battery (3)
  bought by E presses; coins, slot, torch charge and stock all changed; both records printed; a
  press with too few coins sold nothing; the vend's motion sampled frame by frame (button 0.07
  in and back, one coil turn 0.1-0.7 s, the battery in the bin at about 1.07 s, the flap 12° and
  settled by 1.6 s, the next battery moved up). Not seen by eye, not heard. Studio in Edit; its
  id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S1-10c2b The buy's flights
The moment: you press, your coins leave the count in the corner one at a time and fly into the
machine's coin slot with a clink each, the count ticking down; the thing drops, the flap swings,
and it flies out of the bin into your hand (a battery into your torch, which snaps full).
1. Server: tell the buyer's screen of the spend before the count drops (a `MachineBuy` remote,
   as `Pay.Remote` tells the pay): the machine, the bay, the price.
2. CoinView: on it, `price` coins fly from the count to the slot's screen point
   (`Specs.Slot` in the machine's frame), a beat apart, each ticking the count down with the
   chink; the count doesn't jump down meanwhile (today a drop shows at once).
3. MachineVend: once the flap knocks, the thing flies from the bin to the buyer's left hand
   (`Bought`'s userId; a battery to their torch, the right) on every screen; hide the buyer's
   real held tool (`Tools.HeldName` in their character) on screens until it lands, then show it.
4. Hide a battery's Buy from a player whose torch is full (BatteryView's rule) on their screen.
**Acceptance:** checks green; in Play a staged buy (STUDIO.md "Staging a buy") shows coins
leaving the count and the thing reaching the hand (sample positions, or one small capture).
**Read first:** ROADMAP S1-10c2b; `src/client/MachineVend.luau`; `src/client/CoinView.luau`
(grep `paid`, `flyers`, `stepFlyer`); `src/shared/Pay.luau` (its remote); `src/server/Machines.luau`
(grep `press`); `src/client/BatteryView.luau` (grep `wants`).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-10c2b (next), then ROADMAP Phase 2 in order (S1-11, S1-12, then Step 2). S2-06 and
   L-08e3c wait on `OWNER.md`. Lobby polish waits.
2. Found S1-10c2a: Output in Play lists `rbxassetid://98721236013567` (no content) and
   `203785492` (wrong type) failures; with S1-10c1's pale cabinet and texture permission errors,
   unchecked whether they're the machine's.
3. Found S1-10a: watch a whole ride arrive on a next floor in Play (start on floor 1).
4. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
5. Found S1-09: a kept player's torch keeps draining if left on (probably right); the
   first-person torch looks large on a wide desktop view. S1-08's polish is in ROADMAP.
6. Found S1-07a: about 16 in 100 units hold nothing at all (the GDD says 3 in 10 without coins
   hold nothing to take). Owner's call; batteries take a few of them.
7. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts.
8. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
   find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-01 arriving
   on another server, the save claim may wait up to 5 s. Lobby fixes are "later" (owner Nov 12).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
