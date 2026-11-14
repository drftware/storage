# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 124 (S1-04b2 Stuff dealt into units) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-04b2 is built** (D-136). Half the units with nothing to take (no coins, tool, find, keeper
  or note) show somebody's stuff as the door first lifts: an old mattress, a rolled rug, or a
  tower, wall, heap or column of boxes, pushed into a back corner, 0.4 off each wall. It's read
  from the unit's unused pick, so no seed's other draws move (`tests/stuffdeal.spec` holds every
  seed to a fingerprint from before). `DealSpot.stuff` keeps it wholly clear of the door's line,
  both crawl hole spots, the landing and the fallen panel, so the mattress leans on the back wall
  and a small unit fits only the rug. The stacks' sizes now count the open box's flaps and the
  boxes' bulge (`art/stuff/spec.py` `box_reach`; the heap had a flap in the back wall).
- **Seen in Studio Play** (seed 104 floor 3, opened by the player's Open prompt): 309 a heap,
  311 the mattress (looked at from the doorway: reads at once), 315 a wall of boxes, 329 a tower,
  small 332 the rug (drawn a column, which doesn't fit); every part ends at the back wall's 11.60
  and the side wall's 5.60. Studio left in Edit, `DevFloorSeed` back to 7; the place isn't saved
  by me (the owner saves as they go).
- Studio syncs (Rojo connected). Target only "Storage (placeId: 113250085204323)" by its
  `studio_id`; a Brix Studio may be open too.
- The GDD (D-127, D-128) is the newer word; ROADMAP Phase 2 is its build order.

## Next task: S1-05 Finds you carry
The moment: the door goes up on a boombox standing in the bulb's light, you tap it and it's
yours to carry, and now you have to get it to the gate.
1. Read ROADMAP S1-05 and the GDD on finds and slots (docs tools, search "slots"): one tap puts a
   find in one of your three slots beside your tools; slots full, drop something or leave it;
   caught, your finds drop with your tools. Gaps get a default and an `OWNER.md` line.
2. Build it on the tools' slots, not beside them: `Tools/Carry` (pure: take, drop) learns a find
   as a slot item; `Slots` gives a find laid by `Deals` its one-verb prompt ("Take") and moves
   it, held, dropped and on a catch (`dropAll`), as it does tools. Check whether a find is a big
   thing (both hands, slower, as the ladder is) before choosing how it's held.
3. The slot bar (`ToolView`) shows a find in its slot; every take, drop and refusal answers with
   motion and sound in the same ticket.
4. Lune specs: a find takes a slot, full slots refuse it, a catch drops finds with tools.
5. Studio Play: take a find, see it in a slot, drop it, get caught; say exactly what you saw.
**Acceptance:** checks green; specs prove the slot rules; seen in Play (say exactly what).
**Read first:** ROADMAP S1-05; GDD "slots"; `src/shared/Tools/Carry.luau`;
`src/server/Slots.luau` (lay, pick up, `dropAll`); `src/server/Deals.luau` (the Find branch of
`lay`); `src/client/ToolView.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-05 (next), then S1-06 Pay and keeping at the gate. S1-02 Recording can be built now (Brix
   ENG-12a and 12b landed in `../engine` `6717740`; adopt as S1-01 adopted Saves). S2-06 and
   L-08e3c wait on `OWNER.md`. Lobby polish waits.
2. Found S1-04b2: keepers move on their own map and don't know about stuff, so one could walk
   through it; the heap's front reaches 7.2 into an M unit, inside where a keeper may stand to
   search it (up to 8.6). A player can likely jump onto the heap or column (4.0, 4.4 tall); and
   stuff may block a keeper's sight (it's queryable). All untested in Play.
3. Found S1-04b1: the stacks' boxes all wear the same few marker words; more words, more stuff
   and a narrow thing for small units are in ROADMAP's polish list.
4. Found S1-01: arriving on another server, the save claim may wait up to 5 s if the lobby's
   let-go lands after you (Brix retries a held claim every 5 s). If too slow once saved cash
   shows, a Brix ticket in neutral terms: retry sooner after a hold being let go.
5. Found S1-03: Deal's padlock count is a share of the units, so floors get about half as many
   padlocks. S1-07 sets padlocks afresh.
6. Found L-08e3b: a lobby car's `far` isn't cleared when its group's trip fails; it ages out.
7. Found L-08e4b1: no PlayerModule in PlayerScripts in Play, so WatchView's `controls` lookup
   fails quietly (controls may stay on while you watch; untested).
8. Seen (owner, Nov 12, "fix them later"): lobby car floors splotchy inside; a sawn side or top
   flashes see-through as its panel drops; the lobby car's lamp very dim.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
