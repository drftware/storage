# From photos to playable: one find, one ticket

How a find goes from reference photos to something you find in a unit on a climb, take, carry,
bank and press. The owner's brief for the third find run (Nov 16, `WAVES.md`, "The third run's
plan") set this down; P1 built it (F-G1f, D-265). `CRAFT.md` is the bar and the art method; this
file is the order things happen in and the commands.

## The rules

1. **Verbs before sets.** A press nobody has built (Squeeze, Walk, a siren that lights the hall)
   is built once, as a game ticket of its own, before or with the first find that needs it.
   Every later find with that press needs only data: its row.
2. **A find's game row lives in its art spec**, beside its shapes and motions, and the export
   writes the game's row from it. Nobody hand-writes a kit find into the game's lists.
3. **The deal takes every judged find whose art is in the place.** Ticked built in `WAVES.md`
   means judged; imported into `ReplicatedStorage.Props.Finds` means in the place. The server
   leaves out any find it has no art for as it starts, and says so in Output.
4. **An art session ends in the game:** import the find, then one Studio Play check that it turns
   up in a unit and its press plays.
5. **Only three things stay separate:** a press nobody has built (rule 1), the owner's decisions,
   and feel tests on a phone or with friends. The last two go in `OWNER.md`.

## The steps

1. **The art.** `CRAFT.md` whole: references, real size, parts on real hinges, its motions,
   sheets judged and fixed. `scripts/art.sh set <set> textures quick <Find>` while working (a
   new find has no baked `.blend` yet, so `quick` alone fails; about 3 minutes for a ball), the
   full `scripts/art.sh set <set> textures export renders <Find>` at the end, in the background
   (`<set>` is the folder: `lights`, `figures`, `windups`, `squishies`). To look at a sheet
   without filling the context, shrink it first: `sips -Z 1000 -s format jpeg <png> --out <jpg>`
   into your scratchpad (the system Python has no PIL).
2. **Its game row.** Add a `dict(...)` to the `GAME` list at the end of the set's `spec.py`, in
   the order the finds were built (the deal's order). The fields (`src/shared/Finds/Game.luau`
   says what each one does):
   - `key` (its name everywhere: `CymbalMonkey`), `catalog` (its line in `WAVES.md`'s set table,
     written exactly as there), `name` (on screen: "Cymbal monkey");
   - `grade`, `worth`, and `from_` (the lowest floor) and `loose=True` only where the item
     catalog says so (the Old lamp: floor 25 up, loose only);
   - `grip` (where your hand closes, studs from the middle of its bottom), `heft` (0 to 1),
     `size` (`"Small"`, `"Medium"` or `"Large"`: where it sits in your view);
   - `pickUp` and `drop`: sounds from `art/finds/kit/game.py`, `pitched(SOFT, 1.3)` for a
     smaller, lighter thing; a new recording goes in `game.py` with a comment naming it;
   - `press=dict(verb=..., on=[dict(motion=..., sound=...)], ...)`: its one word and the
     motions it plays, by their names in the set's motions, with any of `lasts`, `out`, `off`,
     `reset`, `noise`, `lure`, `toy`, `down`. `FOREVER` loops a step until the light runs out;
     `lamp(on)` is a lamp's whole press. Copy the find in the set nearest to it in kind.
3. **Generate.** `scripts/art.sh rows` (seconds; every set's export runs it too) writes
   `src/shared/Finds/Rows.luau`. Never edit that file: `scripts/check.sh` fails if it is stale.
4. **Judge.** Tick the find's line in its `WAVES.md` set table with the date and the step
   (`Nov 17, S1`), then `scripts/art.sh rows` again: the row is now `judged`, so the catalog
   (`Tools/Catalog`), the presses (`Finds/Use`) and the deal (`Deal.Finds`) all take it.
5. **Check.** `scripts/check.sh` passes. A new press shape gets a Lune spec first
   (`tests/finduse.spec`); `tests/kitrows.spec` holds the rows that were hand-written before P1
   to what they were.
6. **Import.** `lune run scripts/upload_art` (when only one find changed, `git checkout` the
   set's other FBX first, or they all go up again), then in Studio's Edit view, Rojo synced:
   `require(game.ReplicatedStorage.Shared.Finds.Kit).import("<Set>", {"<Find>"})`
   (`CRAFT.md`, "Into Studio"). Import only in Edit. The owner saves the place.
7. **Play check.** Start Play. From the Server, set Workspace's `DevBox` attribute to the find's
   key: the next unit opened deals it in a marked box (`docs/STUDIO.md`, "Opening a marked box in
   Play"). Open a unit, open the box, take the find, press it: see its motion, hear its sound or
   see the Sound play, and for a noisy one a monster turning toward it. Bank it at the elevator.
   Read Output for errors and for "Deals: no art in the place for ...". Stop Play. Write what
   you saw in `WAVES.md`'s "Every built find, in the game" table.

## What the first proof found (S1, the goo ball)

- **One find, two sessions.** References, a boned find's art and two rounds of sheets took a
  whole session's context (200k): stop after step 3 (its row written, not ticked) and hand
  steps 4 to 7 to the next session, which looks at the full sheets, ticks, imports and plays.
  A find that reuses a builder (the mega goo ball) may fit in one.
- **A sound named like a motion.** A set's `spec.py` imports its sounds from `game.py` at the
  bottom, after its motions' keys: a sound with the same name (the squishies' `SQUISH`, `SIGH`,
  `CRINKLE`, `SLOSH`) replaced the keys, and from P1a until S1 the set didn't build at all.
  Import such a sound as `<NAME>_SOUND`. `scripts/check.sh` doesn't build art, so nothing
  caught it: a set's first build after a spec change is its check.

## Not here

- Big finds (both hands, behind a floor's code door) get no game row until a floor has a big-find
  place: the theatre spotlight is built and waits.
- The bedroom set (Boombox, Television, Teddy, Skates) are one-mesh finds with no kit spec: their
  rows stay hand-written in `Tools/Catalog.luau`.
- Presses that only happen at home, and the hard hat worn on your head, belong to the home chain
  (ROADMAP S5-03, F-G1b4).
