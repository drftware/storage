# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 141 (S2-02a the breaker box's art) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S2-02a is done (D-153).** The breaker box, made the unit's way (`art/breaker/`, `scripts/art.sh
  breaker`): a grey safety switch on a plywood board, a conduit to the wall's cap, a yellow
  lightning-bolt sticker, a pilot lamp (`BreakerLamp`, untextured: the game lights it) and the
  lever on its right side (`BreakerLever`), up 42 degrees for on, down 42 for off, its pivot and
  grips in `src/shared/Breaker/Specs.luau`. Template `ReplicatedStorage.Props.Breaker` (asset
  101677099640631): every part's pivot the breaker's origin (the lever's its pivot), lever up.
  Place its origin on a wall's face line looking into the hall.
- **Verified in Studio Edit** on a hall wall built from the corridor templates, under a stand-in
  torch: from across the hall the box, red lamp and grip read; from 11 studs down the hall the
  lever reads down in profile; the ϟ sticker reads. Not seen in Play or on a real phone. Studio is
  in Edit; its id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S2-02b Throw it and switch it back
The moment: one heavy clunk, every hall light dies, motion does nothing; someone finds the box by
its red lamp and holds the lever up for a second: a hum, the lamp goes green, the lights come back.
1. Read ROADMAP S2-02b and the GDD's "The breaker" (docs tools, `search` payload). Precedent:
   Phasmophobia's fuse box (D-153).
2. Pure rules first (Lune): where the floor's one breaker goes (drawn last in the floor's deal so
   seeds keep their floors, like the sleepers in `Deal.new`), on a plain wall or dead end's face,
   never in the lobby's hall; thrown/on state; the hold's length and rate.
3. Server: place a copy of `Props.Breaker`, cut every hall light's zone with
   `MotionLights:cut` (the dev hall's breaker post shows how), keep the elevator's light; a
   one-second hold prompt on the grip (the same hold as cutting a friend free) switches it on.
   Add a dev command to throw it.
4. Client feel: the lever swings (`Specs.Down` to `Specs.Up` over the hold, a snap at the end),
   the clunk heard floor-wide, the hum back, the lamp red/green (Neon, owner's call in OWNER.md).
5. Verify in Studio Play on the dev floor: throw it, see the halls dark and blind, switch it back.
**Acceptance:** checks green with new Lune specs; in Play the throw kills every hall light and
the hold restores them, lever and lamp answering; Output clean.
**Read first:** ROADMAP S2-02; `art/breaker/README.md` "In the place"; `src/shared/Breaker/Specs.luau`;
`src/server/MotionLights.luau` (`cut`); `src/server/DevCorridor.luau` (grep `breakerPost`); the
floor deal's sleepers in `Deal.new` (grep `sleepers`).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S2-02b (next), then S2-02c, S2-03 to S2-05 in order. S2-06 and L-08e3c wait on
   `OWNER.md`. R-01 (Remotes from Brix) is for later, not tonight. Lobby polish waits.
2. Found S2-02a: from the box's left side its lever hides behind the box but for the grip's end;
   the lamp is small at a grazing angle (S2-02b may brighten it or add a faint glow).
3. Found S2-01: S2-03 must decide how a sleeper woken behind a door never lifted stands (deal the
   unit then, or stand its body earlier) and pounds; `Keepers.sleepers` is where it picks.
   Older Studio recipes naming what a unit holds may be stale (the deal moved; STUDIO.md notes).
4. Found S1-12: nothing shows a player's saved cash total yet (ROADMAP polish, when cash buys
   something); a climb left mid-way makes no cash (D-151, owner's call in OWNER.md).
5. Found S1-11: a friend's beam doesn't show the mark (ROADMAP polish); the mark sits on the
   jamb beside the neighbour's door (owner to judge whose it reads as).
6. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's.
7. Found S1-10a: watch a whole ride arrive on a next floor in Play (start on floor 1).
8. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
9. Found S1-09: a kept player's torch keeps draining if left on (probably right); the
   first-person torch looks large on a wide desktop view. S1-08's polish is in ROADMAP.
10. Found S1-07a: about 16 in 100 units hold nothing at all (the GDD says 3 in 10 without coins
    hold nothing to take). Owner's call; batteries take a few of them.
11. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
    find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-02 the test
    hall begins a climb on floor 3; S1-01 arriving on another server, the save claim may wait.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
