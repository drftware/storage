# Handoff

_Overwrite every session, keeping this layout, under 70 lines. History lives in `git log`. What waits on the owner lives in `OWNER.md`, not here._

**Updated:** 2026-11-17, session 260 (S5-03f4b1, the counter's mirror built, D-319) ·
**Checks:** green in the shared checkout · **Git:** `main`, committed, not pushed (`origin` is
github.com/drftware/storage); Brix pinned at `7f25310`, NOT on Brix's `origin` yet.

## State
- The home (D-259; the Claude Doc https://claude.ai/artifact/EUdGarQ2sEiUC6BU5E7Tww, docs tools
  only) is built a ROADMAP piece a session (S5-03), up to f4b1: the counter's mirror, built.
- The counter's mirror (D-319): the home's framed mirror leans on the front wall past the
  counter's door end (`Shop.Mirror`, `Home.mirrorAt`, `Lobby.lay`); its picture stands the front
  office's walls (`Lobby.MirrorRoom`). Each colour card's figure is a Try on while you stand in
  front of a mirror within `Shop.TryReach` (`TryWrap` → `TryOns`, exactly that colour); the
  shop shuts and your view eases to the glass (`TryOn.LookAttribute`, TryOnView). The counter's
  Shop button moved from the old lobby's z -35 to the counter. Passes checks, untested in Studio.
- Rojo still isn't connected; Studio holds S5-03f4a's patched copies, not this session's.
- The test save: one HardHat (on the rail), cash 478. Device Simulator: Galaxy A16, landscape.
  A world button is pressed from a Client `execute_luau` (`InputHoldBegin`/`End`, STUDIO.md).
- Stage only your own paths; the find run commits its own `art/finds/`, `src/shared/Finds/`,
  `tests/stuffdeal.spec.luau`, and may have hunks in `docs/`: stage yours as a blob then.

## Next task: S5-03f4b2 See the counter's mirror in Play
The moment: walking from the spawn to the counter you see yourself in the mirror beside it; at
the shop you tap Pink's figure, the shop slides away, your view swings to the glass and you're
wound in Pink there.
1. Patch Studio from Edit (`git diff 9849b81 HEAD -- src/` names the nine modules). STUDIO.md
   "Patching scripts without Rojo": an edited ReplicatedStorage module stays stale on the
   client, a NEW one doesn't. So for Shop, TryOn, Mirror, Home and Lobby make a new ModuleScript
   with the file's full Source, move the old one's children (Home: Specs, Arrange...; Lobby:
   Specs, Boarding) under it, then destroy the old. Server TryOns and client ShopView, TryOnView,
   MirrorView can take line patches. Mind doubles (STUDIO.md "New modules show up twice").
2. Play on the A16: `Dressing.CounterMirror` leans on the front wall (foot z -155.2 assumes its
   face at -156), `Workspace.ShopCounter` is at the counter. Judge the picture at phone size:
   walls' colours, floor and ceiling there, no dark gaps (`Lobby.MirrorRoom`).
3. Open the shop by the counter, tap a colour's figure (user_mouse_input at the card plus the
   A16's 47-point offset, STUDIO.md). Look for: the pop, the slide away, your view turning to
   the glass, the colour in it, the peel. Away from the mirror: no pills.
4. Capture to `docs/art/S5-03f4b-*.jpg`. Then, if room is left, start S5-03g1 (ROADMAP).
**Acceptance:** check green; seen in Play by the counter with pictures, or exact steps in OWNER.md.
**Read first:** ROADMAP S5-03f4b, S5-03g; D-319; STUDIO.md "Patching scripts without Rojo",
"Pressing a world button from the MCP"; `src/shared/Lobby/init.luau` (`MirrorRoom`, `lay`);
`src/client/ShopView.luau` (`tryOn`, `nearMirror`).

## Queue (next sessions, the owner's ticket order)
1. S5-03g (split: art first), h; S5-03d4 across the trip (unblocked); S5-03a2d the cars' hidden
   triangles; F-G1b4a2 the headlamp's beam (ROADMAP Step 4); F-G1b4b the hat spent.
2. The home's warm fill (D-290): faces turned from the bulb go near black (D-263: warm all round).
3. F-G1b5 waits for its art. Brix: ENG-25b's two-client run; Driving's stick read needs
   `PlayerModule`, fall back to the camera-turned `MoveDirection` (D-254), built in `../engine`.
   A PlayerSaves hook that runs before a leaving save's last write would replace `leaving`.
4. S4-02 monsters by lowest floor, S4-03 the elevator's choice, S4-04 trapping pays, S4-05.
5. The item catalog doc and the design doc's finds section need D-250, D-251, D-259, D-277, D-297,
   D-299, D-300, D-301, D-302, D-304, D-305, D-308 (the spot column), D-309, D-311 to D-319.
6. Once the owner's real purchase passes: mark Brix's ENG-23e done in `../engine`'s HANDOFF.
7. Late arrivals off `ClimbEnd.spot`; the driving torch (D-257); asset 203785492's type error;
   the front office's steel; cart seats vs `Seat:Sit`; a spare home unpadlocked (D-275); the
   hat's first-Wear dark screen; the body unhidden after a respawn (D-282); a Gold's own
   textures and the Packrat wanting a Gold most; a crack drawn on a cracked card (ROADMAP polish).
8. `CaughtSeized` is set by CaughtLunge and ArrangeView and read by FlashlightView, each with its
   own string: share one constant (a "camera held" attribute) when next in those files.
9. S5-03d4's climb server must restamp the lights it receives (`Use.leave`), as Climbs does.
10. The catch's film now comes from `Film.make`: watch a catch in Play once Rojo is connected.

## Kickoff for the next agent
```text
Continue the storage horror game (Roblox + Rojo). CLAUDE.md loads AGENTS.md and HANDOFF.md automatically.
Do the Next task per AGENTS.md's Session protocol.
```
