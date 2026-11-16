# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-15, session 206 (a find's press, its rules) · **Checks:** green · **Git:** `main`, committed, not pushed (`origin` is github.com/drftware/storage).

## State
- F-G1b split in three (ROADMAP). F-G1b1 done (D-229): `Finds/Use.luau`, pure and tested
  (tests/finduse.spec, 87 checks), holds every press: the tea light, oil lamp, glow sticks,
  fairy lights, lantern, hard hat, firefly jar, disco ball and jack-in-the-box. Nothing in the
  game reads it yet: no find has a press button until F-G1b2. Not seen in Studio.
- S4-01b's floors (more doors, Big floors, locked notes) seen in Play last session; not by a
  player on a high floor, two players or a phone (`OWNER.md`).
- Studio holds doubled modules, `FloorRules` too (STUDIO.md, OWNER.md).
- Find art (`art/finds/WAVES.md`): chattering teeth built, not imported; next the walking robot.

## Next task: F-G1b2 The press in the game
The moment: you take a lantern, press Switch, it clicks on and lights the hall; your friend sees
it light in your hand; you drop it lit and it stays lit on the floor. The jack cranks its tune
for 9 s, bangs open, and monsters come to look.
1. Catalog: `built()` takes an optional `verb`; give each of `Use.Rows`' finds its row's verb
   (HornView shows its round button for any row with a verb and routes the press to
   `presses[key]`, `src/client/init.client.luau` line ~133, then fires `ToolUse`).
2. Server `src/server/FindUses.luau`, a system like `Horns.luau` (89 lines, read it whole): on
   `slots.used` for a key in `Use.Rows`, `Use.Gap` per player, then `Use.press` against the
   model's stamp; set attributes on `use.model` (the same model moves hand ↔ floor, so they
   stay): state, `at` = `Workspace:GetServerTimeNow()`, left; tag it (CollectionService) for
   the clients. Motion lengths: `Finds.art(row.template).Motions[m].Duration`. The jack's bang:
   `task.delay(Use.noiseAt(...))`, then if the stamp is unchanged, `keepers:hearHorn(at)` at the
   model's pivot. Register it where Horns is registered.
3. `Finds/init.luau`: add `Finds.joints(model, name, values, scale)`: like `pose` but never
   moves a part (a held find is in a character's assembly; setting a part's CFrame would drag
   the player): work each part's place in the find's frame from its `FindDrawn` attributes and
   `Pose.solve`, positions and sizes times `scale` (your view's copy is `ScaleTo(Hands.Scale)`),
   then each Motor6D's C0 = place(Part0)⁻¹ · place(Part1); then the glow and lights, as `pose`
   does (pull that part out into a shared local function).
4. Client `src/client/FindUseView.luau`: for each tagged model, `Use.frame` from its attributes
   and the server clock, `Pose.at(motion, t, Finds.rest(key))`, then `Finds.joints`. Step only
   models whose frame moves (a held lit lantern holds still: pose it once per change); a step's
   `sound` plays at the model as its step number changes, never on first sight. Your own: the
   real model is `character:FindFirstChild(Tools.HeldName)`; mirror its frame onto your view's
   copy (add `model: () -> (Model?, string)` to ToolView's `Hand`, returning `shownModel`,
   `shownKey`); answer your press at once with a predicted stamp until the server's lands.
   Real lights: only the 2 nearest lit finds to the camera (UnitLight's `NearBulbs` idea), and
   your view's copy lights instead of your real one. Hide the button when `Use.press` says nil.
5. Sounds: switches use the torch click (in the rows); the jack's music box (9117044359) wants
   timing against `Wind`; pick a match strike (tea light, oil lamp), a snap (glow stick), a lid
   and shimmer (jar), a motor hum (disco ball), a spring bang (the Pop) from Pro Sound Effects
   (`search_asset` with `verifiedCreatorsOnly`, query ending "SFX"; each search ~2.5k tokens).
6. Studio: `DevFloorNumber` 1, take a lantern and the jack (D-203's recipe), press each, read
   Output; check `hearHorn` fires at the jack's pop.
**Acceptance:** checks green; each pressed find plays its motions, light and sound in Studio
Play; a press is validated and rate-limited on the server; a dropped lit lantern stays lit;
`OWNER.md` says how to try each (numbered steps).
**Read first:** `src/shared/Finds/Use.luau`; `src/server/Horns.luau`; `src/client/HornView.luau`
lines 100-125, 175-250; `src/shared/Finds/init.luau` (`pose`); `src/shared/Finds/Pose.luau`.

## Queue (next sessions, the owner's ticket order)
1. **F-G1b3** (the monkey's lure, the cars, found lights hold a Mannequin), then **S3-05a, then
   S3-05b: caught players each in an empty unit of their own** (the owner's playtest bugs, Nov
   15), before the run ends. Then S4-02 to S4-05 (5 coins a trapped monster, D-188).
2. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
3. A Studio hook to catch yourself for real (CatchTest finds no keeper even after WakeSleepers
   and 24 s, Nov 15; a Workspace attribute that catches by the nearest sleeper would do).
4. B-05b2b polish: a guard's box hides round the bend. L-08e3c, L-14b2d wait; R-01 later.
5. Small: the shop's polish (ROADMAP S3-04b); Free Everyone's swap sound; Free a Friend's pills
   don't follow the map off screen; coin count and corner map up while wrapped;
   "rbxassetid://203785492 failed"; `ConfigService: Config value not found` (the `sell*`
   switches); "Stand one" never shows from the MCP; two-player reveal/coins/notes; a dropped find
   bumps a walker (D-182); rbxassethash warnings; Packrat's dead Slots entry; Mannequin pose onto
   `Rig.luau` (D-176); the watch bar's empty panel; S1-07a, S2-02b-d4, S2-03b, S2-05a, S2-07a1-b2
   leftovers; S1-10d1-3; box words (D-215); the save's "best floor" still reads 0 after a ride.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
