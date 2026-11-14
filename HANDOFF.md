# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 143 (S2-02c the Mannequin throws the breaker) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S2-02c is done (D-155).** A loose Mannequin picking where to wander next sometimes heads for
  the floor's breaker instead (`Breaker.errand`: 8 in 100 picks on floor 1, 2 more a floor up to
  30; none while thrown or for 45 s after the power comes on). It walks there held by any light
  as ever, stands in front of the lever (`Breaker.stand`) and throws it; keepers within a slam's
  reach (110 studs) hear the clunk and come to look. The brain: `Keeper.offer`, `errand`,
  `threw`; the server: `Keepers` offers it every step (`Breakers:power`, `within`). Studio's dev
  command: Workspace `SendToBreaker` true (STUDIO.md "The breaker").
- **Verified in Studio Play** on the dev floor: a Mannequin stood by the "Stand one" post, sent
  by the dev command, walked 110 studs to the box in 21 s and threw it; all 23 hall lights went
  blind; Output said "heads for the breaker", "threw the breaker", clean of new errors. Not heard,
  not on a phone, not with a friend, never seen in a real climb. Studio is in Edit.

## Next task: S2-03 Sleeping monsters wake
The moment: four minutes into a floor, a pounding starts somewhere behind a shut door, then
another; no clock, no words. You don't know which door, only that time on this floor is running out.
1. Read ROADMAP S2-03 and the GDD's section on sleepers waking (docs tools: `search` with
   `{"kind":"search","text":"pound"}` on the doc's node, then `view` from the hit's heading).
2. Pure rules first (Lune): when the first three wake (4 minutes on floors 1 and 2, 6 above),
   three more every two minutes, sooner and more higher up; which sleepers (`Keepers.sleepers`
   picks); a pounding one breaks out after 90 s unless its door is padlocked.
3. Decide (Queue 1) how a sleeper woken behind a door never lifted stands and pounds: deal its
   unit then, or stand its body earlier. The trapped keeper's bang clock (`Keeper.trap`,
   `bangGap`, `blow`) is the likely reuse.
4. The pounding is heard across the floor by players and keepers (`Keepers:hear`). Verify in
   Studio Play on the dev floor with a dev path that skips the minutes.
**Acceptance:** checks green with new Lune specs; in Play a sleeper wakes, pounds, and breaks out
of an unpadlocked door after its time; Output clean.
**Read first:** ROADMAP S2-03; DECISIONS D-152; `src/server/Keepers.luau` (grep `sleepers`,
`asleep`, `trap`); `src/shared/Keeper.luau` (grep `Trapped`, `trap`, `bangGap`);
`src/shared/KeeperRows.luau` (grep `bang`, `breakOut`); `src/shared/Deal.luau` (grep `sleepers`).

## Queue (overnight run ended; next sessions per ROADMAP Phase 2)
1. S2-03 (next), then S2-04 and S2-05 in order. S2-06 and L-08e3c wait on `OWNER.md`. R-01
   (Remotes from Brix) is for later. Lobby polish waits. Found S2-01: S2-03 must decide how a
   sleeper woken behind a door never lifted stands and pounds; `Keepers.sleepers` is where it picks.
2. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. The thrower hears its own clunk and stands (Output says it "goes
   to look" 0 studs off). The dev command sets keepers' states directly (Studio only).
3. Found S2-02b: nobody can throw the breaker by hand; S2-06's light-sticking monster needs "off
   and on again", so its button can grow an Off then. Restoring flashes the floor's lights on,
   which freezes any Mannequin under one for 7.5 s (owner's call in OWNER.md). The glow's numbers
   were judged in a Studio capture only. S2-02a: from the box's left its lever hides but the grip.
4. Found S1-12: nothing shows a player's saved cash total yet (ROADMAP polish, when cash buys
   something); a climb left mid-way makes no cash (D-151, owner's call in OWNER.md).
5. Found S1-11: a friend's beam doesn't show the mark (ROADMAP polish); the mark sits on the
   jamb beside the neighbour's door (owner to judge whose it reads as).
6. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's.
7. Found S1-10a: watch a whole ride arrive on a next floor in Play (start on floor 1).
8. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
9. Found S1-09: a kept player's torch keeps draining if left on; the torch looks large on a
   wide desktop. S1-07a: about 16 in 100 units hold nothing (owner's call).
10. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
    find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-02 the test
    hall begins a climb on floor 3; S1-01 arriving on another server, the save claim may wait.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
