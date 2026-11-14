# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 130 (S1-09 The flashlight runs down) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **S1-09 built (D-142):** the charge is the server's, per player, in seconds (`Flashlights`,
  pure `Charge`, `tests/charge.spec.luau`): five minutes, drains only while lit in a hand, full at
  `Climbs.began`, whole seconds on the Player (`Charge` attribute). Dead, it goes out (a
  Mannequin is let go) and a switch on is refused. `Flashlights:fill(player)` is ready for
  batteries (false when full, so the battery stays for a friend).
- **On screen (`FlashlightView`):** a ring of 12 ticks inside the button (bottom right on a
  keyboard or gamepad), red and breathing for the last half minute. The flicker (`Charge.glow`):
  a long first stutter, then closer, darker ones with a bulb's buzz; the light sags and browns,
  dies to nothing, clicks off by itself. A dead press: soft click, dip, wobble, dull glyph.
  Friends' dying torches flicker and buzz the same way (untested with two players).
- **Seen in Studio Play** (a 40 s torch via `DevTorchSeconds`): the flicker from 30 s with the
  buzz in each stutter, the light 2.4 down to about 1.4, out at 0 with the server's `On` false,
  the ring red and dropping a tick at a time, the dead press (0.55 click, -10° wobble, stays off).
  Not seen: the climb-start fill, two players. Owner steps in OWNER.md.
- S1-08's break still unseen (needs three padlock cuts with cutters the MCP can't pick up).
- Studio left in Edit, `DevFloorSeed` 7, `DevTorchSeconds` removed.

## Next task: S1-07b Batteries in units
The moment: your beam is stuttering, you lift a door, and there's a battery on the floor; one
tap and your light snaps back full with the ring sweeping round. If yours is full, it stays there
for the friend whose torch is dying.
1. Read ROADMAP S1-07b, the GDD (docs tools, search "battery"), OWNER.md "The flashlight's
   details" (about one unit in ten; takes no slot; full torch leaves it).
2. The battery is art first, the unit's way (`art/unit/README.md`; copy the smallest prop
   script, e.g. `art/coin/` or `art/padlock/`): a chunky D-cell, readable at phone size. If the
   art alone fills the session, split S1-07b in ROADMAP (art, then dealing and pickup) first.
3. Deal it into about one unit in ten (`Deal.luau`, alongside coins and finds; the server lays
   it as the door first lifts, as `Coins` lays a pile). One tap takes it: the server checks reach
   and rate, calls `Flashlights:fill`; refused when full (the battery stays, no text).
4. Every action answers: a snap-in sound and the ring sweeping full on your screen (it already
   sweeps on a fill); a friend hears it. Record the pickup (`Record`, S1-02) if it fits.
5. Studio Play: open units until one holds a battery, take it with a dying torch.
**Acceptance:** checks green; dealing proven in a spec; a battery taken and the torch full in Play.
**Read first:** ROADMAP S1-07b; GDD (search "battery"); `art/unit/README.md`;
`src/shared/Deal.luau`; `src/server/Coins.luau` (a laid pickup); `src/server/Flashlights.luau`.

## Queue (the overnight run, owner Nov 13: sessions until 8:30am, the updated plan)
1. S1-07b (next), then ROADMAP Phase 2 in order (S1-10 machine, S1-11, S1-12, then Step 2).
   S2-06 and L-08e3c wait on `OWNER.md`. Lobby polish waits.
2. Found S1-09: a kept (caught) player's torch keeps draining if they left it on; probably right.
   The first-person torch looks large on a wide desktop view (pre-existing; judge on a phone).
3. Found S1-08: broken-piece art and a strained creak on the use that leaves one (ROADMAP).
4. Found S1-07a: about 16 in 100 units hold nothing at all (the GDD says 3 in 10 without coins
   hold nothing to take). Owner's call; not changed.
5. Found S1-02: in Studio the test hall begins a climb on floor 3 as the server starts.
6. Found S1-06: a kept find's save write and the friends' spark are unseen in Play.
7. Found S1-05: a find standing in a unit can be walked through (polish list).
8. Found S1-04b2: keepers don't know about stuff, so one could walk through it.
9. Found S1-01: arriving on another server, the save claim may wait up to 5 s.
10. Found L-08e3b/L-08e4b1: a failed lobby car trip's `far` ages out; WatchView's `controls`
   lookup fails quietly. Owner Nov 12 "fix them later": lobby car floors splotchy, a sawn panel
   flashes see-through, the lobby car's lamp very dim.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
