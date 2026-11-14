# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 147 (S2-04a, D-159) ·
**Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **A wrong code lets monsters out (S2-04a, D-159).** Each wrong code on a floor rolls up 1,
  then 3, then 5 units holding a monster, by themselves (`WrongCode`): sleepers first, then
  monsters awake behind shut doors, never a padlocked door; the doors roll one after another
  from 1.2 s, the slow, loud open. The keypad stays dead 3.5, 7, then 14 s (`Keypad.dead`,
  counted per floor from `arm`), its bell striking again every 3.5 s. A freed sleeper is stood
  before the alarm is heard, so it comes for the keypad. The picking lives in `Keepers` `letOut`.
- **Waking clock bug fixed:** a floor's clock starts only for feet inside its reach
  (`Climb.stands`), no longer as the floor above is laid level with this one.
- **Verified in Studio Play** on the dev floor (seed 7): standing at spawn no longer starts floor
  3's clock; wrong code 1 rolled up Unit 338 and its Mannequin came and caught the player; in a
  second Play, codes 1 to 3 rolled 338, then 307, 327, 335, then nothing (only padlocked 305 left),
  the keypad dead 3.49, 7.01, 14.02 s. Output one line a wrong code. Studio left in Edit. Not
  heard: the bell's strikes and the doors (in `OWNER.md`).

## Next task: S2-04b Every loose monster heads for the keypad
The moment: the alarm screams and every monster on the floor, near or far, turns for the keypad
you're standing at.
1. Read ROADMAP S2-04b. Today only keepers within the alarm's 400 studs of hall hear it
   (`Keypad.Heard.Wrong`, `hearAt`); a trapped one that heard goes there once out (`heardOut`).
2. On a wrong code, send every keeper loose on that floor to the keypad, wherever it is. Prefer a
   pure function on `Keeper` (like `heardAt`, but with no reach) with a Lune check. Pick a
   default for a keeper already chasing a player it can see (likely: it keeps chasing) and say it
   in DECISIONS and `OWNER.md`.
3. At the keypad it looks round the lobby (the existing "goes to look"), then roams again.
4. Output: one line per wrong code naming how many turned (not one per keeper).
5. Verify in Studio Play on the dev floor (code 2274, seed 7; see STUDIO.md "Testing a wrong
   code": pivot in, press four times, pivot back). Let one Mannequin loose first (a wrong code
   does it), walk it far off, then punch another: it turns for the keypad.
**Acceptance:** checks green; a spec for the pure part; in Play a far keeper heads for the
keypad on a wrong code; Output clean but the known lines; Studio left in Edit.
**Read first:** ROADMAP S2-04b; DECISIONS D-159; `src/server/Keepers.luau` (grep `letOut`,
`onKeypad`, `hearAt`, `heardIt`); `src/shared/Keeper.luau` (grep `function Keeper.heardAt`,
`function Keeper.lookOut`, `heardOut`); STUDIO.md "Testing a wrong code".

## Queue (next sessions per ROADMAP Phase 2)
1. S2-04b (next), S2-04c (the hall lights go out for the alarm; today they all come on and the
   freed Mannequins freeze), then S2-05. The morning run puts S1-10d1 and S1-10d2 (the vending
   machine) between S2-04b and S2-04c. S2-06 and L-08e3c wait on `OWNER.md`. R-01 is for later.
2. Found S2-04a: Output's `ContentId: rbxassetid://89260803894903 ... No asset content
   representation found` ×27 as a dealt unit rolled up; not in the repo, cause unfound.
   Keepers' "steps out to look" line also shows for a freed keeper that heard the alarm and goes
   straight for it (Output only).
3. Found S2-03b: loose keepers hear a pounding door and go to look (felt as a feature; watch
   it). Deals' Studio line for a woken unit says "asleep" though it stands awake: Output only.
4. Found S2-03a: with waves on, a floor can hold more loose keepers than `Deal.awakeCap`;
   `Waking.AwakeMost` (six) bounds it. Watch it on a phone.
5. Found S2-02c: only a wandering Mannequin takes the errand; one standing awake that has never
   been out (Watching) doesn't. S2-02b: nobody can throw the breaker by hand (S2-06 may need it).
6. Found S1-12: no saved cash total shows yet; a climb left mid-way makes no cash (D-151).
   S1-11: a friend's beam doesn't show the mark. S1-10c2a: Output's `203785492` (wrong type) and
   texture permission errors, unchecked whether any are the machine's.
7. Small: S1-07b coin piles and batteries show Take through a shut door; S1-09 a kept player's
   torch drains if left on; S1-07a 16 in 100 units hold nothing (owner's call); unseen: S1-06 a
   kept find's save, S1-05 a find can be walked through, S1-04b2 keepers don't know about stuff.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
