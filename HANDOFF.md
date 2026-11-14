# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 137 (S1-10c2b The buy's flights) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-10 is done** (the ride, its machine, its stock, the buy and its flights).
- **S1-10c2b built (D-149):** the server tells the buyer's screen first (`Buy.Remote`
  "MachineBuy": machine, bay, price) and gives quietly (`Slots:give(..., quiet)`). CoinView
  flies up to 8 coins (`Buy.coins`) from the count into the slot (`Specs.Slot`), each ticking
  it down and clinking there. MachineVend, a beat after the thing lands in the bin, arcs it
  (`Buy.arc`) to the buyer's left hand or torch (`HandAt`) with its pick-up or clack-click.
  `InFlight` (new) holds the change back until it lands: ToolView keeps your hand empty then
  shows the tool where it flew to; a friend's held tool is hidden; FlashlightView keeps the
  charge (your torch now follows the charge once a frame, not in its signal). A battery's Buy
  is hidden (ButtonView "Full") while your torch is full. BatteryView uses `HandAt.torch`.
- **Verified in Studio Play**, sampled frame by frame (STUDIO.md "Sampling a buy"): bolt
  cutters: count 40 to 30 a coin at a time, no jump, coins reached the slot, the cutters
  dropped then flew to the hand, the drawn tool appeared only on arrival; a battery: the ring
  held at 6 ticks until the battery reached the torch (~1.6 s after the press), then swept to
  12; the battery Buy hid once full. Not seen by eye, not heard, no second player. Studio in
  Edit; its id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S1-11 The one faint mark
The moment: sweeping your torch along a hall, one door frame shows a faint mark a few steps
off, and behind that door is one of the floor's notes. Nothing on the corner map says so.
1. Read ROADMAP S1-11 and the GDD's section on notes and the mark (docs tools, never WebFetch);
   name the hit game the mark comes from (AGENTS.md's proven-mechanics rule) or flag it.
2. Server: when the floor is dealt (`Deal`, `Deals`), pick at most one note's unit for the mark
   (a pure rule in `Deal`, Lune-tested) and stamp it where every screen can read it.
3. Art first if the mark needs a texture or decal (art is code); keep it faint and small.
4. Client: the mark shows only from a few steps, and only with your torch's beam on it.
**Acceptance:** checks green; the rule tested; in Play the mark is found on the stamped frame
and shows only within the beam at close range (sample the frame's visibility).
**Read first:** ROADMAP S1-11; GDD note and mark sections; `src/shared/Deal.luau` (grep
`notes`); `src/server/Deals.luau` (grep `note`); `src/client/NoteView.luau`;
`src/client/FlashlightView.luau` (grep the beam's aim).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-11 (next), then S1-12, then ROADMAP Phase 2 Step 2. S2-06 and L-08e3c wait on
   `OWNER.md`. Lobby polish waits.
2. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's.
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
