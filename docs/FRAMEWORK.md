# This game on Brix

**Brix** is the game-agnostic Luau library in `../engine` (github.com/drftware/brix), with its own
repository, rules, design and roadmap. This game takes two things from it: the core every system
runs on, and the pieces every game needs the same way (remotes, save data, live config, telemetry
and the rest of the list below). Before building one of those here, check what Brix exports or has
planned. (Owner, 2026-11-05, D-008.)

The keepers' brain is the exception: it is built in this game (owner, 2026-11-09, D-064; see
"What lives in this game").

## Between the two repositories

- When a ticket here needs a system Brix lacks, a session here builds it in Brix (`../engine`) as
  one Brix ticket, by Brix's own rules: its AGENTS.md, nothing about this game, its check green, its
  ROADMAP, DECISIONS and CHANGELOG, its own untracked HANDOFF overwritten, and its commit with no
  trailer. Then, once Brix is pushed, the pin moves. (Owner, 2026-11-16, D-252: Brix should get
  better at iterating on new ideas in this game; this replaces "never edit Brix from here".)
- This game uses only what Brix exports (`require(ReplicatedStorage.Brix)`), at a pinned version.
- Never put anything about this game into Brix.
- If a ticket here can't wait for a planned Brix piece, it says so and builds the smallest stand-in
  in this repo behind the shape Brix will have, to swap out when Brix ships it. Never a parallel
  system that lives on, with one named exception: the keepers' brain.

## What this game uses from Brix today

At the pinned commit, `c9f6667` (2026-11-16, moved from `5cdb8c2` for F-G1b3c2c). Checked against `src/` on 2026-11-16.

| Brix piece | What the game does with it | Where |
| --- | --- | --- |
| Host, Context and the System contract (the Host owns the clock) | Every system on the server and on each client starts, stops and steps on one clock | `src/server/init.server.luau`, `src/client/init.client.luau`, every system module |
| Signal | Events between systems: a door opened or slammed, a light woke, a tool taken, a wall sawn, a crawl, a climb | `Doors`, `MotionLights`, `Elevators`, `Deals`, `Slots`, `Flashlights`, `Saws`, `Crawls`, `Ladders` |
| Random (seeded) | A floor laid from a seed, and its deals | `src/shared/Floor.luau`, `src/server/DevCorridor.luau` |
| Zone (`box`) measured along Pathing (`free`) | A motion light's watch area; who is aboard the elevator | `MotionLights`, `Elevators`, `src/client/HallLights.luau` |
| Reach (`cone`) measured along the keepers' map (their own Pathing) | A keeper's grasp: whom its hand closes on (L-06b3c, D-077) | `src/server/Keepers.luau` hands it to `src/shared/Keeper.luau` |
| Saves, SaveFormat (`versioned`), Schema, `Roblox.SaveStore.dataStore`, `Roblox.PlayerSaves`, `Roblox.serverId`, `SaveStore.loopback` | Each player's save held by one server, autosaved, let go on leave and shutdown (S1-01, D-134) | `src/server/Saving.luau`, `src/shared/Save.luau` |
| Analytics, `AnalyticsField.oneOf`, `Roblox.AnalyticsSink.analyticsService`, `AnalyticsSink.recorder` (specs) | What every player earns and does, checked against one plan and sent to Roblox's AnalyticsService (S1-02, D-139) | `src/server/Recording.luau`, `src/shared/Record.luau` |
| Handling (`Handling.car`, ENG-24a) | How the RC car answers its stick: the speed to drive at and the turn, held back by walls; its numbers are the game's `Config` | `src/shared/Finds/Drive.luau`, `src/client/DriveView.luau` |
| Driving (`MoveCheck.ground`, `Roblox.Driving.server` and `.client`, ENG-24b) | The RC car driven from its driver's own device: the server hands it over, checks every move and puts a bad one back; the driver's client reads the move stick and steers it | `src/server/Drives.luau`, `src/client/DriveView.luau` |
| Purchases (specs only so far; the server's wiring, PlayerPurchases, Roblox's Marketplace and LiveConfig over ConfigService, is S3-02b) | Robux purchases granted once, after the save holding them is written (S3-02a, D-206) | `src/shared/Products.luau`, `tests/products.spec.luau` |

Exported at the pin but not used here yet: Schema (data shapes for keeper rows and Config), Pool,
the other zones (sphere, polygon, any-of, grown), the floor pathing and the sphere reach.

## What Brix has built since the pin

These are in the pin (moved to `c9f6667` for F-G1b3c2c), still not used here.
Moving the pin is its own small step, taken when a ticket first needs something newer.

