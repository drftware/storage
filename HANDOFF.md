# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 140 (S2-01 Sleepers placed with the floor) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S2-01 is done (D-152).** The floor's deal places its sleepers last (`Deal.new`,
  `deck.sleepers`, slot to keeper name): 10 in 100 units (`Deal.Asleep`), 20 behind a padlock
  (with its find or tool), none in the guard's unit or the first hall on floors 1 and 2. A door
  hands its sleeper back as it lifts; the director's mood odds no longer hold "Asleep" (out of
  the 90 the sleepers leave), the cap still turns an awake keeper asleep. The keepers' brain gets
  a floor's sleepers as it's laid (`Keepers.add`'s new `asleep`) and hands out those behind
  doors never lifted (`Keepers.sleepers(model)`); a caught friend is never kept in a sleeper's
  unit (KeptPlayers). Bodies still stand only as a door first lifts (D-152 says why).
- **Verified in Studio Play** (dev floor 3, seed 7): Output listed "asleep behind shut doors on
  floor 3: Units 305, 307, 327, 335, 338" before any door lifted; opening 307 from the Client
  printed "Unit307 held the Mannequin, asleep and 1 coins" and its body stood asleep in the unit.
  Studio is in Edit; its id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S2-02a The breaker box's art
The moment: the lights die with one heavy clunk, and someone has to find the grey box on a hall
wall and hold its lever up. This ticket makes that box, the unit's way, so S2-02b can wire it.
1. Read ROADMAP S2-02 (split into a, b, c) and the GDD's "The breaker" and "The Mannequin cuts
   the power" (docs tools: `search` payload, never the whole doc); name the precedent.
2. Look at what exists: `breaker` is already a word in `MotionLight`, `MotionLights`,
   `HallLight`, `Floor` and the test hall (a breaker post in the T): reuse its rules, don't fork.
3. Build the box in Blender 5.2 as `art/unit/` builds the unit: one spec for the numbers, parts
   UV-mapped to shared texture sets, baked PBR maps, FBX, a generated `Specs` module, look sheets.
   The lever reads up or down from across a hall at phone size; a small lamp shows power.
4. Into the place by the Open Cloud upload and `insert_asset` (STUDIO.md "Importing kit
   pieces"); judge it on a hall wall in Studio at phone size.
**Acceptance:** checks green; `scripts/art.sh` rebuilds it; the box sits on a hall wall in Studio,
its lever readable at phone size; look sheets in its art folder.
**Read first:** ROADMAP S2-02; GDD "breaker" (docs search); `art/unit/README.md`; STUDIO.md
"Importing kit pieces"; `src/shared/MotionLight.luau` (grep `breaker`); an art script the size of
a box (`art/battery/` or `art/padlock/`).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S2-02a (next), then S2-02b, S2-02c, S2-03 to S2-05 in order. S2-06 and L-08e3c wait on
   `OWNER.md`. R-01 (Remotes from Brix) is for later, not tonight. Lobby polish waits.
2. Found S2-01: S2-03 must decide how a sleeper woken behind a door never lifted stands (deal the
   unit then, or stand its body earlier) and pounds; `Keepers.sleepers` is where it picks.
   Older Studio recipes naming what a unit holds may be stale (the deal moved; STUDIO.md notes).
3. Found S1-12: nothing shows a player's saved cash total yet (ROADMAP polish, when cash buys
   something); a climb left mid-way makes no cash (D-151, owner's call in OWNER.md).
4. Found S1-11: a friend's beam doesn't show the mark (ROADMAP polish); the mark sits on the
   jamb beside the neighbour's door (owner to judge whose it reads as).
5. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's.
6. Found S1-10a: watch a whole ride arrive on a next floor in Play (start on floor 1).
7. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
8. Found S1-09: a kept player's torch keeps draining if left on (probably right); the
   first-person torch looks large on a wide desktop view. S1-08's polish is in ROADMAP.
9. Found S1-07a: about 16 in 100 units hold nothing at all (the GDD says 3 in 10 without coins
   hold nothing to take). Owner's call; batteries take a few of them.
10. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts.
11. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
    find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-01 arriving
    on another server, the save claim may wait up to 5 s. Lobby fixes are "later" (owner Nov 12).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
