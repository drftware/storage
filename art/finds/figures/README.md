# Figures and models

The catalog's "Figures and models" set, built with the finds kit (`art/finds/CRAFT.md`).
`scripts/art.sh set figures [textures|export|renders|quick] [RCCar]`. The generated Luau is
`src/shared/Finds/Sets/Figures.luau`. Two cars were pulled forward from wave 4 (F-03); the set's
other twelve finds join this folder later.

**In the place** (F-S1, Nov 15): every find here is a template in
`ReplicatedStorage.Props.Finds.<Find>`, made by `Finds/Kit.luau`'s `import` from the
uploaded FBX (CRAFT.md, "Into Studio"); the place keeps them once the owner saves it.

## Remote-control car (Rare): "Drive (at home): round your unit and out into the hall of units"

A 1/10 two-wheel-drive off-road buggy of the 1990s, the 27 MHz kind a kid saved up for, with
its pistol-grip transmitter standing beside it (real ones are kept together; D-193).

**Looked at:** Wikimedia Commons, "Takaveto-sähkökrossari.JPG" (a 1/10 2WD buggy side on: cab-
forward lexan shell, ribbed fronts and pin rears on yellow dish wheels, gold shocks, a high rear
wing, the aerial wire); Commons, "Category:Radio controlled model car controllers", the photos
"Volantový vysílač Tactic.jpg" (a pistol grip: wheel on the right, trigger, carry loop, battery
foot) and "Sender car.jpg" (an older one with a chrome telescopic aerial and a rubber-tyred
wheel); Team Associated's spec pages (RB10, RC10 Classic: 381-400 long, 227-248 wide, 268-278
wheelbase) and Tamiya's Astute page (tyres 79 by 27 front, 82 by 41 rear). No maker's name or
another company's body: the shell, its livery and the number 7 are our own.

**Size:** the car 390 mm long, 242 wide, 272 wheelbase (1.07 studs), tracks 196 and 200, tyres
80 and 84 across (radii 0.157 and 0.165 studs), the aerial's red cap 1.18 studs up. The
transmitter 200 to the top of its head, 0.79 studs, its aerial 0.75 more, collapsed. The whole
find is 1.5 studs long, under a person's knee, as a real 1/10 car is.

**Tells:** the fat pin tyres on yellow wheels, the tall aerial with its red cap, the red wing.
From a unit's doorway it reads as a small bright car; it's real size, so it's small.

**Parts** (each `RCCar_<Part>`): `Remote` (the root: transmitter case, foot, collapsed chrome
aerial, the orange frequency flag), `RemoteWheel` (turns on its axle: + steers left), `Trigger`
(+ pulls the throttle, - pushes the brake), `Arms` (the lower arms, hubs and links: what travels
over the floor, its pivot midway between the axles on the floor), `Chassis` (on the springs:
tub, towers, gearbox, motor, gold shocks with blue springs, battery and radio; it pitches and
rolls about a point 55 mm up), `Shell` (lexan body and wing), `Aerial` and `AerialTip` (the
tube in two lengths, each pitching and rolling, so it whips), `SteerL` and `SteerR` (knuckles
turning on kingpins that lean back 10 degrees), `WheelFL`, `WheelFR` (on the knuckles) and
`WheelRL`, `WheelRR` (with their dogbones), each turning about its axle (+ rolls forward).
Left is the car's own left (+X in Blender).

