# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-06, session 9 · **Checks:** green · **Git:** `main`, local only (no remote).

## State
- **The hall is lit like the look sheets at full graphics quality** (P0-02d, done; D-015). A
  shared module, `HallLight`, holds the fixture's numbers: it hangs at 12.1 (2 over the wire tops),
  a 130° cone, cold white, one fixture every 24 studs. The test hall (`DevCorridor`) has a lit
  fixture over 105/106, a weaker one over 101/102, an exit sign glowing red on the far end wall, a
  ceiling at 13.4 and a lighter placeholder floor. Lighting gains `Grade`, a -0.15 desaturation.
  The place's own spawn pad no longer sits in the middle of the hall in Play.
- **Verified in Studio** (Play, Level21): sheet-versus-Studio side by sides in
  `docs/art/P0-02d-hall.jpg`, `-hero.jpg` and `-inside.jpg`; the shut unit is black inside with
  the line of light under the door.
- **The big finding:** the flat, near-white look D-012 described was Studio on Automatic graphics
  quality, which falls back to coarse lighting below about Level11: lights ignore their cone and
  shine through thin walls (`docs/art/P0-02d-hall-low-quality.jpg`; docs/STUDIO.md, "Lighting and
  captures"). Low-graphics phones get the same. That's the next ticket.
- **Not done here:** Rojo never pushed `Grade` into Studio (needs a reconnect, `OWNER.md`); the
  sheets' haze glowing under the ceiling; triangle and draw-call counts; phone shots. All in P0-02g.
- Studio's place is `storage.rbxl`; `rojo serve` was running on port 34872 (`lsof -iTCP:34872`).
  Studio's Quality Level was put back to Automatic.

## Next task: P0-02g The hall on every phone
The moment: on a cheap phone the hall still feels like the posters, with pools of light and dark
between, and a friend shut in a unit sits in the dark, not in a lit box.
1. Owner test results first (`OWNER.md`, "Now: judge P0-02d"). Check `lsof -iTCP:34872` for Rojo;
   ask for Connect. Confirm Lighting has `Grade`.
2. Reproduce the fallback: in Play, set `settings().Rendering.QualityLevel` to Level08 from the
   MCP (Client), pin the camera at the sheets' spots (docs/STUDIO.md, "Lighting and captures") and
   capture hall, hero and inside. Then find the lowest level a phone in the Device Simulator picks.
3. Try, one at a time, what keeps units dark and facades grey there without hurting Level21:
   thicker front walls or facade, the fixture's range and brightness, a darker fallback, or the
   client dimming the hall's lights while you're shut in (`ShutIn`). Say which game each trick
   comes from if it's a mechanic; keep it to light and art otherwise.
4. The sheets' grey haze under the ceiling near a fixture: try a soft glow part or bloom.
5. Count the hall's triangles and draw calls (Studio's View > Stats, Render) at both levels;
   note them in docs/STUDIO.md. Phone-size shots in the Device Simulator at low and high quality.
6. OWNER.md: the shots to judge and what to look for. Put Quality Level back to Automatic.
**Acceptance:** checks green; `docs/art/P0-02g-*.jpg` at low and high quality; a shut unit dark
inside at both; counts noted; the owner judges.
**Read first:** `docs/ROADMAP.md` (P0-02g); `docs/DECISIONS.md` (D-015);
`docs/STUDIO.md` ("Lighting and captures"); `src/shared/HallLight.luau`;
`src/server/DevCorridor.luau` (`fixture`, `building`); `src/shared/StorageUnit/ShutIn.luau`.

## Queue (the next run's order, from ROADMAP)
1. **P0-03 The corridor kit:** hall floor and ceiling, the tile set's walls and corners, the
   motion-light fixture, built around `HallLight`'s numbers.
2. **P0-04 The door's sounds and feel:** peek scrape, open rattle, slam bang and bounce, latch,
   padlock.
3. **Phase 1, then Phase 2** (ROADMAP): the loop with real assets (L-01 to L-09); L-01 must call
   `RollUpDoor.fitCollider` on each placed unit, as DevCorridor does; L-02 carries the phone
   prompt layout (five prompts on one point stack into one tap button).
4. **Polish waiting:** re-run `UnitKit.prepare` on the template so it saves at 1.2 deep (harmless
   until then); sizes S and L by eye; a client-side door collider if the ~0.1 s lag feels wrong;
   the padlock is too small to spot from standing height; touch look speed may want a feel
   number; the cursor hint once ever (needs the saved profile) and "Option" on a Mac.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
