# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 135 (S1-10c1 The machine's stock shown) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-10c1 built (D-147):** `Machine.Stock` (pure, `tests/stock.spec.luau`) deals a waking
  ride two batteries in each bottom coil (bays 1-2) and three or four of Saw, BoltCutters,
  Padlock, BubbleWrap, AirHorn in random tool bays (3-6), with prices; `encode`/`decode` the
  `Stock` attribute. `src/server/Machines.luau` deals once per ride, keeps it by the car's
  `Ride` value, writes it on every machine whose car carries that ride; `stockOf(machine)`
  returns the server's copy (a table it owns: mutate it for a buy).
- `src/client/MachineStock.luau` stands each thing in its coil (`Specs.CoilFront`, `CoilPitch`,
  newly exported by `art/machine/spec.py`); `MachineView` shows a row at its tube's first flash,
  LEDs 88 then prices (dashes for an empty coil) as it catches, all gone at the cut. Today any
  change to the attribute refills every coil.
- **Verified in Studio Play** (test hall floor 3's car, a staged ride, STUDIO.md "Staging the
  machine's stock"): stock dealt and replicated; every tool and the batteries read in their
  coils; prices right; the reveal and LED timing stepped through; a stand-in car given the same
  ride showed the same stock, a new ride a fresh one, a lobby ride none. A real keypad ride and
  the real takeover are unseen. Studio in Edit; its id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S1-10c2 The buy
The moment: mid-ride, the machine awake, you press a lit button; your coins clink into the
slot and count off, the button sinks, the coil turns, the thing drops with a clunk behind the
flap, it swings, and the thing flies into your hand (or your torch snaps full).
1. Server (`Machines`): each `Button{i}` gets a ProximityPrompt ("Buy", ButtonView's world
   buttons or Batteries' prompt) enabled only while its ride wakes it and before the cut
   (`Wake`, the ride's clock). On a press validate in order: type (a bay 1-6 of a machine we
   know), range (near the button), ownership (the player is in that car's `Aboard`, the ride
   live), state (bay stocked, enough coins); rate-limit (Batteries' `allow` pattern).
2. Charge through `Coins` (add a `spend` there: the balance down, saved as earnings are); a
   battery calls `Flashlights:fill` (refused while the ring is full: ignore the press, no text,
   no charge); a tool goes in a free slot (`Slots`; no free slot: ignore, no charge). Lower the
   bay's count in the server's copy and rewrite the attribute on every machine of that ride.
3. Client: change only the bought bay (don't refill all): the coil turns one pitch per thing
   (`CoilPitch`), the front thing tips off into the bin with a clunk, the flap swings, it flies
   to the buyer's hand; the coins fly from the HUD count into the slot (`Specs.Slot`) and count
   off (CoinView's jingle and tick); the button sinks `Specs.ButtonTravel`. Friends see the
   coil, the drop and the flap.
4. Record each buy (`machine` in `Record`'s reasons, `spent` with the item) and a battery taken
   from a unit (S1-07b; Batteries' `taken`).
**Acceptance:** checks green; Lune tests for any new pure rules; in Play a staged ride (State)
buys a battery and a tool, coins drop, the bay empties on screen.
**Read first:** ROADMAP S1-10c2; `src/server/Machines.luau`; `src/client/MachineStock.luau`;
`src/server/Coins.luau` (its earn path); `src/server/Batteries.luau` (prompt, `allow`, `fill`);
`src/shared/Record.luau` (grep `reason`).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-10c2 (next), then ROADMAP Phase 2 in order (S1-11, S1-12, then Step 2). S2-06 and
   L-08e3c wait on `OWNER.md`. Lobby polish waits.
2. Found S1-10c1: in this run's Play captures the machine's cabinet looked pale grey, not
   oxblood, and Output listed dozens of "rbxassethash ... Requester does not have permission
   for Asset" texture failures. Unchecked whether they're linked.
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
