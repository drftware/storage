# Lights

The catalog's Lights (art/finds/WAVES.md), built with the finds kit (art/finds/CRAFT.md, "The
kit"). `scripts/art.sh set lights` rebuilds them; sheets in `art/sheets/desklamp-*.png`, motion
clips in `out/`.

## Desk lamp (Nov 15, F-01)

- **What it is:** a 1960s-70s spring-balanced desk lamp in oxblood enamel: a two-step round
  cast base on felt, a swivel and yoke, a lower arm of two flat bars with two closed-coil
  springs on pins behind, an upper arm of two plated rods, a bell shade (white enamel inside,
  browned near the bulb) with a push switch on top, a 60 W pearl bulb in a bakelite holder, and
  a braided cloth cord down the arms, off the base and across the floor to a plug. Chipped
  enamel on the edges, faded on top, rust freckles on the plating, dust on what faces up.
- **References** (looked at Nov 15): Wikimedia Commons, Category:Anglepoise lamps (the 1227 in
  cream with its springs and shade switch; the Anglepoise 90's three springs close up); the
  sizes from listings of vintage spring-balanced lamps (Chairish, 1stdibs, design-market:
  bases 13-20 cm, shades 12-20 cm, arms about 30 cm each). No maker's design copied: the base is
  round and stepped, the shade our own bell.
- **Size:** about 37 cm tall at rest, an 18 cm base, a 15 cm shade, arms of 30 and 29 cm: 1.45
  studs tall, 0.72 across the base, 0.6 across the shade (10 inches a stud). Rods a touch bolder
  than life so the arm reads on a phone.
- **Tells:** the bent arm and the bell shade; on, the warm pool under it.
- **Parts** (pivots on the real hinges, axis X): `DeskLamp_Base` (root, the base's middle on the
  floor), `_LowerArm` (shoulder), `_UpperArm` (elbow), `_Head` (wrist), `_Switch` (slides along
  the shade's axis), `_Bulb` (rides the head; carries the glow). 6,564 triangles; one 1024
  texture set at 319 texels a stud.
- **Light:** a Spot from the bulb's tip down the shade (2,700 K, Brightness 2.2, Range 10, 80
  degrees, shadows) and a weak Point fill under the rim (0.5, Range 5) for low graphics; the
  bulb's emissive mask at strength 3, tint (255, 196, 128).
- **Motions:** `SwitchOn` and `SwitchOff` (0.6 s): a thumb on the button: it goes in 0.018,
  clicks, springs back with a little overshoot; the shade nods 4 degrees under the push and
  settles; the arm sways after it; the filament flares warm at the click (on) or drops and fades
  orange (off).
- **Not in the place yet:** upload and insert in F-S1.
