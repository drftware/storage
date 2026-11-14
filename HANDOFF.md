# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 142 (S2-02b throw the breaker and switch it back) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S2-02b is done (D-154).** Every floor hangs one breaker box (`Breaker.spots`: a plain wall on
  a straight or a dead end, never the lobby's hall; `deck.breaker`, drawn last). `Breakers` (server)
  owns it: `throw(box)` cuts its floor's power zones, every hall light blind; a one-second hold
  on the grip, judged (`Breaker.judge`), switches it back on and every light on the floor comes
  on at once, then times out. `BreakerView` draws it: the slam, the clunk across the floor, the
  red lamp pulsing with a short red glow, the lever creeping up under a hold, the snap, click,
  green lamp and hum. Studio's dev command: Workspace `ThrowBreakers` true (STUDIO.md "The breaker").
- **Verified in Studio Play** on the dev floor (Floor3, box at -100, 0, -702): the throw blinded
  all 23 lights; a scripted hold crept the lever to about -7 degrees half-way, then on: lever up,
  lamp green, all 23 lights Lit; the red glow judged in a capture. Output clean of new errors.
  Not heard (captures are silent), not on a phone, not with a friend. Studio is in Edit.

## Next task: S2-02c The Mannequin throws it
The moment: you're deep in a wing when the clunk comes from somewhere behind you and the halls die;
the Mannequin, which only moves unseen, got to the box. Someone has to go back through the dark.
1. Read ROADMAP S2-02c and the GDD's "The Mannequin cuts the power" (docs tools, `search`
   payload). Precedent: Phasmophobia's ghost switching off the fuse box (D-153).
2. Pure rules first (Lune): when a loose Mannequin with no light on it takes the errand (a chance
   per check, higher on higher floors; never while the box is already thrown; a gap after the
   power comes back so it isn't thrown again at once), and that it walks to the box's spot.
3. The keepers' brain (D-064, lives in this game): the errand as one more thing a keeper does,
   walking the floor's map to the box (`Breakers:within(floor)` finds it; the grip's spot is
   in front of the box), then `Breakers:throw(box)`. The keepers hear the clunk (`Keepers:hear`).
4. The throw's feel is the box's own (BreakerView). Verify in Studio Play on the dev floor: stand
   the Mannequin loose, give it the errand (a dev path is fine), watch it walk there, lights die.
**Acceptance:** checks green with new Lune specs; in Play a Mannequin walks to the box and throws
it; Output clean.
**Read first:** ROADMAP S2-02c; DECISIONS D-064 and D-154; `src/server/Breakers.luau` (`throw`,
`within`); `src/shared/Keeper.luau` (grep the Mannequin's rules and `Hears`);
`src/server/Keepers.luau` (grep `lightOn`, `hearAt`, `stand`); `src/shared/Breaker/init.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S2-02c (next), then S2-03 to S2-05 in order. S2-06 and L-08e3c wait on `OWNER.md`. R-01
   (Remotes from Brix) is for later, not tonight. Lobby polish waits.
2. Found S2-02b: nobody can throw the breaker by hand; S2-06's light-sticking monster needs "off
   and on again", so its button can grow an Off then. Restoring flashes the floor's lights on,
   which freezes any Mannequin under one for 7.5 s (owner's call in OWNER.md). The glow's numbers
   were judged in a Studio capture only; on a phone they may need another look.
3. Found S2-02a: from the box's left side its lever hides behind the box but for the grip's end.
4. Found S2-01: S2-03 must decide how a sleeper woken behind a door never lifted stands (deal the
   unit then, or stand its body earlier) and pounds; `Keepers.sleepers` is where it picks.
5. Found S1-12: nothing shows a player's saved cash total yet (ROADMAP polish, when cash buys
   something); a climb left mid-way makes no cash (D-151, owner's call in OWNER.md).
6. Found S1-11: a friend's beam doesn't show the mark (ROADMAP polish); the mark sits on the
   jamb beside the neighbour's door (owner to judge whose it reads as).
7. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's.
8. Found S1-10a: watch a whole ride arrive on a next floor in Play (start on floor 1).
9. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
10. Found S1-09: a kept player's torch keeps draining if left on; the torch looks large on a
    wide desktop. S1-07a: about 16 in 100 units hold nothing (owner's call).
11. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
    find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-02 the test
    hall begins a climb on floor 3; S1-01 arriving on another server, the save claim may wait.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
