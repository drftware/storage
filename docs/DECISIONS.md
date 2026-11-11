# Decisions

Durable choices and why, newest last. Add one when a choice would surprise a future session.
Design detail lives in the GDD; this log records the calls that shape the build.

## D-001 · 2026-11-05 · Art is code, built in Blender headless
Every model is a Python script run in Blender 5.2, so an asset can be rebuilt, resized and
re-textured by changing numbers, and the game reads those same numbers from a generated `Specs`
module. Studio's 3D Importer brings the FBX in with its textures as SurfaceAppearances. The
sibling fight project proved the approach (its D-054), with vertex colours for a toy look; this
game's horror wants worn, grounded PBR materials instead (D-007).

## D-002 · 2026-11-05 · The unit's numbers
A 10x10 unit is 12 x 12 studs wall to wall with 10-stud walls and an 8 x 8 doorway, sized so an
R15 avatar (about 5.3 studs) reads like a person (a stud is about 0.28 m). A peek lifts the
door 1.15 studs, the GDD's "a foot". The shut door leaves a 0.06-stud gap for the GDD's line of
hall light. Three sizes come from one spec: S 8x8, M 12x12, L 16x20.

## D-003 · 2026-11-05 · The door is a chain of rigid ribs on a solved coil
38 slats, one corrugation rib each, hinge at the rib valleys and wind onto an Archimedean coil
behind the header, so the door is real from the hallway, from inside and from the wire tops. One
number (rise) poses everything. A skinned mesh was rejected (bounds and culling risk, harder to
pose from code); a sliding slab was rejected (it would poke through the unit's top and look fake
from inside, where kept players watch it).

## D-004 · 2026-11-05 · Paint is the part's Color, through Overlay alpha
The door and corridor-wall colour maps carry alpha: 0 where paint shows, so SurfaceAppearance's
Overlay mode shows MeshPart.Color there. One texture set paints any door colour, so a floor can
repaint its doors for free. `UnitKit.prepare` forces Overlay in case the importer picks another
alpha mode.

## D-005 · 2026-11-05 · The server sends one motion; clients animate
A door move replicates as one string attribute (action, from, to, server start time). Every
client samples the same curve from `Motion`; the server moves only an invisible DoorCollider.
Slats are cloned on each client and never replicated. The GDD's timings live in `Motion`: peek
1 s, open 2 s, close 1.6 s, slam lands in 0.28 s, lift from inside 6 s.

## D-006 · 2026-11-05 · A shut door is one merged mesh
Most doors on a floor are shut, so a shut door shows `CurtainClosed`, the whole curtain merged
into one part, and its client builds the 38-slat chain only while it moves or stands open (from a
code review for low-end Android). A padlocked door refuses to lift, and the bolt only shoots on a
shut door.

## D-007 · 2026-11-05 · The look: after-hours self storage, worn and real
Galvanized partitions with spangle and white rust, enamel doors chalky and chipped, rust from
chips and rib valleys, kick marks and dolly scuffs where people actually hit things, oily concrete
with saw-cut joints, under cold corridor light. Detail stays where it wouldn't repeat visibly
every rib. The owner approved the unit's look on 2026-11-06 (see D-012 for its light).