**Driving it is wiring** (`Drive` in the Luau, `RC_DRIVE` in spec.py): wheel radii, wheelbase,
track, steering lock 26 degrees (Ackermann: the inner wheel more), suspension travel 24 mm, a
suggested top speed of 20 studs a second (a touch faster than a player runs, so friends chase it
down the hall and can't quite catch it), acceleration, braking, and how far it leans and squats.

**Motions,** from a small driving simulation in `build.py` (`drive()`): every wheel turns by the
distance its own tyre rolls over its radius (inner wheels slower in a turn), the chassis leans on
a damped spring, the aerial's lower length swings and its tip lags and whips.
- `Launch` (1.4 s): the trigger squeezed, the rear tyres spin up a little ahead of the ground,
  the nose lifts and the aerial is flung back, then shivers; it leaves the transmitter behind.
- `Drive` (2.6 s): part throttle into a right-hand corner and out: the wheel turned, the front
  wheels steer, the body leans out and the aerial swings wide.
- `Stop` (1.4 s): rolling in past the transmitter, onto the brake: the nose dives and bobs back
  as it stops where it was found, the aerial whips forward and settles.

**Look:** glossy white lexan, a red nose fading through orange, dark smoke windows, a dark sill,
a blue pinstripe and a 7 in a roundel each side; red wing with an orange band; black nylon, a
graphite towers, a silver can motor with a blue end bell; dried back-yard mud low down and in
the treads, dust on top. Texture 1024, 172 texels a stud; 18,000 triangles in 14 parts.

**Not in Studio yet** (F-S1).

## Die-cast car (Common): "Push: it rolls off down the hall"

A pocket-size metal toy car of the late 1960s (F-03b, D-200): our own two-door saloon, a zinc
body in metallic blue, a bright zinc base riveted under it that makes the bumpers and grille,
and black plastic wheels with silver hubs on crimped steel axles.

**Looked at:** Wikimedia Commons, "Matchbox No. 25 1960s Ford Cortina.jpg" (a 1968 regular-
wheels car: metallic paint over soft cast edges, a clear window insert with a pale interior,
the bright base wrapping up into the grille and bumpers, small black wheels with silver hubs),
the Mercedes saloon from the same photographer's series (metallic blue) and a play-worn van
from the same search (paint chipped to the zinc on every edge); collectors' notes on how the
bases were riveted on and the axles crimped (Lesney from 1958), and on sizes (2 to 3 inches;
Tootsietoys 78 to 84 mm). Its real size: 76 mm nose to tail, 30 wide, 21 tall, wheels 9.6
across on a 44 wheelbase: 0.31 studs long. No real maker's or carmaker's design or badge: the
body, its grille and the base's raised lettering are our own.

**Tells:** the metallic paint's shine, the dark glass with pale seats behind it, the silver
bumpers and grille, four wheels. From a doorway it's a speck (a small find), held it's a toy car.

**Built:** `dc_*` in `build.py`, numbers `DC` and `DC_PUSH` in `spec.py`. The body is one loft
of cross sections worked out along the car (`dc_half`: sills, belt crease, shoulder, the
greenhouse standing up the windscreen and down the back window), its arches cut by raising the
section's foot round each axle, the nose and tail turned under in a 1 mm round. Windows, shut
lines, door handles, lamps and the grille's slots are painted and pressed in by the look; chips
to bare zinc on the edges. No dust: on glossy metallic paint any film read as blotches. Texture
1024 at 1,783 texels a stud; 5,700 triangles in five parts.

**Parts:** `Body` (root, pivot on the floor midway between the axles) and `WheelFL`, `WheelFR`,
`WheelRL`, `WheelRR`, each turning on its axle (X).

**Push:** a shove from the hand (0.12 s) sends it off at 4 studs a second; it slows on rolling
drag (1.1 studs a second each second) and stops about 7 studs away, 3.8 s later. The same
small simulation as the RC car's (`dc_push`, keys by `rdp`): each wheel turns by the distance its
own tyre rolls, the heading wanders 3 degrees a second on the loose axles, the body tips nose up
on the shove and drops back with a bounce, and rattles side to side on its axles, dying away as
it slows. The travel (x, y, yaw) is on the root: the game moves the model's pivot to play it.
Its filmstrip camera looks down from the front (`view`, `drop`).

**In the place** (Nov 15): uploaded and imported with `import("Figures", {"DiecastCar"})`; its
parts and pivots checked in Studio's Edit view.
