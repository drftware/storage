# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-10, session 88 (overnight run, 3 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-07e done (D-100): the padlock.** Each keep has a clock on the server (`KeptPlayers`,
  `Kept.tick`): 150 s of your door being down (it stops while a friend has it up), the warning its
  last 20 s. Through the warning a hand works keys in a padlock at your door, closer and louder,
  "Padlock in 20" beats high on your screen and "Sam: padlock in 12" sits under friends' top bar
  (`PadlockView`); then `Doors:lock` padlocks it, the click jolts you with a low hit, and
  "Padlocked" stays until a friend's bolt cutters take it off. One padlock a keep; a padlock on
  stays on the empty unit. Studio's short clock: Workspace's `DevPadlockSeconds`.
- **Testing:** docs/STUDIO.md, "Testing the padlock from the MCP". Friends' lines need two
  players (the owner's, `OWNER.md`).
- Studio: nothing imported this session; left in Edit, seed 7, floor 1; `DevPadlockSeconds` is
  not set in Edit.

## Next task: L-06c1 A walk that frightens
The moment: you hear it before you see it, and what you see moves wrong. The owner, Nov 10
night: today's steps "sound like fucking pinnoccio walking around" (the light wooden clack has to
go) and getting caught "doesn't seem like a big deal" (that half is L-06c2). Heavy, wrong,
close-sounding steps, and silence that means danger. No new keepers: this is the Mannequin only.
1. Owner test results first, if pasted.
2. Read ROADMAP L-06c1 and D-083 (today's tell: a clack each step, joint knocks). Pick from the
   ticket's list, each with its precedent: a stiff, uneven gait, one foot dragged and the head
   lagging a beat behind the body (Doors' Figure, Silent Hill's mannequins); dead still, then a
   sudden fast, jerky rush across the gap (SCP-173, Doors' Seek); footfalls that get heavier the
   nearer it is, and a fibreglass creak as it turns.
3. Sound first (the owner's loudest note): find heavy footfalls in the library (Pro Sound Effects,
   `search_asset` Audio), measured as docs/STUDIO.md does (AudioPlayer to AudioAnalyzer, 50 ms
   bins, the spectrum for phone speakers); a body's weight on concrete, not wood. Footfalls
   nearer sound heavier (a curve in `KeeperTell`, Lune-tested), a creak on a turn, and silence
   while it stands still (the freeze stays dead quiet).
4. Poses and timing on each screen (`Mannequin.Pose`, `KeeperView`): the uneven gait, the dragged
   foot, the head's lag; the server's motion stays as it is (L-06b4's smoothing must survive).
5. Feel numbers in the shared modules they belong to (`KeeperTell`, `Mannequin.Pose`), each with
   a comment on what it does to the player; pure curves Lune-tested.
**Acceptance:** checks green; in Studio on seed 7, floor 1 (docs/STUDIO.md's "Testing a chase
from the MCP" and the keeper's tell recipes): the new steps measured playing at the body, heavier
nearer; the gait's poses captured (a clone posed by `Pose`, the halls lit as STUDIO.md says);
the freeze silent; no new allocation per frame in `KeeperView`'s step; Output clean.
**Read first:** ROADMAP L-06c1 and "The overnight run" paragraph; D-083 and D-039;
`src/client/KeeperSounds.luau`; `src/shared/KeeperTell.luau`; `src/shared/Mannequin/Pose.luau`;
docs/STUDIO.md's "Sounds measured for the keeper's tell".

## Queue (the next run's order, from ROADMAP)
1. L-06c2 the catch as a jump scare (its face rushes your camera with a sting, then the black).
2. L-08a the ride, L-08b the next floor, L-08c left behind, L-08d the climb ends. L-08e (the
   start, in the lobby) waits for the owner's lobby plan (Nov 11).
3. L-15 keepers hear the keypad, dropped tools, the saw, crawls, the ladder and drop-ins.
4. L-16a and L-16b, the fix pass before friends play; L-16c the roof crawl made smooth.
5. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
6. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
