# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 149 (S1-10d1, D-161) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **The machine has a menu (S1-10d1, D-161).** One "Buy" on the middle of its glass (8 studs,
  no line of sight, for riders while the bottom row is lit) opens MachineMenu: the machine's own
  front rising from the screen's foot, its rows lit in step with the real tubes, each bay's
  picture, paper label, LED price and chrome button, states from the pure `Buy.tile`. A pick
  sinks the real button (MachineView's `Pick`) and goes up the new `Buy.Pick` remote; the panel
  drops away for the vend and rises after. The six per-bay prompts and the server's per-frame
  arming are gone.
- **Verified in Studio Play, server side only:** six malformed picks sold nothing; a real pick
  sold the saw (12 coins to 4), rewrote the stock, stamped `Bought`, told the buyer's screen; a
  pick short of coins was refused. **The panel itself is unseen:** Studio drew no frames
  (RenderStepped 0 a second, screen capture timed out), so no client system stepped. Its look,
  motion and sounds are in `OWNER.md`. Studio left in Edit.

## Next task: S1-10d2 A shallower machine
The owner's words (ROADMAP S1-10d): "I think we shrink the depth of the vending machine a bit".
The moment: a full car of friends fits round it, and the vend still reads: the coil turns, the
thing drops behind the flap and flies out.
1. Read ROADMAP S1-10d2 and `art/unit/README.md` (how art is made). In `art/machine/spec.py`
   make it about a third less deep (the owner's "a bit"): the cabinet's depth, the bays' and
   coils' depth (a coil holds fewer loops, so check `Stock.MaxCount` and how many things stand
   in a coil, `MachineStock`), keeping the face (glass, rails, flap, slot) where it is so the
   menu's button point (`Buy.point`, on the glass) still sits on it.
2. Rebuild with `scripts/art.sh machine`; check the look sheets; re-upload and prepare it
   (STUDIO.md "Importing kit pieces"); the generated `Specs` updates itself.
3. Check what reads the depth: `MachineVend` (`FALL_Z`, `REST_Y`, `BIN_X`), `MachineStock`
   (`stand`), `Specs.InCar` (it stands against the back wall: its front moves back toward it).
4. Verify in Studio Play: stage a ride (STUDIO.md "Staging the machine's stock") and a buy; first
   check the Client's RenderStepped fires (STUDIO.md "The machine's menu"); judge at phone size.
**Acceptance:** checks green; the machine about a third shallower; stock, vend and flight still
land right; the menu still opens from its glass; Output clean but the known lines.
**Read first:** ROADMAP S1-10d2; `art/unit/README.md`; `art/machine/spec.py`; STUDIO.md
"Importing kit pieces"; `src/client/MachineVend.luau` (top constants); `src/client/MachineStock.luau`.

## Queue (next sessions per ROADMAP Phase 2)
1. S1-10d2 (next), then S2-04c (the hall lights go out for the alarm; today they all come on and
   freed Mannequins freeze about 4 s), then S2-05. S2-06 and L-08e3c wait on `OWNER.md`. R-01 is
   for later.
2. Found S1-10d1: a tool pick with every slot full presses and clicks, then nothing (the server
   refuses quietly, the menu stays up). Show it on the bay instead (dim, like a full torch's
   battery) once the client knows the slots are full.
3. Found S2-04b: monsters called to one spot (the keypad, a door) all go to the same point and
   nothing keeps them apart, so four may stand inside each other at the keypad (inferred from
   distances, not seen). Spreading them round the spot is a small brain change worth a ticket.
4. Found S2-04a: Output's `ContentId: rbxassetid://89260803894903 ... No asset content
   representation found` ×27 as a dealt unit rolled up; not in the repo, cause unfound.
5. Found S2-03b: loose keepers hear a pounding door and go to look (felt as a feature; watch
   it). Deals' Studio line for a woken unit says "asleep" though it stands awake: Output only.
6. Found S2-03a: waves can exceed `Deal.awakeCap`; `Waking.AwakeMost` (six) bounds it.
7. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. S2-02b: nobody can throw the breaker by hand (S2-06 may need it).
8. Found S1-12: no saved cash total shows yet; a climb left mid-way makes no cash (D-151).
   S1-11: a friend's beam doesn't show the mark. S1-10c2a: Output's `203785492` (wrong type) and
   texture permission errors, unchecked whether any are the machine's.
9. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept player's
   torch drains if left on; S1-07a 16 in 100 units hold nothing (owner's call); unseen: S1-06 a
   kept find's save, S1-05 a find can be walked through, S1-04b2 keepers don't know about stuff.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
