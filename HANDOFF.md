# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-11, session 93 (overnight run, 8 of up to 15) · **Checks:** green ·
**Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- **L-08c done (D-105): left behind.** As the car leaves with someone aboard, everyone else on the
  floor is out of the climb (`Watching` on the server, `Left` pure, `WatchView` on screen): "Left
  behind" in red with the clang, the bars over the HUD, the lamp drawing away and the motor fading
  above, a low hit and the controls gone as the light goes, black before the floor is cleared,
  the bell far above, then the black lifts behind a friend as their gate opens. Their character
  goes; they watch over a friend's shoulder (smoothed, pulled off walls, drag to orbit), switch
  with the arrows, and Cut Free (Studio only until the product exists) puts them in the friends'
  lobby. Nobody left to watch lets everyone back in (L-08d replaces that). GateClock no longer
  shows its own "Left behind".
- Verified in Studio on seed 7 with stand-in friends (STUDIO.md, "Testing left behind from the
  MCP"). Two players, a phone, kept-and-left: `OWNER.md`. After the Studio runs, the arrows'
  press pop was rewritten to allocate nothing a frame: passes checks, untested in Studio.
- Studio: nothing imported; left in Edit, seed 7, floor 1; `DevRideHold` unset; quality back on
  Automatic. A `caffeinate -u` timer (about 40 min) ends on its own.

## Next task: L-08d The climb ends
The moment: the last friend is kept or left and it's over, or the team reaches the top; one
screen says how far you got, and one button, "Again", starts the next climb, as DOORS' Play
Again does (Gate 1 is friends asking for another run).
1. Owner test results first, if pasted.
2. Read ROADMAP L-08d (its hand-off notes), then the GDD's "Whole team kept" and "Left behind"
   (docs tools, not WebFetch). Check `docs/FRAMEWORK.md` (ENG-13, the round loop) first.
3. The end: nobody left climbing (all kept or watching: `Watching:isOut`, `Kept.Attribute`), or
   the car leaving the stand-in top (floor 3, a default with an `OWNER.md` line). Replace
   `Climbs`' `comeBack` for the top and `Watching`'s "Alone" let-in with it.
4. The results screen on every player's screen: the floor reached, the time, few words; one
   "Again" button that starts a new climb from floor 1 (`Climbs:begin`, everyone given a fresh
   character in its lobby). Every action answers: motion, sound, short copy.
5. The GDD's Missing board is in the lobby: no lobby work (it waits for the owner's plan). Put
   the board, and where "Again" should really take you, in `OWNER.md`.
6. No new keepers. Phone first: the screen and its button at phone size.
**Acceptance:** checks green; in Studio with stand-ins (STUDIO.md's recipes): the team gone ends
the climb with the screen; reaching floor 3's top ends it; "Again" starts floor 1 afresh with
everyone in its lobby; Output clean. Two-player feel goes to `OWNER.md`.
**Read first:** ROADMAP L-08d; the GDD's "Whole team kept"; D-105; `src/server/Climbs.luau`
(`comeBack`, `departed`, `begin`); `src/server/Watching.luau` (`check`, `letIn`); `src/shared/Climb.luau`.

## Queue (the next run's order, from ROADMAP)
1. L-08e (the start, in the lobby) waits for the owner's lobby plan (Nov 11).
2. L-15 keepers hear the keypad, dropped tools, the saw, crawls, the ladder and drop-ins.
3. L-16a and L-16b, the fix pass before friends play; L-16c the roof crawl made smooth.
4. L-17 every button on a phone at once; L-18 the art saved with the code (optional).
5. L-09a the first run with friends, floors 1 to 3. L-14b2d only if the owner asks.
6. Seen: a ladder stood on a floor when it's cleared should go with it (untested); anyone still
   in the car 6 s after it opens is shut in (`OWNER.md`'s L-08a decision 2); watching a friend
   ride doesn't draw their shaft (ROADMAP polish).

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
