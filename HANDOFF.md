# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 139 (S1-12 Cash on the results) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-12 is done (D-151); Phase 2 Step 1 is complete.** As a climb ends (ClimbEnds' `ended`),
  CashOut freezes every coin count (Coins' `close`, once a climb), turns each into cash one for
  one (`Cash.from`, `tests/cash.spec.luau`), adds it to the save (`Save.earn`) and writes it at
  once; it puts each player's cash on them (`Cash.EarnedAttribute`) for the results row
  (`id:fate:floor:cash`). The counts leave the screen at the cover (ClimbEnds' new `covered`,
  Coins' `clear`). Recorded as coins out (`cashOut`) and cash in (`climb`, a second currency).
  CarResults shows each friend's cash under their photo; yours counts up with rising ticks and
  lands with a swell, a chink and a jingle; the board grew 0.4 studs at its foot.
- **Verified in Studio Play:** 42 dev coins, a wipe: Output "CashOut: drftware's 42 coins made
  $42, now $42", the save went from cash 0 to 42, read back from `Saves.studio`; the coin count
  cleared at the cover; Again began a new climb at 0. A faked car board counted +$0 to +$42 with
  a 1.3 swell and its sounds, and read well on screen. The count's tail was then eased (Cubic,
  rounded) after the last dollar stalled 0.8 s: passes checks, not re-run. Studio is in Edit;
  its id this run: 4694c6c7-b56c-4a68-ac46-72f07b63568c.

## Next task: S2-01 Sleeping monsters are placed when the floor is made
The moment: a sleeper is already behind its door before anyone touches it, so later a monster
can wake and pound (S2-03), or be let out by a wrong code (S2-04), from a door nobody opened.
1. Read ROADMAP S2-01 and the GDD's sections on sleeping monsters and the wake (docs tools: read
   the GDD's tab with a `search` payload, never the whole doc); name the precedent or flag it.
2. Pure: the floor's deal places its sleepers up front (`Deal.new`, drawn last so nothing else a
   seed lays moves), and `Deal.open` hands back the placed sleeper instead of drawing one; the
   awake cap and the guarded note's keeper keep working. Lune specs first (`tests/deal.spec`,
   `tests/guard.spec`).
3. Server: Deals and Keepers know each placed sleeper's unit before its door lifts (nothing on
   screen changes yet; S2-03 wakes them).
**Acceptance:** checks green; the same seed places the same sleepers; opening a sleeper's unit
plays as today; in Play a floor's sleepers are listed in Output before any door opens.
**Read first:** ROADMAP S2-01 to S2-04; GDD sleeping monsters (docs search "asleep");
`src/shared/Deal.luau` (grep `Asleep`, `function Deal.open`); `src/server/Deals.luau` (header,
line ~330); `src/server/Keepers.luau` (grep `Asleep`); `tests/deal.spec.luau` (header).

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S2-01 (next), then S2-02 to S2-05 in order. S2-06 and L-08e3c wait on `OWNER.md`. R-01
   (Remotes from Brix) is for later, not tonight. Lobby polish waits.
2. Found S1-12: nothing shows a player's saved cash total yet (ROADMAP polish, when cash buys
   something); a climb left mid-way makes no cash (D-151, owner's call in OWNER.md).
3. Found S1-11: a friend's beam doesn't show the mark (ROADMAP polish); the mark sits on the
   jamb beside the neighbour's door (owner to judge whose it reads as).
4. Found S1-10c2a: Output in Play lists `rbxassetid://203785492` (wrong type) failures and
   texture permission errors; unchecked whether any are the machine's.
5. Found S1-10a: watch a whole ride arrive on a next floor in Play (start on floor 1).
6. Found S1-07b: coin piles and batteries show their Take button through a shut door (the server
   refuses the press); tools hide theirs (BehindDoors). Worth matching.
7. Found S1-09: a kept player's torch keeps draining if left on (probably right); the
   first-person torch looks large on a wide desktop view. S1-08's polish is in ROADMAP.
8. Found S1-07a: about 16 in 100 units hold nothing at all (the GDD says 3 in 10 without coins
   hold nothing to take). Owner's call; batteries take a few of them.
9. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts.
10. Unseen or small: S1-06 a kept find's save write and the friends' spark in Play; S1-05 a
    find in a unit can be walked through; S1-04b2 keepers don't know about stuff; S1-01 arriving
    on another server, the save claim may wait up to 5 s. Lobby fixes are "later" (owner Nov 12).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
