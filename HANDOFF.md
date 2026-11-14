# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 125 (S1-05 Finds you carry) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-05 is built** (D-137). A find (teddy, TV, boombox, skates) is a row in the tools' catalog
  (`find = true`, with a `grip` and a `heft`) and rides the tools' slots: `Deals` lays it with
  `Slots:lay`, standing and facing the doorway, with a "Take" prompt; one tap puts it in a slot
  and your hand; drop, hand-over and a catch (`dropAll`) treat it as a tool. Its template is
  built at run time from its art in `Props.Finds`, grip at the pivot (`Tools.template`). Weight
  is felt only in your view (`Tools.Heft`): slower up, no spring, a sag and rebound, a heavier
  sway; your walk is unchanged (an `OWNER.md` question). Each find has its own take and drop
  sounds (measured, docs/STUDIO.md).
- **Seen in Studio Play** (seed 7 floor 3): opening Unit 301 laid the teddy standing in
  `Workspace.Tools` with Take; Take put it in slot 1 (`ToolSlot1` Teddy), in your view and welded
  in your left hand; Drop fell it from 2.0 to rest in 0.32 s, 2.5 studs ahead, Take back; taken
  again then health set to 0 (the same `dropAll` a catch calls): it lay 3 studs off, Take back,
  slots empty. Unit 327's TV: up in 0.55 s, no overshoot, a 0.05-stud dip at the view's scale,
  settled by 1.1 s, walk still 16; friends see it hang at your left side, 0.77 off the floor.
  Both read at once in a capture but sat too big and central, so all four finds' places in your
  view were moved lower and left after: that new place passes checks, **not seen in Play**.
- Studio left in Edit, `DevFloorSeed` untouched (7); the place isn't saved by me.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order.

## Next task: S1-06 Pay and keeping at the gate
The moment: the gate slams with you aboard, coins pour into your count, and the boombox in your
slot is yours for good: the slot empties as it's kept.
1. Read ROADMAP S1-06 and the GDD "When the gate shuts" (docs tools, search "gate shuts"):
   everyone aboard is paid the same coins, a little more each floor; the finds in their slots
   become theirs and the slots empty; anyone not inside, or wrapped, gets nothing that floor.
   Gaps (how many coins, how much more each floor) get a default and an `OWNER.md` line.
2. Find where the gate shuts with who's aboard (grep "aboard" in `Elevators`, `Climbs`, `Trips`).
3. Pay through `Coins` (the count from S1-04), the numbers a pure rule with Lune specs.
4. Keeping: a pure `Carry.keep(c, isFind)` (takes the finds out, leaves the tools; specs) and
   `Slots:keep(player)` returning the kept find keys; hand them to what S1-01 saves (`Save`'s
   "finds you keep"; `Saving`).
5. Every pay and every kept find answers on screen: coins fly to the count (CoinView), each kept
   find leaves its slot with motion and sound. No text that explains a rule.
6. Studio Play: carry a find aboard, ride; say exactly what you saw (coins, the slot emptying,
   the saved finds).
**Acceptance:** checks green; specs prove pay and keeping; seen in Play (say what).
**Read first:** ROADMAP S1-06; GDD "When the gate shuts"; `src/server/Coins.luau`;
`src/server/Slots.luau` (`carried`, `spend`); `src/shared/Save.luau`; the file where the gate shuts.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-06 (next), then S1-02 Recording (Brix ENG-12a and 12b landed in `../engine` `6717740`;
   adopt as S1-01 adopted Saves). S2-06 and L-08e3c wait on `OWNER.md`. Lobby polish waits.
2. Found S1-05: the finds' new places in your view (moved after one look) are unseen in Play; a
   find standing in a unit can be walked through (inert, as a lying tool; polish list).
3. Found S1-04b2: keepers move on their own map and don't know about stuff, so one could walk
   through it; the heap's front reaches 7.2 into an M unit, inside where a keeper may stand to
   search it (up to 8.6). A player can likely jump onto the heap or column. Untested in Play.
4. Found S1-04b1: the stacks' boxes all wear the same few marker words (polish list).
5. Found S1-01: arriving on another server, the save claim may wait up to 5 s if the lobby's
   let-go lands after you. If too slow, a Brix ticket in neutral terms.
6. Found S1-03: Deal's padlock count is a share of the units; S1-07 sets padlocks afresh.
7. Found L-08e3b: a lobby car's `far` isn't cleared when its group's trip fails; it ages out.
8. Found L-08e4b1: no PlayerModule in PlayerScripts in Play, so WatchView's `controls` lookup
   fails quietly (untested).
9. Seen (owner, Nov 12, "fix them later"): lobby car floors splotchy inside; a sawn side or top
   flashes see-through as its panel drops; the lobby car's lamp very dim.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
