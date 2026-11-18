# Packs: the packaging a sealed find still sits in

Now and then a find comes out of its box still sealed in the packaging it was sold in, worth
three times the loose one (ROADMAP S5-02b, D-423). One pack is shared by every find of a size,
and the game fits it round the find it holds. Built with the finds kit (`../CRAFT.md`):
`scripts/art.sh set packs [textures|export|renders|quick] [Blister|WindowBox|Carton]`. Every
number is in `spec.py`.

## The three

- **Blister** (Small finds): the card a toy car or a rubber duck hangs on in a shop. Printed
  board, a hang slot cut through its header, a clear bubble sealed to its front by a flat
  flange. Its print: warm yellow, a paler glow behind the bubble, a red header with a white
  burst, a red foot, a white keyline round the edge; the back plain board with a red strip and
  a block of bars. A real card for a 3 in toy runs about 5 by 8 in, the bubble 4 in proud.
- **WindowBox** (Medium finds): the printed carton a wind-up toy stood in on a shelf. A window
  cut in its front with clear film behind, a yellow keyline framing it, a printed backdrop
  inside (pale, orange rays rising behind the find), a hang tab standing up off the top. About
  9 by 9 by 13.5 in for a 10 in toy.
- **Carton** (Large finds): a brown corrugated carton, its top flaps meeting in the middle,
  taped along the seam and down both ends, a window cut in its front (the flutes showing at the
  cut edge), a hand hole in each end. One bold red on a pale band, as cheap retail cartons are
  printed.

No maker's name, no words, no copied print (catalog rule). Their tells from a doorway: the
blister's bright card standing up behind its bubble, the window box's red and yellow frame
round the find, the carton's brown board and tape.

## How the game fits a pack round a find

Each pack has a room for a find (`spec.py`'s `cavity`). To hold a find, the pack scales on each
axis to what the find needs with `pad` round it, and no axis less than the largest over
`stretch` (`fit`), so the blister's print never squashes much (1.15) while the carton's brown
board takes more (1.8). The find sits in the middle of the scaled room. `export` writes these
numbers as `src/shared/Finds/PackFit.luau` for the game (S5-02b2 mirrors `fit` in Luau).

## Parts

Each pack is two parts: the board (`Card`, `Box`, `Carton`, the root) and the clear plastic
(`Bubble`, `Film`), see-through in AlphaMode Transparency at about 0.17 (CRAFT.md: under 0.15 it
vanishes), a diagonal glare across it so it reads as plastic at phone size. No motions, no
lights, no game rows: the packs are never dealt on their own.

## The sheets

`blender -b --factory-startup -P art/finds/packs/build.py -- --stage sheets` renders each pack
fitted round a real find from the windups set (the rubber duck, the cymbal monkey, the singing
fish): `art/sheets/packs-studio.png`, `packs-held.png` (on a phone, in your hands, under a
unit's bulb) and `packs-unit.png` (on a unit's floor from its doorway, on a phone).

## Owed

- A photo pass: the packs were built from how these packagings are made (blister cards with a
  hang slot, tuck-top window cartons with a hang tab, regular slotted cartons H-taped), not from
  photos opened this session.
