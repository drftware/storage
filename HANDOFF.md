# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 144 (S2-03a when sleeping monsters wake) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S2-03 is split (ROADMAP); S2-03a is done (D-156).** `src/shared/Waking.luau` holds the pure
  schedule: the first wave at four minutes on floors 1 and 2, 15 s sooner a floor above (never
  under 150 s); three at a time on floors 1 to 3, one more every three floors (up to five); two
  minutes between waves, closing to 75 s higher up. `Waking.now` says how many to wake this
  step (never more than owed or left asleep, never past `AwakeMost`, six keepers stepping on a
  floor for phones; held-back wakes come once there's room); `Waking.pick` is a fair pick of
  which doors. `tests/waking.spec.luau`. Nothing in the game calls it yet: nothing to see in Play.
- Roadmap's "(six above)" vs the GDD's "sooner higher up": built sooner, asked in `OWNER.md`.

## Next task: S2-03b They stand and pound
The moment: four minutes into a floor, a pounding starts somewhere behind a shut door, then
another; no clock, no words. You don't know which door, only that time here is running out.
1. Read ROADMAP S2-03b and D-156. In `Keepers`, keep each laid floor's seconds since the team
   arrived (the floor's add, or the first player on it: pick and say which), and each step ask
   `Waking.now(floor, seconds, woken, awake, left)`: `awake` is every keeper stepping on that
   floor (loose or trapped), `left` is `#sleepers`.
2. `Waking.pick` among `Keepers.sleepers(model)`'s slots with the floor's Brix Random. For each:
   stand its body where the deal laid it (`stand(name, model, at, facing, true)`, the same place
   a door lifting stands it), clear its `asleep` entry so the door lifting later doesn't stand a
   second one, and `Keeper.trap(k, slot, index)` it so it bangs on the trapped clock and bursts
   at its row's `breakOut` (90 s) unless padlocked (`Keeper.padlock`). Check `trap` accepts a
   keeper behind a door that never went up (it was written for a door coming down on it).
3. Its blows already move the door and are heard by keepers; check players hear them across the
   floor (the trapped bang sound's reach) and that a padlocked door holds. One Output line per
   wake (which units), none per blow.
4. A Studio dev path (Workspace attribute, like `SendToBreaker`) that skips to the first wave.
   Verify in Studio Play on the dev floor: one wakes, pounds, bursts an unpadlocked door at 90 s.
**Acceptance:** checks green (a Lune spec if any pure logic is added); in Play a sleeper wakes,
pounds, and breaks out of an unpadlocked door after its time; Output clean. Studio left in Edit.
**Read first:** ROADMAP S2-03b; DECISIONS D-156, D-152; `src/shared/Waking.luau`;
`src/server/Keepers.luau` (grep `sleepers`, `asleep`, `trap`, `SendToBreaker`, `function system.stand`);
`src/shared/Keeper.luau` (grep `function Keeper.trap`, `Trapped`, `padlock`).

## Queue (next sessions per ROADMAP Phase 2)
1. S2-03b (next), then S2-04 and S2-05 in order. S2-06 and L-08e3c wait on `OWNER.md`. R-01
   (Remotes from Brix) is for later. Lobby polish waits.
2. Found S2-03a: with waves on, a floor can hold more loose keepers than the director's own cap
   (`Deal.awakeCap`); `Waking.AwakeMost` (six) bounds it. Watch it on a phone once S2-03b lands.
3. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. The thrower hears its own clunk and stands (Output says it "goes
   to look" 0 studs off). The dev command sets keepers' states directly (Studio only).
4. Found S2-02b: nobody can throw the breaker by hand; S2-06's light-sticking monster needs "off
   and on again", so its button can grow an Off then. Restoring flashes the floor's lights on,
   which freezes any Mannequin under one for 7.5 s (owner's call in OWNER.md). S2-02a: from the
   box's left its lever hides but the grip.
5. Found S1-12: nothing shows a player's saved cash total yet (ROADMAP polish, when cash buys
   something); a climb left mid-way makes no cash (D-151, owner's call in OWNER.md).
6. Found S1-11: a friend's beam doesn't show the mark (ROADMAP polish); the mark sits on the
   jamb beside the neighbour's door (owner to judge whose it reads as).
7. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's. S1-10a: watch a whole
   ride arrive on a next floor in Play (start on floor 1).
8. Small: S1-07b coin piles and batteries show Take through a shut door (tools hide theirs);
   S1-09 a kept player's torch drains if left on; S1-07a 16 in 100 units hold nothing (owner's
   call); unseen: S1-06 a kept find's save and the friends' spark, S1-05 a find can be walked
   through, S1-04b2 keepers don't know about stuff, S1-02 the test hall starts on floor 3.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
