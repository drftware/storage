# This game on Brix

The game's systems come from **Brix** first: the game-agnostic Luau library in `../engine`
(github.com/drftware/brix), with its own repository, rules, design and roadmap. It is further along
than this game, so before building any system here, check what Brix exports or has planned. This
game supplies only what is its own: its rules as policies, its Roblox wiring as adapters, its
content as data, and its art. (Owner, 2026-11-05, D-008.)

## Between the two repositories

- Never edit Brix from a session here, and never put anything about this game into it. Brix work
  happens in a Brix session, which keeps its own HANDOFF.
- This game uses only what Brix exports (`require(ReplicatedStorage.Brix)`), at a pinned version.
- When Brix is missing something this game needs, write a ticket in Brix's `docs/ROADMAP.md` in
  neutral terms, with no names from this game.
- If a ticket here can't wait for a planned Brix piece, it says so and builds the smallest stand-in
  in this repo behind the shape Brix will have, to swap out when Brix ships it. Never a parallel
  system that lives on.

## What Brix has, and what this game takes from it

As of Brix commit `4c21b5f` (2026-11-05; 0.1.0 not tagged yet). Recheck its `src/init.luau` and
`docs/ROADMAP.md` when a ticket starts.

| This game's need | Brix piece | State |
| --- | --- | --- |
| Startup and every system's lifecycle, stepped on one clock | Host, Context, Registry, Clock | ready |
| Data shapes: keeper rows, tile rows, Config | Schema | ready |
| Events between systems (door slammed, light woke, player kept) | Signal | ready |
| The floor laid from a seed (L-01), the director's deals (L-04) | Random (seeded) | ready |
| Motion lights' watch areas (L-03), aboard the elevator (L-05), inside a unit | Zone (sphere, box, polygon, anyOf, grown) | ready |
| Keepers chasing players (L-06), getting caught (L-07) | Pursuit contract, Pathing (floor, free), Reach (sphere, cone) | contract and parts ready; the system is ENG-06, its Studio adapters ENG-07 |
| Allocation-free hot paths | Pool | ready |
| Remotes for door prompts, the keypad, tools | Remotes (ENG-09) | planned |
| Player data: finds, cash, best floor | Saves (ENG-10) | planned |
| Tuning live during playtests (L-09) | Live config and flags (ENG-11) | planned |
| Retention and funnel gates (the GDD's) | Telemetry (ENG-12) | planned |
| The climb as lobby, floors and results (L-08) | Round loop (ENG-13) | planned |
| Juice, UI, debug overlay and cheat console | Presentation kit, UI, developer tooling (ENG-15 to ENG-17) | planned; camera shake stands in as `src/shared/Shake.luau` and `src/client/CameraShake.luau` (P0-04) until ENG-15 |

What stays in this game: the storage unit and its roll-up door rig (`src/shared/StorageUnit/`),
every keeper's row and its reason to be alive, floors as data, and all art. The door is a system
on the Host's clock (`Doors`, L-02), its events on a Brix Signal; its buttons are ProximityPrompts,
so it needs no remotes until the tools (ENG-09).

## How the game references it

A git submodule at `vendor/brix`, pinned to a commit and mapped by Rojo to `ReplicatedStorage.Brix`
through Brix's own `default.project.json` (its README), until Brix publishes 0.1.0 (its ENG-08);
then the Wally package at a pinned version. Mounted in P0-02: `vendor/brix` at `4c21b5f`; the
server and client entry points each run a Host.
