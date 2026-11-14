# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-14, session 158 (planning only: the owner chose the second monster) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- No game code changed. The owner dropped the silent monster that moved only in the light
  ("there isn't a way to stop it") and chose the Packrat in its place (D-167): it carries
  finds to its own unit, takes your best find if it reaches you, and wraps you only if your
  slots are empty. The GDD's section is rewritten ("The Packrat collects things, not people").
- S2-06 no longer waits on the owner and is split into five sessions (S2-06a to S2-06e: its
  art, carrying finds home, taking from you, its pile and trapping it, its sounds).
- The camera feed's two fixes from the owner's play are still next (S2-02d4).
- The order ahead (ROADMAP): S2-02d4, S2-05, S2-07a, S2-07b, S2-06a to S2-06e, then Step 3
  (S3-01 to S3-04) and Step 4 (S4-01 on).

## Next task: S2-02d4 The owner's two feed fixes
ROADMAP S2-02d4 (the owner's words are there). The moment: the camera only ever shows a floor
you're still on, and it cuts in and out on plain TV static.
1. **No feed once you've left.** A floor keeps a flag for each player who has left it, set the
   instant its gate shuts with them aboard (`Climbs.shut` names the riders and the floor; grep
   `shut:` in `src/server/Climbs.luau`). `watchers` in `src/server/Keepers.luau` skips them
   (today it picks by position: within 40 studs up or down and over the plan, so a rider
   climbing out passes). A feed already showing to them closes for them that moment: add a
   per-player close to `Feeds` (it keeps who watches each open feed in `open`), static and the
   map back. A Mannequin stops starting errands on a floor nobody is on (`Breaker.errand`'s
   caller in Keepers). Lune spec first if any of it is pure.
2. **Plain static in and out.** Swap `Feed.InSound` and `Feed.OutSound` (`src/shared/Feed.luau`)
   for plain TV static, two different clips, short and hard-edged, timed to `Feed.SnowIn`
   (0.22 s) and `Feed.SnowOut` (0.4 s) with a short tail. Free on the Creator Store (Pro Sound
   Effects first). The quiet bed and the clunk stay (default in `OWNER.md`). Each id must load
   in Play with no permission line in Output; prime them as now (`SoundPrimer`).
3. A feed that starts while the map is still sliding in takes the map's place as it lands
   (`mapWindow` in `src/client/FeedView.luau`).
4. Verify in Play: count `RenderStepped` first and keep the display awake (STUDIO.md "Getting
   frames back"); send a Mannequin to the box with you on floor 3 (`SendToBreaker`), then
   again just after your car's gate shuts. Output clean.
**Acceptance:** checks green; in Play the feed shows on the floor and not to a rider whose gate
has shut; one already up when the gate shuts cuts out; the new static plays in and out.
**Read first:** ROADMAP S2-02d4; `src/server/Keepers.luau` (grep "watchers", "errandFeed");
`src/server/Feeds.luau`; `src/server/Climbs.luau` (grep "shut"); `src/shared/Feed.luau`;
`docs/STUDIO.md` (grep "Getting frames back").

## Queue (next sessions per ROADMAP Phase 2)
1. S2-02d4 (next), S2-05 (the tap when you shut a door on a sleeper; likely two sessions),
   S2-07a, S2-07b, then the Packrat (S2-06a its art first). L-08e3c and L-14b2d wait on
   `OWNER.md`. R-01 is for later.
2. Brix has no purchases piece in its ROADMAP yet. S3-02 needs one: before Step 3, file it in
   Brix's ROADMAP in neutral terms (receipts granted after the profile saves, prices read from
   Roblox, offers switched off live) so Brix can build it in its own sessions.
3. S4-04 "Trapping pays" (a quarter more pay per trapped monster) was never agreed by the
   owner (`OWNER.md` asks); don't build it until they say yes.
4. Left in the Queue, not in S2-07: S1-07a 16 in 100 units hold nothing (may be right);
   S2-02c only a wandering Mannequin takes the errand; S2-02b nobody can throw the breaker by
   hand (the Packrat doesn't need it); S2-03b loose keepers go to look at a pounding door (a feature).
5. Unseen with the menu really open: the wheel's slide, the dim bays with full slots, the menu
   staying down after a buy (S1-10d1 to d3, `OWNER.md`). Unseen: S1-06, S1-05.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
