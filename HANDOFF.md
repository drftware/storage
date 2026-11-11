# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 86 (overnight run, 1 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-14e done (D-098): every tool unit holds a tool.** The cut blanket and glow sticks are out
  of `Deal`; the bag is the six built tools, nine to a bag. `tests/carry.spec` fails if the deal
  ever hands out a tool without its catalog row and Specs. The guarded note is now drawn before
  the bag, so changing the bag never moves a seed's guard (`tests/guard.spec` checks): seed 7,
  floor 1's awake Mannequin is still in **Unit 157**, and every recipe naming it still holds.
- **`lune run scripts/floor-deal <seed> <floor>` now deals what Studio deals** (it seeded its
  own Random before) and names the guarded note. Verified in Play on seed 7, floor 1: 26 units
  dealt door for door as printed, every tool laid. Only which tool lands where depends on the
  order doors first lift.
- **Overnight run (owner, Nov 10 night):** ROADMAP's "The overnight run" paragraph. No lobby
  (L-08e waits for the owner's plan on Nov 11), no new keepers; the Mannequin can get scarier.
- Studio: nothing imported this session; left in Edit, seed 7, floor 1.

## Next task: L-07d Cut free
The moment: you're wrapped in the dark, the door goes up, a friend kneels and tears the film off
you, and you're back on your feet. Today opening the door lets you out (L-07a's stand-in).
1. Owner test results first, if pasted.
2. Pure rules in `Kept` (Lune-tested): the hold (1 s), who may cut (alive, not kept, within
   reach of the kept player, the unit's door all the way up), what counts as in reach.
3. Server (`KeptPlayers`): a "Cut free" prompt (`Prompts.make`, hold 1 s) on the kept player,
   shown only while their door is all the way up; its trigger checked on the server against
   those rules lets them go. Remove the stand-in: the door going up no longer lets you out.
4. Feedback in the same ticket: the film tears (a measured tape-rip sound, found the way
   `KeptSqueal`'s was, played at the body for everyone near), the wrap comes off over a beat,
   not a vanish; the freed player's view kicks as they're let go, the cutter's a little too.
5. The kept player sees nothing of a friend's hold beyond the sound. Check the prompt at phone
   size beside the door's own buttons: no overlap.
6. Heads-up: Studio's Play from the MCP is one player, who can't cut themselves free. Check
   the refusals there and plan how to see a valid cut (the owner's Team Test goes in OWNER.md).
**Acceptance:** checks green; in Studio on seed 7, floor 1 (get kept: stand at (47, 3, -632)
facing 157, tap Open; docs/STUDIO.md's "Testing getting kept from the MCP"): opening your unit
no longer lets you out; Cut free shows only with the door all the way up; a trigger from a kept
player or from too far is refused (Output); a valid one lets you out, the film gone with its
sound; Output clean.
**Read first:** ROADMAP L-07d; D-095 and D-097; `src/server/KeptPlayers.luau`;
`src/server/Prompts.luau`; `src/client/KeptSqueal.luau`; docs/STUDIO.md's "Testing getting
kept from the MCP".

## Queue (the next run's order, from ROADMAP)
1. L-07e the padlock (a warning before it locks).
2. L-06c1 a walk that frightens (the owner: today's steps sound like Pinocchio), L-06c2 the
   catch as a jump scare.
3. L-08a the ride, L-08b the next floor, L-08c left behind, L-08d the climb ends. L-08e (the
   start, in the lobby) waits for the owner.
4. L-15 keepers hear the keypad, dropped tools, the saw, crawls, the ladder and drop-ins.
5. L-16a and L-16b, the fix pass before friends play; L-16c the roof crawl made smooth.
6. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
7. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