## D-008 · 2026-11-05 · Systems come from Brix first
Brix, the shared library in `../engine`, is further along than this game, so the game leans on it
for as many components as it can: the lifecycle and clock, Schema, Signal, seeded Random and Zones
now; the keepers' chase (Pursuit) as soon as its system lands; remotes, save data, live config,
telemetry and the round loop as Brix releases them (owner). This game keeps only its policies,
adapters, data and art; `docs/FRAMEWORK.md` maps each need to its Brix piece. A ticket that can't
wait for a planned piece builds the smallest stand-in behind Brix's shape and swaps it out later.
(Amended Nov 9 by D-064: the keepers' brain is built in this game, not on Pursuit.)

## D-009 · 2026-11-05 · The unit template lives in the place, not in Rojo's tree
Rojo's live sync can't set the mesh on an imported MeshPart (Studio won't let plugins write it),
so a unit model synced from a file would arrive in Studio with blank parts. The prepared unit
therefore lives in the place itself at `ReplicatedStorage.Units.<Size>`, where Rojo leaves it
alone (ReplicatedStorage has no `$path`, so Rojo keeps children it didn't make). A fresh place gets
the template back from its asset ID (D-010 replaced the saved `.rbxm` copy planned here).

## D-010 · 2026-11-05 · Art goes up through Open Cloud, not the 3D Importer
The owner's porch-pirates ships every model this way, so no art waits on someone clicking a
dialog. `scripts/upload_art.luau` (with `scripts/lib/OpenCloud.luau`, taken from porch-pirates)
sends each changed FBX as a Model asset, updating the same ID in place after the first upload, and
records the hash and ID in `art/unit/assets.json`. The key lives in the git-ignored `.config/.env`.
A session then inserts the asset through Studio's MCP and prepares it (art/unit/README.md, "Into
Studio"). The asset ID is the durable record, so the planned `assets/units/<Size>.rbxm` copy is
dropped. Not taken: building meshes from repo data at run time, as the owner's fight game does,
because a game script can't set SurfaceAppearance's normal and roughness maps and the unit's look
depends on them.


## D-011 · 2026-11-05 · First-person camera
The owner's call: players see the building through their own eyes, as in Pressure. It keeps the
dark close and a keeper's arrival sudden, and it fixes what P0-02b found: Roblox's third-person
camera backed through the shut door behind you into the unit across the 8-stud hall, because a
unit has no part that stops it (docs/STUDIO.md, "Camera and prompts"). With the camera locked at
the head, the units keep their invisible box colliders as the only collision and need no
camera-blocking walls. Not taken: third person with solid unit walls, which would also need the
facade remodelled in three pieces so the doorway stays open. The owner confirmed first person
again on 2026-11-06, and it was built that day (P0-02c).

## D-012 · 2026-11-06 · The game is lit like the look sheets
The owner's call after the two-player test: the storage units look right, and the light in the look
sheets (`art/sheets/unit-hall.png`, `unit-hero.png`, `unit-inside.png`, the door videos) is the
light the game should have. The MCP's captures show the game as it really renders (the owner's
darker shot was dimmed by the pause menu), and today the hall and units read flat and near white
next to the sheets. P0-02d does it.

## D-013 · 2026-11-06 · A shut door hides whoever is behind it
Measured in Play (P0-02e): Roblox's run animation keeps playing while you push into a wall, so a
hand swings up to 1.25 studs through a 0.4-deep door collider and still 0.8 through a 1.2-deep one.
Hiding it with collision alone takes a collider about 3 deep, which would stand an invisible bump a
full stud out from every door in the hall. Instead the collider is 1.2 deep (a hall player stops
flush with the facade) and each client stops drawing anyone a shut door stands between it and
(`BehindDoors`, rule in `ShutIn`): the door is solid metal, so that is what you'd see anyway, and it
covers every avatar, accessory and tool. Footsteps still play. Not taken: a client guard that stops
your walk into a door (Roblox's control script moves the character through flag-gated internal
paths, so it would be fragile, and the swing on the last stride still crosses), or a custom run
animation (feel the owner hasn't asked for).

## D-014 · 2026-11-06 · Left Alt frees the mouse, through a Modal button
First person pins the mouse to the middle of the screen, so a computer player couldn't take a
screenshot or reach another window. Left Alt (Option on a Mac) toggles a free cursor for mouse
players; phones and gamepads get no key and no hint. It works the way Roblox documents: a visible
GuiButton with `Modal` set leaves the mouse unlocked, and the right mouse button still looks around
while it's free. The mouse is either the view or a cursor, never both (owner, Nov 6): no cursor is
drawn while it turns the view, the way first-person shooters hide theirs. Not taken: writing `MouseBehavior` ourselves (the camera script puts LockCenter back
every frame), or a fork of the PlayerModule. The key is a default the owner can change (`OWNER.md`).

## D-015 · 2026-11-06 · The hall's light: fixtures every two units, tuned at full quality
The look sheets' light comes from a few fixtures, one every 24 studs, hanging 2 studs over the
wire tops, each pooling hard cold light on the doors below with the dark between; the stairwell's
exit sign tints the far end red. `HallLight` holds those numbers for the corridor kit (P0-03) and
the motion lights (L-03). Tuned where Roblox draws its full lighting (graphics quality about 11 and
up in Studio's levels): there the hall, the hero door and a shut unit's dark inside match the
sheets. D-012's "captures are accurate" was wrong in one way: Studio on Automatic quality, like a
low-end phone, falls back to coarse lighting that ignores a light's cone and shines through thin
walls, which is where the flat, near-white facades came from. P0-02g takes on that fallback. A
default until the owner says otherwise: at most 6 real lights awake on one client at once; the
test hall uses 3. Not taken: matching the sheets' haze with Atmosphere (it stays black indoors at
midnight) or classic fog (barely shows in a dark hall).

## D-016 · 2026-11-06 · Shut in, the client keeps the hall's light out
Below graphics quality about 10 (Studio's levels; a low-graphics phone), the hall's lights cast no
shadows at all: a 2-stud concrete roof and a 2-stud block in front of the door changed nothing
inside a shut unit, and range barely matters there. So no wall thickness keeps a unit dark. The
door does it on the shut-in player's own screen instead: `BehindDoors` scales every light tagged
`HallLight.Tag` by `ShutIn.light` (6% while shut, about half at a friend's peek, full when open,
cut as fast as a slam falls) and draws the line under the door as a thin glowing strip on the hall
floor. Full quality gets the same treatment, so the moment looks the same on every device; its
real shadows already kept the room dark. Not taken: thicker walls or a unit roof (no effect),
guessing the device's quality (Roblox doesn't say on Automatic), a light under the door (one more
real light, and it would leak in too). The hall's own low-graphics look is P0-02h.

## D-017 · 2026-11-07 · A fixture is two lights: a short tube and a fill at door height
Studio's Automatic quality (and a phone's) switches between low graphics and full quality
mid-play. Measured from the spawn: floors came out the same at both, but low graphics lit upright
walls, facades and an open unit's insides 2 to 3 times brighter, so the hall flickered between
two looks and an open unit between lit and black. Neither exposure nor brightness separates the
two (both move together; low graphics doesn't cap a light). Range does: low graphics ignores
shadows, so a 22-stud tube flooded the units, while 14 reaches only the floor and doors under it.
So each fixture is now the tube, shadowed, 14 studs, for the pool on the floor, plus a
shadowless PointLight 5 studs up (`HallLight.FillHeight`) standing in for light bounced off that
pool: level with the walls, it lights them at full quality as low graphics does, and it reaches
into an open unit at both. Result: low graphics about 1.7x full quality, an open unit dimly
readable at both (the owner's pick, Nov 6). Cost: two real lights per lit fixture, so the 6-light
budget (D-015) holds three lit fixtures; the fill is tagged like the tube, so `BehindDoors` dims
it for a player shut in. Not taken: a fill at the tube's height (lit the units' tops, closed less
of the gap), guessing the device's quality (Roblox doesn't say on Automatic).

## D-018 · 2026-11-07 · The haze is a few dust puffs under each lit tube, mostly self-lit
The look sheets show grey air glowing around a lit fixture. Roblox has no light shafts or
volumetric fog indoors, so each lit tube carries a ParticleEmitter with Roblox's built-in smoke
texture: about six slow puffs, 4 to 6 studs wide, gathered 2.5 studs under the tube
(`HallLight.HazeHeight`). Measured in Play: low graphics draws a hard line where a puff cuts into
the ceiling (full quality softens it), so the puffs hang low enough to miss it, and spread in a
flat fan along the hall. A puff fully lit by the hall (LightInfluence 1) dims with its fixture but
reads about twice as bright at low graphics as at full quality, like the walls (D-017), and faint
at full quality; at 0.4 the two looks sit within about 1.3x from the spawn. The self-lit part
can't dim with the light, so a fixture's level scales the puffs' colour, a dead fixture hides
them at once (transparency is read live), and a fixture coming on throws a burst of five
(`Emit` on the server reaches players already watching). Shut in a unit you can't see the hall's
air, so `BehindDoors` needn't dim it (checked at Level08). Not tried, since the puffs did it: a
glow part, more bloom (it already smears bright neon into blobs at low graphics), a thicker
Atmosphere (it would fog dead stretches as much as lit ones).

## D-019 · 2026-11-07 · Each player's screen emits the haze's puffs
Measured in Play (P0-02j): Roblox thins a ParticleEmitter's steady puffs with graphics quality,
to about (level ÷ 21) of its Rate: 7% at Level01, 35% at Level08, all of it at Level21. The haze
held about six puffs per lit tube at full quality, two at Level08, and under one at the levels a
cheap phone plays at, where the look sheets' grey air simply wasn't there. The P0-02i shots hid
it: each was taken on a fresh burst, and `Emit` is never thinned. So the server leaves each haze
emitter's Rate at 0 and tags it `HallLight.HazeTag`, and the client system `HallHaze` emits one
puff at a time at `HallLight.HazeRate` (`Pace` carries the timing between frames, and a hitch
never dumps a cloud). Now about eleven puffs hang under the two lit tubes at Level01, Level08 and
Level21 alike. The cost of keeping them on weak phones is small: the puffs add 24 triangles and
3 draw calls. The haze is only for looks, so the client owning its timing breaks nothing the
server must own. The same client bursts a tube already lit when it first gets it (joining late,
or the tube streaming in), which fixes the haze starting clear for a late joiner. Not chosen:
raising Rate to match the player's quality level, which Automatic changes mid-play; emitting
directly needs no level at all.

## D-020 · 2026-11-07 · The corridor kit: 24-stud pieces on the unit's textures, a steel ceiling
The hall becomes pieces a floor is laid from (GDD tech plan: one tile graph). The straight piece
is 24 studs: two M units a side, three S, and one hall light's stretch. Its length is set by the
floor's texture: the unit's Concrete set repeats every 8 studs with a saw-cut joint on its edge,
so a piece a multiple of 8 long, with UVs starting on that edge, meets the next on a joint and
never shows a seam (12-stud pieces would land mid-texture). The ceiling is a corrugated steel deck
on open-web joists, the look of a real storage building and of the look sheets, reaching over
the hall and a row of units each side (32 across), so back-to-back unit rows between two halls
meet under one continuous ceiling. Its deck sits at 14 (was 13.4) so the joists can be 1.2 deep
and still stop at 12.8, clear of the haze's 12.6. The kit bakes nothing: the floor wears the
unit's Concrete and the ceiling its TrimSheet (painted and raw-steel strips), and a piece is two
MeshParts, so a hall of identical pieces draws in two calls. Templates live in the place at
`ReplicatedStorage.Corridor.<Piece>`, beside the units' (D-009). Not chosen: a MaterialVariant
floor on plain parts (seamless at any length, but a second way of shipping art, outside the
Blender pipeline); I-beams (cheaper, but read as a parking garage, not a storage building).

## D-021 The hall light is a hung strip light whose sensor dome is the building's eye (P0-03b, 2026-11-07)

The fixture is a steel strip light on two jack chains from the deck, midway between two joists,
with an occupancy sensor on one end: the GDD's "motion lights are its eyes" made literal. Its own
FBX and template (`ReplicatedStorage.Corridor.Fixture`), not part of the straight piece, so the
floor generator places lights through L-03's system rather than every 24 studs by default. Three
MeshParts: the Housing (TrimSheet: painted channel, galvanized chain, clips and junction box, a
rubber cord) and two untextured parts the game colours, the Diffuser (the lens `HallLight.light`
lights, its place and size read from `HallLight.Height` and `TubeSize`, so the art follows the
tuned light) and the Eye. The eye has three looks: Watching (a red glow, so a dark hall is dotted
with eyes), Seen (full red, the flare L-03 shows when it trips) and Blind (dead plastic, the
breaker room's zone). Its dome is a half-sphere 0.36 across, about twice a real sensor's, because
at 0.26 only the nearest eye in a dark hall read on a phone. Neon only, no light of its own: the
light budget stays at two per lit fixture (D-017). Not chosen: a separate pinprick LED beside a
white dome (real, but a pixel or two on a phone); the sensor mid-lens (it would split the tube
the light was tuned on).

## D-022 · 2026-11-07 · The hall's walls are a unit's front without the door
Where no unit stands, and at a hall's dead end, the wall is the corridor wall the units' fronts
are: the same painted Facade panels (painted per floor, like the units), posts, diamond kick plate
and cap at 10, so the hall reads as one building and a stretch with no doors reads as a blank wall,
nothing to hide behind. Above the cap an R-panel (the units' Partition set) rises to the deck: a
unit is open over its wire top, a wall isn't, which is what a real building has where a room or the
outside lies behind. The plain wall is one M unit wide (12) and its frame is a unit's door face, so
a hall side is a row of 12-stud slots, each a unit or a plain wall (L-01). The dead end is a wall
placed at a piece's open end, not a piece of its own: it spans the whole deck (32), so any hall end
can be closed, and a dead-end tile is a straight piece plus one. Its panel's valleys sit flush with
the deck's end, so no gap opens where the flutes stop. Three MeshParts each (Facade, Trim, Panel);
a wall's frame is found from its flat Facade and the Panel behind it. Not chosen: concrete block
walls (a second material the building doesn't otherwise have); a plain wall full height in the
facade paint (its texture is drawn for a 10-stud wall); a dead end with its own floor and ceiling
(a second straight piece's worth of mesh for one wall).

## D-023 · 2026-11-07 · Junctions: 24-stud squares, the deck turns on a girder
The corner, T and cross are 24-stud squares, a straight's length, so they sit on the straights'
grid (D-020): a junction's floor is the whole square mapped like a straight's, so every arm meets
it on a saw-cut joint, and its joists keep the 6-stud beat along its X arms. Halls stay on 24-stud
centres; a turned straight's floor meets a junction rotated, on a joint. Every straight keeps its
deck running along its own hall (option b of the ticket); a junction's deck continues its X arms
and a joist girder, as deep as a joist (clear of the haze) with heavier chords and a closure plate
on top, carries the seam across each Z arm's mouth. Not chosen: one deck direction for the whole
floor (option a), which needed a second straight for halls along Z, joists running along those
halls instead of across, junction ceilings that can't turn with their floors, and joists 2 studs
apart over the back-to-back rows of parallel Z halls (32 apart, not a multiple of 6). Not chosen
either: 32-stud junctions covering the whole span, which break the floor joints (16 is not 4 off a
joint) and the 24-stud grid. What a junction leaves of a hall side is whole slots: 8 (the new
short wall, an S unit's width) beside its blocks of wall and along a corner's outer sides, and two
12s across a T's stub. A steel column covers each corner where two walls meet (the posts' notch,
the caps' overlap that would flicker, the R-panels' slit). A junction's frame is its floor part's
own: Roblox's importer keeps each part's FBX axes (docs/STUDIO.md), so a square floor still knows
its turn.


## D-024 · 2026-11-07 · Motion lights: the server keeps state, each screen draws it
Every hall fixture is a motion light the server owns (L-03, GDD "Lights"). Ten times a second the
server hands a pure watch (`MotionLight`, Lune-tested) where every body that trips lights is; it
wakes the fixtures whose watch area someone moved in and darkens those that saw nothing move for
5 s, and only those changes reach players, as a string attribute on the fixture's model. A body
"moves" at 1 stud a second or more, so holding still under a light puts you in the dark (the GDD's
"hold still and you go dark to it"). A watch area is a Brix box zone under the fixture: 32 studs
down the hall (the next light wakes about 16 studs before you reach it), 10 across (the hall and a
stud into each doorway, so a unit's inside is unseen), floor to deck. Fixtures sit in a spatial
hash on the 24-stud grid. A fixture is a motion light by its tag; players' root parts trip lights
by theirs, which keepers will carry too, all but the Mannequin's. Each screen draws the state
(HallLights): the eye flares hot and settles red, the sensor's relay clicks (Pro Sound Effects,
from Roblox's audio library), the tube flickers twice and holds; falling dark, it cuts out with a
softer click and the eye sinks back; cut by the breaker, tube and eye die silently. Real light only
for the three lit fixtures nearest the camera (two lights each, D-017), with 8 studs of
stickiness against swapping; the rest glow, with no dust. Not chosen: the server lighting fixtures
itself (every Light instance replicated, and a client couldn't budget or flicker them without
fighting the server), and a fixture staying lit while anyone stands in it (a real sensor, but it
would kill the freeze). The hold, the speed and the areas are first guesses for the owner to tune.

## D-025 · 2026-11-07 · The lights follow you: your screen predicts your own
The owner played L-03: right, but the light lagged, so you could step into the dark before it
came on, and it went out too soon. A real storage hall's lights follow you. So: each screen runs
the same pure watch on its own character and shows a light lit the moment either it or the
server says so; the server's word alone puts it dark or blind, and only the server's state is what
the building sees (keepers, the light board). Other players' and keepers' lights still wait for
the server, now ticking at 20 a second (was 10). The watch area is 40 studs long (was 32), so the
light ahead wakes as you pass under the one you're at; the hold is 7.5 s (was 5; the owner said
7 to 8); the tube lights at once and holds within a tenth of a second (one stutter, was 0.3 s).
Real light goes to the lit fixtures nearest a point 12 studs ahead of the camera, so the light
you walk into wins over the one behind you. Every stretch of the test hall now has a fixture
watching it, junctions included: a junction's middle is midway between its joists, so L-01 can
hang one there. Not chosen: the server alone with a longer reach (your own first step after a
freeze would still wait a round trip).

## D-026 · 2026-11-07 · A door sounds like its motion: a rattle that follows its speed, hits on its strikes
Each player's screen plays a door's sounds from the motion the server already replicates, so no new
traffic. While it moves, one looping roll-up door rattle (Pro Sound Effects' truck rear door)
takes its volume and pitch from the door's speed every frame: the curve can't drift from the
sound, and a lift from inside's three heaves surge on their own. Hits are one-shots timed off
`Motion.strikes` (when a slam lands and bounces, a close settles, a lift meets the stop bolts), on
the server's clock, so every player hears the slam when they see it. Loudness and reach per
action follow the GDD's noise column and live in `DoorSound` for keepers to share. The slam
shakes the camera with trauma that drains (squared on screen, smooth noise), layered on Roblox's
camera by taking last frame's offset off before it updates, so aim never drifts; a stand-in for
Brix's ENG-15. Recordings are Pro Sound Effects only (licensed, load in any game); their stretches
were found by measuring loudness in Studio, since no one here can listen. Not chosen: one recorded
open and close per action (its timing would fight the curve, and Peek and LiftInside have none).

## D-027 · 2026-11-07 · The floor: halls grown from the lobby on a grid of junction points
A floor is pure data from a seed (`Floor`, L-01a). Junctions and the lobby stand only on every
other point of the 24-stud grid, 48 studs apart, with one straight on each link between two: the
D-023 rule (a straight between two junctions) holds by construction, and parallel halls stand 48
apart with both rows of units. A point with two arms in line is a straight; one with a single arm
is a straight closed by a dead end. The halls grow from the lobby as a tree (from the newest point
half the time, otherwise any; carrying straight on 60% of the time, for long aisles), so every
hall is reachable, then loops join near halls, closing a dead end first. The lobby is the grid's
first row's middle, at the origin, its one hall leading into the floor (-Z) and the elevator
behind it, so every floor's elevator stands in the same spot. Each straight's side is two M slots
or three S (25%); the kit fixes a junction's (two M across a T's stub, two S on each outer side of
a corner). Where two halls leave one junction side by side, an M slot at that end is always a plain
wall: both of them, not one, since either unit's wire top would show the decks' overlap; half such
sides are three S instead, which stop short of it, so a hall between two junctions isn't all
wall. Units are numbered floor then two digits in the order you meet them walking out (left, ahead,
right at each fork), units across the hall back to back, your left first; a floor holds at most
99, and past that units picked at random become walls (1 floor in 1,000 at today's sizes). Each
floor's doors wear one colour, in turn. A light hangs over every hall piece's middle; with the
40-stud watch every stud of hall is watched (the spec checks each one). Power zones: "Lobby" to
the first fork, then a letter per wing. Short floors (1, 2): 5 by 3 points, 8 halls and a loop,
about 60 units; full ones: 5 by 4, 11 halls and two loops, about 80. The module takes Brix's Random
through its call (the contract's rule) and stays free of Roblox paths; Brix Schema checks the
plans in the spec, and moves to their loader when live config (ENG-11) can change them. Not chosen:
junctions on every grid point (two could touch and parallel halls collide, needing a repair pass);
odd numbers on one side and even on the other, as the test hall does (with mixed S and M rows the
sides don't pair up, and gaps would run a floor past 99); numbering by distance from the lobby
(numbers would hop between wings).

## D-028 · 2026-11-07 · The small unit wears the M's textures, cropped, not squashed
The S (8 by 8, a 6-wide door) is built from the same scripts as the M and wears the same five
texture sets (L-01b). Two things made that true, and neither was before. The slats, the bottom
bar and the drum span the door's width, and their texture was laid across the whole M door, so a
narrower door squashed the paint's grain to 77%; a narrower door now shows the middle of the
texture at the M's grain (`Spec.u_across`). And Blender's smart project packs the small hardware
(the padlock, latch, plates, drum ends) differently once a part moves, so the S's pack sampled
the wrong texels of the M's bake; another size now copies the M's pack face for face from the M's
scene (`bake.copy_atlas`), and the build stops if any of those faces differs in shape from the M's.
`art.sh` never bakes for another size and rebuilds its scene before every stage, so an export
never ships stale geometry. The curtain is identical at every size (the door height is common), so
the rig, the motion and every sound cue are the M's. In the test hall the short hall past the
corner holds three S a side, numbered 109 to 114, 112 padlocked: the cramped part of the building,
apart from the M rows the owner's earlier tests use. Not chosen: baking a texture set per size
(five more sets to stream and keep in step); the S door squashing the M's texture (the grain reads
finer than the M's beside it); the S row replacing two M units in the main hall (it would move
units the open tests in `OWNER.md` name).

## D-029 · 2026-11-07 · Laying a floor: piece by piece from the lobby, inside a frame's share
`FloorBuilder.lay` (server) turns `Floor` data into the building (L-01c). It lays the lobby, then
the hall pieces nearest the lobby first, each piece with everything on it (the kit's straight or
junction, its units and plain walls, a dead end, its light) dressed in an unparented folder and
parented once; between units, and after each piece, it waits a frame once 4 ms of that frame are
spent. Floor 3 of seed 7 (67 units) took 65 ms of work over 15 frames, at most 6.2 ms in one, so
L-08 can lay the next floor while the elevator rides without a stutter. A junction is laid with
its own walls except where a unit stands (`CorridorKit.junction`'s `units`, faces in the
junction's frame), so the unit's door is the hall's side; a junction's plain-wall slots keep the
kit's wall. A unit's `drops` (floor Dirs) pick WallLeft or WallRight by whichever stands toward
that way, so it holds at any turn of the floor. Each light's power zone is named for its floor
(`Floor3.A`), so two floors laid at once never share a breaker. The lobby is a stand-in until
L-05: one plain room, its square and the elevator's space behind it, lit only by a warm lamp in
the car, the one light on a floor that is always on, so you arrive in a glow and the hall's mouth
stays dark. The door's test prompts moved from the test hall to `DoorPrompts`, for any laid unit,
until L-02 replaces them. In Studio the test hall lays floor 3 of seed 7 (Workspace's
`DevFloorSeed` and `DevFloorNumber` change it) 600 studs off, and prints its map; "Walk a floor"
by the spawn goes there. Not chosen: the floor replacing the test hall (the owner's open tests in
`OWNER.md` name its units); a fixed count of pieces a frame (a piece holds none to six units, and
six can take a whole frame); padlocks on a laid floor (L-04 deals those).

## D-030 · 2026-11-07 · The door as a state machine: buttons for its state, each in a fixed place
The door is the GDD's state machine in a pure module (`Door`), read from what it's doing (its
Motion) and its padlock: closed, peeking, opening, lifting (from inside), open, closing, slamming,
locked. The GDD's list had no closing or lifting; both are needed, closing because a door pulled
down by hand can be turned back, lifting so nobody outside can shut a door while a friend heaves it
up from inside (the GDD: lifting from inside is always possible, a clip and never griefing). The
server's `Doors` system (on the Host clock, only doors in motion stepped) shows only the buttons
the state allows, each in a fixed place on screen (`Door.Slots`, `UIOffset` 150 px apart): Peek
left, Open middle, Slam right; Close shares the left spot with Peek as a toggle, so after any tap
the spot it hit holds nothing else and a double tap can't misfire. A press is checked for reach
(plus 4 studs of lag), side (Lift only from inside the unit's doorway, Peek and Open only from the
hall while the door is down), tools and rate (0.3 s a player), then decided by `Door`. A padlocked
door tried from either side rattles: a new door motion (`Rattle`, three jerks of a few
centimetres against the bolt, the light under the door flickering) whose sound is Pro Sound
Effects "Door Shake 4" (its first shake, 0.14 to 0.9 s), so motion and sound ride one attribute
and keepers hear it as far as players (`DoorSound.Actions.Rattle`). Every door event fires the
system's `acted` signal with that reach. Not chosen: a Lock button on every door (server prompts
show to everyone, so a padlock button would sit on every shut door for a tool few carry; the
padlock tool will call `Doors:lock`); hiding Cut from players without bolt cutters (no per-player
prompts without a client-side layer; "Need bolt cutters" teaches the tool exists); buttons stacked
vertically (a landscape phone has room across, not down); Lift on T (inside, Lift is the only
button, so it takes E). Tools are a stand-in: a player's `Carries<Tool>` attribute until Phase 2.


## D-031 · 2026-11-07 · Crawl holes between side-by-side units; tops run along a row, plain walls lidded
Built on the owner's default (their choice is still open in `OWNER.md`): a saw's crawl hole goes
only into the unit beside you, as the GDD's hole trap, and a ladder's tops run along a row. Rows
stay where L-01a put them, 16 studs apart back to back, so no unit backs onto another. The pure
`Floor` records, for every slot, what shares each of its walls (left and right as you face the
door from the hall, and back): the slot sharing the most of that wall, if at least 4 studs
(`CrawlWidth`: a 3-stud hole and a stud of wall each side). A run is a row's slots side by side,
facing the same way; every plain wall in a run that has a unit gets a lid, the unit's own wire top
and floor (`FloorBuilder`), so a friend running the tops never drops into the empty slot behind a
plain wall, and looking down through the wires shows an empty unit, not the sky under the building.
Two rules came from measuring 400 seeds (`scripts/floor-survey`): up to 11 units on a short floor
had no neighbour to crawl to and 1 short floor in 10 had at most one crawl pair before the first
fork. So a plain wall picked at random stays a unit if it would strand a unit beside it, and on
floors 1 and 2 (the plan's `teachHoles`) the hall from the lobby to the first fork has no plain
walls but a back corner's, and a back-cornered side there is three S units: at least 4 crawl pairs
on the way out of the lobby, none cut off anywhere on those floors. The random draws are made as
before even where their answer is ignored, so every other choice of a seed stays the same. Not
chosen: closing a run's back and its ends at a junction's hollow block (needed before the ladder,
ROADMAP Phase 2; the deck's 2.8 studs over the tops may make them crawl-only anyway); one lid of the
two that cross at a back corner where both halls' slots are M walls (the other slot would stay an
open drop; the two wire grids cross unseen from any hall).

## D-032 · 2026-11-07 · The moving boxes: real sizes, one Cardboard atlas, faces shared in pairs
L-04 split in three (boxes, the first finds, the director's dealing) because each prop set is a
session of its own, built the unit's way. The boxes come first: every unit is full of them, the
Stack keeper is a pile of them (GDD), and a unit dealt "nothing" is boxes alone. Five boxes at
U-Haul's real sizes, 10 inches a stud (the unit's 10 feet are 12 studs), so a large box comes to an
avatar's chest and a wardrobe box looms. Each box is one MeshPart sharing one 1024² Cardboard set
(colour, normal, roughness; no metalness map). Its faces are packed whole into the atlas, and a
face's opposite twin wears the same texels seen from outside, so the atlas holds half of each box at
97 texels a stud, near the unit's walls (128) and door (118); the cost is a box showing the same
label on both long sides, as people label boxes anyway. The recipe paints in each box's own studs
and each face's, so the tape, holes and labels sit where they would on that box, and words come
from a label sheet rendered from Studio's own fonts. Not chosen: a second texture set (twice the
memory for boxes alone); SurfaceGui labels (one draw call each, on every box of every open unit);
corrugation at the cut edges (2 texels a flute at this density). Every box of a size looks alike;
a second set of labels is in ROADMAP's polish list.

## D-033 · 2026-11-07 · Each unit has its own dim bulb; players carry no torch
The owner's call, after L-04a found the hall light stops at an open unit's doorway: "a small light
in each unit, dim", and players don't need a torch. So what's behind a door is seen by the unit's
own bulb, not by a beam the player aims. Default for the gap (`OWNER.md`): the bulb comes on as the
door rises and goes out when it's shut, keeping a shut unit the GDD's blind spot and P0-02g's dark
with a line under the door. On a phone only the nearest lit bulbs throw light, as the hall lights
do. Not chosen: a torch every player carries (R.E.P.O.'s head lamp), which would make the dark
something you push back yourself rather than the building's.

## D-034 · 2026-11-07 · The unit's bulb: wired to its door, drawn by each screen from the door
L-04b builds D-033. Each unit hangs a caged bulb on a short cord from the middle of its wire top, a
piece of the corridor kit (`Bulb`: a galvanized guard and a bakelite socket on the TrimSheet, a
plain glass the game lights), hung by `FloorBuilder.unit` from the wire top's own box, so every
size gets one. It's wired to the door like a fridge's light (`ShutIn.bulb`): on as the door starts
up, a peek's included, out the frame a closing door lands, and out through a slam's bounce; a
padlocked door's rattle never lights it. Each screen draws it from the door's replicated motion, as
it draws the door, so the server sends nothing new and the bulb can never disagree with the door.
Warm amber (the hall is cold white), 0.6 strong with an 11-stud reach, tuned at Level21 on the
Galaxy A16 view: at 1 and 12 an M unit read as a lit room to its corners. The guard casts no
shadow: from a point light its wires threw hard black bands across the whole unit. Real light and
the hum go only to the 3 lit bulbs nearest a point ahead of the camera, as the hall's fixtures do.
The light carries HallLight's tag, so BehindDoors dims a lit neighbour's bulb for whoever is shut
in (low graphics lights through walls), but leaves the bulb of the unit you're shut in whole. Not
chosen: a server-owned bulb state (one more replicated value that can only echo the door); the
bulb as part of the unit's own model (the unit's FBX and bake are the unit pipeline's, and a
lamp is a kit piece the lobby can reuse).

## D-035 · 2026-11-07 · The bedroom set's first finds: four real things, one atlas, unwrapped one by one
L-04c builds the GDD's 1980s bedroom set first, four pieces chosen to read from a doorway at phone
size in a dim unit: shape first (two round speakers and a handle; a screen and rabbit ears; a
bear's round ears; four pink wheels) and colours apart from the boxes' kraft (chrome and black;
walnut and silver; cream; white and pink). Real sizes at the boxes' 10 inches a stud. One texture
set per set (Bedroom: colour, normal, roughness and metalness, which the chrome needs), so a
floor's finds cost one set of maps. Dust is baked in on whatever faces up; a mimic will wear the
same atlas baked clean, not a second mesh. The GDD names no look for rarity, so there's none.
The pipeline differs from the boxes' in three places, each a Blender trap met here: each find is
smart-projected alone into its own square sized by its surface (unwrapped together, the teddy's
islands folded over one another); the bake runs with no margin and pads the gutter afterwards from
a coverage pass (each object's margin painted over its neighbours' island edges); and the bake's
unwrap is saved and worn by the later stages, with spheres built point by point (smart project
packs differently each run, and bmesh's `create_uvsphere` numbers its points differently). The
import into Studio was split off to L-04c2. Not chosen: the boxes' face-by-face atlas (curved
things have no flat faces to pack); printed words now (unreadable at phone size, in polish);
a rarity glint.

## D-036 · 2026-11-07 · Finds stand behind the unit's bulb; the skates lie wheels to the door
L-04c2 judged the four finds in unit 101 from its doorway on the Galaxy A16 view. Staged between
the bulb (at the unit's middle) and the door, each showed the doorway its unlit side: the TV a
black box, the boombox a dark lump, at Level21 with or without its metalness. A step deeper, behind
the bulb, all four read at Level01 and 21. So the director deals a find deeper than the bulb,
facing the door within a small turn, among the boxes in the back half, which is also where a real
unit's things end up. The skates' pair was re-posed in `art/finds/spec.py`: the fallen skate lay
behind with its wheels away, hiding the standing one's; it now lies in front with its row of pink
wheels to the door, the shape that says roller skate at 30 pixels. The pair is placed after the
bake, so the atlas didn't change. Not chosen: a brighter bulb (L-04b tuned it for dread, and the
owner judges it); a glint or rim light on finds (no hit-game precedent named; a mimic's clean look
is the tell, D-035); bigger-than-life finds (they match the boxes' real sizes).

## D-037 · 2026-11-08 · The loop first: every tool that works on any keeper moves into Phase 1
The owner judged the finds and boxes good, and set the order: an entity on the floor and the loop
proved fun (being chased, finding the code and tools, trapping keepers, slipping between units
from inside) before more polish. The props only dress a unit; finds are the run's payout and the
collection (GDD "Meta"), which the GDD's own build order already left to its second step. So
Phase 1 now holds the flashlight, the saw and the hole trap, the ladder (with closing the tops'
edges), bolt cutters, the padlock, bubble wrap, the air horn, the moving blanket and glow sticks
(L-11 to L-14), and the GDD's build order says the same (edited that day). Keeper-specific tools
(mothballs, the box cutter) stay with their keepers, the dolly with the finds. The Mannequin
splits: its art (L-06a) goes now, its chase (L-06b) waits on Brix's ENG-06 and ENG-07 and moves up
when they land. Where a unit's boxes and find stand, and carrying finds out, moved to Phase 2.

## D-039 · 2026-11-08 · The Mannequin: rigid R15 parts, posed by code, a stop-motion walk
The Mannequin is a shop mannequin cut at every joint into R15's fifteen body parts, each a rigid
MeshPart (no skinning), each end a dome that shows as a ball when bent, 6.3 studs tall (a head
over a player). `Mannequin.prepare` joins them as `Humanoid:BuildRigFromAttachments` would: a
RigAttachment pair at each pivot and a Motor6D named for the joint, under an anchored, invisible
HumanoidRootPart; no Humanoid yet (L-06b adds one only if Brix's `MoveTo` driver is chosen).
Poses are code, not uploaded animations (`Mannequin/Pose.luau`, pure, Lune-checked): its joints'
turns in degrees within each joint's limits, solved through the joints so every pose is checked
standing on the floor with no part through another, applied as `C0 = RigAttachment * turn`. Its
walk is four held keys with a snap between (stop-motion), and a light freezes it on a key, never
between two: it moves only unseen (GDD), so the keys are what players see, as Five Nights at
Freddy's animatronics are seen only where they stopped and SCP-173 moves only while unseen.
Uploading animations was possible but would put the poses beyond Lune's reach.

## D-038 · 2026-11-08 · The deal: notes and padlocks when the floor is laid, the rest on the first lift
`Deal` splits the GDD's "What's behind the door" in two. When a floor is laid: the code, its notes
(two with two digits each on floors 1 and 2, four with one above), placed one to each wing in turn
(the zones past the first fork) so a team splits up, at least 48 studs apart where any room
allows (it held on all 600 test floors), as DOORS spreads its door-50 code through the library;
the padlocked doors (6 in 100 units on floors 1 and 2, 12 above), never in the lobby's hall, and
from floor 6 the first note behind one. When a door first lifts (a peek or an open), the director
deals: nothing, a find, a tool, or a keeper asleep or awake, by its mood (Build 40/25/20/10/5,
Peak and Relief wake nothing), times the padlock's (more finds and keepers, rarely empty, as
Escape from Tarkov's locked rooms hold its best loot), the awake share turning asleep at the
floor's cap (1 on floors 1 and 2, 2 on 3 and 4, 3 above, as Left 4 Dead caps its specials). Each
unit's roll is drawn when the floor is laid, so a seed deals a unit the same kind of thing in the
same mood whatever order doors open in. Tools come out of a shuffled bag of 11 (two saws, bolt
cutters and padlocks, one of each other tool), as Tetris deals its pieces, so none goes missing
for long. Floors 1 and 2 teach: the bag's first tool is a saw and the lobby's hall deals no
keepers. A floor with no fork (about 1 in 50) counts its first 8 doors as the lobby's hall. Not
chosen: one random stream for everything (the order of opens would change every kind); notes at
random with spacing alone (all four could land in one wing); a cap on sleeping keepers (the GDD
caps only awake ones; the owner judges the count from `scripts/floor-deal`). Fake notes wait for
Phase 2's floors.

## D-040 · 2026-11-08 · The elevator: the car's own lattice gate, notes written by the game
The way up is a freight car behind a steel frame in the lobby's back wall (a 12.4 x 9.2 hole),
12.5 x 11 x 9.6 inside: room for the GDD's six to stand clear of the gate and for the Mannequin
to walk under its track. There is one gate, the car's own, a collapsible lattice gate as old
freight cars have, so it rides up with the car and you watch the lobby through it while the
timer runs (the gate shutting on its own timer is Dandy's World's). It folds to the left post as
you face the car and closes toward the keypad on the right; its pickets and 72 straps are cloned
from three meshes and posed by code (`Elevator/Gate.luau`, pure: a strap's angle is
acos(pitch / its length), so its pins stay on the pickets at any spread). Its sills are striped:
the line to be over when it shuts. The notes' digits aren't baked: a note shows one or two
digits in four slots (`_ 7 _ _`, GDD), too many ways to bake, so the game writes them with a
SurfaceGui in Kalam (Roblox's pen hand, Bold), as the units' numbers are written; the sheets use
the same font. Notes are a big pad's (0.7 studs) so they're spotted from a doorway. Three
texture sets: the car's walls and floor tile (80 texels a stud), the big trim is baked (41), the
small fittings (gate, lamp, keypad, keys, note) are baked at 133. Not chosen: a landing gate as
well (two gates to read, and the car's is the one players watch); baked note faces; vertical
bi-parting doors (solid, so you couldn't see what's coming while you wait).


## D-041 · 2026-11-08 · The elevator in the place: one template, its lamp casting shadows
The elevator is one template at `ReplicatedStorage.Props.Elevator` and the note another at
`Props.Note` (D-009), both made by `Elevator.prepare` from the Open Cloud import. The lobby's back
wall is three blocks round `Specs.Opening`, its face on the threshold, and the lobby is now just
its square: the car fills the floor's elevator space alone. The car's lamp is the stand-in's
light moved into the jelly jar (warm, 1.2, range 22) with shadows on, so it reaches the lobby only
through the opening and prints the gate's lattice on the lobby floor, the strongest "elevator"
read from across the room; the lamp, its glass and the keypad's small parts cast none. The whole
elevator streams as one piece (`ModelStreamingMode` Atomic), so a phone never shows half a gate.
`setGate` moves the gate's 85 parts in one `BulkMoveTo`. A note's digits are written on an
invisible card over the paper's flat writing area, not on the curled paper's box, at 400 pixels
a stud, with no padding top or bottom: Kalam's line is tall, so the width sets the size, as on
the sheets. Not chosen: a light without shadows (it lit the lobby through the car's walls);
writing on the paper's own face (its box stands 0.12 proud where the foot curls). The keypad
lights itself (owner's test, Nov 8): it hangs on the lobby's side of the wall, so once the lamp's
shadows settle no light reaches it and it went black; a small red light just in front of the
panel (`Elevator.KeypadGlow`, 1.6 studs) makes it the keypad's own glow, the sheets' "red glow"
seen across the lobby. Not chosen: a landing light (the lobby stays lit only by the car).

## D-042 The keypad is shared, checks on the fourth digit, and the server owns it (L-05b1a, Nov 8)

One keypad per floor and one readout for the team, as a real keypad is: you can punch the first
three digits while a friend runs back with the last (the GDD's co-op moment). There's no enter
key: the fourth digit is checked at once, as door keypads do, so a fat thumb costs a wrong code.
A Clear key, on the on-screen keypad only (owner, Nov 8; the wall's keypad has none), takes
back a mistyped digit before the fourth, so the alarm punishes guesses, not thumbs. Every
player types on that on-screen keypad, opened by the wall keypad's own prompt (owner, Nov 8),
as DOORS' padlock at door 50 opens: the wall's keys are a fifth of a stud across, and on a
phone the jump button sits over them. A wrong
code rings the alarm, lights every powered light on the floor at once (`MotionLights.flash`,
which lights them without `woke`: the building didn't see anything there, the keepers come to
the lobby instead, L-06b) and leaves the keypad dead for 3.5 s, its readout blinking the wrong
digits, then clears it. The code never leaves the server; the keypad's state crosses as one
counted value (`Keypad.Attribute`), so the same press twice still shows. The remote is the
smallest stand-in for Brix's typed remotes (ENG-09), its checks in their order: types, range,
rate, state. The gate's motion is one value too (`Gate.Attribute`: from, to, start), which every
screen folds the gate from and the server sizes the collider from, so the gap you see is the gap
there is; the gate gathers speed into its slam (ease-in) and recoils 2.5% for 0.22 s, as a
yanked lattice gate does, and its fold sound builds to the same slam. Not chosen: 85 parts moved
by the server; a ProximityPrompt per key (ten prompts on a panel a thumb wide); an idle timeout
on the readout (it would wipe the first three digits while you wait for a friend).

Settled (owner, Nov 8, after playing L-05b1c: "looks good"): all three rules stay as built.

## D-043 The keypad answers on every screen: LED digits, a pad by your thumb, sounds on the gate's clock (L-05b1c, Nov 8)

The readout is four seven-segment LEDs drawn as segments (`LedReadout`), not a font: no Roblox
font looks like a keypad's LEDs, and a dash at rest is then exactly the middle bar lit low, with
the unlit segments faint under the glass as a real one's are. One pure rule set
(`Elevator/Readout.luau`) feeds the wall and the screen, so they never disagree; the wrong code
blinks 0.2 s on, 0.2 s off with the status light, and green holds once the code is right.

The on-screen keypad (`KeypadPad`) opens from the keypad's own "Use" prompt (owner, Nov 8). Its
left edge sits 58% across the screen so the wall's keypad stays in view and you see its keys
sink; it fills 92% of the height under the top bar, which on the Galaxy A16 makes a key 44 by
41 points (at 72% they were 36 and hard to hit) and still leaves 22 points to the jump button.
A press dips the key and beeps and sinks the wall's key at once; the readout waits for the
server (one ping), so it never shows a digit the server dropped. The server's echo names who
pressed (`by`, now on a clear too), so your own press never beeps twice. Dead keys dim during the
alarm; the right code shows green for 0.9 s, then the pad slides away as the gate folds.

The sounds are timed off the server's clock (`Elevator/Sounds.luau`): the beep at once, the
buzzer 0.12 s after the last beep and the bell 0.4 s after, ringing exactly as long as the keypad
is dead; the ding 0.12 s after the right code, the latch 0.3 s before the gate moves, and the
fold started where its recording's slam lands the instant the gate hits, for any distance it
travels. A recording's first play in a session starts 0.26 to 0.35 s late even preloaded, which
would put the slam after the gate; `SoundPrimer` plays each once silently at start. The slam
jolts anyone within 5 studs (trauma 0.5, gone by 24), on the frame the gate hits.

Not chosen: a font for the digits; showing a pressed digit before the server accepts it; the pad
centred over the wall's keypad (it hid the keys you'd want to watch sink).


## D-044 The code's notes on the units' back walls, read from a few steps in (L-05b1b, Nov 8)

Each note the deal hands a unit (`Deal.new`, two notes on floors 1 and 2, four above) is stuck as
FloorBuilder lays that unit: always on the back wall, facing the door, at first person's eye
height (4.5 studs), on a crest of the corrugated wall, a little off the middle and up to 4
degrees crooked, varied by the unit's number (`Elevator/NoteSpot.luau`, pure, Lune-checked). One
place to look, learned on floor 1, so the search is about which door, never where in the unit.
The door lifts, the unit's bulb comes on, and the note is the one yellow thing in the box.

Measured on the Galaxy A16: the writing's digits stand 0.107 studs tall on the art's 0.7-stud
note, about 5 rows of the phone's view from a small unit's doorway, so nobody reads a digit from
there. The note is drawn at 1.6 times the art's size (`NoteSpot.Scale`, a 1.1-stud note): a
plain square from any doorway, its digit about 30 rows tall (2 mm on the phone) from 5 studs.
So you see a note from the hall and read it two steps into a small unit, five into a big one.
Reading from the doorway itself needs the writing laid out larger, four slots across with each
digit as tall as the note allows (about twice today's), or the note held up to the screen as
DOORS shows its library hints: the owner's choice (`OWNER.md`).

The text is written on the server and replicates with the unit, so an exploiter can read every
note on the floor; the hunt's honesty rests on the keypad's server check, not on hiding the
notes. Clients load Kalam as they start (`NoteView`, by measuring text in it) and redraw any
note that arrived first, since a note can stay blank until its writing is redrawn.

Not chosen: notes on a box (units hold no boxes until L-04e, and boxes move); notes anywhere in
the unit (a hunt inside the hunt, on a phone, in the dark); the note at the art's size.

Settled (owner, Nov 8): a "Read" button on each note holds it up on your screen, big, as DOORS
shows the hint in a library book (L-05b1d). The note stays on the wall at 1.6 so it's spotted
from the doorway; the button is how its digit gets read on a phone.

## D-045 Reading a note: the real note held up on the screen (L-05b1d, Nov 8)

Two steps into a note's unit (within 6 studs of the button, `NoteCard.Reach`) a "Read" button
shows under the note, never over it and never from the hall: you go in to read it, as DOORS makes
you walk to the library book. A tap lifts the note into the middle of the screen, as big as a
phone held sideways allows (84% of the height under Roblox's bar, at most 48% of the width, so the
thumbstick and jump button stay clear and stay usable). It rises from below, a little smaller
and more crooked, and settles with a small overshoot at the same tilt it hangs at on the wall, to
a paper flap; the world behind dims to 55% so the note stands out and you still see what's coming.

The card is the note itself: its own paper mesh, drawn face on in a ViewportFrame under a warm
light so it's the wall's yellow, brighter, with its thumb smudge and curled foot. A SurfaceGui
draws nothing inside a ViewportFrame (seen in Studio), so the four slots are TextLabels laid over
the paper's writing area (`Specs.Note.Write`, the wall's 4% margins), each a quarter of it, all
at one TextSize, so a blank and a digit are written alike. On the Galaxy A16 that's TextSize 94
and a digit 7.7 mm tall; on the wall from 5 studs it's 2 mm.

It drops on a tap on it, Read again (E, gamepad X), B, a click (mouse), walking back out to about
the doorway (8 studs, `NoteCard.LetGo`), dying, or the note leaving. For 0.3 s after it lifts,
taps and keys are ignored, so the tap that pressed Read or an impatient second one can't throw it
away. You can walk and look while it's up: the keepers don't wait while you read. The mouse isn't
freed for it: a click anywhere drops it.

The sound is Pro Sound Effects' "File Folder Movement 5" (9114409576), its one sharp flap at 0.78
to 0.88 s; the drop plays it lower and softer. All on the client: the note's writing already
replicates (D-044), so nothing new goes over the wire.

Not chosen: the note's texture cropped from the Fittings atlas as a flat image (the UVs are packed
and may turn, and it's the same 130 texels as the mesh); a plain yellow square (not the real art);
the digits laid larger than the wall's writing area (the card should be the note you saw); freeing
the cursor with FreeCursor (nothing to click but the note itself).

## D-046 The gate's clock: 30 s from the slam, felt everywhere on the floor (L-05b2, Nov 8)

The clock starts when the right code's gate has slammed open (the chime, the latch, the 1.6 s
fold), not at the code itself, so the 30 s are 30 s of open gate. It's the server's: one
replicated value on the elevator (`Departs`, the server time the gate starts to shut) that every
screen counts from, so friends count the same seconds; the server shuts the gate at zero with the
gate's own 1.2 s slam (`Gate.ShutSeconds`), and nobody can send it early (GDD). The instant the
shut gate hits its post, a Brix Zone box over the car (wall to wall, the gate's pickets to the back
wall, floor to ceiling) says who rode: their UserIds go out as one value (`Aboard`) and the server
fires `departed`. A player diving through the narrowing gap makes it if their middle is inside the
pickets when the gate hits (verified: crossed at 28% shut).

Everyone within 240 studs of the elevator is on its floor (a floor's farthest hall is 195 studs
away, measured over 300 seeds); they see the clock and hear the PA. What they get, by the GDD's
Dandy's World line (an alarm and a heartbeat over its elevator timer):
- The clock: the elevator's own seven-segment LEDs on a dark plate, in the middle of Roblox's top
  bar row (clear of its buttons, `GuiService.TopbarInset`), so it never covers the play or a held
  note. Green while there's time, red from 10 s; it jumps each second of the warning.
- The PA's chime as it starts (Pro Sound Effects' synth elevator chime, heard alike across the
  floor), so a friend at the far end knows to run before they see anything.
- From 10 s: the car's lamp blinks, slowly then ever faster (0.9 s blinks down to 0.16 s), and a
  heartbeat (APM's, 78 a minute) swells from 0.2 to 0.6 volume and quickens to 1.45 times its pace.
- The last five seconds: the elevator's bell (the right code's double-ding) once a second, each a
  little higher.
- Leaving: "Going up" in the lamp's warm colour for those aboard, a lurch 0.7 s after the slam;
  "Left behind" in a cold red for the rest, and the car's light draws away over 1.6 s, leaving the
  lobby dark. The stand-in ride (until L-08): 4 s, fading to black over its last 0.6 s while the
  dev floor moves those aboard back to the spawn and re-arms the elevator.

Not chosen: the clock started at the code (the gate isn't open yet); a timer label in the play
area (it covered the held note and the keypad's pad on a phone); a client deciding who's aboard
(the server owns it); positional countdown sounds (a friend at the far end must hear them);
a PA voice now (no recording yet: ROADMAP polish).

## D-047 The flashlight: yours drawn on your screen, the server owns on and off (L-11a, Nov 8)
Everyone carries the torch from spawn, in the right hand, as the GDD's tools table says; it is no
slot's tool. Your own is a copy on your screen only, held to the camera (`Torch.Hold`) in a local
Workspace folder and stepped after the camera and its shake; the one in your character's hand is
hidden from you by Roblox's first-person camera and drawn for friends. Each screen lights a torch
itself: yours the moment you click (the click, the lens, the beam, the button), friends' from the
`On` attribute the server writes. The client sends the state it wants, not a toggle, and sends it
again if the server disagrees for 0.4 s, so a refused or lost message can't leave it inverted; the
server takes a burst of four switches, then one each 0.08 s, so three blinks ("it's me", GDD) go
through and mashing doesn't. While it's on, your look's pitch goes to the server (unreliable, at
most ten a second, only when it moves 1.5 degrees); friends' screens raise your arm to it after
your animation (the shoulder's Transform), and keepers will read it (L-06b). Keys: a right click
(Lethal Company uses its mouse buttons for the held item) and R1, because F already closes a door;
a phone button above the jump button. No battery and no flicker: the GDD gives the torch neither.
Light budget: your beam and the nearest three friends' (within 140 studs) are shadowed spotlights;
past that a friend's torch shows its lit lens only. A soft PointLight just above your torch's head
throws the spill ring round the pool and lights your torch in a dead hall; it also lights a wall
close in front of you at low graphics, where a spotlight lights nothing nearer than about 3 studs.
Not chosen: F (the door's Close); the server switching lights (your own would show twice and lag a
round trip); the torch as a Tool (Roblox's backpack and its arm pose); a battery (not in the GDD).


## D-048 Two tool slots, Lethal Company's way; the tool in your left hand (L-11b, Nov 8)
You carry two tools besides the torch (GDD: "two tools plus whatever's in your hands"), as Lethal
Company's slots: one slot is in your hand, and an empty slot is an empty hand. Picking up or being
handed a tool puts it in your hand if it's empty, otherwise in the other slot and into your hand
(you see what you took); both refuse when both slots are full ("Hands full" on the prompt). Drop
and Give take what's in your hand and leave that hand empty. Rules are pure (`Tools.Carry`); the
server owns every tool (`Slots`): a tool lies on a floor with a "Pick up" prompt (E, X on a pad)
until taken; carried, the one in hand is welded in the left hand for everyone, the rest are out of
the world. A tool is one row in `Tools.Catalog`, keyed by `Deal.Tool`, as keepers are rows.
The left hand, because the torch has the right (D-047); your own is drawn on your screen, low on the
left with the torch's sway, swinging up as it arrives and down as it goes. Switching answers at
once on your screen (a soft clank; the server is told and has the last word after 0.6 s); a pick-up,
drop and handover wait for the server, whose clanks everyone near hears. A drop lands crosswise
2.2 studs ahead of you, its middle on the floor a ray finds (short of a wall), falling 0.32 s.
The bar: two squares at the bottom middle with a real 3D picture of each tool, tap or 1/2 or the
d-pad; Drop beside it (G, d-pad down) while you hold something; the tool's name above the bar for a
moment, as Minecraft's hotbar names what you switch to. Handing over is a local "Give" prompt on
each friend within 10 studs while you hold a tool: Lethal Company has no handover (you drop it at
their feet), so this one-press shortcut is an untested bet in `OWNER.md`. Brix has no carried-items
piece (FRAMEWORK); `Carry` and `Slots` are the stand-in behind that shape. Until L-11c reads the
slots, `Slots` keeps the old test attribute `CarriesBoltCutters` true while either slot holds
cutters, so Cut still works; the test hall's "Bolt cutters" post is gone, two pairs lie on floors.
Not chosen: Roblox's Tool and Backpack (its arm pose, its own hotbar and keys; the Backpack core UI
is now off); the server drawing your own held tool (a round trip late, and it can't sway).

## D-049 Tools work in your hand; the padlock goes on and the cutters snap it off (L-11c, Nov 8)
A tool works only in your hand, as Lethal Company's do: Cut needs the cutters in your hand, Lock a
padlock in your hand. One in your other slot gets "Hold the cutters" or "Hold the padlock"; none at
all gets "Need bolt cutters" or "Need a padlock" (`Door.decide` takes where each tool is: hand,
slot or none; `Doors` reads it from `Slots:carried`). The `CarriesBoltCutters` stand-in is gone.
Lock is a door button like Cut, in the same right-hand spot (they never show together), both held
(Cut 1 s, the GDD's; Lock 0.5 s so nobody padlocks a friend in by a slip; `Door.Holds`), keys R
and R2 (R1 is the torch's, D-047; Cut moved off R1). The server shows Lock on every shut door; each
screen hides it unless a padlock is in that player's hand (ToolView sets the button's reach to 0:
the server never changes a button's reach, so it stays). The padlock that goes on a door leaves
your slots for good (`Slots:spend`); on the door the building's own padlock part shows.
"One padlock per use" (GDD, the cutters' row) is read as: a cut padlock is spent, the cutters last;
the owner may mean the cutters break instead (`OWNER.md`). The cut answers in three ways: the jaw's
snap (Pro Sound Effects' "Scissors Snap 28" at half speed, loud, heard 40 studs: keepers hear a cut)
with a jolt for whoever's at the door; a copy of the padlock thrown off the latch on every screen,
tumbling about 1.5 studs out onto the hall floor, lying 20 s, then fading (`DoorView`); and its
clatter as it lands. While you hold Cut or Lock with the right tool, your view brings it out to the
door (the row's `use` pose), and it jerks as it works. The padlock you carry is the doors' laminated
padlock, open, at twice their size so it reads on a phone (`art/padlock`).
Not chosen: a brass padlock of the players' own (it would change look on the door unless the door
drew it too); a per-player Lock prompt made on each client (the server owns the door's buttons).

## D-050 The deal laid on the floor: padlocks as the floor is laid, the rest on a door's first lift (L-04e, Nov 9)
The doors a floor's deck padlocks arrive padlocked: FloorBuilder sets each one's padlock as it
lays the unit, before it reaches Workspace, so no padlock sound plays and every screen gets the
unit already locked (`Doors:lock` with no player would fire a padlock's sound for each door).
Everything else is dealt when a door first lifts, a peek, an open or a lift from inside, by the
new `Deals` system listening to `Doors.acted`, as Left 4 Dead's director deals as the team moves:
`Deal.open` in the Build mood (the director is Phase 2), the keepers awake counted from those dealt
awake on the floor so far. What's laid goes down at the start of the lift, so a peek's foot of gap
shows it on the floor. A tool lies to be picked up (`Slots:lay`); a find stands as a prop (carrying
finds out is Phase 2, "Finds in a run"), which find picked by the unit's own roll from `Deal.Finds`
(the bedroom set, equal odds until rarity); a keeper's place is handed on by `Deals.dealt` for
L-06b to stand the keeper there. A tool with no art yet (the saw, the ladder, bubble wrap, the air
horn, the moving blanket, glow sticks) is dealt but lies nowhere: about 6 dealt tools in 11 show
nothing until L-12 to L-14 build them; Output in Studio says so per door.
Where in the unit is `DealSpot`, pure and Lune-checked: on the floor, 0.4 studs off the walls'
middle lines, 2.5 studs clear of the door's line; finds and keepers wholly behind the bulb, facing
the doorway's middle within 8 degrees (D-036); tools in the bulb's pool (their footprint between a
quarter and 70% of the depth: at the back wall of an M unit the bolt cutters read as a red smear
on the Galaxy A16, `docs/art/L-04e-cutters-301.jpg`), at one of six careless turns; the spot picked
by the unit's number. The note's sight line (D-044) is kept as a real line, not a floor plan: the
eye looks at the note from 4.5 studs up or higher, so a thing under 3.5 studs (every tool and find)
may stand under the note, and anything taller (a keeper) keeps 0.3 studs off the whole floor
between the doorway's width and the note's. A small unit's 6-stud door in its 8-stud box leaves a
keeper only the back corner beside the note's line, too tight to turn in, so there a keeper faces
straight out (then square on) instead of at the doorway.
Not chosen: dealing every unit when the floor is laid (the deal is the director's to pace, and a
peek should be a gamble, D-038); keeping finds out of the whole floor fan in front of the note (in
an S unit it left a boombox nowhere to stand, and nothing that short can hide the note); a glint or
highlight on tools (no precedent named, D-036's reasoning); laying a stand-in for unbuilt tools.

## D-051 The saw: a green cordless reciprocating saw, standing on its battery (L-12a, Nov 9)
The GDD's saw ("cuts a crawl hole into the next unit; keepers can't fit through; loud") is a
cordless reciprocating saw, the tool a real crew would cut drywall and sheet metal with, built
from code the cutters' way (`art/saw/`): one MeshPart, one baked 1024² set, no brand. Green,
because the torch is yellow and the cutters red, so the three never blur at a glance, and green
stays green under a unit's warm bulb where blue goes grey. Sized about 1.3 times life (2.9 studs
blade to tail), a little under the cutters' scale but a bigger thing, so it reads on a phone from
a doorway as a green power tool with a blade. It's laid standing on its battery (every tool is
laid with its lowest point on the floor and its own up kept up, `Slots`), its side profile the
most readable thing in the unit. In your view it sits low on the left by its rear handle, turned
in 26° so you see its side, sticker and blade reaching to the middle; far enough out and left
that the slots' bar clears it on the Galaxy A16. A friend sees it carried upright by the rear
handle at your side, blade forward (`inHand` 0, 0, 0), as you'd carry a drill at the ready; the
honest carry (hanging nose-down from a relaxed hand) reads less as a saw, and is the owner's call
(`OWNER.md`). Its `use` pose (out in front, blade level) is a placeholder for L-12b. Picking it up
plays Pro Sound Effects' "Plastic Ice Chest 25" (a hollow plastic knock, 0 to 0.42 s); dropping
it, "Chair Drop 3" from its first hard hit (0.22 s, 0.9 s long, a little higher pitched), both
measured by loudness since nobody here can listen. The saw is the first tool out of the bag on
floors 1 and 2 (D-038's teaching floors), so it now lies there; `Specs/Saw` carries its blade's
tip and the shoe's face for L-12b.
Not chosen: a hand saw or a drywall jab saw (quiet, and the GDD says loud); a chainsaw (a horror
villain's weapon, not a crew's, and too crude for a neat hole through a unit's wall); lying the saw
on its side (its profile foreshortens from a doorway and its battery hides).

## D-052 The crawl hole: one fixed spot per wall, its own kit swapped in (L-12b1, Nov 9)
A saw's crawl hole opens at the same place in every unit's side wall: 3.75 to 6.75 studs along
from the corridor wall's outer face, 0.3 to 2.9 up (`crawl_*` in `art/unit/spec.py`). Players
learn where to look and where to crawl, the "Crawl through" button and keepers (L-12b2, L-12c)
have one spot per wall, and the art is built once rather than cut anywhere at runtime. The spot is
past the door's guides and in the bulb's light, and a stud short of a small unit's back wall, so
it fits whichever neighbour stands the shared wall (D-031): two units side by side in a row share
at least a small unit's whole side. It is 3 wide and 2.6 tall: a player ducks through on hands and
knees, a standing body (4 studs to the top of its root) can't walk it, and the Mannequin (6.3 tall,
and stiff: it can't bend) never fits. The hole is a kit of its own (`art/hole/`, asset
`Props.CrawlHole`), not parts in the unit's FBX: the unit and its prepared templates stay as they
are, and only a cut wall pays the hole's triangles (2,532 against the plain wall's 336). The holed
walls and the fallen panel wear the unit's own Partition texture (`prepare` copies it from
`Units.M`), so the swap changes nothing but the hole; the bright strips, cut faces and tongues are
a small Hole set. Its pieces come both ways round (Pos and Neg): the tongues bend and the panel
falls away from whoever sawed. The wall's one collision box becomes four round the hole
(`CrawlHole.Boxes`). Not chosen: a hole cut wherever the saw meets the wall (runtime geometry, or
many prebuilt walls, for no gain in play); a hole down to the floor (the bottom track would have
to be cut, and a saw cuts the sheet above it); a corner pair's two walls (a side against another
unit's back wall) holed: those stay unsawable, the rarer case, until a floor needs them.

## D-053 Sawing the hole: a four-second hold, loud the whole time, lost if you let go (L-12b2, Nov 9)
Every two units side by side in a row get a Saw button each side of the wall they share, at the
hole's front third (`Saws`). It shows only on the screen of someone carrying a saw (either slot):
a saw in your other slot gets "Hold the saw", as the cutters' "Hold the cutters". Hold it 4 s (R,
R2 on a pad, the cutters' keys): a held, noisy job, as Dead by Daylight's generators are worked by
holding and Granny hears every sound you make. The motor (a grinder's whine) and the blade (a cold
saw grinding pipe) are heard 200 studs off, further than any door (110), and `Saws.sawing` tells
keepers the same as the motor starts and as the panel falls (L-06b). A bright orange-hot line
crawls round the cut from its top front corner at one speed (`Sawing.line`, pure, 3,248 Lune
checks), sparks fly on the sawer's side, the sawer's view buzzes and their saw shakes out at the
wall. Through, the panel tips over from the hole and slaps flat on the far side with a sheet-metal
clang that jolts anyone within 30 studs. The server checks the press as Cut's (inside the unit you
saw from, in reach, the saw in hand, rate) and again before the hole goes through: the hold must
have run its time (a faked press can't cut early); walk off, switch tools or die and the cut
stops. Let go early and the cut is lost: the next try starts over (the prompt's own ring restarts,
and a half-cut wall would need art of its own). The deal keeps tools off both side walls' hole
spots, and finds and keepers too unless they'd have to stand in front of the bulb (D-036 first):
in a small unit the hole's stretch is most of the back half, so its finds and keepers mostly
stand on a spot anyway. Not chosen: progress kept between holds (no partial-cut art; a timer
restarting is honest); the button shown to everyone (a Saw button in every unit's walls, for a
tool most players don't carry); a hold under 3 s (the floor barely hears it) or over 5 s (too
slow to cut one mid-chase for the hole trap).

## D-054 Crawling through: a pressed button, a short move the game makes, your screen moving you (L-12b3, Nov 9)
Every holed wall gets a Crawl button each side at the hole (`Crawls`), E (X on a pad), the door's
key: a verb you press, not hold, because it's the escape with a keeper on your heels. The game
then takes you through in about 1.4 s, as DOORS' and Pressure's vents take you low through a gap:
0.3 s down onto your belly at the hole's mouth (from wherever you pressed), 0.75 s in two pulls
that surge in their middle, 0.35 s up on your feet a step past the hole (`Crawling.pose`, pure,
Lune-checked: always forward, flat at the hole's height wherever any of you is in the wall's
plane, both ends fitting a small unit). Your own screen moves your body (Roblox gives each screen
its own player's body, so friends see it move smoothly; a server-moved body steps at the network's
rate), with PlatformStand on and your parts in a collision group that touches nothing, so the
hole's edges and the floor can't snag it; the server checks the press (inside the unit you crawl
from, within reach, rate, not crawling already, the hole free) and, if you're still in that unit
once the move is over, puts you through itself. Your view rides with your head: low, looking at
the hole, rocking toward each hauling arm, then rising, handed back exactly where Roblox's
first-person camera sits (1.5 up, 0.5 back) so nothing jumps. Every screen poses a crawler's arms
up past the head, tucked in so they fit the hole, the hauling hand planting on the floor; plays a
body's thud as you land, a drag on each pull and a steel scrape as your shoulders reach the cut,
heard 35 studs (`Crawls.crawled` tells keepers the same). One body in a hole at a time: a second
press gets "Wait for them". A Crawl button shows only on your own side of its wall (through the
hole you'd see the far one) and none while you crawl. A keeper (6.3 tall) never gets the button
and can't fit the 2.6 hole. Not chosen: a crawl you steer yourself (a crouch mode and its camera
for one gap; the ticket's moment is the escape, not the steering); holding the button (slow when
it's the escape); a longer move (reads as a cutscene) or under a second (reads as a teleport); a
wider hole (the default avatar fits with its arms tucked; OWNER.md asks).

## D-055 The tops closed: lids round the junctions, a panel at every drop (L-13a, Nov 9)
Before the ladder, the tops had to be a place you can't fall off the world from. A floor's pure
`Floor` now says where everything goes, so Lune checks it over 400 floors on a 2-stud raster: no
edge of the tops is open except a unit's front onto its hall (the way down), a wall a junction or
the lobby already stands to the deck, or a dead end; no panel stands across the tops' way, hangs
in a hall or turns its bare sheet into a unit. **Lids:** of a junction's four corner squares,
those no slot stands in (its blocks of wall, and a corner's outside square behind both its rows)
get an S unit's wire top (its floor is the junction's) wherever a run reaches them, so a run goes
on round the corner instead of dropping into a floored pit with no way out; each run lists the
lids it reaches (`Run.lids`) for L-13b's ladder and for keepers to know where the tops lead.
**Panels:** every other open edge, found as 4-stud stretches and closed line by line, is the plain
wall's panel above its cap (an M's 12 or an S's 8, the kit's own `Panel` mesh, `CorridorKit.panel`)
with a collider from the cap to the deck: the rows' backs over the 16-stud gap, the 4-stud step
where a 12-deep unit stands beside an 8-deep one (about ten a floor), a run's end beside the
lobby, a lid's side over an empty slot. A lone 4 studs takes an 8 that reaches on into the dark
behind the tops, which nobody can see once the backs are closed. Every panel's sheet stands on its
line, so panels meet flush along a line and at corners, and over a unit it goes on up from the
unit's own wall (whose sheet is on that line too). Where the tops have no wall of their own below
(a plain wall's lid, a junction's square), the panel turns its bare sheet to them down to the floor
and brings the wall's trim, whose cap closes the seam: looking down through the wires shows a wall,
not the night sky under the building (Studio showed the sky there before). Up to 120 panels and 22
lids a floor. Not chosen: a new 4-stud panel built in Blender (the 8 hides its spare 4 in the dark);
a panel per slot side (back corners and two extensions meeting left gaps or overlaps on 9 floors
in 400); the deck's edge for the backs of 8-deep units (leaves a 4-stud slot behind them to fall
into); the whole plain wall for the pits (its painted face and kick plate inside an empty unit).

## D-056 The ladder: a two-part aluminium extension ladder, on your shoulder, both hands (L-13b1, Nov 9)
The GDD's ladder ("gets you onto open unit tops") is an aluminium extension ladder built from code
the saw's way (`art/ladder/`), at the building's scale, not enlarged to a hand: 6.8 studs
collapsed, so it lies across a small unit (7.2 inside) and turns a hall's corner, and two parts,
the base (the tool's body) and the fly welded on it, so L-13b2 can run the fly out 5 studs when
it's leaned (11.8 long, reaching 11.4 up at the 4-to-1 rule, past the 10-stud wire top), as
Lethal Company's extension ladder shoots up when placed. Pale, mostly diffuse aluminium (shiny, it
lay on a unit's floor as a black shape); a yellow rope and orange and yellow labels for detail,
no colour of its own: its shape is the read. **Carrying:** friends see it on your left shoulder on
its edge, top leading, welded to your upper torso (`Catalog` row `shoulder`): from the hand it
would see-saw with the walk's arm swing and drag the floor. It takes both hands, as Lethal
Company's two-handed items: while it's in your hand you can't switch slots or pick anything up
("Drop the ladder first", said on your screen and refused by the server), and nobody can hand you
a tool ("Their hands are full"); your torch stays in your other hand. It slows your walk to 12
(Roblox's is 16), as Lethal Company's weight slows a carrier: the one with the ladder is the one
the team waits for. In your view it sits low on the left on its edge, rolled to show its rungs,
its top end reaching across the bottom of the view. Picking it up plays Pro Sound Effects' "Metal
Ladder Bang Slams Against Body 1" (a bang and its rattle, 0.85 s); dropping it, "Metal Ladder
Impact 1" from 0.62 s (a creak, the hard hit on concrete at 0.70 s, rattling bounces), both picked
by loudness. **Where it lies:** by its whole collapsed box (`Tools.bounds`, both parts), at
DealSpot's dropped turns; it can't keep off the crawl-hole strips in a small unit (wall to wall
there, one place) or fit the bulb's pool beside them in a big one (it lies deeper), DealSpot's own
fallbacks, and big enough to read anywhere.
Not chosen: a one-piece ladder (L-13b2 couldn't extend it); a fixed 11-stud ladder (through every
wall as you carry it, and no small unit holds it); carried hanging from the hand (swings, drags);
posing both arms on it (the torch has the right hand; a friend's raised arm is in the polish list);
leaning the dealt ladder on a unit's wall (a new resting pose; listed as polish for after L-13b2's
lean).

## D-057 The ladder leaned and climbed: a pressed Lean, a pressed Climb the game makes, a spot each on the top (L-13b2a, Nov 9)
**Leaning:** a Lean button (R, R2 on a pad: the hold verbs' key, a tap here, so it never fights a
door's E) sits up by each unit's top edge on the left of the door as you face the unit, shown
only to whoever has the ladder in hand (ToolView, as the saw's button). Pressed, the ladder leaves
your hand (`Slots:place`; Slots still owns it) and stands at the 4-to-1 rule (feet a quarter of
the height out, about 2.7 studs into the 8-stud hall), its back resting on the front's top edge
beside the door, so most of the doorway stays open; one ladder per front. Every screen plays it
going up from the server's start time (`Leaning.raise`): a 0.4 s swing off the shoulder that
settles, a bang as its top lands, then the fly runs out its 5 studs accelerating, rattling, and
stops dead with its locks' clack at 0.85 s, as Lethal Company's extension ladder shoots up when
placed. Collapsed it doesn't reach the edge; run out, its caps are 1.4 studs past it, under the
deck. Its parts stay inert: nothing collides with it. **Climbing:** a pressed Climb (E) at its
foot, and the game moves you, as the crawl does (D-054; DOORS' and Pressure's vents): onto it,
up it at 7 studs a second in surges a step every two rungs, then over the edge in an arc onto
your belly on the wire top, about 2 s in all, your screen moving your body (PlatformStand, the
crawl's collision group) and playing Roblox's own climb animation from your character's Animate
while you're on the rungs, so friends see a climber, not a sliding body. Your view stays yours to
turn and rides with your head (Roblox's camera follows the root turned with it, so lying flat it
sits at your head, 0.85 above the wire). Each climber lies in a spot of their own along the
front, 2.2 apart (three on a small unit, four on a big one: "No room up there" after); one on
the rungs at a time ("Wait for them"), the next free once the one before starts rolling over.
**Down:** a Climb down button (E) just ahead of each spot, out of reach from the hall; the game
slides you back onto the ladder, down it and a step back into the hall. **Take** (F, beside
Climb) puts it back on your shoulder (`Slots:handBack`), refused while anyone's on it ("Someone's
on it") or up there ("Someone's up there"): until L-13b2b's drop off a front exists, taking the
ladder would strand them. Every press is checked on the server (reach plus lag, rate, the ladder
in hand to lean it and not to climb, your spot to come down) and if your screen never moved you
the server puts you at the move's end. Keepers never get these buttons; `Ladders.climbed` tells
L-06b's keepers about the bang going up (60 studs) and each climb (30). Not chosen: Roblox's own
truss climbing on an invisible TrussPart along the ladder (tried in Studio: a truss leaned 14
degrees off vertical flicked the climber between Climbing, Running and Freefall, and a vertical
one leaves a friend climbing a stud off the ladder); a climb you steer (stopping halfway is no use
on an escape, and the crawl already set the pressed move); Climb down as a screen button (the
prompt keeps every verb the same on phone, pad and keyboard); leaning in front of the door's
middle (it would block the doorway).

## D-058 The tops closed in steel: nobody sees into a unit from above (L-13b2b, Nov 9)
Owner, Nov 9: with open wire tops, a player up there could shine a torch down into every unit,
find the floor's code and see which units to avoid without opening one. That kills the slow, loud
open the game is built on. So every unit's top, and every lid round a junction, is now the walls'
ribbed R-panel steel laid flat: two sheets running front to back, the back one lapped over the
front one on the middle of the three channels (the unit's bulb still hangs from that one), the
rib ends closed at the front edge and at the lap as a roof's closure strips close them, so
nobody looks down a rib into a unit. One part, `Top` (was `WireTop`), in the walls' Partition
set, wearing its clean upper band (no new texture set); 860 triangles on an M (the wire was 696);
the same collider, so the ladder's spots didn't move. From the tops you now see only into the
halls, over a unit's front edge: you scout where the keepers walk, not what the units hold.
Landing on it is Pro Sound Effects' "Metal File Cabinet Body Impact Ringy Resonance 11", a body
against thin steel that rings (measured in Studio: hit at 0.15 s, settles at 0.65 s, gone by
1.6 s; unheard), and its tail as you slide off; the fence rattle went with the wire. Also decided
(owner, Nov 9), for the tickets after: the crawl along the tops is steered, as Outlast's crawl
spaces are, kept on the run so nobody slides off or clips (L-13b2c), and steel is loud under you,
heard below as Alien: Isolation's vents are; and the saw can cut down through a top so you drop
into a unit blind, as Rainbow Six Siege's floor hatches, one-way with no ladder inside (L-13b2d).
Not chosen: leaving some tops as mesh (those units are scoutable again), a mesh kept dark (a
torch defeats it), a texture set of the top's own (the walls' steel already is one).

## D-059 Along the tops: a steered crawl held on the map, a drop off any front (L-13b2c, Nov 9)
Once you're up a ladder, the stick steers your lying body over the steel, as Outlast's crawl
spaces: slow (4.5 studs a second, about a quarter of a walk, so being up there is a commitment and
a unit's width takes a few seconds), each 2.2-stud pull surging as an arm hauls, backward at half
speed with your head still the way you look, and your body turning toward where you crawl at 200
degrees a second (it barely moves until it faces about the way, so it turns before it slides).
Your screen moves your body (PlatformStand, the crawl's collision group, D-054) and nothing
physical holds you: the pure `Tops` map does. Each floor publishes its tops as rectangles on its
model (`Floor`'s run slots and lids, D-055, plus a 1.4-stud lip over each unit's hall), the test
hall from its units; a lying body is three squares along it (head, middle, feet) that must lie on
the steel, only the head may go out over a front's lip, so you can push your view about half a
stud past the edge and look straight down into the hall, and never through a panel, a junction's
wall or a dead end. Wedged by an edge while turning round, the body turns the long way or squirms
off the edge (the first lying spot by a run's end is too near it to swing a 5-stud body round).
The server checks your claimed place five times a second (on the map within 1.5 studs, at lying
height, no faster than the crawl's surge allows plus lag) and puts you back where you last were,
telling your screen. Push comes from `Humanoid.MoveDirection` (Roblox keeps it current while you
lie PlatformStand; the PlayerModule no longer hands out its move vector, docs/STUDIO.md). Your view sways and dips a few
hundredths of a stud with each pull (`CameraOffset`). Every screen hears each crawler's pulls from
how far their body moves: a soft low boom of the steel (the landing's recording, pitched down and
quiet), every other one higher, with a quiet drag; every other pull is a `Ladders.climbed` "Crawl"
heard 30 studs, for keepers. **Off the tops:** once up you're off the ladder (your spot free once
you crawl from it), so Take is refused only while someone's on the rungs. Climb down sits over the
ladder's top just past the edge, from wherever you crawled to (you slide over onto it). Drop down
(F, pad B; G is already Slam and Drop) sits over the middle of every unit's front, just past the
edge and a little above the steel, so it's on screen whether you look along the top or down over
the edge (back on the steel it was behind your view as you looked down; Studio). Pressed lying by
the front, the game takes you over the edge (0.3 s), down feet first (0.3 s, about Roblox's
gravity over 8 studs) and into a crouch as you land (0.3 s), standing 1.8 studs out facing the
hall, with the steel's tail as you slide off and a body's thud and a jolt as you land, heard 45
studs (`climbed` "Drop"). Up there only you see these two buttons. Not chosen: real physics on the
steel (a body slides and clips at the panels' seams, and the server couldn't hold anyone to the
tops); a disc for the body (the head would poke through panels); the body turning with your view
(the view, at your head, would swing round your hips whenever you looked about); a drop without a
button (G clashes, and walking off an edge by accident on a phone is an instant, unwanted escape).

## D-060 What you hold is drawn small and near your eye (L-13b2c2, Nov 9)
The owner saw the torch and tools go through the roof and doors. Roblox draws held things in the
world with everything else (no layer on top, as shooters draw your gun), and the full-size torch
reached 2 studs from your eye. Each is now drawn at a third of its size a third as far away
(`Hands.Scale`, scaled once with `Model:ScaleTo`): every point lies on the same line from your eye,
so the screen shows exactly the same thing, but the torch reaches 0.61 from your eye, and standing
flush to a wall your eye is 1.45 from it. Where even that touches (lying on a top looking down),
a spherecast from behind your eye along your view finds the nearest solid surface and the thing
pulls back at once and ducks under your view, easing back out (Ready or Not, Escape from Tarkov).
The beam keeps its full-size spot so the light and its shadows fall as the owner approved, but
reaches there from the drawn lens only as far as it's clear: never past a lid or a door (looking
down over a front it still lights the hall; a lens spot behind your eye would have lit the steel).
A friend's beam is checked from their head. Not chosen: a ViewportFrame overlay (its own lighting,
so the torch wouldn't sit in the dark hall); pull-back alone at full size (the torch would duck
whenever you came within 2 studs of a wall: in every tight spot); the third of size smaller (the
torch's tail would cross the camera's 0.1-stud near plane). Friends' tools and the ladder on a
friend's shoulder still pass through doors in third person, as nearly every Roblox game allows.

## D-061 The sawn top: one spot per unit, behind the drum across the first channel (L-13b2d1, Nov 9)
A saw's way down into a unit from the tops (Rainbow Six Siege's floor hatches) opens at one spot
in every unit, as the wall hole does (D-052): in the middle of its width, from half a stud in front
of the first of the three channels the steel rests on to 1.55 behind it, 2.8 across and 2.05 front
to back. A body drops through that feet first, shoulders across and arms up; the drop is a move the
game makes (as `Tops.drop`), so its size is for the eye, not for collision. The spot lands you in
the clear part of a unit, between the door and the bulb (finds stand behind the bulb, D-036),
facing the room with the door at your back, the way out if it's unlocked. It clears the door's drum
(open, its coil reaches about 1.65 back on every size) and, on a small unit, the two sheets' lap
(3.975), with the bulb hanging just behind it. No hole that size fits between two channels on a
small unit (1.8 apart), so the saw cuts the first channel too: the hole is measured from that
channel, the same in every size, so one cut edge and one panel serve both (an M's is a stud further
back, as its channel is). The cut-out panel falls with the channel's stub still screwed under it and
lies tilted on it, slid 1.7 aside and turned, so whoever drops after it lands mostly beside it, not
on a slope. The kit is its own (`art/tophole/`, asset `Props.TopHole`), the wall hole's build loaded
as a library with the top's spec, so the drawing, strips, cut faces, packing and recipe are one
code; its pieces are the holed tops in their units' frames and the edge, the panel's edge and the
panel in the hole's (`Specs.Channel[size]` along the unit). From along the tops the cut is only a
glint (the tongues bend down); a lit unit's bulb shining up through it is what gives a sawn top
away. Not chosen: the back half (you'd land among the boxes, behind the finds' unlit sides); a hole
between channels on an M only (two hole sizes, and a small unit could never be sawn); cutting
anywhere you lie (runtime geometry for no gain, as D-052); the channel left across the hole (it
would bar the drop); the panel landing flat on its face (the stub under it makes that impossible).

## D-062 The sawn top in the place: swapped at the top's own CFrame, the panel one model (L-13b2d2a, Nov 9)
`TopHole.saw(unit, at?)` cuts a unit's top as `CrawlHole.saw` cuts a wall: the unit's `Top` is
swapped for the kit's `Top_<size>` at the same CFrame (the two meshes share their box and axes),
keeping the old top's shadow, collision, query, touch and collision group, so the bulb, the
torch's room and anything reading the top see the same part. The hole's frame is read from the
unit's own top and the generated Specs alone (`TopHole.frame`), so the server can place the Saw
button and the map can cut the hole out of the tops before or after a cut, with or without the
kit in the place. The top's collision box is split round the hole by `Boxes.around` (the wall
hole's), measured in the box's own frame from the hole's corners, so it holds whichever way the
box's axes run. The fallen panel and its bright rim are two parts in two texture sets, so they
are one Model (`TopPanel`, primary part the panel) that a screen moves as one when it falls. The
tops and panel take their look from `Units.M.Top` (the top they replace), not the wall. Not
chosen: one part for the panel (two texture sets can't share a MeshPart); placing the holed top
from the unit's pivot (the pivot's axes are Blender's, the top's are the game's).

## D-063 Sawing a top: the wall's saw on the tops, a thin line on the steel, the panel dropped (L-13b2d2b, Nov 9)
A top is sawn by the same `Saws` system and rules as a wall (D-053): a held Saw button (R, R2 on a
pad, 4 s), loud the whole time (the motor heard 200 studs off), lost if you let go, checked as you
press and again before it goes through. A wall and a top differ only in where the button is, the
frame the line is drawn in and what happens at the end, so each place a saw can cut is a job of
one of two kinds in that system. The top's button sits over the middle of its hole's spot, a
little above the steel, and only someone lying up on the tops with a saw sees it (the tops'
buttons tag and the saw's). The server also checks you're crawling (`Ladders:crawling`), over this
unit's top and above its steel, and not lying on the hole: your middle within 0.6 studs of it gets
"Move off it" (you can't saw the steel you lie on). The line runs round from the front edge's end,
the edge nearest the hall, through `Sawing.line` on the hole laid flat (`Sawing.flat`, a frame
turned so the wall's maths holds). It's a thin bar on the ribs' face, not through the steel as a
wall's is: lying beside it you look almost along the top, and a line through the steel showed its
depth as a thick yellow band (Studio). Through, the panel hangs 0.1 s in the hole, drops at the
game's gravity (about a third of a second for its ten studs), hops a tenth of a stud and settles,
with the wall's clang pitched lower and heard floor-wide (a sheet with its channel's stub, falling
ten studs, as loud as the saw) and the same jolt nearby. Where it was in the hole comes from the
art's own fall exported as `TopHole/Specs.Fall` (`TopHole.unfallen`), so it leaves the hole exactly
where it was cut and turns into its tilted rest as it nears the floor. `sawing` fires for keepers
with the kind. Not chosen: a second system for tops (the hold, checks, rate and sounds would be
copies); starting the drop flat and guessing the turn (the exported fall is exact); the line
through the steel (the band); the clang at the wall's 110 studs; refusing a cut while a friend
lies across the hole (L-13b2d2c slides them off instead).

## D-064 The keepers' brain lives in this game; Brix keeps the core and the shared spine (owner, Nov 9)
The keepers' brain is built in this game, not on Brix's Pursuit system. The brain is everything
that decides what a keeper does: the halls as a map it walks (shortest trips over the floor's
graph, the GDD's tech plan, with a doorway shut while its door is down), going to a place (a lit
fixture, a door's noise, the air horn, the lobby on a wrong code), what it hears and sees, its
states (asleep, roaming, going to look, hunting, frozen, blinded, trapped), the catch, and the
director's orders to it. It is one system on the Host's clock with each keeper a data row (the
GDD's "one chase engine, keepers as data"), so a new keeper is still a model, animations and a row.

It is written against Brix's contracts and parts wherever they fit, so it can move later: the hall
map keeps Brix's Pathing contract (`length`, `advance`, `route`), the catch is a Brix Reach (the
cone), areas are Brix Zones, its events Brix Signals, its dice Brix's seeded Random. It does not
run on `Brix.Pursuit` unless the session that builds the hunt (L-06b3) finds that the chase and
the catch fit it with no new Brix work. Once the brain has shipped and been tuned with players,
and if it still makes sense for another game, a Brix session lifts it into Brix in neutral terms
and this game swaps to it. Until then it is the one named exception to D-008 and to FRAMEWORK's
"never a parallel system that lives on".

Everything else stays Brix first (D-008): the lifecycle, signals, zones and seeded random the game
uses now, and remotes, save data, live config, telemetry, the round loop, the presentation kit, UI
and developer tooling as Brix builds them. `docs/FRAMEWORK.md` lists each with its Brix ticket and
what stands in until then.

Why: Brix's Pursuit was shaped by another game's chase, a runner heading for a safe zone and a
catch on a schedule. A keeper here spends most of its time not chasing, and that is what Pursuit
lacks. As of Brix `3aee79e` its hunters travel in straight lines with no way round a wall, stand
still unless they are chasing a player, and are taken once as the frame driver starts, and a caught
player only comes back as a runner by respawning. Brix's roadmap after ENG-07b goes to that other
game's swap (ENG-08), then remotes and saves. So every keeper need would be a ticket in neutral
terms, a Brix session, an owner's Studio run, a new pin and then a session here: about double the
sessions and the owner's testing, for a design only one game has shaped. This game has to earn and
the keeper is its core, so the game shapes the brain first and Brix takes it once it's proven.

Not chosen: waiting on Brix (about five Brix sessions before the first keeper walks); building on
Pursuit and filing each gap as it's met; a brain with shapes of its own (it couldn't move later).

## D-065 A sawn top on the map: its hole air the head may go over, a body on it slid off (L-13b2d2c, Nov 9)
A sawn top's hole joins the tops' map as a third list (`Tops.Map.holes`, the attribute's text
`tops|lips|holes`): a point strictly inside a hole is off the steel, but, as a front's lip
(D-059), your head may go out over it. So crawling at a hole you stop at its edge with your view
about half a stud past it, looking straight down into the unit, and you can't cross it: your
middle and feet never go over (Outlast's crawl spaces' ledges). The whole hole is the head's: the
body itself keeps the head within about 1.3 studs of the edge, short of the far side (the hole is
2.05 by 2.8). Every hole is bigger than any of the body's squares (1.8 at most), so the map's
corner checks can't miss one a square straddles. The server cuts the hole in the moment a top goes
through (`Ladders:holed`, called by Saws): it decodes the floor's (or test hall's) map, adds the
hole's rectangle read off `TopHole.frame` (the same numbers as the art's hole; Studio matched it to
the thousandth), publishes it, and hands every crawler the new map; each screen looks for a newer
map every 0.4 s while crawling.

Anyone lying across it then, the sawer too if their feet or side were over its spot (the saw only
refuses your middle within 0.6 of it), slides off its edge to the nearest place the whole body lies
on the steel (`Tops.settle`: rings a quarter stud apart, 32 ways round, at most 5 studs, the same
heading). The server moves you and tells your screen through `FixAttribute` as any put-back; your
screen glides you there in a quarter second (any put-back within 6 studs now glides, not jumps),
and when the place you were in doesn't fit the new map it's the steel giving: its ring as you slide
off a front (`Tops.Sounds.Shift`) and a small jolt. A climber still on the rungs as it goes through
is slid off it the moment they're up.

The ladder offers only the lying spots whose body clears every hole and whose roll from the ladder
onto them never passes over one, brushing its edge by 0.3 at most (the roll is 0.6 s, a brush is
never seen). The first spot, by the ladder, always clears it: it lies at least the hole's half
width, the body's widest half and a hair (2.35) out from the unit's middle, which moves a small
unit's first spot a quarter stud out from the ladder's middle (2.1) on every small unit, sawn or
not. So a sawn top of either size has one spot, the ladder's own: a team climbs one at a time,
each crawling off before the next ("No room up there" until they do). Not chosen: moving the spots
behind the hole (a small unit has no room behind it for a five-stud body); refusing the ladder on a
sawn small unit (the unit you just sawed is the one you most want to climb back onto); punching the
hole out of the top rectangles (more rectangles, and "over a hole" has to be asked anyway for the
slide and the spots); refusing the cut while a friend lies across it (the slide is the answer the
GDD's co-op wants: no one is kept off a hole by a friend lying there).

## D-066 Dropping in through a sawn top: tipped in under the ceiling, landed facing the door (L-13b2d3a, Nov 9)
Drop in is Rainbow Six Siege's drop through a hatch, played by the game as the drop off a front is
(D-059), in the hole's own frame (`TopHole.frame`, which the server puts in the climber's front
attribute for this move, "In"). **Offered** only lying at the hole's edge with your head out over
it (`Tops.atHole`: your head's point within 0.3 of the hole, the server allowing 1.5 more for lag),
and while it's offered that unit's Drop down is hidden on your screen: both are F, Roblox shows one
button per key, and at a hole's edge looking down it you mean the hole. The button sits three studs
down the hole's middle: at the steel's face, or a stud under it, it was off the top of the screen
as you looked at the floor below (Studio).

**The move.** The halls' ceiling is 3.86 studs over a unit's top, so nobody can stand up there:
the first build, springing upright over the hole and dropping straight, put the view 1.07 studs
through the ceiling (Studio). And a stiff 5-stud body can't go through a 2.05-stud hole until it's
steep. So you tip up about a point over the hole's middle, head toward the door, your body's line
always meeting the steel's face mid-hole: your feet stay over the steel to about 33 degrees, then
your legs slide down the hole as your head comes up to 3.6 over the steel, you hang upright in it a
beat, and fall the last 8.5 studs at Roblox's gravity (0.36 s in, 0.3 falling, 0.3 landing crouch).
Your arms keep the crawl's reach until you fall, then go up over your head. Lune holds it to: head
under the ceiling, your body's middle line 0.3 inside the hole front and back through the steel's
0.4 thickness, its belly and heels clear of the cut edge, shoulders 0.4 clear each side. You land
under the hole's middle **facing the door**: the body has to face along the hole's short way to
fit its 2.8 width, the door is your way out, and in first person your view stays your own.

Not chosen: landing facing the back of the unit (the handoff's sketch said both; the owner can
swap it); a rise to standing over the hole (the ceiling); offering Drop in from anywhere near the
hole (it would take F from Drop down along the whole front of a sawn unit); its own key (one verb,
one key for leaving the tops by dropping). Left for L-13b2d3b: the floor under the hole kept clear
by the deal, and every way out.

## D-067 The floor under a top's hole kept clear, and a saw's hole deals the unit (L-13b2d3b, Nov 9)
**A unit is dealt the first time anyone can see into it**, which is now also a saw's hole going
through: the unit a wall's hole leads into, or the unit whose top was cut (`Deals` listens to
`Saws.sawing`, the event that says the panel fell). Before this only a lifting door dealt, so you
looked down a sawn top into an empty unit, dropped in, and what it held appeared round you when you
lifted the door. It is D-050's rule (Left 4 Dead's director dealing as the team moves) with one
more way to see in. Not at the saw's start: a short hold would deal units nobody opened.

**Kept clear by the deal** (`DealSpot`, in the door's frame): the landing, 1.5 studs either side of
the point under the hole's middle and 0.9 behind it, and on to the doorway's face, so a body 2
across lands on concrete with its step to the door free; and the box the top's cut-out panel falls
in, 0.2 bigger all round (`TopHole`'s Specs, read by `Deals`). A thing that fits nowhere gives up
the crawl hole spots first, then the top's panel, then being behind the bulb, and the landing
last. A tool's search now tries every dropped turn anywhere past the door before giving a zone up
(it tried only its unit's own turn, so a ladder in a small unit lay on the landing in 200 units of
300). **A small unit is tight**: its pool is mostly landing, panel and crawl spots, so the bolt
cutters lie in a strip up its middle, deeper than the pool (6 studs in, nearer than a medium
unit's pool reaches) and in one of four places, where they had eight or more.

**Out again.** Lift from inside was already there and reaches from where you land (2.7 studs). A
padlocked door's Lift now says "Saw a wall" as it rattles: the button already reads "Padlocked",
the padlock is on the hall side, and the way out that is yours is a side wall (three words, as
the door's test holds refusals to). Not chosen: "Padlocked" again (nothing on screen changed).

## D-068 The keepers' map: places and passages, each keeper walking it with its own abilities (L-06b1, owner, Nov 9)
The floor is a map of places and passages (`src/shared/KeeperMap.luau`). A place is floor a keeper
crosses in a straight line, a plain rectangle: each straight hall piece, a junction's middle and
each of its arms, the lobby, each unit. A passage joins two places: the joint between two hall
pieces, and each unit's doorway. A keeper's shortest trip is A* over the passages (the GDD's tech
plan), so it walks down the middle of the halls and turns at the middle of each joint: deliberate
and stiff, as a mannequin should move. If that reads as robotic on screen, L-06b4 can cut corners
tighter without touching the map.

Keepers differ in what they can do (the GDD's row: "turning, climbing, senses"; owner, Nov 9: a
later keeper may climb ladders, another crawl through cut-outs, each with different abilities). So
a passage may need an ability (`"Climb"`, `"Crawl"`), each keeper's row lists its abilities, and
the brain walks each keeper through `KeeperMap.pathing(map, row.abilities)`, a pathing that uses
only the passages those abilities open (keepers with the same abilities share one). The floor's
own passages need nothing. Raised places (the tops) and new passages (a leaned ladder, a sawn
hole) can be added while a floor runs (`addPlace`, `connect`, `setOpen`); a point belongs to the
highest place whose floor is at or under it, so someone up on the tops is on the tops, not in the
unit below. A keeper that climbs or crawls is then its row plus the calls that add those, never a
new map or a new brain. A new ability is a name in `KeeperMap.Ability` and the passages that need
it. The Mannequin has none.

Defaults the owner accepted (Nov 9): a keeper goes through a doorway only while its door is all the
way up (`KeeperMap.letsThrough`: peeking, rising, coming down and locked are all shut, so pulling a
door down is always safety); the lobby is on the map and the elevator car isn't (the GDD: keepers
can't ride it), so a keeper hunting someone in the car stops at the lobby's edge nearest them.

Each pathing keeps Brix's Pathing contract, checked by Lune over 60 seeded floors. Two things follow
from it. A passage goes both ways at the same cost, because the contract measures every trip the
same both ways: a one-way drop (down a top's hole) can't be a passage, and a keeper that drops in
would need a contract question taken to Brix first. And a point off every place (inside the
elevator, inside a wall) is measured from the nearest place's edge, the way out to it counted in;
two such points that meet the map at the same spot measure straight between them. A trip with no
way through is `math.huge` long and nothing moves along it. Heights: within a place height counts
for nothing (as Brix's floor pathing), and a traveller keeps its height over its place's floor.

Not chosen: a grid of nodes (thousands of points where a few hundred passages say the same);
Roblox's PathfindingService (the GDD: per-keeper calls cost more, are less predictable, and the
director can't read dead ends from them); abilities as separate maps per keeper (one map, one set
of doors to keep in step, filtered per keeper instead).

## D-069 A keeper goes to look: Granny's walk to a noise, heard along the halls (L-06b2a, Nov 9)
The first thing a keeper does is go and look at a noise, the way Granny walks to any sound you
make, stands there looking, then wanders off. You open or slam a door and, two halls off, the
Mannequin walks the halls to stand square in front of that door, three studs out, facing it, for
its row's `linger` (5 s); then it walks back to where it woke and goes still, facing as it was. A
newer sound it hears takes it there instead, as Granny turns to the latest noise, and where it goes
back to stays where it first woke. A door coming down across its way stops it where it is (it
waits there, or, with no way home, sleeps where it stands), so no keeper is ever stuck walking.

What it hears: a door's open, slam and lift from inside (`Keeper.Hears`, the GDD's door table's
loud rows), each as far as DoorSound's reach for that action, the one players hear by, times the
row's `hearing` (1 for the Mannequin). The distance is the trip along the halls (`length` on the
keeper's own pathing), so a door 86 studs off in a straight line but 116 round the walls is out of
an open's 110-stud reach. A peek is quiet on purpose; a close, a rattle at a padlock, a padlock
going on and the cutters' snap aren't in the GDD's list, so keepers don't hear them for now
(`OWNER.md` asks). Asleep means still and listening. A keeper inside a unit hears nothing while
its door is down, its own door rising included (a doorway counts as shut until its door is all the
way up, D-068), so how a keeper dealt behind a door wakes is L-06b2b's to decide.

How it's built: the brain is the pure `Keeper` (one keeper's states and hearing, Lune-tested) and
its numbers a row in `KeeperRows`, so a new keeper is a model, its animations and a row (the
GDD's "one chase engine, keepers as data"). The server's `Keepers` system runs every keeper on
the Host's clock: a floor joins with `add` as it's laid (its map built once, each door's state
fed in from the new `Doors.changed` signal through `letsThrough`), `stand` puts a keeper on it,
and the brain works in the floor's own coordinates. Speeds are shares of a player's full run,
`StarterPlayer.CharacterWalkSpeed` (there is no sprint): the Mannequin's top speed is 0.9 of it
(its hunt, L-06b3) and it looks at half that, about 7 studs a second, so a slam two halls off
gives you about seven seconds to get behind a door. The body is an anchored `Mannequin.clone`
moved by its root part, streamed whole (Atomic), posed on the server at most 20 times a second
while it walks and holding the key it stopped on (`Pose.freeze`) when it stops, so it stands
mid-stride; L-06b4 moves posing to each screen.

Not chosen: going into the unit whose door it heard (that's the hole trap's job, L-12c, and would
make every open a death; it stands at the door instead); hearing measured in a straight line (it
would hear through walls, and the map exists so it doesn't); a hearing radius per keeper separate
from the sound's reach (players and keepers would hear different worlds); PathfindingService
(D-068).

## D-070 A keeper behind a door: the Witch asleep, the one turning to you awake (L-06b2b, Nov 9)
The deal can put a keeper behind a door asleep or awake (GDD: "a dormant Kept Thing or an awake
one"), and now it stands where the deal laid it as the door first lifts, so even a peek shows its
feet. Asleep, it stands slack in its shop pose, facing as laid, still and listening, the way Left
4 Dead's Witch sits until a noise startles her: the first loud sound that reaches it along the
halls (an open, a slam, a lift from inside; later the air horn, which the GDD says "wakes dormant
things") wakes it, and it goes to look as Granny does (D-069). Woken, it never sleeps again.
Awake, it stands on its walk's first stride, square to the doorway, reaching at whoever lifts the
door; the moment its door is all the way up it walks out to the door's front and stands facing
out into the hall for its linger, then goes back in and stands watching its doorway. Each time its
door gets all the way up again it steps out again. Looking out is its stand-in for sight until
L-06b3 lets it notice the player standing there.

Its own door's open doesn't wake a sleeping one: the open's rattle sounds as the door starts up,
while the doorway still counts as shut (D-069), so only the next loud sound wakes it. That keeps
the peek meaningful (see the feet, close it quietly, padlock it, or open it and keep the noise
down) and keeps the deal's cap honest: past the cap a keeper is dealt asleep so the halls aren't
flooded (D-050), which would mean nothing if every open woke the one inside. A slam on its own
door does wake it, shut in: the bang sounds before the door comes down (`Doors.acted` fires before
`Doors.changed`). The cap now counts the brain's keepers awake on the floor (`Keepers:awakeOn`),
dealt awake or woken, in place of the deal's tally of those dealt awake.

How it's built: the brain gains two states, Asleep (dealt asleep, not yet woken) and Watching
(awake and standing), in place of the old Asleep that meant both; `Keeper.awake` says which, and
`Keeper.lookOut` sends an awake keeper standing in a unit out to look when that unit's door is
up. `Keepers` takes `Deals.dealt` and stands the keeper; `Deals` asks `Keepers` for the count
through the registry, since Keepers already requires Deals. Verified in Studio on seed 7, floor 1.

Not chosen: waking on its own door's open (the cap's point, above); waking on a peek's light (the
Mannequin's own rule is that light stops it, GDD Keepers); an awake one walking out on a peek (the
doorway is shut until the door is all the way up, D-068); a new "awake" pose (its walk's first
stride already reads as caught moving, the Mannequin's language, D-039).

## D-071 A keeper out roams, a trapped one breaks out, and a slam only buys time (owner, Nov 9)
Playing L-06b2b, the owner found the keepers too easy to put away: open a unit, see an awake
Mannequin, slam the door and it was gone for good; or stay quiet while it walked back into its unit
after looking, and shut it in there. The GDD means the slam to be how you trap a keeper, but as a
way to buy time, never to end the threat. Four changes, agreed with the owner:

1. **Once out, never home.** A keeper that has left its unit roams the halls between noises, the
   way Granny walks the house room to room after checking a sound, and never goes back to stand in
   its unit. This replaces D-069's walk back to where it woke, D-070's step back into its unit
   after looking out, and D-069's sleeping where it stands when its way home is shut. Until the
   director steers it (Phase 2, as Alien: Isolation's director keeps the alien near you and pulls
   it back after a close call), it picks hall places some way off that it hasn't visited lately.
   Built in L-06b3a1, before the hunt, so the hunt's give-up is simply "roam again".
2. **The break-out comes forward** from the hole trap (L-12c) to its own ticket after the catch
   (L-06b3d), so every trap is a clock from the start. Trapped means its doorway was open and the
   door came down on it awake inside; a peek lowered over an awake one isn't a trap, since it
   never had a way out. It bangs, dents the door and bursts out at about 90 s going after the last
   thing it heard, as Amnesia's monsters batter down a door you shut. A padlock keeps it in.
3. **A trapped keeper takes no place in the cap.** D-070 counted one shut in toward the floor's
   cap of awake keepers, so on floor 1 (one place) slamming the awake one in made every later deal
   a sleeper: trapping made the floor safe. Now a keeper trapped or padlocked frees its place, so
   the next door can hold a fresh one, and takes it back when it breaks out.
4. **No bonus for trapping.** The GDD's "trapping a keeper pays the team a bonus" was drafted early
   and never decided; the owner dropped it. The trap pays for itself in time. The first trap of
   each keeper type still goes in the Catalog.

The owner also judged the walk jerky, which makes it less scary: the smoothing on every screen
moves up from L-06b4 to its own ticket (L-06b4a) right after the hunt, so the chase and the freeze
are judged on smooth movement.

Not chosen: keepers lifting doors themselves at will (the break-out does that job with a clock
players can read); counting a trapped keeper toward the cap until it breaks out (it rewards the
cheapest play); a bonus kept only for keepers you lured in (no precedent named, and the owner
dropped the bonus outright).

## D-072 The guarded note: every floor has a chase, and the peek finds it (owner, Nov 9)
The owner saw that the peek did nothing as a mechanic: the notes are stuck when the floor is laid
and keepers dealt at random as doors first lift, so on most floors you could peek, skip every unit
with feet in it, and still find the whole code without letting one keeper out. A peek is only worth
something when you might have to go in anyway.

So one note on every floor sits in a guarded unit that always holds an awake keeper, as DOORS puts
the library's code hints in the room Figure walks (the GDD already does it once, with Dale's digit
on floor 5). The floor's build picks the guarded unit from the notes' units, seeded; the deal
always deals it an awake keeper. The guard holds one of the floor's awake places from the start,
so on floors 1 and 2 (one place) every other keeper is dealt asleep until the guard is trapped:
those floors are one keeper that comes for you and sleepers you stay quiet around. A peek can't
show the note (it's high on the back wall), so the team knows which units hold keepers and which
stand awake, not which one has the code.

The peek becomes scouting before you commit: it tells you, without the open's noise, which units
need a plan. Every plan uses pieces built or planned: a friend's torch freezing the Mannequin while
the other takes the note (the Mannequin's GDD rule), a slam elsewhere drawing it out of its doorway
while you slip in behind (Granny going to a thrown vase), a sleeper passed quietly (Left 4 Dead's
Witch), or a hole sawn in from next door. Built in L-06b5, after the break-out, since a guaranteed
chase means nothing until a keeper can catch you.

Left open: units the peek showed safe are still risk-free to open until you take on the guard, so
the floor stays calm until you choose the fight. The planned answer is the Phase 2 director waking
keepers while you search (GDD "Build wakes a keeper"); judged after the owner plays a floor with a
guard and roaming keepers. One guarded note per floor is a default.

Not chosen: the peek showing the note (it would make the peek a free answer key); a tool rather
than a note as the guarded thing (tools are optional until floor 6's padlocked note; the note is
the one thing every floor needs); the guard asleep on some floors (the owner wants a chase on
every floor).

## D-073 How a keeper roams: hall pieces some way off, never its last few (L-06b3a1, Nov 9)
D-071 says a keeper out of its unit roams the halls between noises and never goes home. As built:
after looking at a noise, or out of its own doorway, it picks the middle of a hall piece (a
straight, a junction's middle square or the lobby: one stop per piece, so junctions with four arms
aren't picked four times as often) whose trip along the halls is 40 to 120 studs, that it hasn't
stood in among its last four stops, walks there at its looking pace (about 7 studs a second),
stands 3 s holding the stride it stopped on, and picks again: Granny's walk from room to room.
With nothing in that band it takes any piece it can reach and hasn't stood in lately, then any it
can reach. A newer sound still takes it to look, from a roam as from anything else. Each pick is
one draw from the floor's own seeded Random, a fresh Brix Random from the floor's seed handed to
`Keepers:add` (not the deal's, whose later draws at a door's first lift would shift with every
roam and change what a unit holds), so a seed roams the same way for the same play. Those numbers
are row data (`roamNear`, `roamFar`, `roamLinger`, `roamMemory`); the owner tunes them (OWNER.md).

It never walks into a unit: every goal it ever has is in the halls (a door's front, a hall
piece's middle), and a trip between two hall places never passes a doorway, as each unit has only
the one. So its own door shut behind it changes nothing, and D-069's "no way home, it sleeps where
it stands" is gone with the walk home. A door coming down across its way makes it pick again; one
that came down before it got out of its unit leaves it nowhere to go, so it stands watching there
until its door is all the way up and it steps out again (the break-out, L-06b3d, gives it a clock).
The brain's Returning state is replaced by Roaming, and Waiting now covers both its stops (at a
sound, facing it, for `linger`; on a roam, for `roamLinger`). Verified in Studio on seed 7,
floor 1.

Not chosen: roaming toward players (Phase 2's director steers picks, as Alien: Isolation's keeps
the alien near you; until then it would be a hunt with no sight); picking any map place (a
junction's arms would weigh junctions four times over, and units are never goals); a turn to look
down the hall at each stop (no precedent named and its stopped stride already reads as caught
moving; OWNER.md asks); the deal's Random for picks (above).

## D-074 How a keeper sees and hunts, in its own brain, not on Pursuit (L-06b3a2, Nov 9)
Brix's Pursuit doesn't run the chase. A hunter the game places (`moveHunter`) is never moved by
Pursuit again, so a keeper couldn't hand back from the chase to its own roam and search; its
runners all head for a safe zone this game doesn't have; and its `Reach` and targeting measure
straight lines with no walls or sight. Fitting it would be new Brix work, which D-064 rules out.

As built: a keeper awake in any state (watching, going to look, waiting, roaming, searching) sees
a player within its row's `sight` (48 studs) and `sightAngle` (60 degrees either side of the way
it faces), along a straight line `KeeperMap.clear` passes: on the floor all the way, crossing from
place to place only at a joint between halls or a doorway whose door is all the way up, and there
only within the door's opening (`Floor.Sizes`' `door`), so never through a wall, a shut or
peeking door, or the posts beside a door. Feet more than 8 studs over or under its own are out
of sight: up on the tops (10 up) or another floor; a jump isn't. Off the map (the elevator car)
is out of sight. It hunts the nearest it sees, turning to them at once (Granny's chase on sight),
at its top speed (`speed`, 0.9 of a run) along the halls, stopping 2.5 studs off (`Keeper.Close`,
where L-06b3c's catch will land). Hunting, it keeps them while it sees them any way it faces, and
no sound calls it off, so a slammed door is no free escape mid-chase. Lost, it rushes at its top
speed to where it last saw them (Searching), stands its `linger` facing on, then roams (D-073):
Granny's search. A sound heard while searching takes it to look, so a friend can draw it off.
The server feeds each living player's feet (floor coordinates, reused lists) to a floor's
keepers each step, only while one there is awake. Verified in Studio on seed 7, floor 1.

Not chosen: a noticing build-up before the hunt (Alien: Isolation's; OWNER.md asks); sight that
needs light (the Mannequin's light rule is L-06b3b's, and keepers seeing in the dark is Granny's);
a small all-round sense of someone touching close behind (the catch covers contact); seeing by
sampling points along the line (it can miss a wall's corner; `clear` follows the line place by
place exactly).

## D-075 How keepers move on every screen: motion records, followed per screen (L-06b4a, Nov 9)
The server moved each keeper's root every step and turned its fifteen joints (Motor6D C0) up to
20 times a second, all replicated, and a phone drew the body hopping between updates: Roblox
doesn't smooth an anchored part's moves, and nothing smooths a C0.

As built: the brain stays on the server (`Keeper` is the truth). The server sends each keeper's
motion as one short line of text on its body's `KeeperMotion` attribute: where its feet are (the
world's), the way it faces and walks, its pace, how far it walks before it stops (`Keeper.left`:
its trip along the halls, short of arm's length if it hunts), how far it has walked (its pose),
its state and the server's time. It's dead reckoning, the way shooters move other players: the
server keeps the last record as screens read it (rounding and all), works out each step where
they show it, and sends a new one only when that drifts a quarter stud, or it starts, stops,
turns 4 degrees, changes pace or state, or is about to walk past where the last one stops it;
never more than one each 0.08 s in one state, while a new state goes at once. A straight walk is
its start, its stop and one or two records as it nears the stop; a close chase about 6 a second.
The server leaves the joints at rest and moves the root only with each record, or once it has
walked 8 studs from the last: that's what streams the body (Atomic, as before) to whoever is near.

Each screen's `KeeperView` follows the records (`KeeperMotion.follow`, `receive`, `update`): it
shows the keeper 0.1 s behind the server's time, so a turn or stop that arrives in time is shown
exactly (each record bent onto the next), never walked past (`left`); a late record's difference
eases out over 0.12 s (more than 4 studs snaps); turns ease over 0.06 s; its pose follows how far
it has walked, never backward. It's posed through each joint's `Transform` (C0 at rest) in one of
33 fixed frames of the walk (`Pose.frame`: Still, each key, seven steps of each snap), each
frame's turns worked out once per screen, so a joint is written only when the frame changes. Only
bodies moving on that screen are stepped, in the Host's RenderStepped step (after replication
lands, before the frame draws). Verified in Studio: the chase drew at its pace with no stalls.

Not chosen: unanchored bodies moved by constraints so Roblox interpolates them (a fight with
physics, at rates Roblox picks); replicating the root every step and posing only on screens (half
the cost, still hops); sending every step for screens to buffer (60 records a second each); a
delay fitted to each screen's lag (ROADMAP polish); a client copy of each body (two bodies, and a
torch's ray would hit the wrong one).

## D-076 How light freezes the Mannequin, decided in its brain (L-06b3b, Nov 9)
The GDD's Mannequin moves only while no light is on it and never trips a light; you stop it by
keeping a light on it, moving under the hall's lights or pointing your torch at it. It's
SCP-173's rule in SCP: Containment Breach, and Five Nights at Freddy's animatronics never moving
while the camera is on them.

As built: a row says whether light freezes it (`freezesInLight`) and how tall it is (`height`).
Each step the server tells its brain whether a lit hall light's pool is where it stands
(`MotionLights.lightOn`) and each living player's torch: from their head, along the way their
root faces (the first-person camera's), tipped by their aim, or none while it's off. The brain
(`Keeper.step`) decides: a hall light counts only while it stands in a hall, since a unit's walls
shade its inside from the tube; a torch counts when a point up its middle (seven, feet to head)
is within the beam's 42 studs and 27 degrees of its middle (Torch's numbers, the cone players
see) along a line `KeeperMap.clear` passes from the player's feet, so never through a wall, a
shut door or round a corner. Who lit it is `lit` (Output names them). Lit, it holds where it
stands, as it stands: no step, no turn, its state, trip and clocks kept, so the light gone, it
carries on exactly as if no time had passed. It still sees and hears while frozen, so it can
start hunting you while your light is on it, without turning, and comes the moment the light
leaves. A freeze or a let-go goes to screens at once, not after the records' 0.08 s gap
(D-075), so screens stop it on the stride it was on; in Studio it drew 0.07 studs past and eased
back.

A lit fixture's pool is round, 13 studs across the floor from it: the tube reaches about 12 at a
body's height and fixtures hang 24 apart, so two lit ones leave no gap, junction arms included.
The watch box (40 by 10, what the light sees) was not used: a junction's side arms would have
been lit but not freezing, and players would see it walk in the light.

Not chosen: the light decided on the server outside the brain (Lune couldn't check a whole
freeze); a beat of hold after the light leaves (the GDD says the moment); a frozen keeper that
turns to face you (it reads as moving; OWNER.md asks); its clocks running while frozen (a light
on a waiting one would cut its wait short); the beam's edge measured against its width (a stud
either side, ignored for now).

## D-077 How a keeper catches you: Brix's cone, in its brain, and a stand-in in the black (L-06b3c, Nov 10)
The moment: you stood still too long in the dark, and it's there; its hand closes on you. A
hunting keeper that reaches you catches you, as Granny's grab or Piggy's swing ends the chase the
moment she reaches you. The GDD's "Getting kept" then wraps you and stores you (L-07).

As built: each row has a grasp, `reach` (studs, feet to feet along the halls) and `reachAngle`
(degrees either side of the way it faces); the Mannequin's is 3.5 studs, a stud past arm's length
(`Keeper.Close`, where its hunt stops), and 45 degrees. The brain makes its grasp with Brix's
cone reach (`Reach.cone`) over its own map's pathing, handed in by the server
(`Keeper.new(..., cone)`), since the pure brain requires no Brix. `Keeper.catches` asks: is it
hunting, are the feet of the one it hunts within the cone (measured along the halls, so the way
round a wall is the walk, not the straight line), along a line `KeeperMap.clear` passes (never
through a wall, a shut door or a door's posts, never from up on the tops) and no higher or lower
than its height (a jump at its face is caught; the tops are not). `step` checks it after the
keeper moves, so never while a light holds it (it returns first) and never asleep (it only hunts
awake). Caught, it stands over the spot its linger and roams, the one it hunted let go; `caught`
names whom for that step. A straight-line check comes first, so most steps never ask the map.

The server then: tells the caught player's screen (Remotes.Caught, to them alone; nothing goes
client to server), says it in Output, fires `Keepers.caught` (body, player, floor) for L-07, and
leaves that player out of every keeper's sight for `Caught.Out` (2 s, the GDD's wrap), so the one
that caught you can't catch you again before you're moved; a second hand on the same step is
ignored. The screen (`CaughtView`): the view jerks (CameraShake 0.85), the screen drops to 55%
dark at once and closes to black over 0.4 s, "Caught" in the dark for 0.9 s, then it opens over
0.7 s; you're held still the whole time (walk and jump 0 on your own screen, which owns your
movement). The stand-in until L-07 (DevCorridor, like the stand-in ride): once the screen is
black, the server puts you in the floor's lobby, facing the hall. Verified in Studio on seed 7,
floor 1: it came out of 126 and caught me at arm's length; with my torch on it, it hunted frozen
for 12 s and never came; torch off, it came and caught me.

Not chosen: Pursuit's catch (D-074: Pursuit doesn't run keepers); a wind-up before the grab (the
GDD says it catches you; a speed under your run already gives the chance to flee); the cone alone
without the clear line (measured along the halls it already won't go through a shut door, but a
thin wall between two halls is long to walk round and short to the eye; the line keeps "never
through a wall" plain); the PlayerModule's control switches to hold you (they don't hold
movement any more, see docs/STUDIO.md); turning your view to its face as the dark closes (a
strong grab, but it fights Roblox's camera; ROADMAP's polish list).

## D-078 A trapped keeper bangs on its door, then bursts out; a padlock holds it (L-06b3d1, Nov 10)
The moment: you led it into a unit and slammed the door on it. A breath later it hits the door
from inside; the door jumps on its rail with each blow and the blows come faster; at about 90 s it
throws the door up and comes out (the GDD's hole trap; Amnesia's battered doors). A slam buys
time; it never ends the threat. A padlock does, for the floor.

As built: a door that comes down from all the way up (a close or a slam, the only ways down from
Open) traps an awake keeper standing in its unit (`Keeper.trap`, called by the server when a
doorway that let keepers through stops). A peek lowered over one isn't a trap. The slam is heard
before the door's state changes, so a sleeper woken by the slam it hears is awake inside and is
trapped too: slam a door on a sleeping one and it wakes banging; close it quietly and it sleeps.
Trapped, it walks to stand 1.2 studs inside the door, facing it (a peek shows its feet there),
and bangs: the first blow 1.2 s after the door came down, then gaps from 5 s closing to 2 s as its
time runs out, each a quarter longer or shorter from the floor's Random, none within a second of
its burst (row numbers). Each blow is a door motion, `Bang`, played by `Doors.move`, so the door's
one replicated motion carries it to every screen: the door jumps about 0.2 studs on its rail and
drops back (0.5 s), the slam's boom at 0.55 and pitched down with a thump under it, and a camera
jolt (0.45, about a third of a slam's on screen) for anyone within 6 studs, fading by 30. Keepers
hear a blow to 70 studs (a rattle's reach), so others come to look at the door. At 90 s it bursts
it: a `Burst` motion (a full stroke in 0.6 s, fastest at the start; the door reads Lifting, so
nobody outside can pull it back down), a slam's full boom and jolt as it tears free and a boom at
the stop bolts, heard 130 studs. Once the door is all the way up it goes after the last thing it
heard while trapped, or steps out to look and roams. Lift the door yourself and it's just out.
Trapped, it hears only through its own door: its way to the door plus the trip from the door's
front along the halls (D-069's rule still holds: never through a wall); its own door's sounds it
doesn't count. A padlock: it bangs on until its time, gives one last blow, then stands quiet for
the floor; cut the padlock and it bursts out at once. While shut in it takes no place in the
floor's cap (`Keeper.loose`, which `awakeOn` counts). Someone shut in with it gets hunted; after,
with nowhere to roam, it goes back to its door, trapped, its clock carrying on. Verified in Studio
on seed 7, floor 1: slammed as 126 got up, it was trapped, banged 28 times and burst out 90.25 s
later; padlocked, it gave its last blow at 90 s and was still in at 103 s.

Not chosen: the blows as their own remote (the door's motion attribute already reaches every
screen in step, one path for every door sound); the burst as a lift from inside (6 s of heaving
reads as a struggle, not a burst); banging forever behind a padlock (it would call every keeper on
the floor to that door every few seconds for the rest of the floor, a lure the GDD doesn't give);
its blow clock keyed to the last sound it heard (the GDD gives a fixed "about 90 seconds").

## D-079 The dent: each blow bows the door out, in three baked steps (L-06b3d2, Nov 10)
The moment: the door you slammed on it starts to bow out toward you, worse with each blow, so from
the hall you can see how close it is to coming through (Amnesia's battered doors).

As built: the server keeps one number on the unit, `DoorDent`, the share of the keeper's break-out
time gone at its latest blow that landed (a `Bang` or the `Burst` that `Doors.move` played), and
never lowers it (`Dent.raise`). Every screen turns it into one of three baked steps
(`Dent.step`; `Dent.Lands` 0, 0.4, 0.75): dented from the first blow (a fist-sized pocket at chest
height, 0.34 out), bowed from about 36 s of 90 (the ribs bowed guide to guide with a first fold,
0.66 out, level with the wall's face), buckling from about 68 s (1 stud out, proud of the wall,
the fold sharp, a third blow high). A door keeps its dent for the floor, lifted or burst (a
default, OWNER.md). The rigid hinged ribs can't bend, so each step is bowed copies of the ribs it
reaches, every one read from one displacement field at its place on the shut door, so they meet
each other and the plain ribs exactly (`art/unit/dent.py`). They ship as their own small FBX per
size, `Props.DoorDent_M` and `_S`, not in the unit (dozens of units a floor would each carry 39
parts), dressed in the unit's own slat texture at prepare time and its paint at runtime. A dented
door keeps its slat chain; `RollUpDoor`'s rig swaps a step's bowed ribs in while each hangs below
the doorway's top and drops one flat as it rolls up behind the header, so the coil stays round
and nothing pokes through the header. The collider and what keepers see are unchanged. Roblox's
lighting is flatter than Blender's renders: at first the dent (0.2 to 0.55 out) barely showed in
Studio, so the steps are deep enough that the ribs above the fold tip up into the hall's light
and those below into shadow. Its worst passes the collider by about 0.4, so a player pressed to
the door can clip it.

With it: the trapped keeper stands 3.4 studs inside its doorway, not 1.2 (`Keeper.Against`). The
Mannequin's walk holds an arm out level about 2.7 ahead of its feet, and at 1.2 its hand stood 2
studs out in the hall through the shut door (`docs/art/L-06b3d2-arm-through-door-before.jpg`).

Not chosen: a shape key or bones (Roblox's importer keeps neither for a plain mesh); merged dented
curtains only (a blow's jolt and a peek pose the chain, where the dent would vanish); bowed ribs
riding up onto the coil (lumps through the header and the unit's top); the dent counted per blow
rather than by its time (a jittered clock would show different steps for the same wait).

## D-080 The guard on the deal (L-06b5a, Nov 10)
D-072 built as the deck's rule, pure in `Deal`: `Deal.new` marks one note's unit guarded
(`deck.guarded`) and `Deal.odds` deals it a keeper awake whatever the mood, the padlock or the cap.
- **Which note.** One of the floor's notes, picked from the floor's Random, behind an unlocked door
  wherever a note is: a padlocked door can't be peeked, and the peek is how D-072 has you find
  the guard. With every note locked (17 floors in 4,000 of the spec's) the guard takes a locked
  one. Notes already lie past the lobby's hall, so the guard never stands in the first doors.
- **Drawn last.** The pick is the deck's last draw, so every seed lays and deals all else as
  before: the code, notes, padlocks, each unit's roll and the bag. (Since D-098 it's drawn just
  before the bag instead, so a change to the bag never moves it.)
- **Its place under the cap.** Until the guard's unit is dealt, every other door counts it among
  those awake (`awake + 1` against `Deal.awakeCap`); once dealt it's counted with the rest by
  `Keepers:awakeOn`, and trapped it takes no place (`Keeper.loose`), so the place frees as D-072
  says. On floors 1 and 2 every other keeper is dealt asleep until then. A keeper woken by a
  noise isn't the deal's doing, so the guard can still make two loose on floor 1 after a slam
  has woken a sleeper: the cap governs what the deal deals.
- **Where it stands.** As every dealt keeper: `DealSpot` keeps it out of the note's sight line,
  awake on its walk's first stride, square to the doorway (D-070).
- **Output.** In Studio the dev floor's notes line marks the guarded one, and `Deals` says
  "guarding its note" as it deals it.
- **Found in Studio:** the built peek has no crouch, so a standing eye sees only a stud or two in
  under the foot of gap and no keeper's feet. The GDD's peek crouches; that's L-06b5b.

Not chosen: the guard as a separate kind in `Deal.Kinds` (it's an awake keeper like any other,
only certain); the guard's place kept by `Deals` rather than the deck (it's the deal's rule, so
Lune proves it); a fixed guarded note (the first, say), which a team would learn.

## D-081 The peek's kneel (L-06b5b, Nov 10)
The GDD's peek crouches; as built it only lifted the door, and a standing eye 4.5 up sees a stud
or two in under the foot of gap. Rainbow Six Siege's players drop to look under a door; this drop
is quick and automatic, part of the Peek.
- **Your view, not your body.** Your screen eases `Humanoid.CameraOffset` down over 0.35 s to an
  eye 1.0 off the floor, just under the gap's top (1.15). Tried in Studio: at 1.2 to 1.3 only the
  feet show; at 1.0 the feet and shins, so a guard's stride and a sleeper's square stance read
  from the doorway (`docs/art/L-06b5b-peek-*.jpg`). Your root stays standing: the server's checks
  on reach, the keepers' sight of your feet and the door buttons' reach are unchanged.
- **Your screen first.** The drop starts the moment you tap (`PromptTriggered`), not when the
  server answers; if the door hasn't started lifting within a second (a refused press) you stand.
  Your Open, Close or Slam stands you as you press it; any other move of the door stands you when
  it reaches your screen.
- **Staying down.** While the door holds its peek and you stay within a stud of where you knelt
  (1.5 up or down: a jump). A climb, crawl or catch taking your body (PlatformStand) stands you
  at once. One pure rule (`Kneel.holds`, `doorMoved`) runs on your screen and on the server.
- **The buttons come down with you,** on your screen only: at the door's standing height (4) they
  sit above a low gaze and a prompt shows only while its spot is in view. They sit 16 degrees
  over a level gaze, never lower than 1.8 so they don't hide the gap, and go home as you stand.
  The server's reach check uses its own copy of the spot, a couple of studs higher: well inside
  its slack.
- **A friend sees you kneel.** The server tags your character (`Kneeling`) once it lifts the door
  for you and keeps the same hold; every screen eases that body into the pose by its joints'
  `Transform` before physics, from whatever its animation says (or rest, for a joint none
  drives). Animations would replicate on their own, but need an uploaded asset; this needs none
  and fits any R15 avatar (the drop and shift are shares of the hip height). The pose: both knees
  down, chest to the floor, forearms out to the door, head up, tuned in Studio to within a tenth
  of a stud of the floor. Your own body isn't posed on your screen: you never see it in first
  person, and a torso leant into the door would push your character off its spot.
- **The rustle.** Pro Sound Effects' "Cloth Rub Soft Rustle 3", 0.45 s from 0.55 s, as you drop
  and stand, heard to 24 studs. Keepers don't hear it; the peek's latch is the door's noise.

Not chosen: a prone body flat on the floor (Siege's): the GDD says crouch, and it would lay the
feet five studs back into the hall; taking over the camera (Scriptable), which
would fight Roblox's first-person turn; a new remote for the kneel (the server already knows who
peeked and where they stand).

## D-082 The sting and the chase bed, heard by the hunted player alone (L-06b4b1, Nov 10)
A keeper seeing you had only its turn and its run to say so. Granny's chase music cuts in the
instant she sees you and runs under the chase; that's the precedent.
- **Who hears it.** Only the hunted player: it's your music, not a sound in the hall, so it plays
  from SoundService, the same wherever you stand. Friends hear the keeper itself (its tell is
  L-06b4b2), never your music.
- **How the screen knows.** No screen knew whom a keeper hunts (`KeeperState` says only
  Hunting). The server counts, after any step in which a keeper's quarry changed (it saw, lost or
  caught someone, or was trapped), how many keepers hunt each player, and tells a player's screen
  that number (`Remotes.Hunted`, to them alone) only when it changes: one message per sighting
  or loss, never per step. A count rather than a yes or no, so a second keeper joining a chase
  is a rise the screen can hear.
- **The rule (`Chase`, pure, 46 Lune checks).** A rise is a sighting. It stings only if it's a
  fresh one: not within 4 s of a keeper losing you (`Regain`: ducking out of sight for a moment
  and being seen again is a glance back, and the bed just comes back up) and not within 8 s of the
  last sting (`StingGap`: a second keeper right behind the first only adds to the chase). The bed
  rises over 0.8 s (`BedIn`, under the sting's hit) while any keeper hunts you and fades over 4 s
  (`BedOut`) once none does; the level moves evenly and its square is what's heard, so a fade
  dies away. A catch cuts the sting and the bed at once and holds silence through the blackout
  (`Hush` = `Caught.Out`); the first sighting after it is fresh.
- **The sounds** (APM, Roblox's licensed library, each loaded and measured in Studio, none
  judged by ear yet). The sting is "Rising Fear Hit 1" (1841353894): full by 0.1 s, loud for
  0.8 s, rings down by 7 s, a boom with a bright edge (a third of it 500 Hz to 2 kHz). The bed is
  "Tension Repeat Drones 39" (1843739491), looped over its first 118 s: of eight beds measured it
  alone had most of its sound (82%) between 150 and 500 Hz; the rest sat under 150 Hz, where a
  phone's speaker barely plays, and phone is first. Volumes 0.8 and 0.45 (`Chase.Sting`, `Bed`).
- **Verified in Studio** on seed 7, floor 1: opening 157 in front of the guard, the server's
  word came 2.07 s after the tap and the sting started that frame; the bed rose, and the catch
  0.5 s later cut both. Escaping 0.3 s after the sighting, the loss reached the screen 0.2 s
  later and the bed fell evenly to silence and stopped. A 34-stud sighting in the halls held the
  bed full for 1.3 s until the catch cut it. No sound errors in Output.

Not chosen: the server deciding when to sting (the rule is presentation, the screen's to keep;
the server only says how many hunt you); a sting per keeper's own sighting by its id (more to
send, and the gap would swallow most); music that swells with distance (Alien: Isolation's) or
the bed's own loudness telling you how near it is: the bed only says "hunted"; the keeper's tell
(L-06b4b2) says where.

## D-083 Its tell: the walk each screen shows, heard from the body (L-06b4b2, Nov 10)
The moment: in the dark you hear it before you see it, as Five Nights at Freddy's footsteps say
an animatronic moved. Its walk is stop-motion (D-074's keys: it holds each, then snaps to the
next), so the sound is the snap landing: a stiff clack of its foot as a step key lands and a
hollow knock of its joints as a pass key lands, alternating; a jerk from its slack shop pose
into a stride knocks too.

As built: nothing new crosses the network. Each screen's KeeperView already poses the body from
its records, so it asks `Pose.tell` each time it poses one: the key it shows, counted from its
first and never going back, against the last one heard. Each key is heard once, the moment that
screen shows it landing; a late record jumping several keys makes one sound (the last key's); a
snap a light froze early isn't heard again as it walks on; its first pose on a screen (it
streamed in) is silent. KeeperSounds plays it from the body's root: two takes of each sound, in
turn, at a random pitch in the row's range, cut to one hit with a short fade (one reusable fade
per take), footfalls heard to 70 studs (past the 48 it sees: you hear it coming first), knocks to
40 and 6 dB under (the knocking means it's near), never two from one body within 0.08 s, never
played from past its reach. Every number is on the keeper's row (`tell`).

The reveal: as a lift (Peek, Open, or a Lift from inside) first takes a door's curtain 0.4 up
(its feet), a keeper standing in that unit, asleep or watching, knocks once, deeper and louder
(1.5 times, pitch 0.85); not again within 3 s. It's timed off the door's own motion on the
server's clock (`KeeperTell.reveal`), so it lands as the screen shows the gap open (0.10 s into
a peek). The deal stands a keeper as its door first lifts, so its body reaches a screen just after
that lift began: KeeperSounds checks the lift it arrived in. Everyone near hears it, as a door.

The sounds, by measurement (docs/STUDIO.md): Pro Sound Effects' "Wood Drop Light" 4 and 2 (a
light board dropped flat on concrete, about 860 Hz, where a phone speaker plays) for the foot;
"Knock Slap Plastic" 9 and 7 (a hand knocking a thin plastic shell, about 700 Hz) for the joints.

Not chosen: the server sending each footfall (it doesn't pose the body, and every screen would
hear its own walk out of step with the one it shows); a sound per frame change (a snap is eight
frames); a footfall per key (every key a clack reads as a machine, not a walk); the reveal from
the server's deal (the screen knows when its curtain clears the feet); sounds at the feet (a stud
or two truer up close: ROADMAP polish).

## D-084 Your torch's freeze lands at once: the server takes your look, your screen holds it (L-06b4b3, Nov 10)
The moment: you swing your torch onto it mid-stride and it stops dead that instant, as SCP-173
and FNAF's animatronics hold the moment you look. Measured first in Studio (seed 7, floor 1,
157's guard hunting at 14.4 studs a second): the server tested your beam along your character's
facing as the server sees it, and the server sees a player's turn 0.06 to 0.13 s late and then
eases it in over another 0.15 to 0.4 s (Roblox smooths a client's character on the server). Your
screen showed it walk on under your light, and the server never froze it: it caught me with my
beam on it for a quarter of a second.

As built, three parts. The torch's aim (`Remotes.FlashlightAim`) carries its heading with its
pitch, whole degrees (`Torch.heading`: a real number, brought round to -180..180), sent each
0.1 s on a 1.5 degree move, after only 0.05 s on a 10 degree swing or the moment your screen sees
your beam land on a keeper (`Torch.shouldSend`); the server takes one no sooner than 0.025 s
after the last and forgets the heading as the torch switches. Keepers test your beam along it
(`Torch.look`), your character's facing only until the first one. Trusting it gives a cheat
nothing new: a client already turns its own character however it likes. One beam test serves
both sides (`Torch.lights` at each `Keeper.beamPoint`): the brain's line is `KeeperMap.clear`,
your screen's a raycast that respects CanCollide. They can disagree: a ray reaches a keeper's
feet under a door that isn't all the way up, where the map says shut (the screen holds, no stop
comes, it walks on after its patience); a friend or a box in the way stops the screen's ray and
not the map's (the screen doesn't hold; the server's stop lands as before). And your screen holds
it (`KeeperMotion.hold`, from `KeeperView`): exactly where and as it was shown, posed on the key
the light freezes it on, until a stop record after the hold answers it within its patience (0.15 s
plus two pings, at most 0.5), then until the screen reaches the server letting it go. The server's
stop lies a little further on (the screen's 0.1 s `Delay` plus your aim's trip): the screen never
slides there while the light holds it, and makes the gap up as it walks again, about two thirds
of it within a stride (5.4 studs) or all of it by the stop its record walks to, so it never stands
short and never steps back. A stop more than 4 studs off lets go at once and jumps. A walk going
on from a stop that landed mid-snap holds the key it froze on until its walk reaches it
(`Pose.along`, the furthest shown), never flicking back into the snap.

Verified in Studio: the frame the camera turned onto it, it stopped (drawn at the same place
every frame after, on its pass-right key); the server froze it 0.03 s later, 1.66 studs on; the
light leaving, the server let go 0.03 s after the turn, and it closed on me about half again its
pace for two frames. A beam on the trapped guard through 157's shut door hit `DoorCollider` with
all seven points in the cone: no hold, no freeze.

Not chosen: holding on your screen alone (the server's keeper walked on under your light and
caught you); rewinding the server's keeper to where your screen held it (friends would see it
step back); the server testing your beam against where your screen showed it, as shooters favour
the shooter (the beam is 54 degrees wide; ROADMAP polish if edges miss); sliding the held body to
the server's stop (it moves while lit); predicting the let-go too (its records still say it
stands, so it would slide). Known: a hunter that catches you right after the light leaves stops
short of its record, so your screen shows it up to a stud short; the catch's blackout hides it.

## D-085 The hole trap lands: neighbours paired right, a press on arrival counts, it searches off the walls (L-12c, Nov 10)
The moment: it's on you, you dive into a unit, squeeze out through the hole you sawed, sprint
round and slam its door on it while it stands staring at where you vanished (GDD "The hole trap";
the crawl is DOORS' and Pressure's vents, D-054; the slam buys time, as Amnesia's battered doors,
D-078). Played end to end in Studio first, on seed 7, floor 1: 155 and 153 open, a hole sawed
between them, 157's guard let out and walked to the junction by 133's door, then up the hall by
156's, so it saw me at 155's front from 24 studs. Three things broke it.

1. **The wrong neighbour.** `CrawlHole.between` took any unit whose door face lines up along the
   wall within 20 studs, so 157 and 153 (155 between them) matched 153's wall with 155. `Saws`
   and `Crawls` pair every two units near each other and keep the first match, so on this floor
   the 155|153 wall's Saw buttons went to 157 and 153 (nobody in 155 could saw it), and once
   sawed, its Crawl button on 155's side belonged to 157: the server refused a crawl from 155
   because you weren't in 157. Now each door face must stand within half its own unit's width
   (plus half a stud) of the wall, so the unit two along never matches.
2. **A press lost to the server's late view.** The server sees your run late (D-084's
   measurement: 0.06 to 0.13 s, eased in over another 0.15 to 0.4 s). Run into the unit and
   press Crawl as you reach the hole, and the server, 4 studs behind, still saw you in the
   doorway: not inside the unit, so the press was dropped without a word and the keeper caught
   me at the hole. Now a press counts if you're inside the unit and within reach of the button
   where the server sees you, or where you'll be `Crawling.Lag` (0.4 s) on at the speed it sees
   you moving (`Crawling.counts`, pure). In Studio the press then came with the server seeing me
   on the door line, running in at 15.5: counted. It gives a cheat nothing: the client already
   moves its own character. The door's Slam, pressed the same way on arrival, already landed.
3. **It searched inside the wall.** Lost, it rushes to where it last saw you; mid-crawl that's
   your feet on the wall's own line, so it stood half in the wall, its reaching arm through the
   hole. Now in a unit the spot is kept `Keeper.Against` (3.4 studs, its arm's room, as the
   trapped stand) off the unit's walls (`KeeperMap.offWalls`; a unit too small for that, its
   middle), and on arriving it turns to where it last saw you: from 153 you see its legs
   through the hole, standing back in 155, facing it. Halls keep the exact spot: nobody's feet
   are ever in a hall's wall.

What already held: it loses you through the wall (the hole is on no keeper's map, so no line of
sight and no way through, D-068); it never follows; it stands its linger (5 s) where it lost you,
and the run round took 0.9 s from the crawl's end to the slam, which traps it.

Verified in Studio: the guard saw me from 24 studs at the junction, I reached the hole and pressed
at once, crawled, it lost me, stood at 3.4 studs off both walls facing the hole, my slam came
0.9 s after the crawl ("the Mannequin is trapped in Unit 155"), and it banged.

Known, left to the owner (`OWNER.md`): the trap needs a lead. You're lost only once your body is
through the wall (about 0.65 s into the crawl, plus the server's lag), and a hunter closes at its
top speed while you lie at the mouth, so it must be about 16 studs behind as you press Crawl, a
little over a second at its hunt; a keeper a few steps behind catches you at the mouth. The trap
is something you set up and lure it into from afar, not a panic escape.

Not chosen: making the server wait for its view to catch up before judging a press (sound, but
it delays a crawl that must start at once); trusting a position sent by your screen (a prompt's
press carries none; the velocity the server already has is enough); pulling every search spot
off the walls, halls too (it changes where a keeper stops after a corner, for no gain); the
keeper hearing the crawl (queued with the other quiet sounds, D-059, D-066).

## D-086 The air horn: a white can with an orange trumpet standing up (L-14a1, Nov 10)
The GDD's air horn ("Lures keepers to a spot", its risk "Wakes dormant things nearby") comes from
Lethal Company, whose air horn draws the monsters that hunt by sound. It's a marine air horn, the
kind boats and stadiums use, built from code the saw's way (`art/airhorn/`): one MeshPart, one
baked 1024² set, 6,000 triangles, no brand. A white steel can with a black band, a black collar,
and a safety-orange trumpet standing straight up out of it, pressed down to blow, as the common
canned horns are. White because the torch is yellow, the cutters red and the saw green: the can is
the one white tool, and the flared trumpet is its outline from a doorway. The band carries an
orange sound-wave mark (a dot and three arcs), the one picture on it, so it says "loud" at a glance
without words. Sized about 1.6 times life (0.15 studs to the inch, 1.86 studs tall), more than the
saw's 1.3 because it's a small thing, less than the padlock's two. It's laid standing on its foot.
In your view it's held low on your left, the trumpet standing up beside the hall and the mark
turned to you (`hold` -1.2, -1.15, -2.2, turned 205, 4, 10); a friend sees it in your fist,
trumpet up, the mark out to your side (`inHand` 0, 90, 0: at -90 the mark faced your body,
measured in Studio). Picking it up plays Pro Sound Effects' "Metal Hit Steel Plate Hit Slapped 2"
(its one slap, a little faster); dropping it, "Metal Container 2" from just before its hard hit
(0.36 s) at 1.3 times speed, an empty can landing and bouncing, both measured by AudioAnalyzer
since nobody here can listen. Its `use` pose is its hold: L-14a2 raises it to blow. `Specs/AirHorn`
carries the bell's mouth for the blast. The test hall lays one beside the spawn's bolt cutters.
Not chosen: a trumpet bent forward (a sport horn's; harder to read standing on a floor, and the
straight one is the familiar shape); a red can (the cutters are red); a brand or words on the band.

## D-087 Blowing the air horn: a blast keepers hear as they hear doors (L-14a2, Nov 10)
Lethal Company's air horn draws the monsters that hunt by sound; ours does the same through the
keepers' own hearing (D-069), so nothing new decides who hears it. You press Blow with the horn in
your hand (a left click as Lethal Company's use, a gamepad's L2, since R1, R2, L1, X, Y and B are
taken, or a round button left of a phone's jump button, under the right thumb that turns and
jumps, so you can blow and run). Every keeper on that floor whose trip along the halls to you is
inside 130 studs comes to where you blew it and looks, as for a door; a sleeper in an open unit
that near wakes and comes (the GDD's "wakes dormant things nearby"); a hunting one keeps its eyes
on you; nothing hears it through a shut door. 130 is a door bursting open, the loudest door
sound, past an open's or a slam's 110: the horn is the loudest thing a player makes, and players
hear it to the same distance (D-069: players and keepers hear one world). The sound is placed
where you stand, dropped to the floor of the place you're in, and the keeper's spot kept off a
unit's walls, as a search's is (`Horn.where`). One blow every 2.5 s, kept by the server per player
(a press up to 0.15 s early is taken), with no count: Lethal Company's never runs out and the GDD
gives none (`OWNER.md` asks).
How it's built: a tool whose catalog row has a `verb` ("Blow") has a press of its own, so bubble
wrap, the blanket and glow sticks reuse it: `Tools.UseRemote` ("ToolUse"), taken by `Slots`
(a living player with such a tool in hand, then its own rate, never the hand's) and fired as
`Slots.used`. `Horns` (server) keeps the horn's gap, stamps the carried horn's model with the
server's clock (`Blown`) and tells `Keepers:hearHorn` the bell's mouth; `Keepers` finds the floor
the point is on (`Horn.onFloor`, by `KeeperMap.off`) and hands each keeper `Horn.heard`. On your
screen (`HornView`) the blast plays at once, ToolView brings the horn up into the row's `use`
pose for the 1.1 s blast with its jerk (`Hand.use`), and CameraShake kicks 0.32; the button dims
until the gap is up. Friends' screens play the stamped blast at its bell (skipped if over 0.5 s
old) and lift the blower's left arm to 135 degrees after their animation. The blast is Pro Sound
Effects' "Air Horn Various Lengths 4" from 0.92 s (one 1.1 s stadium blast, then its echo).
Not chosen: a separate wake radius for sleepers (keepers and players would hear different worlds,
D-069); the 60 studs the last handoff suggested (quieter than a door, so the horn would lure less
than opening one); the horn heard from the tops by keepers below (the map puts a blast up there
in the unit under you, so a shut door muffles it: the same open question as sight between the
tops and the halls, `OWNER.md`); a client-only sound for friends (the server's stamp keeps one
truth, and a late screen skips a stale blast).

## D-088 Bubble wrap: a roll you carry, a sheet it lays (L-14b1, Nov 10)
The GDD's bubble wrap ("Laid across a hall, it pops when anything crosses", its catch "Friends pop
it too") is a tripwire alarm, and its precedent is Minecraft's tripwire, which any mob or player
walking through sets off. Lethal Company's whoopie cushion sounds when stepped on too, but whether
its monsters hear it is only anecdote, so it isn't the precedent. Built from code the air horn's
way (`art/bubblewrap/`): one baked 1024² set and two MeshParts in one FBX. The roll is a 12-inch
household roll of large-bubble wrap at 0.15 studs to the inch (1.6 times life, the horn's scale):
1.8 studs long, 0.78 across, on a brown cardboard core that stands a little proud of each wound
end, its loose end high on the front held down by a strip of brown packing tape. The sheet is that
wrap unrolled across the 8-stud hall: 7.35 studs across (short of each door face), 1.8 deep, its
ends curled up as a roll's wrap does, rippling a little, sitting just off the floor. Bubbles are a
fat inch across in staggered rows ("large bubble" wrap), because half-inch bubbles are under four
pixels a few studs off on a phone; each is painted as a clear dome with a white rim, which reads in
Roblox as rings (the owner judges, `OWNER.md`). Clear film with a cool tint, milky where it's
wound thick; on the floor the film is painted grey, as if over concrete. The sheet is its own
template, `ReplicatedStorage.Props.BubbleSheet` (pivot: the middle of the floor under it), not a
second part of the tool: the tool's template is what's carried, dropped and handed over, while a
laid sheet stays where it was laid, and several may be down at once. The sheet is its top surface
only: it lies on a floor and curls up towards the hall, so nothing sees its underside. The atlas is
laid out by hand, the sheet a strip along the bottom at 137 texels a stud and the roll
smart-projected into the square above it at 240, since packing a 4-to-1 strip into a square tile
wastes most of it. Held low on your left, its axis reaching in from the bottom corner, the taped
end up (`hold` -1.3, -1.2, -2.6, turned 240, -8, 0); a friend carries it by its middle along the
forearm (`inHand` 0, 90, 0). Picking it up plays Pro Sound Effects' "Plastic Bubble Wrap Short
Fluttering Movements 12" from its first crinkle; dropping it, "11" from just before its sharp
crackle, a little lower; both measured by AudioAnalyzer. No `verb` yet: a Lay button that did
nothing until L-14b2 would be a silent action, so the row gains `verb = "Lay"` there. Not chosen:
pink anti-static wrap (reads as a toy); a 24-inch roll (3.6 studs in your hand covers the hall);
a loose tail flapping off the roll (harder to read on a floor than the tape); real see-through film
(`AlphaMode` Transparency, in ROADMAP's polish list).

## D-089 Owner calls, Nov 10: a corner minimap, two tools parked, the Moth out
- **The map is a small corner minimap, always on, for now** (L-10). The owner may later make it a
  map you stop to open, so you're exposed while you read it; the drawing stays apart from its frame
  so that's a small change. Friends as dots stays the default, and moving it up the queue is the
  owner's call (`OWNER.md`).
- **Only the bubble wrap of the tools left:** the moving blanket and glow sticks are parked, not
  cut (L-14c, L-14d); the owner isn't sure we need them (`OWNER.md`).
- **The Moth and its mothballs are out:** "taking the whole storage unit thing too literally".
  Beyond the Mannequin, the GDD's roster was never the owner's pick; it waits on a rework from the
  loop, each monster with a hit game's rule and storage only as its look (`OWNER.md`). The GDD
  still lists them until then; build none of them.
- **"Keepers" was never agreed as their name.** It's our working word in the docs and code only;
  nothing on screen says it. The code keeps `Keepers` until a name is picked and reaches the screen.
- **The air horn's controls pass** (the round Blow button left of a phone's jump button; a left
  click): tweak if playtesters ask.

## D-090 Laying the bubble wrap: one sheet across the hall at your toes (L-14b2a, Nov 10)
Minecraft's tripwire is strung where you want the alarm; ours is laid where you stand. With the
roll in your hand you press Lay (the same round button, click or L2 as the horn's Blow: HornView's
button now takes any tool with a verb, each tool's view answering its own press), and the whole
roll unrolls into one sheet square across the hall, its near edge just in front of your toes
along the hall the way you face, on the hall's centreline (`Wrap.place`). Facing a dead end's
wall it lies under your feet, or backed off the wall. Ahead, not under you, so you watch it go
down and the natural move is to face the way the threat will come, lay it, turn and run; the
layer is never standing on it. At a junction's middle it lies across whichever way you face
more. Only in a hall: the straights and the junctions (`Wrap.halls`), never a unit, the tops
(your middle over 6 studs up), the lobby (a room, and the car opens off it) or the car; refused,
your screen says "Lay it in a hall" on Slots' short line. One sheet a roll, the roll spent
(`Slots:spend`): the GDD gives no count (`OWNER.md`). The server facing is the character's as
the client holds it, a moment late (D-084); the sheet is square to the hall either way.
On every screen (`WrapView`) a sheet stamped within the last second unrolls from the layer's
left to their right in 0.55 s, eased out like a pushed roll: a loose copy of the roll's body
rolls over the floor along the hall's axis, turning by the distance over its radius and thinning
to 0.4 of its girth, the sheet's part grown behind it from the left edge (a MeshPart's size
scales its mesh; at this speed the stretch reads as wrap laid out), then the core sinks and
fades in 0.18 s. A crinkle plays at the sheet (the pick-up's, slowed to 0.85: a real unroll
rustle is in ROADMAP's polish list). Your view brings the roll out and down (the row's `use`).
The test hall gives `Wraps` its own list of halls (DevCorridor's `TEST_HALLS`).
Not chosen: under your feet (you'd stand on your own trap and not see it go down); a sheet as
long as you like or two a roll (no precedent or GDD number); a client-side check of where you
stand (screens don't have the floor's layout; the server's refusal is one short line away).

## D-091 Owner calls, Nov 10: softer bubbles, two tools cut, the minimap's friends and slot
- **The bubbles are softer** (L-14b1's look): each bubble now goes gently milky from a third of
  its radius to its edge at half strength, with a soft glint high on one side (`MILK`, `GLINT`
  in `art/bubblewrap/spec.py`), instead of a white ring. Re-uploaded in place; the new textures
  have new IDs, so the templates' SurfaceAppearances were swapped in Studio (docs/STUDIO.md).
- **The moving blanket and glow sticks are cut**, not parked (L-14c, L-14d gone). Bubble wrap
  is the last of the GDD's tools. The deal still deals them as unbuilt tools until a session
  takes them out of `Deal.Tools` and its bag (it reshuffles every seed: Queue).
- **The minimap shows friends as dots**, behind one Config switch so they can come off in a line.
- **The minimap comes straight after the bubble wrap**, before getting kept (L-07).

## D-092 The pops: a tripwire anyone treads on, heard as far as an opened door (L-14b2b, Nov 10)
A laid sheet is Minecraft's tripwire: anything that walks into it sets it off, a keeper, a
friend or you. A foot entering the sheet (its 7.35 by 1.8 studs, plus 0.4 round its edges for a
foot reaching past your middle, which covers the hall wall to wall) pops it, once (`Wrap.crosses`,
Lune-tested). So does a step passing clean over it between two server steps. Stepping off it or
shuffling on it doesn't (a sheet laid under you at a dead end stays quiet as you leave it), nor
does walking beside it. Feet more than 1.2 studs over it are in the air, so a jump clears it, as
you can hop a tripwire: a skill for you and your friends, never for a keeper, which doesn't
jump. Feet read up to 3 below it while crawling. A move longer than 8 studs in one step (caught,
respawned) pops nothing on the way. The server (`Wraps`) checks only while a sheet lies unpopped,
each step, from where each foot was last step: players' feet from their root down to the floor,
keepers' from `Keepers:feet` (a read, so `Wraps` never reaches into the brain). A pop stamps the
sheet `Popped` (the server's clock) and tells `Keepers:hear(at, reach, what)`, the general hearing
the horn now uses too (`hearHorn` is `hear` at the horn's reach; the pure rule moved from `Horn`
to `Keeper.onFloor`, `soundAt`, `heardAt`). Its reach is an opened door's, 110 studs along the
halls (D-069): laid two halls back, it brings a keeper as a door opened there would. The keypad,
a dropped tool, the saw and the rest can use `hear` later (Queue).
On every screen (`WrapView`) the pops play at the sheet, heard as far as keepers hear them: Pro
Sound Effects' "Plastic Bubble Wrap Short Fluttering Movements 2" from 3.34 s for 1.05 s, a
crackle building to one sharp pop at -6 dB, at volume 2 (measured, docs/STUDIO.md). The sheet goes
flat over 0.6 s, fast then settling: its bubbles squash to 0.35 of their height (the part's size
scales its mesh, the bubbles are geometry) and its film dulls (`SurfaceAppearance.Color` to 0.72
grey). Popped while still unrolling, it flattens as it unrolls. Under your feet, your view jolts
(0.16, half the horn's). A sheet seen long after it popped just lies flat. Default (`OWNER.md`):
a popped sheet stays, flat and silent; one roll, one alarm.
Not chosen: popping as you walk on it (the layer at a dead end would set off their own);
counting a jump (no skill, and a tripwire doesn't); a chain of pops per foot (one alarm reads
cleaner, and the GDD names one).

## D-093 Three pops, then spent; laid sheets stream whole (L-14b2c, Nov 10)
The owner, Nov 10: a sheet should pop three times as it's walked over, then lie visibly spent
and do nothing. It wears through in stages you can see, as Minecraft's anvil goes chipped, then
damaged, then breaks. Each walk across (D-092's crossing) pops it while it has pops left and the
last one is 0.8 s gone (`Wrap.ready`): a friend on your heels or a foot dithering at its edge
doesn't spend a pop, and pops never blur into one crackle. Every pop is heard by keepers as the
first was. On screens each pop plays the same measured crackle at its own pitch (1, 1.1, 0.9) and
wears the sheet a third of the way (`Wrap.worn`): squashed toward 0.3 of its height, tinted grey
and turned up to 0.35 see-through, the air gone out of it. The server stamps the count (`Pops`)
before the time (`Popped`); screens act on the time and read the count.
The owner's "only heard it once" was mostly a bug: `WrapView` dropped any sheet whose part
reached the screen after its model, so it never played, popped or wore there. Laid sheets now
stream `Atomic`, and `WrapView` waits for a late part (docs/STUDIO.md).
Not chosen: a baked burst-bubble texture for the spent sheet now (an art session: L-14b2d, if the
owner finds the grey, flat, clear look doesn't read as popped); clearing it away when spent (the
owner wants it seen); a rest per walker rather than per sheet (more state, and one alarm a moment
reads cleaner).

## D-094 The corner map: a window that follows you, filled in as you walk (L-10, Nov 10)
The map sits top right under the top bar, a square about a third of the screen's height (104 to
176 points), showing 112 studs of floor round you: halls at least 7 points wide on a phone. It
fills in each hall piece you stand on (a straight, or a junction's middle and arms; standing in a
unit or on its top fills in the hall it opens onto), as R.E.P.O.'s map fills in rooms as you find
them; the lobby and the car are drawn from the start. While the car is off the window an amber
mark waits on the edge the way it lies, as GTA's radar holds a waypoint on its rim, so the way
back is always on screen. North stays up, the lobby and the gate at the bottom ("the way back is
always down"); your dot turns with your view. Friends are blue dots, held on the edge, paler, when
off the window (D-091). A unit is ticked once the deal has shown its inside (a peek, an open, a
lift from inside, a saw's hole: `Deals.dealt`), for everyone on the floor, so friends see what's
been searched; it goes green (the sign that reads at 6 points) with a tick on it. What you walked
stays yours: a friend's walking draws nothing on your map. Roblox's player list is off: it would
open over the map on a computer.
**The layout reaches screens as shapes, never the seed.** `Floor.generate` would rebuild the floor
from its seed on a screen, but the deal is drawn from the same seed, so a screen holding the seed
holds the code, the notes and every unit's contents. `Minimaps` sends the drawn rectangles
(`Minimap.encode`, about 2 KB a floor) and the opened list; the server owns both.
Not chosen: the whole floor fitted in the corner (halls 4 points wide on a phone, too small to
tick a unit); turning the map with you (a full map later would have to turn too, and "down" stops
meaning the way out); drawing the doors' own state from each unit (far units aren't streamed to
your screen, so a friend's opened unit wouldn't show).


## D-095 Getting kept: stored in a shut unit away from you, let out as its door goes up (L-07a, Nov 10)
The moment: the keeper's hands close, the screen goes black through the 2-second wrap, and you
wake in the dark inside a unit somewhere on the floor, facing its door, until a friend opens it.
Dead by Daylight's hook and Flee the Facility's freeze pods are the precedent (caught, stored, a
teammate frees you). Stored at random and never the nearest is the GDD's own twist on the hook,
an untested bet in `OWNER.md`.

As built: Keepers marks the caught player kept (`Kept.Attribute`, a player attribute only the
server sets) at the catch and skips them while it's on, so no keeper sees or catches them twice;
`Caught.Out`'s 2-second spare became "while kept", and its length is now `Caught.Wrap`.
`KeptPlayers` takes `Keepers.caught`: everything carried drops (`Slots:dropAll`, as dying does),
the root is anchored (only the server moves a kept player; nothing to fall through while the far
unit streams in), and `Kept.choose` picks the unit: its door all the way down (not padlocked, not
open), no keeper dealt there nor the guard's place, no keeper's feet inside, nobody kept in it;
never the nearest of those while another will do; an unopened one ahead of one already seen into,
at random. That unit is never dealt (`Deals:hold`), so the friend who opens it finds only you,
never a keeper beside you; a note already stuck there stays. At `Caught.Dark` (the screen black)
the server pivots you 62% of the way in, facing the door. You're let out when its door's state
reaches Open (`Doors.changed`): any friend's Open, the stand-in until L-07d's Cut free. Dying,
leaving, a new character or the floor going lets you go too; no unit free holds you through the
wrap and lets you go where you stand.

Refused while kept, on the server: every prompt in the world (`Prompts.wrapped`: doors, the lift
from inside, crawl holes, ladders, the saw's cut) and Slots' pick-up and hand-over either way.
The screen (`CaughtView`): the catch's blackout as before; in the black the camera turns the way
the server stood you and the body stops turning with the camera (`Humanoid.AutoRotate` off while
held: the game is always first person, and the body turned to the old camera otherwise, so you
woke facing the back wall); the prompts hidden (`ProximityPromptService.Enabled`); "Wait for a
friend" comes up over 1 s; all of it undone as the attribute clears.

Not chosen: only units already opened (few early in a floor, and a friend's map already ticks
them); dealing the unit as usual when it's opened (a keeper could be dealt in beside you); the
building rolling an open door down on you (needs a door motion the building doesn't have, and a
shut door is the GDD's picture); a dev command to get out (Reset already does, alone); waiting on
the stream before the move (an anchored root can't fall, and the screen is black anyway).

## D-096 The wrap you can see and hear: fitted film the server welds on, a squeal each screen plays (L-07b, Nov 10)
The moment: a friend lifts the door and there you are in the dark, shrink-wrapped head to foot in
cloudy film; as the keeper wraps you, the film screeches in the black. The film is real art
(`art/keptwrap`, the unit's way): a cocoon lofted round Roblox's default blocky R15 body at rest,
bands of film in a spiral, each over the last, a bright cord along every edge, the film twisted
shut over the crown; its alpha in the colour map (AlphaMode Transparency).

As built: at the move (`Caught.Dark`) `KeptPlayers` clones `Props.KeptWrap`, sizes it with the
pure `Kept.fit` to the kept body's rest box (each body part placed by its joints' rest offsets,
Motor6D or AnimationConstraint, so a mid-swing arm or a hat doesn't size it; clamped to 0.5-2.5x
per axis), welds it to the root (massless, no collision, touch, query or shadow) and parents it
in the character, so it streams and goes with the body; it's destroyed as they're let out. Its
part Transparency is 0.02 (`Kept.WrapBlend`): at 0 Roblox cuts the alpha into shreds instead of
blending it. `CaughtView` keeps it undrawn on the kept player's own screen. The squeal needs no
network of its own: every screen watches each player's `Kept` attribute (only the server sets
it) and plays Pro Sound Effects' duct tape peel 2, 0.6 to 2.5 s at 0.92 speed (about the whole
2-second wrap): close for the caught player, from where they stood for everyone else (45 studs).

Not chosen: the wrap at the catch rather than the move (seen for 0.4 s, then gone with the body;
the catch's own look is L-06c2's); a server-played squeal (it moves with the body into the unit
and would tell friends where you're kept, which is L-07c's bang to tell); sizing by
`GetExtentsSize` (hats, wings and a walk's swing would size it); hiding hats and hair while
wrapped (a roomy head holds most hair; a big hat pokes out).


## D-097 Banging: the door's own thud, a mark friends see through walls, the hall's light under the door (L-07c, Nov 10)
The moment: alone in the dark, wrapped, you hammer on your door; down the hall your friends hear
it thud and see which door, and so might a keeper. Dead by Daylight's hook is the precedent:
everyone sees where you hang, and a teammate comes.

As built: once you're inside your unit a round Bang button comes up (`CaughtView`), under the
right thumb on a phone and low in the middle elsewhere with its key under it (a click, Space, a
gamepad's A or R2). Each press jolts your view at once (`Kept.BangKick`) and fires
`Remotes.Bang`, which carries nothing. Presses come no faster than `Kept.BangEvery` (0.55 s, so
the door's 0.5 s jolt plays out whole); one press made too soon is held for the next bang, as a
fighting game buffers an input, so mashing hammers at the door's pace. The server
(`KeptPlayers`) takes a bang only from someone kept and already inside, at most one per
`BangEvery` less `BangSlack` (0.15 s for a jittery connection): a spam of 362 presses in 3 s
landed 8. A bang is the building's own `Doors:move(unit, "Bang")`, the trapped keeper's blow, so
the door's thud and shake play on every screen near it and keepers hear it as they hear that
(DoorSound's Bang, 70 studs along the halls): no second call to `Keepers:hear`, which would
double it. It never dents the door.

The mark: each bang stamps the floor's model (`Kept.BangsAttribute`: slot, who, when, the door's
foot), the model the corner map already reads, so every screen marks it however far off the unit
is and whether or not it has streamed in. On friends' screens (`BangMarks`) a blue dot with the
kept friend's name stands over the door, drawn through walls, a ring going out at each bang; on
the corner map the unit gets a bigger blue dot with a ring, held on the window's edge when off it.
Both fade `Kept.BangMark` (8 s) after the last bang, the last 2 s fading, and go at once when the
friend is let out. Never on your own screen, nor while you're kept. A kept friend's own map dot
is hidden (`MinimapView`): the GDD stores you at random so friends have to look, and a dot that
shows where you're kept would make the banging pointless (`OWNER.md` asks).

The light under the door (`UnderDoor`): while you're kept the server names your unit
(`Kept.InsideValue`, an ObjectValue under you) and your screen alone draws a thin warm Neon strip
against the inside of the door's bottom bar, with a SurfaceGui spill fading 1.6 studs across the
floor, lit only while the nearest motion light outside is Lit, flickering on with the tube
(`HallLight.Flicker`). Motion lights trip for players and keepers but never the Mannequin, so the
line coming on means someone walked by. No real light (the GDD's cap).

Your torch keeps working while you're wrapped (the default the ticket named; `OWNER.md` asks).

Not chosen: a mark on the unit itself (a far unit isn't streamed to a friend's screen, D-094's
reason); a remote event to friends for each bang (a screen that streams in or joins late would
miss a mark still showing); a quieter or shorter-reaching kept bang (it's the same door's thud);
a sound for a far friend as the mark appears (polish, ROADMAP); a real light under the door (a
light instance per kept player, against the phone budget).

## D-098 The deal hands out only built tools; the guard drawn before the bag; the deal script deals what Studio deals (L-14e, Nov 10)
The moment it fixes: a door rolled for a tool always has one behind it. With the moving blanket
and glow sticks cut (D-091) but still in the bag, about one tool unit in five opened on nothing,
a lie about what the deal promised.

As built: `Deal.Tools` and `Deal.Bag` hold the six built tools (two saws, two bolt cutters, two
padlocks, a ladder, bubble wrap, an air horn: nine to a bag, as Tetris's bag deals). The rule
that keeps it true is a test, not a habit: `tests/carry.spec` fails if any tool the deal hands
out lacks its `Tools.Catalog` row or its generated Specs, so a future tool joins the bag in the
ticket that builds it. `Deals`' "no art yet" path stays as a guard and no longer fires.

The guarded note (D-072) is now drawn before the bag is filled, still after everything the floor
lays. Drawn after the bag, as it was, it moved with any change to the bag's tools or counts, and
with it the floor's one awake keeper on floors 1 and 2, which the Studio recipes and the owner's
test steps lean on (seed 7, floor 1: Unit 157). Every seed's bag order moved anyway in this
change, so this was the free moment. What it moved: each seed keeps its layout, code, padlocks,
notes and every unit's kind (all drawn earlier); the bag's order changed, and the guard on
about half of floors (138 of 300 kept theirs over seeds 1 to 100, floors 1 to 3). Seed 7 keeps
its guard on floors 1, 2 and 6 to 10 (157 on floor 1); floors 3 to 5 moved (377 to 367 on 3).
`tests/guard.spec` holds it: a bigger bag moves no guard over 300 floors (it fails with the old
order).

`scripts/floor-deal` now carries on the layout's own Random into the deal, as `DevCorridor` lays
the Studio floor, and names the guarded note. Before, it seeded the deal apart (seed + 1000000,
as `tests/deal.spec` still does), so it never showed what Play deals (L-13b1 saw the gap and put
it down to the order doors open). Verified: on seed 7, floor 1, 26 units opened in Play dealt
door for door what the script prints. Only which tool lands where depends on the order doors
first lift.

Not chosen: leaving the guard after the bag (seed 7, floor 1's guard went to Unit 124 that way,
and every recipe naming 157 would have needed rewriting, and again at the next bag change); the
specs dealing from the layout's Random too (they check rules over 200 seeds, which holds either
way).

## D-099 Cut free: a friend's one-second hold at your open door, a rip, the film slumping off you (L-07d, Nov 10)
The moment: you're wrapped in the dark, the door goes up, a friend steps in and grabs the film;
it strains round you for a second, then rips. Strips of film fly at them, the wrap drops down
your body into a heap round your ankles, and you're on your feet. Dead by Daylight's unhook is
the precedent (a teammate at your hook holds a button and you're down and running), as Flee the
Facility's freeze pods are for a teammate letting you out. It replaces L-07a's stand-in: the door
going all the way up no longer lets anyone out.

As built: once you're inside, `KeptPlayers` puts a `CutFree` Attachment on your root, a little
up and 1.2 studs out in front of the chest toward the door (`Kept.CutUp`, `CutAhead`), so the
button sits on the film where hands would grab it and its line of sight clears the body. The
prompt (`Prompts.make`): "Cut free" over your name, E or X (Open's keys, and Open never shows on
a door that's all the way up), held `Kept.CutHold` (1 s), shown within `Kept.CutReach` (7 studs:
from a big unit's doorway, a step out of a small one), enabled only while your door's state is
Open (`Doors.changed`). Your own screen hides prompts, so you never see it, nor any of a
friend's hold but its sound.

The server judges each trigger with the pure `Kept.cut`, in the unit's frame: never yourself,
never a friend who's kept or down; you must be inside and your door up; the hold must have
begun on the server's clock (`PromptButtonHoldBegan`) at least `CutHold - CutSlack` (0.75 s)
before the trigger, so a trigger with no hold does nothing; and the cutter must stand between the
unit's side walls, from `CutOut` (3 studs) into the hall to the back wall, and within `CutReach`
plus `CutReachSlack` (2) of the cut point. That refuses a cut through a side or back wall, from
across the hall or from up on the tops. A refusal a friend can fix flashes on the button ("Get
closer", "Hold to cut"); the rest can't come from a real button.

The strain: each friend holding is counted onto the wrap (`Kept.PullAttribute`), and every
screen plays the wrap's own peel there (`Kept.Pull`: the squeal's recording at 0.74 speed),
swelling from a third to full over the hold (`Kept.pull`), so the rip lands on a peak.

The rip: the wrap is unwelded and left anchored where you stood, parented to Workspace with when
it tore (the server's clock), who it freed, who cut and which way it lists, then destroyed after
`Kept.tearLength()` (2.1 s) and a half. Every screen that has it (`CutFreeView`, from the tag
`Kept.WrapTag`) plays the rest itself: Pro Sound Effects' "Plastic Sheet Impacts Rips Paper
Tears 9" from 0.31 s (a sheet torn hard, bursts to 1.1 s), 18 strips of film flung toward the
door (a ParticleEmitter with the film's own colour map, squashed into strips), and the slump
(`Kept.tearPose`): a bulge as it's torn, a fall down the body gathering speed, its foot held on
the floor, listing toward the door, to a heap 0.16 of its height, 0.8 as wide and 1.6 as deep
(round your ankles, not the shoulders), a squash as it lands with "Plastic Bag Handling Crunchy
Cellophane 8", lying 0.75 s, fading 0.6 s. A screen that streams it in late joins the beat where
it is, silent past 0.3 s. The freed player's view jolts (`Kept.FreedKick`, 0.5, softer than the
catch) and widens 7 degrees and back over 0.8 s (`Kept.widen`); the film is drawn on their own
screen again, so it drops away past their eyes; their Bang button fades over 0.3 s. The
cutter's view jolts a little (`Kept.CutterKick`, 0.2).

Not chosen: a remote event for the tear (a late screen would miss it, and the wrap already
carries everything); the server playing the sounds (one more thing to stream, and no say over a
late screen); the wrap vanishing, or tweened on the server (every screen's own steps are smoother
and cost the server nothing); a torn-open wrap mesh (a squashed cocoon reads as film dropping off
at the speed it moves; the torn mesh is polish in ROADMAP); hold progress on the kept player's
screen (the ticket: they get only the sound); a grace after you're free and keepers hearing the
rip (both `OWNER.md`); reading the colour map's `ColorMap` (game scripts can't; its
`ColorMapContent` they can, docs/STUDIO.md).

## D-100 The padlock: a clock on your door, a hand working keys at it, the click shut (L-07e, Nov 10)
The moment: you've been kept a while. In the dark you hear keys worked in a padlock right outside
your door, and a countdown comes up; down the hall your friends see your name counting down, and
one of them sprints. Then the bolt shoots and the shackle clicks: now only bolt cutters get you
out. Dead by Daylight's hook stages are the precedent (wait too long and it gets worse, and the
whole team sees the clock); the GDD's "Left too long" is the rule ("after a few minutes the
building padlocks your unit, so freeing you needs bolt cutters").

As built: the clock is the server's (`KeptPlayers`), one a keep, started as you're put inside:
`Kept.PadlockAfter` (150 s) of time that counts, the warning its last `Kept.PadlockWarn` (20 s).
Time counts only while your door is down (`Kept.counts`: shut, open a crack, coming down); going
up or up, a friend has come and Cut free is on offer, so it stops. Run out, the padlock goes on
the moment the door is down and still (`Kept.lockable`, `Kept.tick`): with it held a crack open
the hand keeps working every `HandleAgain` (3 s) until it drops. The padlock is the game's own
(`Doors:lock(unit, true)`), so its bolt and click play on every screen near (DoorSounds), its
buttons read Padlocked with Open and Cut, keepers hear it as any padlock, and Cut free can't show
until a friend's bolt cutters take it off and the door goes all the way up (the door's own rules).
A door padlocked by a friend's hand first counts the same. One padlock a keep: once it's been on,
the clock is done, so a friend who spent bolt cutters never faces a second. Let out, dying or
leaving stops the clock; a padlock still on stays on the empty unit (it's the building's, and
taking it off unseen would be a silent change).

The wire: two attributes on the kept player, which every screen has however far off: the server
time the padlock goes on while the warning runs (`Kept.WarnAttribute`, set as it starts and as
the door comes back down, cleared while it's up) and `Kept.PadlockedAttribute` while it's on.
Every screen plays the rest itself (`PadlockView`). The hand: Pro Sound Effects' "Keys In
Padlock" 4, 5 and 2 (`Kept.Handle`, slowed to 0.85, turned up: the takes sit at -24 to -36 dB),
at the hall side of the door 1.5 studs up, heard to 40 studs, five times (`Kept.Handlings`: 19.5,
14, 9.5, 6 and 3 s left), closer and louder to the end, the last over 1.4 s before the bolt; each
trembles the kept player's view (`HandleKick`). Your line, high in the middle at the Caught
headline's size: "Padlock in 20", beating each second, red for the last five. Friends' lines
under the top bar: "Sam: padlock in 12", the name in the map's friend blue. The click (as
DoorSound's PadlockShut lands, 0.32 s after the bolt): your view jolts (`ClickKick`), APM's "Evil
Mind 9" hits (dark, most of it above 150 Hz so a phone plays it) and "Padlocked" slams in red and
stays while it's on; friends get "Sam: padlocked" in red and the hit at `DreadFriends` (0.35)
wherever they are, as DbD sounds a hook for everyone. Cut off or let out, the lines fade.

Studio: Workspace's `DevPadlockSeconds` (read in Studio only, `Kept.DevPadlock`) shortens the
clock for each keep that starts after it's set, the warning kept whole unless the clock is
shorter.

Not chosen: a clock that runs with the door up (a friend at your open door would race a padlock
they can't stop); a peeked door stopping it (a crack is still a shut door, and a friend who peeks
and walks off shouldn't freeze it); the building pulling a peeked door down to lock it (the ticket
waits for it to come down; a door moving by itself in a friend's face is a new mechanic); a timer
on screen the whole keep (the warning is the clock you feel; the dark before it stays yours);
the line naming the unit or marking it on the map (banging is how friends find you, D-097); a
second padlock after one's cut; a remote event for the warning (a screen that joins or streams in
late would miss it); the server playing the hand (one more thing to stream, and no say over a
late screen); the chase's sting for the click ("Rising Fear Hit 1" is the chase's own).

## D-101 A walk that frightens: it limps, its head lags, its steps get heavier as it nears (L-06c1, Nov 10)
The moment: you hear it before you see it, and what you see moves wrong. The owner, Nov 10
night: its steps "sound like fucking pinnoccio walking around". The light wooden clack each step
and the plastic knocks between (D-083) were a puppet's sounds, so both went.

The walk (`Mannequin/Pose`, every screen's own, the server's motion untouched): it limps on a
stiff left leg, as Silent Hill's mannequins and Doors' Figure move like things that shouldn't
walk. The left keys are no longer the right ones mirrored: the left knee stays all but straight,
and on the pass the left hip hitches up to swing the stiff leg round on its toe. Each key carries
it its own distance (`Walk.Spans`, shares of the 2.7-stud step: 0.8 for the plant, 1.4 for the
drag, 0.7 for the stiff heel, 1.1 for the swing through) and holds its own share before snapping
on (`Walk.Holds`: 0.7, 0.15, 0.55, 0.5): the plant held long and then a jerk, the drag starting
at once and sliding slowly, the one smooth thing it does. Its head lolls hard to one side on the
plant and the other on the heel, and lands a beat late: over the first half of each key's span
(`Walk.Lag`, never past the hold) it swings from the last key's place into this one's, so it
bobbles after every step. A light still freezes it on a key, head settled (a small snap of the
head as the light lands). Each key's frames are now 3 of the head settling, the key held and 9
of the snap (`Walk.Settle`, `Walk.Snaps` 10), still worked out once per screen and cached.

Its sounds (`KeeperTell`, `KeeperRows`, `KeeperSounds`): each beat is layers, recordings played
at once. The plant is a hollow fibreglass thunk (four Pro Sound Effects planter drops on
asphalt, pitched to 0.74 to 0.86, heard to 70 studs, past the 48 it sees) with a body's weight
under it (a plastic cooler's hit, a body's thump and a railroad tie on pavement, mostly 190 to
470 Hz so a phone still plays it). Nearer is heavier, as Five Nights at Freddy's footsteps swell
as an animatronic comes: `heft` eases from 1 within 10 studs to 0 at 40, and each sound's
`farGain` and `farPitch` say what's left of it far off (the weight: a tenth, 15% higher), so a
tap down the hall becomes a thud in yours. The drag is a rock scraping concrete (SCP-173's
grind), raised to 1.1 to 1.3 for a phone, heard to 45. The heel is the thunk lighter and a
little higher with a third of the weight; the swing through is silent, so you hear the limp:
thump, scrape, tock, nothing. Its body creaks (a rubber pedal's ratchet and a tire's rub pitched
down) as it jerks out of its shop pose and each time its facing turns 40 degrees (`turned`,
tested on every screen as KeeperView moves it, no more than one a 0.9 s), so it creaks at
corners and as it turns to you. A door lifted on one standing in a unit answers with a deep
thunk and a creak. Standing or held in light: nothing, as before. Every take is cut to one hit
and measured (docs/STUDIO.md, "Sounds measured for the keeper's walk"); three or four takes a
sound, never the last again, each at a random pitch, so no two steps sound alike.

Not chosen: the dead-still-then-rush (SCP-173, Doors' Seek), which needs the server to move it
faster than its walk for a moment, against the GDD's "nothing outruns you" (ROADMAP polish, the
owner's call); one heavier recording in place of the clack (one sound can't be both a far knock
and a close thud); an equaliser for heaviness (layers do it with no effect per sound, and what
a phone can't play an equaliser can't add); its head turning to follow you (it would say it had
seen you when it hadn't); sounds at the feet (still ROADMAP polish).

## D-102 The catch as a jump scare: silence, its face rushing your eye, the cut, a slow wake (L-06c2, Nov 11)
The moment: the worst thing that can happen to you. The owner, Nov 10 night: getting caught
"doesn't seem like a big deal"; it has to land. Five Nights at Freddy's and Piggy end a run with
the face rushing the camera and a scream, no blood; this overrides the GDD's "no screamer" line
(owner, Nov 10). D-077's jerk, half-dark and fade is replaced on the caught screen; the server's
catch is unchanged but for the timing below.

As built, on the caught player's screen only (CaughtLunge, run by CaughtView; every number in
`Caught`): its hand closes and the hall goes silent (SoundService's listener moved a million studs
off, so only your own sounds play; the chase music already cuts itself), every other screen is put
away, and your view is taken (Scriptable) and wrenched round to its face in 0.12 s with a kick
(0.55). The real body is hidden on your screen and a copy from the template stands in its place in
the same stride (its joints' `Transform`s copied), lit faintly by a light hung before its face.
It holds still for the dread (to 0.48 s) while your view tunnels in to 86% of its width. Then it
snaps into a lunge pose (arms out wide and low, clawing in from either side, head cocked over) and
its head flies at your eye, a twitch back and then ever faster (0.32 s, `reach`: u²((k+1)u − k),
k 0.8), the body hanging off it (`Mannequin.head`), while the view crash-zooms to 48% of its width
and the light on its face comes up. On that first frame of the rush: the scream (Pro Sound
Effects' "Creature Screech Pterodactyl Vocals Screams 1" at 0.8 pitch, volume 2.4, the loudest
thing on a phone), APM's "Razormorph K" (a huge hit, mostly for headphones, ringing into the black)
and "Whoosh Fast Swish By 5" (rising to its peak as the face lands), with its own body's groan and
scrape (the row's new Lunge beat). It lands 1.5 studs from your eye, taller than the screen, with
its hollow thunk and weight (the Catch beat) and the hardest kick (1.0) plus a knock that yanks
your view toward it, tips it and rolls it; it presses in to 0.85 studs for 0.16 s, your torch out
of sight; then the screen is cut to black at 0.96 s (`Dark`, when the server moves you; was 0.4),
the copy gone and the view yours again. "Caught" comes up a beat into the black while the film
screeches round you (your own squeal now waits for the black, so the dread is silent), 1.25 s.
You come to over 2.2 s: your eyes crack half open, drop shut, then open, the view blurred (22) and
grey (−0.75) clearing evenly, the hall's sound back as they first open. The whole wrap is 4.4 s
(was 2.1).

Friends see the film go on: the server now wraps you at the catch where you stand (stamped
`Kept.WoundAttribute`), not in the black, and every other screen hides the real film and winds a
copy on from the feet, clouding in, while your body turns once round on that screen only, as a
pallet wrapper's turntable spins a load (`Kept.wind`, KeptWrapOn); the moment the server moves you
it stops and the real film shows.

Not chosen: the stock chase sting (already "it sees you"; the catch has its own); "Shock Chord",
"DS Horror Stinger" (their attacks ramp over 0.2 to 0.6 s, no startle), the other APM stings
(mostly under 190 Hz, silent on a phone); the face at 0.7 studs (only its dark surface showed,
read as the screen going black); raised arms (they covered its face mid-rush); a knock that shoves
your view back (its face shrank just as it should press in); fading to black (a cut is the blow);
the wake's haze clearing as a square (gone before the eyes opened). A Studio-only hold
(`DevCatchHold`) stops the catch's clock on every screen to look at one frame; it's how the frames
were judged (docs/STUDIO.md, "Testing the catch from the MCP").

## D-103 The ride: a still car, a sliding shaft, the counter turning over (L-08a, Nov 11)
The moment: the breath between floors, as Dandy's World's elevator carries the team between its
floors. Relief as the car takes you, then dread as the readout turns over to the floor you're
about to face and the next landing's dark mouth slides down level with you.

It runs on the server's clock, as the gate's does (D-046). The instant the shut gate hits its post
the server writes one replicated value on the elevator (`Ride.Attribute`: that moment, the floors
from and to), just before who rode (`Aboard`); every rider's screen draws the whole ride from it,
and the server folds the gate open on its own clock (`Ride.opens`), firing `arrived` as the car
levels. Timeline (seconds after the gate hits its post; every number in `Ride`): the car sits 0.8
s, its brakes let go, it gathers speed over 1.8 s on a cosine S-curve, climbs 4.6 s at full speed
(2.4 studs a second), slows over 2.4 s and is level at 9.6 s; the gate starts to fold at 10.3 s
(open at about 11.9 s). One floor is 16 studs.

The car never moves. Moving a car with characters in it jitters on Roblox and the owner's line is
that the ride never jitters the camera. Instead each rider's screen lays a thin sleeve of shaft in
the 0.09-stud gap between the landing's frame and the car's front (`Ride.Shaft`, RideView) and
slides it down past the gate: the hall you left goes black over 0.3 s as the brakes let go (under
the lamp's dip, so you see the light fail, not a fade), its header beam, lamp-lit concrete with
two formwork seams and the next floor's number painted on it, the next landing's apron and bright
sill, then its black mouth, level with you; that black lifts off the real hall over the 0.7 s
before the gate folds. The car's lamp prints the gate's lattice on the sliding wall.

The motion is held on the camera (CameraShake's new `hold`, read each frame under any shake): the
lurch (the car drops 0.08 studs on its cables and springs back at 1.8 Hz, eased out of rest over
0.05 s so it's a shove, never a snap), your weight sinking as it pulls and floating as it slows
(0.03 studs per stud/s²), two cable clanks (0.02 studs, a single damped knock each), a slow roll
and nod at full speed (0.12° and 0.07°), the bob as it levels. No noise is ever added. Lune holds
it to 0.15 studs and 0.6° at most, and no frame (at 60 a second) moves more than 0.012 studs or
tips more than 0.05°.

The counter: an amber LED readout over the gate inside the car (two digits and a stepped arrow,
drawn on a card on the fascia like the keypad's), lit at rest with the floor the car stands at
(`Ride.FloorAttribute`), the arrow lit while it climbs; and the gate clock's plate in the top bar,
which turns from the clock's 0 to the floor in the same amber for riders. Both tick over to the
next floor as the brakes start to bite (7.2 s), with a relay's click, so the new number is the
first sign of what's coming.

Sounds, on riders' screens only, flat (you're inside the box), from Pro Sound Effects and measured
(docs/STUDIO.md): "Freight Elevator 3"'s brake release (its clunk at 1.13 s lands as the brakes
let go) and stop clunk (15.15 s, lands as it levels); "Conveyor Belt 5"'s clanky motor, the part a
phone plays (nine tenths of it 190 Hz to 2 kHz), its pitch 0.82 to 1 and volume following the
speed, handing over to its own winding-down (its stop at 13 s lands as it levels); "Freight
Elevator 2"'s deep run under it for headphones; the motor's start knock pitched down for the
clanks; the unit lights' toggle for the relay; the elevator's own bell (the right code's
double-ding) at 0.84 pitch as it levels. The car's lamp dips to 0.3 as the brakes let go with one
more flicker, a little at each clank, to 0.6 as they bite at the top (ElevatorView, riders only).

Until L-08b lays the next floor, the car arrives back at the same lobby, its number one higher;
`Ride.Linger` (6 s) after the gate opens, DevCorridor arms it again with the same code, the gate
shutting behind the team. The stand-in ride's fade to black and teleport (D-046) are gone. L-08b
hands riders over mid-ride: it writes the same ride on the next floor's car and moves them; a
rider's screen follows whichever riding car holds them.

Not chosen: moving the car and its riders (physics jitter); a fade to black (the old stand-in, a
cut, not a ride); a landing door that parts (no art for it, and the lobby has none); camera noise
for the shudder (the owner's jitter line: the clanks and the sound carry it); counting through
several floors (one floor per ride); a second plate for the counter (the clock's plate is where
eyes already are). A Studio-only hold (`Ride.Hold`, Workspace's `DevRideHold`) stops every ride
where it is, on the server and every screen, to look at one frame.

## D-104 The climb: the next floor laid ahead, riders moved on the cable's knock (L-08b, Nov 11)
The moment: the gate opens on a floor nobody has seen, and the one below is gone, as each of
Dandy's World's elevator stops opens on a new floor. A server system, `Climbs`, runs it: the
smallest stand-in for Brix's round loop (ENG-13, unbuilt), floors only, no lobby or results.

Each floor has its own seed (`Climb.seedOf`: floor 1's is the climb's, each one above the seed
plus a large stride), because one seed for every floor laid floor 2 as floor 1 again, its units
numbered 2xx. `scripts/floor-map` and `floor-deal` use the same rule, so `floor-map 7 2` prints
the floor 2 the game lays. Floor 1 of every seed is unchanged; floors above 1 of a seed differ
from what those scripts printed before today.

Each floor is laid at its own spot, 1000 studs on from the last along -Z (`Climb.Spacing`): two
floors' nearest halls stand at least 792 studs apart over 600 Lune-checked floors, far past the
256-stud streaming radius, so a phone near one never holds the other, and nothing left on a
cleared floor can show up on a later one. The next floor is dealt and laid as the right code
opens the gate (30 s before the car can leave), not as the car leaves: laying took 0.3 to 5 s in
Studio, and the hand-off can't wait past `Climb.Latest`. It waits there with nobody on it;
keepers wake only as its doors open. Laid during play, a floor once held the server 160 ms in one
frame because a hall piece entered the game with all its units at once; each unit now joins its
placed hall piece as it's dressed (peaks of 5 to 9 ms).

The hand-off. The car never moves (D-103), so riders change cars. `Climb.Lead` (0.5 s) before
the move the new floor's car takes the ride over (`Elevators:takeOver`: the same `Ride` and
`Aboard` values, the old car marked done), after the server asks each rider's screen again to
stream the new lobby (`RequestStreamAroundAsync`, waited on: a long hold let it go once). Every
rider's screen lays a second shaft outside the new car, sliding in step (RideView), so whichever
car a frame draws you in, the gate shows the shaft; the older one goes once you've stood in the
new car 0.3 s, and a ride with no shaft at all is let go after 1.5 s. On the cable's second knock
(6.1 s, `Climb.HandOff`) the server moves every rider to the same spot in the new car (turned with
it if it faced another way) in one frame, so friends arrive together, and clears the floor below
in the same frame: whoever's still on it goes to the spawn (L-08c makes them watch), its tools go
with it. The move costs a screen a long frame (0.16 to 0.4 s in Studio at 15 frames a second);
on the knock, under the clank, it reads as the jolt (cut on the bump, as film cuts on action).
Measured in Studio across the hand-off: the camera moved 0.006 to 0.008 studs and turned 0° in
the car's frame on the switch frame, the shaft never jumped, no frame lacked a shaft.

The car leaving empty, from the top floor, or before the next floor is ready comes back to its
own lobby and is armed again for the same floor; a next floor already laid waits for the next
time it leaves. The new car's gate shuts `Ride.Linger` after it opens, armed with its floor's code.

Not chosen: laying as the car leaves (the ticket's first plan; too tight when Studio took 5 s);
one seed for every floor (the same layout); floors stacked up the Y axis (they'd stream
together); the client moving its own character (no snap if walking, but a friend would vanish
from your car for a round trip); clearing the floor below a second after the move (a second
long frame, uncovered); a fade to hide the move (D-103's line: the ride never cuts).

## D-105 Left behind: the sting, then a friend's shoulder until you're back in (L-08c, Nov 11)

The GDD's "Left behind": when the gate shuts, anyone still kept or still on the floor is out of
the climb, and watches the team until they finish, or Cut Free back in on the next floor (DOORS'
rule: death ends your run unless you revive). Watching is Lethal Company's: the dead crew watch
the living from behind them.

Who's left. As the car leaves with someone aboard (a player, or in Studio a stand-in friend),
everyone else whose feet are on that floor, in the halls or kept in a unit, however far from the
car, is marked (`Left.Attribute`, the server time the car left). `Elevators.departed`'s `left`
only names those within the clock's 240 studs, so Climbs checks the whole floor itself. A ride
that comes back after all (the next floor late, the takeover refused) un-marks them. The car
leaving empty, or from the top, leaves nobody behind: it comes back (L-08d's to end).

The sting, on their screen, timed off the ride's clock: "Left behind" slams up in a cold red with
the gate's clang (it was GateClock's headline; one place owns the moment now), the screen dims
behind it and its top and bottom darken over the HUD like a cutscene's bars; the car's lamp draws
away up the shaft (ElevatorView, unchanged) while its motor groans and fades above, muffled by
the building; as the light goes (1.6 s) a low hit lands with a jolt and the controls go, the play
HUD with them; the black comes down whole by 5.5 s, before the floor is cleared under you at 6.1
s; the bell rings far above under the black at 9.75 s; the black lifts on a friend's shoulder as
their car levels, and the gate folds open on the new floor without you (10.3 s).

Watching. At the hand-off your character is taken away (`Player.Character = nil`, destroyed; no
respawn follows) after what you carried drops with the floor, so nothing can hurt, see or prompt
you and the play HUD has nothing to show. Not parking the body somewhere: every system would
have to learn to skip it, and a parked body still streams, shows on maps and can be reached. The
server streams the world around the friend you watch (`ReplicationFocus`), and names them in a
`Watching` ObjectValue (nil on your screen until they stream in; the name rides as an attribute so
it shows at once). The camera is the game's own: behind the friend's head and over their right
shoulder, looking a little down, its spot and heading eased toward theirs at any frame rate (so
steps and network jitter never shake it), pulled in short of any wall behind them at once and
easing back out, a cut when they jump more than 25 studs (the move into the next car); drag, the
right mouse button or the right stick swings it round them. Not Roblox's own camera on their
humanoid: the place is locked to first person, and that would put you inside their head. While
you watch, every car is drawn as its riders see it (the lamp the ride's, not drawing away), so
the friend's car is lit as you arrive on it. The bar at the bottom (in the phone's safe area, big
round arrows) says who, how you get back in ("Back in when they finish"), and switches with a
tick, a dip to black, and a lift once the next friend has streamed in (0.08 s for the server's
answer in Studio). The server checks each watcher four times a second: a friend gone, left or
respawned is followed to the next.

Back in. Cut Free is a developer product in the GDD (40 to 55 Robux, DOORS' revive). The product
doesn't exist yet and there are no saved profiles to grant it after, so only Studio takes the ask
(a "Cut Free" button over the bar); `OWNER.md` has the product and price to decide. A let-in
waits for a floor to stand on (not between two floors mid-ride), loads a new character in the
lobby in front of the car facing the hall (`Climbs.Arrival`, where "Walk a floor" put you), and
the black lifts on it with the film's rip and "Back in" in the lamp's warm light. With nobody
left climbing to watch for 3 s, everyone watching is let back in the same way: a stand-in until
L-08d ends the climb.

Verified in Studio (seed 7, two stand-in friends in the car, the player left in the lobby): three
rides (1 to 2 twice, 2 to 3), held frames and real time; the sting's log matched its timeline (hit
at 1.64 s, character gone on the move frame at 6.1 to 6.6 s, camera on the friend at 9.12, clear
at 10.18, bell 9.79 to 12.59); the camera moved at most 0.003 studs a frame on a still friend;
switching, Cut Free into floor 2's lobby, a friend removed (followed to the other) and both
removed (let back in after 3 s) all worked; Output clean but the known asset line. Captures:
`docs/art/L-08c-*.jpg`.

Not chosen: the default camera on the friend's humanoid (first person inside their head); parking
the body under the floor (every system would need to skip it); fading to the friend at the move
(6.1 s: their car would stand shut and still for 4 s); a free Cut Free in live games before the
product and profiles exist.

## D-106 The climb ends: a wipe, the top, one screen and "Again" (L-08d, Nov 11)

The GDD's "Whole team kept": the climb ends. Gate 1 is friends asking for another run, so the end
is one screen saying how far you got and one button, "Again", as DOORS' Play Again does.

When it ends. **Kept** (a loss): nobody left climbing, every player kept in a unit or left behind
watching (`ClimbEnd.over`; in Studio a stand-in friend counts as climbing, so the L-08c recipe
still works). The server looks ten times a second and ends it `Caught.Dark` (0.96 s) after it
first sees nobody climbing, so the end lands on the last catch's cut to black. A watcher's Cut
Free can't save a wipe: with nobody left to watch, there's nothing to cut back into (`OWNER.md`).
**Top** (an escape): the car leaving the top floor with friends aboard (`Climbs.topped`). The top
is a stand-in, floor 3 (`Climb.Top`; `Climb.Building` stays 10), so a run is short enough to play
again; Phase 2's top floor replaces it. Everyone left on the floor is left behind as at any floor
and loses their character on the cable's second knock, as at a hand-off. The empty car still
comes back; the "Alone" let-in of D-105 is gone (the end replaces it).

On every screen, from one server time (`ClimbEnd` on Workspace, each player's `ClimbFate` written
first): a wipe's black comes down over 1.2 s (no later than the caught friend's eyes would open in
the unit); at 1.3 s the server clears the climb (`Climbs:finish`: threads, the tools lying on its
floors, the floors; `Watching:release`; every character taken away, so nothing reaches anyone
behind the screen) and every screen goes quiet: the listener is taken far away, as the catch
silences the hall, and held there each frame (the catch's wake would put it back); a beat of
nothing; two doors come down far off in the building (the roll-up door's bang and thump, pitched
low, the top end cut, a long reverb tail); "Kept" slams down in the cold red of "Left behind" from
1.28 times its size with the dread hit and a jolt; the photos drop in one by one, greyed and
pinned askew, each with the floor it was lost on; "Floor 2 · 6:42"; then the warm "Again". An
escape plays the ride untouched until the cable's second knock (where any other ride hands over),
then light floods in, slow and then all at once, whole by 7.4 s, when the climb is cleared and the
motor goes with it; the bell rings clear in the white; it settles into a warm dark and "Made it"
rises in the lamp's light, the riders' photos in colour. The photos are the GDD's Missing board in
small (avatar headshots, preloaded as the end starts); the board itself is the lobby's.

"Again": a press beeps, squashes the button and reads "Waiting"; each friend who is in warms
their photo back to colour with a tick on every screen; the first press starts "Going up in 10"
everywhere, and the next climb starts when everyone's in or the count runs out, so one friend who
wandered off never holds the rest (as DOORS' lobby elevators start counting down once the first
player steps in).
It goes with the elevator's chime and "Going up": a fresh seed, floor 1 laid at the last climb's
spot, everyone's new character side by side at `Climbs.Arrival` (the middle first, then either
side, 3 studs apart), then the end is cleared; each screen lifts the black off its new character
with the bell and "Floor 1". Where it leads is one function (`ClimbEnds.go`), for the owner's
lobby to replace. Enter, Space and a gamepad's A press it too.

The screen is two ScreenGuis over everything (50 and 51): the backdrop with no insets, the words
and button in the phone's safe area. It draws nothing (and sinks no touch) until the end shows
something, so a rider's controls answer through the ride. The title is sized from the screen's
height (never past 96 px), not scaled to its box: scaled text stops at 100 px, so the slam's
UIScale couldn't grow it on a big screen.

Verified in Studio (one player, seed 7): a real catch by 157's Mannequin ended the climb (Kept,
floor 1, 0:26), the character went under the black, the screen held its frames on the Client's
`DevRideHold`; "Again" by mouse and by Enter each laid a fresh floor 1 and lifted onto it with the
character at the arrival spot; floor 3 punched and ridden alone ended in the white (6.1 to 7.4 s
logged), "Made it", 1:30; left behind watching two stand-ins who were then removed ended as Kept
with the team on floor 2 and your photo on floor 1, the watch let go under the black with no
"Back in"; after each Again, prompts, camera, field of view, walk and sound all back; a saw
carried into the lobby dropped at the end and went with the floor (the new floor 1 had none);
Output clean but the known asset lines. Captures: `docs/art/L-08d-*.jpg`.

Not chosen: ending the climb when the car leaves empty (nobody chose to leave anyone); a vote
with no count (one absent friend holds everyone); keeping the floors until Again (keepers, the
padlock's dread and the ride would sound behind the results); the results over the world (a
character left standing there can still be caught); a fixed seed for Again (each climb a new
building, as DOORS' rooms are).

## D-107 Keepers hear the rest: every loud thing, a shut door muffles, a new sound stops it (L-15, Nov 11)
The moment: you punch the keypad, drop a tool, saw, crawl, put up the ladder or drop into a unit,
and somewhere down the hall the limp you were hearing stops dead on one deep thunk, and then comes
your way, as Lethal Company's Eyeless Dogs stop and turn to a noise before they come. Noise is a
choice with a price.
**What's heard, as far as players hear it** (one world, D-069): the keypad's beep and clear (30),
its chime (60) and a wrong code's alarm (400, every hall on the floor) from `Elevators.acted`; a
dropped tool's clank as it lands (`Carry.DropHeard` 40, the reach its sound already had; `Slots`
now fires `landed`); the saw starting (200) and its panel falling (a wall's 110, a top's 200) from
`Saws.sawing`; a crawl through a hole (35) from `Crawls.crawled`; and from `Ladders.climbed` the
ladder going up (60), climbing it (30), a crawl along the tops (30, every other pull), a drop off
a top or into a unit (45). `Keepers` listens to each signal, as it does `Doors.acted`, and calls
its one hearing (`hearAt`, `Keeper.heardAt`). A wall's hole is heard from the side it's sawn or
crawled from, a stud into that unit. Nothing is ever knocked flat yet, so that noise waits.
**Where it's heard from** (`Keeper.heardFrom`, Lune-tested): a sound in a hall, in a unit whose
door is all the way up, or in the unit the keeper stands in is where it is, as before. One up on
a unit's top (more than `Keeper.OnTop`, 8.5, over its floor) carries out over its front: heard
from that unit's door, its reach less the way to the door. One in a unit whose door is down gets
out through the door the same way at half its reach (`Keeper.Muffled`), as Lethal Company halves
noise made inside the shut ship; the keeper comes to stand outside the door and look at it, and
can't get in. Before, no sound got through a shut door (D-069, D-087), which made the saw, the
crawl and the drop-in silent wherever the door was pulled down: pulling a door down now buys
quiet, not silence. A keeper inside a shut unit still hears nothing from outside (a sleeper stays
asleep), and a horn blown on the tops is now heard from the hall, not the unit under you.
**The reaction** (`Keeper.hear`): a sound new to a keeper (not within `Keeper.Same`, 12 studs, of
the one it's already going to or looking at) stops it where it stands for its row's `startle`
(the Mannequin's 0.8 s, about two missing steps of its limp), turned to face the sound, then it
walks there at its looking pace. The same noise going on (a code's presses, a crawl's pulls, the
blows on a door) turns it toward the newest spot without stopping it again. The server stamps the
moment on the body (`KeeperTell.HeardAttribute`) and every screen plays its new Heard beat as it
shows the stop (`KeeperMotion.Delay` behind): the hollow Shell thunk at 1.7 and pitch 0.78, its
Weight, and its Creak at 1.4 groaning round. Far off only the thunk carries (to 70); within 32
you hear the groan too. Verified in Studio: the full chord at 30 studs, the lone thunk at 67.
**Output** says only news: "heard a wrong code's alarm 69 studs off along the halls; it wakes,
turns to it and goes to look", never once a pull. A trapped keeper prints one line as it's shut
in ("bangs on the door until it bursts out at 90 s") and none a blow; the padlock's last blow and
the burst still print. A crawler's feet, as the pops read them, are on what they lie on
(`Wrap.feetBelow`): from a tall avatar's hips they'd have read past `Wrap.Under`.
Not chosen: a faster walk when going to a sound (it would shrink D-069's seven seconds to get
behind a door; the stop says "it heard" without taking your time); silencing sounds behind shut
doors (the ticket's crawl and drop-in would never be heard); a voice (a mannequin has none).

## D-108 In hand and caught: the fix pass before friends play (L-16a, Nov 11)

The moment: the bugs a friend would hit in their first run with you. Each fixed at its cause.
**A friend's torch arm now rises.** The players' shoulders, elbows and wrists here are Roblox's
newer avatar joints (`AnimationConstraint`), not `Motor6D`s; FlashlightView looked only for
`Motor6D`s, found nothing, and never raised a friend's arm. Five views had their own copy of the
lookup, so one new client module, `Joints` (`find`, `get`, `set`, `bend`), now finds and turns
either kind for all of them (FlashlightView, HornView, CrawlView, LadderView, KneelView). Checked
in Studio on your own body: all three right-arm joints are AnimationConstraints, and the raise
lifts the hand from 0.95 below the root to 0.86 above it. A friend's arm needs two players.
**Caught mid-crawl or on the ladder, you're let go at once.** Before, nothing ended a crawl or a
climb at a catch: the server's Ladders lifted a caught climber onto the tops when the climb's
time ran out, then put them back there every check while KeptPlayers held them in their unit;
Crawls put a caught crawler through the hole; and the caught screen kept PlatformStand and moved
an anchored body the server no longer listened to. Now a kept player's climb or crawl ends on the
server that step (`Prompts.wrapped`), and their screen lets go of their body the moment `Kept`
goes on (LadderView, CrawlView: standing again, their own collision), never taking it over while
kept. The crawl's scripted camera is left to the catch, which takes it that frame (CaughtLunge)
and hands back your own camera at the black, not the crawl's. Verified in Studio both ways,
through a new Studio-only `ServerStorage.CatchTest` (the standing keeper nearest you catches you
through the real catch): caught 9.6 up the ladder and 1.3 s into a crawl, woken in a unit, then
cut free by a stand-in and walking 7.2 studs in 0.6 s.
**G at an open door is Slam.** G was both a door's Slam (a ProximityPrompt key) and the tool's
Drop (ContextActionService), so at an open door it did both. The slam is the moment, so while a
button in the world that takes the same key is up, ToolView's Drop passes the key to it and the
tool stays in your hand; anywhere else G drops as before. Verified in Studio: G at 102's open
door slammed it with the horn still held; G with the door shut dropped the horn. Not chosen:
moving Drop to another key (G is where Lethal Company players reach for it, and the slots' bar
says G).
**A click on a button on screen is never a use.** HornView's use (every verb tool's) took any
left click, so clicking a slot, Drop or its own button blew the horn or laid wrap (and its own
button used it twice). It now asks what's under the click (`PlayerGui:GetGuiObjectsAtPosition`,
which takes a click's `InputObject.Position` as is and skips hidden screens): on an active
button, the click is the button's. Verified: a click on slot 1 with the horn held blew nothing,
one out in the world blew it.
**Every recording is primed.** DoorSounds preloaded its sounds but never gave them the silent
first play (`SoundPrimer`, docs/STUDIO.md), so the first slam's bang could land a third of a
second late; the motion lights' click, a unit light's click and hum, and a peek's rustle had the
same gap. All four now prime at start. Tonight's Studio started even never-primed recordings on
time, so the late start wasn't seen again; the owner's ear on the first slam is the check.
**Output at Play.** KeeperView gave up for good on a keeper body it got before all of it had
arrived ("can't move ... Mannequin": seen once as the guard in 157 stood), leaving that keeper
frozen on that screen. It now waits for the rest (its row, its root, its joints) and binds then,
warning only for a keeper it doesn't know; and the server finishes a body (streamed whole,
its row, its first motion, its tag) before it goes into the world. The race didn't come back in
Studio either way, so this is belt and braces. `ContentId 203785492 ... Asset type does not
match` is Roblox's "Pop Close Sound", requested as something else by Studio or a plugin: it is in
neither the place (about 18,000 instances searched, Roblox's own interface included), the repo
nor Brix, and nothing the game does can silence it. 120448020095820 ("content representation is
being generated") is the kept wrap's colour map in the place, still being processed after its
upload; it didn't show in tonight's Plays.

## D-109 The test hall runs on live servers until the lobby exists (Nov 11)

The owner published the place to play it on a phone and got only the baseplate. Nothing was
missing from the upload: the code and the imported art were all in the place. The test hall
(`DevCorridor`) ran only when `RunService:IsStudio()`, and its "Walk a floor" post is the only
thing that starts a climb (the "Again" after a climb's end restarts one, but only once one has
run). So a live server, or a Team Test, built no hall, laid no floor and kept Roblox's baseplate
and spawn pad. It now runs on every server, so a published place plays exactly as Studio's Play
does: the hall, its test posts, "Walk a floor", the climb. The Studio-only test tools stay
Studio-only (stand-ins, `CatchTest`, the ride hold, `DevFloorSeed` and `DevFloorNumber`, which
no live player can set), so a live climb starts on seed 7, floor 3. Its posts (teleports, a
Mannequin on demand) and the floor's code in the server log are fine for a private test place
and wrong for a public game: the lobby (L-08e) replaces the hall as the way in on live servers,
and the hall goes back to Studio only, before the game goes public. Not chosen: a bare live start
that lays floor 1 and drops players in its lobby, which is the lobby's design (L-08e) built
early, and would differ from what the owner tests in Studio.