| Brix piece | State in Brix | This game's use |
| --- | --- | --- |
| The frame driver (`Brix.Roblox.HostDriver`): steps a Host each Heartbeat, catches up after a hitch of up to half a second and says when it had to drop time | Built, not yet run in Studio (its ENG-07a) | Take it when the pin moves; today the server steps the Host from Heartbeat itself |
| Remotes and the RemoteEvent transport (ENG-09): declared asks and tells, checked and rate-limited | Built | The game's own remotes stand in until a ticket moves them |
| LiveConfig, `Roblox.ConfigSource.configService`, `Roblox.ConfigRefresher` (ENG-11) | Built, run in Studio | S3-02b uses it for the offers' switches; L-09's tuning later |
| RoundLoop, RoundPlayers, countdowns, teams, round ends (ENG-13) | Built | `Climbs`/`ClimbEnds` stand in; adopting it is its own ticket |
| Purchases, Marketplace, `Roblox.PlayerPurchases` (ENG-23) | Built, run in Studio; ENG-23e waits on this game's phone test | S3-02b wires it on the server |
| The Pursuit system, its stock chases and targetings, and its Roblox adapters (players as runners, a hunter driver) | Built; the adapters not yet run in Studio (ENG-07a). What players see is ENG-07b, not started | Not what keepers run on (D-064). Checked for the chase at L-06b3a2 and not used (D-074): a hunter the game places is never moved by Pursuit again, so a keeper couldn't hand back to roaming, and its reach and runners have no walls or sight |

## What Brix plans that this game will use

None of these is built. Each row says what stands in here until it is.

| This game's need | Brix piece | Brix ticket | Until then |
| --- | --- | --- | --- |
| Every client→server ask (the keypad, the torch, tools) declared once, checked and rate-limited | Typed remotes | ENG-09 | The game's own remotes under `ReplicatedStorage.Remotes`, each checked by its server system (`Elevators`, `Flashlights`, `Slots`) |
| Systems' own key events (catches, escapes, save losses) and a plan merge | Telemetry | ENG-12c | `Recording` listens to the game's systems' signals itself (D-139) |
| The climb as lobby, floors and results (L-08) | Round loop | ENG-13 | `src/server/Climbs.luau` (L-08b, D-104): floors dealt, laid and handed up; `src/server/ClimbEnds.luau` (L-08d, D-106): the end, the results and "Again" into a fresh floor 1; the lobby's cars `src/server/LobbyCars.luau` (L-08e1b, D-120, D-121). Checked Nov 12: ENG-13 unbuilt |
| A lobby's group sent to a server of its own, together, and received there (L-08e1c) | Round loop's matchmaking | ENG-13 (to file in it) | Stand-in `src/server/Trips.luau` with pure `Trip` (D-122). For a Brix session to file, in neutral terms: "Send a party to a new private instance: one teleport for the party with a payload, a validated payload on arrival, retries to the same instance, a give-up, failures handed back per player, a fallback when sending keeps failing; on the instance, wait for the party (all, or a timeout) before the round starts" |
| Juice: camera moves, slow motion, sound cues | Presentation kit | ENG-15 | Camera shake stands in as `src/shared/Shake.luau` and `src/client/CameraShake.luau` (P0-04) |
| The HUD and menus | UI library and shared components | ENG-16 | The game's own screens, such as the keypad (`src/client/KeypadPad.luau`) |
| A debug overlay, a gated cheat console, replaying a seed | Developer tooling | ENG-17 | Studio-only dev systems (`DevCorridor`) |
| Error reports and step timing from live servers | Observability | ENG-18 | Nothing yet |
| Carried items: slots, one in hand, pick up, switch, drop, hand over (L-11b) | None planned (checked Nov 8) | To file | Stand-in `Tools.Carry` (pure rules) and `src/server/Slots.luau`. Ticket for a Brix session to file, in neutral terms: "A carried-items system: a fixed number of slots per player, one active; take, switch, release and transfer between players, each validated (type, reach, room, rate) and replicated; items as data rows" |

## What lives in this game

- **The keepers' brain** (D-064): the halls as a map keepers walk, going to a place, what a keeper
  hears and sees, its states, the catch, and the director's orders. One system on the Host's
  clock, each keeper a data row. It is built against Brix's contracts and parts wherever they fit
  (the Pathing contract for the hall map, a Reach for the catch, Zones, Signals, seeded Random), so
  that once it has shipped and been tuned with players, a Brix session can lift it into Brix in
  neutral terms if that still makes sense, and this game swaps to it. Tickets: ROADMAP's L-06b.
- The storage unit and its roll-up door rig (`src/shared/StorageUnit/`), every keeper's row and
  its reason to be alive, floors as data, and all art. The door is a system on the Host's clock
  (`Doors`, L-02), its events on a Brix Signal; its buttons are ProximityPrompts.

## How the game references it

A git submodule at `vendor/brix`, pinned to a commit and mapped by Rojo to `ReplicatedStorage.Brix`
through Brix's own `default.project.json` (its README), until Brix publishes 0.1.0 (its ENG-08);
then the Wally package at a pinned version. Mounted in P0-02: `vendor/brix` at `4c21b5f`; the
server and client entry points each run a Host. This game doesn't wait on 0.1.0: that release is
Brix's own milestone with another game, and a pinned commit serves until it lands.
