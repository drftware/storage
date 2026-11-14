# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 148 (S2-04b, D-160) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **A wrong code calls every monster on the floor (S2-04b, D-160).** `Keeper.alarm`: every
  keeper awake on the alarm's floor hears it however far, as Left 4 Dead's car alarm calls the
  horde; loose, it walks to the keypad, looks round, roams; shut in, it comes once out; one
  chasing a player it sees keeps chasing; a sleeper wakes only within 400 studs.
- **Nothing pulls them off it.** Found in Play: a freed sleeper's first blow (1.2 s) and the
  rolling doors' opens drew monsters to those doors instead. Now a keeper behind a door the alarm
  picked stands quiet (`Keeper.hush`) and the opens of doors it rolls up aren't heard (`rolling`
  in `Keepers`). Output: one line a wrong code, with how many turn now and how many once out.
- **Verified in Studio Play** on the dev floor (seed 7): wrong code 1 freed 338's Mannequin; it
  came, looked, roamed off; at 127 studs off, wrong code 2 freed 307, 335, 327. Output said "1
  monsters turn for the keypad, 3 more once out"; no bangs, no door opens heard; all four walked
  to the keypad (the far one 142 to 12 studs). No warnings or errors besides the known texture
  lines. Studio left in Edit. Not watched on screen or heard (in `OWNER.md`).

## Next task: S1-10d1 The vending machine's menu
The owner's words are verbatim in ROADMAP S1-10d ("it's difficult to see what's available ...
you click a prompt that opens an overlay where you can make your selection. Then you can still
see it animate and drop out of the vending machine as-is."), and "make me fucking proud".
The moment: you walk up in a crowded car, press one button, and every bay is there on your
screen with its picture and price; you tap one and watch it drop from the real machine.
1. Read ROADMAP S1-10d and S1-10d1. Today each bay has its own Buy prompt (`Machines`, grep
   `prompts`, `"Buy"`); the server's buy checks (`Machine.Buy`, D-148) stay as they are.
2. Replace the per-bay prompts with one prompt on the machine (one verb). Pressing it opens a
   phone-first panel: every bay in the machine's order, each with its thing's picture (rendered
   like the coin count's coin, `CoinView`/`ToolPicture`), name, price, and lit / sold out / too
   few coins shown, never explained.
3. Tapping a bay fires the same `MachineBuy` remote as today; the panel gets out of the way so
   the coins, coil and drop play as now (`MachineVend`). It closes when you walk off, the ride
   ends or you're caught; each friend opens their own. Every press answers with motion and sound.
4. Verify in Studio Play: ride a car, open the panel, buy; judge it at phone size.
**Acceptance:** checks green; one prompt per machine; the panel shows every bay correctly and
buys through the unchanged server path; closes on its own; Output clean but the known lines.
**Read first:** ROADMAP S1-10d and S1-10d1; DECISIONS D-148, D-149; `src/server/Machines.luau`
(grep `prompts`, `Buy`); `src/client/MachineVend.luau`; `src/client/ToolPicture.luau`;
the roblox-dev:roblox-ui skill.

## Queue (next sessions per ROADMAP Phase 2)
1. S1-10d1 (next), S1-10d2 (a shallower machine, art the unit's way), then S2-04c (the hall
   lights go out for the alarm; today they all come on and freed Mannequins freeze about 4 s),
   then S2-05. S2-06 and L-08e3c wait on `OWNER.md`. R-01 is for later.
2. Found S2-04b: monsters called to one spot (the keypad, a door) all go to the same point and
   nothing keeps them apart, so four may stand inside each other at the keypad (inferred from
   distances, not seen). Spreading them round the spot is a small brain change worth a ticket.
3. Found S2-04a: Output's `ContentId: rbxassetid://89260803894903 ... No asset content
   representation found` ×27 as a dealt unit rolled up; not in the repo, cause unfound.
4. Found S2-03b: loose keepers hear a pounding door and go to look (felt as a feature; watch
   it). Deals' Studio line for a woken unit says "asleep" though it stands awake: Output only.
5. Found S2-03a: waves can exceed `Deal.awakeCap`; `Waking.AwakeMost` (six) bounds it.
6. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. S2-02b: nobody can throw the breaker by hand (S2-06 may need it).
7. Found S1-12: no saved cash total shows yet; a climb left mid-way makes no cash (D-151).
   S1-11: a friend's beam doesn't show the mark. S1-10c2a: Output's `203785492` (wrong type) and
   texture permission errors, unchecked whether any are the machine's.
8. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept player's
   torch drains if left on; S1-07a 16 in 100 units hold nothing (owner's call); unseen: S1-06 a
   kept find's save, S1-05 a find can be walked through, S1-04b2 keepers don't know about stuff.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
