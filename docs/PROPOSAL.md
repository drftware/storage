# Proposal: the loop and the store, with your answers

_Second version, Nov 13. The first version held 36 ideas. You answered every one, added a note
on the shop, and then answered four follow-up questions. This version is those answers written
in. Nothing here is built, and the design doc and the roadmap haven't been changed to match
yet._

## How to read this

Every idea keeps the number it had, so you can still answer by number. Under each heading there
is a line saying what you answered, and then how the idea stands now, written out in full.

Each idea carries one of these labels:

- **Agreed.** You said yes. It stands as it was, apart from anything noted.
- **Changed.** Your version replaces mine.
- **Cut.** It's out. The heading stays so the numbers don't move.
- **Open.** You asked me for ideas, or part of it still needs your answer. My suggestion is
  written out, and nothing in it is fixed until you say.
- **New.** It came out of your answers. There are three: 37, 38 and 39.

Where I had to pick a number or a small rule to make an idea complete, it says "my starting
guess" or "my default". They are all gathered in one list near the end, with the five things
that are still open.

Words I use:

- **Monsters.** The docs and the code call them keepers. You haven't picked a name, so I say
  monsters.
- **Caught.** When a monster gets you. On screen the game says "Kept".
- **Wrapped.** What you are after you're caught: in shrink-wrap, in a unit, until someone frees
  you.
- **Finds.** The items sitting in units: a lamp, a box of records.
- **Coins.** What you pick up and get paid during a climb. The first version called them
  quarters. You call them coins, so I do now.
- **Cash.** The money you keep between climbs. The design doc has it; the game doesn't yet.
- **Robux.** Real money.
- **Slots.** The places that hold what you carry. The game has three today and they hold tools.
  The first version said two; that was wrong.
- **The machine.** The vending machine in the elevator.
- **The corner map.** The small map of the floor in the corner of the screen.
- **The counter.** The shop desk in the lobby.

## What your answers changed most

1. **The building isn't a character.** It doesn't watch you, send monsters or come for you. The
   monsters do things to the floor, each in its own way, and the players have to go and deal
   with it before they can get back to searching. The first of these is yours: a Mannequin can
   switch off the floor's breaker (idea 7).
2. **The climb has no top.** No roof, no last floor, no Dale. Floors are made by rules up to
   about floor 100 for launch, each harder than the last, and the number to beat is your best
   floor (idea 20).
3. **You keep what you carry.** A find goes in one of your own slots, beside your tools. When
   the gate shuts it becomes yours for good and the slot is free again. Everyone aboard is paid
   coins for the floor. Nobody gets a copy of anyone else's find (ideas 13 to 15).
4. **Caught means caught.** You stay wrapped until a friend frees you or you pay. You are
   carried up floor after floor in the meantime, earning nothing (ideas 17 and 18).
5. **Not every unit pays, and doors don't give themselves away.** Most units have coins and
   some have nothing to take. A padlocked door is the one promise of something good. Every
   other door is "no idea", because having to open them, and what that lets out, is the game
   (ideas 1, 4 and 5).
6. **Players learn by playing.** No text that explains a rule (idea 16). I've applied that to
   everything else in here too.

---

## Part 1: Opening doors

**How it works today.** A floor has about 60 storage units on floors 1 and 2, and about 80 on
the floors above. Opening a door takes two seconds and makes a loud rattle that monsters can
hear. The game decides what's inside at the moment the door opens. Out of every 100 doors, 40
have nothing in them, 25 have a find, 20 have a tool, 10 have a sleeping monster and 5 have a
monster that's awake. The notes with the code's digits are different: they are put in
particular units when the floor is built. Finds can't be picked up.

### 1. Coins in most units, not all of them (Changed)

**Your answer.** Most, not every one. A couple of units with no coins is fine, or with props you
can't pick up. If every unit has coins they lose their value. DOORS has gold in most drawers,
not all of them.

**How it stands now.**

1. About seven units in every ten have one to three coins lying on the floor. Seven in ten is
   my starting guess.
2. You tap the coins to pick them up, and a small count on your screen goes up.
3. A unit with coins can still hold a find, a tool, a note or a monster as well, as now.
4. The other three in ten have nothing to take. Some are bare. Some are full of things that
   are only there to look at: stacked boxes, a mattress, a rolled-up carpet.
5. You said those units could get "other crazy ideas" later. Nothing is planned for them yet.

**Where the idea comes from.** DOORS, where gold sits in drawers. That is from memory; I
couldn't find a page that says how many drawers have it.

### 2. Coins are spent during the climb, and what's left becomes cash (Agreed; tools are Open)

**Your answer.** Good. But do tools still go in units, or less often? If tools are everywhere
they stop being something you're glad to get. Stocking back up should feel good. Maybe tools
should break, since right now they don't.

**How it stands now.**

1. Coins only exist inside one climb. Each player has their own.
2. You spend them at the machine in the elevator, which sells tools (idea 22).
3. Any coins you still have when the climb ends are turned into cash, which is the money you
   keep (Part 6).
4. Coins are never sold for Robux. The design doc already says this of its quarters.

**My suggestion on tools (Open).** You asked, so here is what I would do. Say yes, no, or
change the numbers.

1. **Tools turn up in units less often.** Today one unit in five has a tool. I'd make it about
   one in twelve. Finding one becomes a good moment, and the machine becomes the place you can
   count on.
2. **Tools wear out.** Each tool works a set number of times and then it's gone. My starting
   guesses:
   - Bolt cutters cut three padlocks.
   - The saw cuts two holes.
   - The air horn has three blasts.
   - The bubble wrap already works this way: it pops three times and is spent.
   - A padlock is used up when you lock a door with it, as now.
   - The ladder stays as it is for now.
3. **You can see how much is left.** A small mark on the tool's slot shows the uses it has
   left, so running out is never a surprise.
4. **The flashlight doesn't change.** Everyone has one and it never runs out. It is the only
   thing that stops a Mannequin, and a flashlight that dies is a bigger change than you asked
   for.

**Where the idea comes from.** DOORS: its flashlight runs down, and you find batteries in
drawers to keep it going. Lethal Company: a can of spray paint runs dry and can't be refilled.
Both checked.

### 3. About half as many units on each floor (Agreed)

**Your answer.** Fine. But remember not every unit should pay. A unit doesn't have to be empty:
it can have props, or other ideas later.

**How it stands now.** About 30 units on floors 1 and 2 instead of 60, and about 40 on the
floors above instead of 80. The halls stay as long as they are, with stretches of blank wall
where the removed units were, so there is still room to be chased. Fewer units is also less for
a phone to draw. 30 and 40 are my starting guesses.

### 4. Two kinds of door (Changed)

**Your answer.** No tags. There's no story in place that says you won an auction, and the story
isn't worked out yet. The padlocks are the difference between doors. Two kinds, not three: a
padlocked door is "definitely something good in here, but you need cutters", with the best odds
of something great and of monsters; every other door is "no idea what's in here". No common,
medium and rare doors.

**How it stands now.**

- **A padlocked door** needs bolt cutters. It always has something good behind it. It also has
  the best chance of something great, and the highest chance of a monster.
- **Every other door** looks the same as the next one. It might have coins, a find, a tool, a
  note, a monster, or nothing to take.

The tagged door from the first version is gone.

**Where the idea comes from.** Escape from Tarkov has locked "marked rooms" that every player
knows hold its best loot. From memory.

### 5. At most one faint mark, and nothing on the map (Changed)

**Your answer.** Meh. At most one door gets a faint mark, not the others, and no map. Having to
open every door is the point: every door you open may let a monster out, and the floor gets
harder the more doors are open. Hints work against that.

**How it stands now.**

1. On a floor, at most one of the notes has a faint mark on its door frame. You can only see it
   from a few steps away, with your flashlight on it.
2. The other notes have no mark. Some floors have no mark at all.
3. The corner map shows nothing about notes.

The first version called it Dale's pencil mark. It is just a mark now (idea 20).

Your other thought, a marker players can use to tag doors themselves, is idea 38.

### 6. A timing tap when you shut the door on a sleeping monster (Changed)

**Your answer.** Skip it on every door; that would be annoying. Use it only when you've opened
a door on a monster that is asleep or hasn't noticed you. When you close that door the tap
comes up by itself. Do it perfectly and the monster is more likely to stay asleep. Miss and it
wakes up and starts pounding on the door.

**How it stands now, in order.**

1. You open a door. There is a monster inside, asleep, or awake but not looking your way.
2. You pull the door back down. As it comes down, a small bar appears on screen with a marker
   moving across it. You don't press anything to ask for it.
3. If you tap while the marker is inside the highlighted part of the bar, the door settles
   quietly, and the monster is much more likely to stay as it was.
4. If you miss, the door bangs. The monster wakes and starts pounding on the door from inside.
5. My default: not tapping at all counts as a miss.
6. My default: a monster pounding on a door breaks out after 90 seconds unless someone
   padlocks that door. That is what a trapped monster already does today.

**Where the idea comes from.** Dead by Daylight: a timing tap comes up on its own while you
repair a generator, and missing it makes a bang the killer hears. From memory. Dandy's World
has timing taps on its machines; checked.

### What we'd sell in Part 1

Nothing. This part is what gives coins and cash a reason to exist, and everything sold later
depends on players wanting them.

One thing has to be built alongside it that players won't see: saving (idea 31). Coins that
turn into cash need somewhere to be kept.

---

## Part 2: Monsters that mess with the floor

**How it works today.** The hall lights are motion lights. They come on when you move under
them and go out a few seconds after you stop. The only monster in the game is the Mannequin,
which can only move while no light is on it. Your flashlight never runs out. Put those together
and a player who keeps moving, or keeps a flashlight on the Mannequin, is safe.

The design doc says each light that comes on tells the building where you are, and the building
sends a monster to look. That isn't built.

**What you said about this whole part.** You don't want the building to be a character. "The
building is coming for you" makes no sense, and the building wouldn't send monsters. The
monsters are all different and respond to different things. What's needed is mechanics and
situations that show off what each one is good at, and force players to deal with it so they
can get back to searching. Your example: a breaker on each floor that a monster can switch off.

**What I've taken from that.** Two things.

First, the lights are just lights. Nothing is ever "sent" because a light came on. The design
doc's rule comes out.

Second, a pattern for every monster, which your breaker already follows. Each monster has:

1. **Something that stops it.** For the Mannequin, light.
2. **A way of going after that thing.** The Mannequin cuts the power.
3. **Something players have to go and do to put it right.** Find the breaker and switch it
   back on.

Ideas 8 and 12 use the same pattern for two more monsters. The pattern is my reading of your
answer, so say if it's wrong.

### 7. The Mannequin cuts the power (Changed)

**Your answer.** The "don't move" moment is okay, but a power cut, with every Mannequin free to
roam, is a lot more tense. Put a breaker somewhere on each floor. A monster can shut it off.
You have to find it and turn it back on, or the lights stay off. And you never know when it's
going to happen.

**How it stands now, in order.**

1. Every floor has a breaker box somewhere on it, in a different place each climb.
2. A Mannequin that is loose, with no light on it, doesn't always come for a player. Some of
   the time it heads for the breaker. Nothing tells the players when.
3. If it gets there, it throws the breaker. There is one heavy clunk that everyone on the
   floor hears, and every hall light goes out.
4. The lights stay out. Moving under them does nothing.
5. Every Mannequin that is loose can now walk anywhere a flashlight isn't pointing at it.
6. To get the lights back, somebody has to find the breaker and switch it on. Until someone
   does, the floor stays dark.
7. It can happen again on the same floor.

**What a player can do about it.** A Mannequin that is walking somewhere other than toward a
player is probably going for the breaker, and a flashlight on it stops it. So knowing where the
breaker is, and noticing where a Mannequin is heading, are things a good team gets better at.

**My defaults.**

- How keen a Mannequin is to go for the breaker is a number to tune, and it goes up with the
  floor number.
- Switching the breaker back on takes a one-second hold, the same as cutting a friend free.
- The elevator keeps its own light, so the team can always find its way back to the keypad.

**What this replaces.** The five-second "don't move" moment from the first version is gone.

**Where the idea comes from.** Phasmophobia: the ghost can switch off the house's breaker, and
the team has to go and switch it back on. Lethal Company: pulling the apparatus out of the wall
cuts every light in the building, and you're left with your flashlights. Both checked.

### 8. A monster you hide from (Open)

**Your answer.** Rethink it in the same vein as 7. There are good ideas to be found here, but
doing it on a timer is dumb. Like the power cut, you shouldn't know when it's coming, and
whatever it becomes has to be great and add suspense.

**What's gone.** The clock that winds up and strikes once or twice a floor.

**My suggestion.** Keep the rule from the first version, "be inside a unit with the door down",
and give it to a monster. This would be a third monster, after the one in idea 12.

1. It sleeps in a unit, like the others.
2. Noise wakes it: a door rattling up near its unit, the alarm from a wrong code, a wrapped
   friend banging on a door. There is no clock. The team's own noise decides when.
3. Once it's awake it doesn't pick a player to hunt. It runs the halls from one end to the
   other, faster than anyone can run.
4. You get a few seconds of warning. You hear it coming, and you see the hall lights come on
   one after another toward you with nobody under them.
5. It can't reach anyone who is inside a unit with the door pulled down. So you get into the
   nearest open unit, pull the door down, and listen to it go past.
6. **How it messes with the floor.** A shut door is what stops it, so it goes after the open
   ones. It pulls down every open door it runs past. After a run there are fewer places to
   duck into. Opening one again takes two loud seconds, and noise is what woke it.
7. **What players do about it.** Keep a unit open near wherever they're searching, and open
   another when it has been shut. It can be trapped like any other monster.

**Where the idea comes from.** Rush in DOORS: the lights flicker, you hide in a closet, and it
tears through the rooms. DOORS doesn't show a timer for it. From memory.

**Why it's open.** It's a sketch for a monster that would come third at the earliest. Say
whether it's worth keeping on the list, and what you'd change.

### 9. Stay too long and the sleeping monsters start to wake (Changed)

**Your answer.** Some version of this makes sense, but "closing time" is lame. Have monsters
wake up in their units after a certain amount of time: maybe three after so long, more after a
while longer, and more of them the higher the floor. The feeling of strolling around
disappears, because you start hearing pounding all over the level.

**How it stands now, in order.**

1. There is no announcement, no clock on screen and no name for it.
2. After the team has been on a floor for a while, three of the monsters still asleep in their
   units wake up. They pound on their doors from inside, and you hear it across the floor.
3. A while after that, more wake up.
4. On higher floors it starts sooner and wakes more at a time.
5. My default, the same as in idea 6: a monster pounding on a door breaks out after 90 seconds
   unless someone padlocks that door. So the pounding is a warning, and a padlock is the
   answer to it. That makes padlocks worth buying at the machine.

**My starting guesses for the numbers.** On floors 1 and 2 the first three wake after four
minutes. On the floors above, after six minutes, because those floors are bigger. Three more
wake every two minutes after that. Higher floors shorten those times.

**One thing this changes underneath.** Today the game decides what's in a unit at the moment
its door opens. For a monster to wake behind a closed door, the sleeping monsters have to be
put in their units when the floor is made. Idea 10 needs the same.

**Where the idea comes from.** Lethal Company: more monsters come out the later in the day it
gets. Checked.

### 10. A wrong code lets monsters out (Agreed, with your penalty added)

**Your answer.** Agreed. A wrong code should open some number of units with monsters in them:
maybe one the first time and three the next, so guessing is a penalty.

**How it works today.** A wrong code sounds an alarm for three and a half seconds and turns on
every light on the floor. Because the Mannequin can't move in light, that freezes it. So a
wrong code makes the team safer, and a team with three of the four digits can stand at the
keypad and try all ten numbers for the last one.

**How it stands now.**

1. The first wrong code on a floor: one closed unit with a monster in it rolls its door up by
   itself. That monster is awake and loose.
2. The second wrong code: three more units open the same way.
3. My default for the third and after: five each time.
4. The hall lights go out for the length of the alarm, instead of coming on.
5. Every loose monster heads for the keypad. The design doc already says this.
6. The keypad stays locked for longer each time on the same floor: 3.5 seconds after the first
   wrong code, 7 after the second, 14 after the third.

Guessing the last digit is still allowed. It is now a gamble.

**Where the idea comes from.** The library in DOORS: players are allowed to guess the last
digit of the code there, but they do it with a monster walking the room. From memory.

### 11. Keep one walking speed (Agreed)

**How it stands now.** Nothing changes in the game. The four ways to move (standing still,
crouch-walking, walking and sprinting) come out of the design doc. That is two fewer buttons
on a phone.

### 12. The second monster: silent, and it only moves in the light (Open)

**Your answer.** We definitely need another monster. The Mannequin freezes in light and tries
to cut the power. The next one doesn't have to be the opposite, just different. Maybe it makes
no sound when it moves but doesn't move in the dark, so you constantly have to look for it and
can avoid it by keeping your light off. But the ceiling lights kind of ruin that. You asked me
for ideas, or to improve on it.

**My suggestion: let the ceiling lights be how it gets around.** The lights come on when you
move, so you are the one lighting its way.

1. It makes no sound at all. No footsteps and no warning.
2. It can only move while it is standing in light: under a hall light that is on, or in a
   flashlight beam. In the dark it stops where it is.
3. The hall lights come on when you move under them and stay on for a few seconds behind you.
   So when you walk down a hall, you leave a lit stretch behind you, and it can walk along
   that stretch after you.
4. If you stand still, the lights above you go out after a few seconds. Switch your flashlight
   off as well, and it is standing in the dark and can't move.
5. It walks no faster than you do. So if you spot it while it is still some way behind you,
   stopping and going dark works. If it is already close, the lights won't go out in time, and
   the answer is a door: get into a unit and pull it down.
6. Because it's silent, the only way to know it's there is to look behind you.

**What it does with a Mannequin on the same floor.** Light stops the Mannequin and lets this
one walk. Dark stops this one and lets the Mannequin walk. With both loose, the team has to
keep choosing which one to give ground to.

**What it does in a power cut (idea 7).** Every hall light is dead, so this monster can only
move in a flashlight beam. You swing your flashlight down a hall to stop a Mannequin, and
something at the far end of the beam starts walking toward you. It only walks while your light
is on it.

**How it messes with the floor.** The dark is what stops it, so it goes after the dark. Any
hall light it walks under gets stuck on and stops going out by itself. The longer it's loose,
the more lit hall it has to move through without anyone moving.

**What players do about it.** Go to the breaker and switch it off and on again. That sets
every stuck light back to normal. For the moment the breaker is off, the floor is dark and the
Mannequins can walk. So this time it's the team choosing when to cut the power.

**The line planned for the thumbnail** is "Don't move. The lights are watching." With this
monster in the game, not moving is the thing that saves you, so the line would be true.

**Where the idea comes from.** Lethal Company has two monsters with opposite rules: one stops
while you look at it, and one comes for you if you look at it too long. Having both around is
harder than either alone. From memory. A monster that moves only in light is your idea, and I
don't know a hit game that has one, so it is on the untested list at the end.

**Why it's open.** You asked for ideas and this is one. It also needs a look, a name and a
reason to be alive, and those are yours.

### What we'd sell in Part 2

Nothing, now or later. These are the rules that decide whether you get caught. If Robux could
soften them, anyone who didn't pay would feel the game was rigged against them.

---

## Part 3: Getting to the elevator, and what you take with you

**How it works today.** When the right code goes into the keypad, the elevator gate opens and a
30-second countdown starts. At zero the gate shuts and the elevator leaves. Anyone not inside
is left behind. The moment that is meant to make this game is the last friend sprinting for the
gate.

In practice the keypad is right beside the elevator, so a careful team gathers there first and
then types the code. Nobody is far away when the countdown starts. And there is nothing to
carry out, because finds can't be taken. You have three slots, and they hold tools.

### 13. A find goes in one of your own slots (Changed)

**Your question.** Why does it go to the team? Is gold shared with the team in DOORS, as I
referenced?

**The answer.** No. In a normal DOORS run, gold belongs to whoever picks it up. Its shop has a
plate for handing your gold to another player, which would be pointless if gold were shared,
and its wiki names Daily Runs as the one mode where gold is shared. I named DOORS for picking
things up with one tap. The team pile was my own addition, and I shouldn't have put DOORS
beside it.

**How it stands now, from your answers to 13 and 14.**

1. You pick up a find with one tap, and it goes into one of your slots.
2. Tools and finds use the same slots. You have three today. Carrying three tools means you
   have no room for a find.
3. When your slots are full, you drop something or leave the find where it is. Idea 38, the
   marker, is for coming back to it.
4. More slots can be bought, up to six (the store in Part 5).

**Where the idea comes from.** Lethal Company: you have four slots, and the scrap you collect
and the tools you bring share them. From memory.

### 14. One big find on each floor, shown only once the code is in (Changed)

**Your answer to my question.** Keep it, but it's only shown after the code is entered, so
going for it is a risk.

**How it stands now, in order.**

1. From floor 2 up, each floor has one big find: a jukebox, say, or an arcade machine. It is
   worth several times what a small find is.
2. While the team is searching, nobody can see it or get to it.
3. When the right code goes in, the gate opens and the 30 seconds start. At that moment the
   big find is shown. My default: one unit somewhere on the floor rolls its door up by itself
   with a loud rattle, the big find is inside, and its place shows on the corner map so the
   team can see how far away it is.
4. To take it you pick it up in both hands. It doesn't use a slot. While you carry it you walk
   slower than any monster and you can't use a tool. You can put it down whenever you like.
5. It only counts if it is inside the elevator when the gate shuts. Whoever carried it in
   keeps it.

**What the player sees.** The code goes in and the countdown starts. Somewhere down a hall a
door rattles up, and a mark appears on the corner map. Somebody has to decide, right now,
whether to run for it. If they go, a friend goes with them to keep a flashlight on the
Mannequin.

**Why.** This is what puts a player out on the floor during the 30 seconds, which is the
moment the game is built around.

**A number that needs care.** It has to be far enough away to be a real risk, and close enough
that getting it back is just possible at carrying speed. My starting guess: no further than a
player carrying it can cover in about 20 seconds.

**Where the idea comes from.** Lethal Company: the big items take both hands and slow you
down, and only what gets back to the ship counts. From memory. Showing it only once the code is
in is your idea, and I don't know a hit game that does it, so it is on the untested list.

### 15. Everyone aboard is paid coins, and your finds become yours (Changed)

**Your answer.** Everyone gets paid coins for surviving. You keep what you found and carried.
No copies: one lamp doesn't turn into four.

**How it stands now, in order.**

1. When the gate shuts, every player standing in the elevator is paid coins for the floor.
   Each player gets the same amount.
2. My default: the amount goes up a little with each floor. It also goes up for each monster
   the team has trapped (idea 23).
3. At the same moment, the finds in your slots become yours for good. They leave your slots
   and can't be lost after that. Your slots are free for the next floor. This is your answer
   to my question.
4. A player who is wrapped when the gate shuts is paid nothing and keeps nothing from that
   floor (idea 17).
5. If you are caught, everything you're carrying drops where you stood: tools, as happens
   today, and finds too. A friend can pick them up.

**A correction.** The first version said Dandy's World pays every player for each floor the
team clears. I checked, and it doesn't work that way: it pays each player for the things they
do, such as filling a machine. Paying everyone who gets out is how round games on Roblox
usually pay (Piggy and Flee the Facility both pay the players who escape), but that is from
memory.

### What we'd sell in Part 3

Nothing. The design doc has a rule that Robux never sit beside a timer. Selling extra seconds
on the gate would be selling the game's best moment. Extra slots are sold at the counter and
listed in Part 5.

---

## Part 4: When a monster catches you

**How it works today.** A monster that catches you wraps you in shrink-wrap and puts you in a
unit somewhere on the floor. Everything you were carrying drops where you stood. It is dark in
the unit. You can bang on the door so your friends can find you, which also draws monsters. A
friend who opens your unit holds a button for one second and you are free. If nobody comes
within two and a half minutes, your unit is padlocked, and then a friend needs bolt cutters to
get you out.

When the elevator leaves without you, whether you were caught or just late, you are out for
the rest of the climb, and you watch your friends play. If you are playing alone, one catch
ends the climb, because nobody is there to free you.

### 16. Tell the player what got them (Cut)

**Your answer.** No. Players learn the rules from playing.

**How it stands now.** Nothing is added to the screen you see when you're caught. I've taken
this as a rule for the rest of the proposal: no text whose job is to explain a rule.

### 17. No free way out (Changed)

**Your answer.** You're stuck and you stay stuck, and you're carried up the floors until
someone frees you. You're not out, but you don't get coins in the elevator and you can't grab
any new items. If your friends leave you, you need better friends. A paid "cut yourself free"
should show when you're caught. Freeing yourself for nothing by holding a button is dumb.

**How it stands now.**

1. Once you're wrapped, you stay wrapped until a friend frees you or you pay.
2. There is no hold-the-button way out.
3. You are not out of the climb. When the elevator leaves, you go up with it (idea 18).
4. While you're wrapped you are paid no coins when the gate shuts, and you can't pick
   anything up.
5. The screen you see while you're caught offers Cut Free, for Robux. Your answer to my
   question: Robux only, with no coin item that does the same.
6. Playing alone, there is nobody to free you. So a catch ends the climb unless you buy Cut
   Free. That is how playing alone works today.

### 18. Left behind or still wrapped, you turn up on the next floor (Agreed)

**Your answer.** Agreed.

**How it stands now, in order.** Your answer to 17 stretches this to cover anyone who is
wrapped when the elevator leaves, not only someone who was late.

1. The elevator leaves without you, because you were wrapped or because you didn't make the
   gate.
2. You watch your friends during the ride, as now.
3. When they arrive at the next floor, you are on it too: wrapped, inside one of that floor's
   units.
4. You bang on the door. They find you and cut you free, the same as any other rescue.
5. If they don't find you before that floor's gate shuts, you are carried up again to the
   floor after it. This goes on for as many floors as it takes.
6. You come back with empty hands.

**My default for when a climb ends.** A climb ends when every player is wrapped at the same
moment, because nobody is left to free anyone. The team is offered Free Everyone first (the
store, below).

**Where the idea comes from.** R.E.P.O.: when a player dies, their head is left where they
fell, and a teammate carries it to the extraction point to bring them back. Checked.

### 19. While you wait: bang on the door, or watch your friends (Changed)

**Your answer.** No map and no marking spots for friends. If a caught player can help the rest
of the team, someone could get caught, help, wait to be freed, and it would be easy. They can
bang on the door. You were also considering spectating.

**How it stands now.**

1. A wrapped player can bang on the door, as today.
2. A wrapped player can also switch to watching a friend. The game already has this view for a
   player the elevator has left behind.
3. Nothing else. A wrapped player has no way of helping the team.

The light board from the design doc isn't given to the caught player. Your bigger idea, a
monster that takes your head so that you see through its eyes, is idea 39.

### What we'd sell in Part 4

You said the shop is good for now (idea 37), so this list is the first version's. All of it is
offered only on the screen you see while you're caught. Nothing ever pops up over play.

- **Cut Free** (45 Robux, then 75 if you buy it again in the same climb). It frees you right
  now. If you are being carried up, it puts you standing in the elevator when it reaches the
  next floor, instead of wrapped in a unit waiting to be found.
- **Free a Friend** (49 Robux). You pay to free a friend who is caught, from wherever you are
  standing.
- **Free Everyone** (149 Robux). It frees every caught player at once. If the whole team has
  been caught, it is offered before the results screen, and the climb carries on from that
  floor.
- **Wrap colours** (99 to 499 Robux). The colour or pattern of the shrink-wrap you get wrapped
  in. It is what your friends see when they find you.
- **Gift versions** of each, so one player can buy for another.

The prices are the design doc's drafts, taken from what other games charged on Nov 2.

**What your answer to 17 does to the money.** The first version gave players a free, slow way
out, and I said fewer people would buy Cut Free because of it. With your answer there are two
ways out: a friend, which is free, or Cut Free. Nobody is put out of the climb, and Cut Free is
worth more than it was.

---

## Part 5: The shape of a whole climb

**How it works today.** The plan in the design doc is ten floors, with the roof on top. Three
floors are built. The elevator ride between floors takes just under ten seconds, and there is
nothing to do during it.

### 20. No top floor (Changed)

**Your answer.** Completely rethink it. Dandy's World has no limit. The point is to see how far
you can get, and it gets harder as you go. Kids play more and spend more because they want to
beat their best. You don't know who Dale is or why we'd want him. Every five floors or so
something different can happen, such as the stair chase, but that can come later. Build floors
so they're generated up to about 100 for launch. As monsters are added, each gets a lowest
floor it can appear on, and the system adds them in at random.

**How it stands now.**

1. A climb has no roof and no last floor. You climb until the whole team is caught. Your best
   floor is the number you're trying to beat.
2. Floors are made by the game from a set of rules, not laid out one at a time by hand. For
   launch the rules cover floors up to about 100.
3. Each floor is harder than the one before it.
4. Every monster has a lowest floor it can appear on. From that floor up, the game mixes it in
   at random. Adding a monster later means adding it to the list with its lowest floor. This
   fits how the game is built: every monster is a row of numbers on one shared system.
5. About every five floors there can be a floor that plays differently, such as the stair
   chase. Those come later. The rules that make floors leave room for them.
6. The roof, Dale's floor and the ending where you cut the power are all out. Dale is out of
   this proposal altogether.

**What you keep when a climb ends.** Everything that became yours at a gate (idea 15), and
your unspent coins as cash.

**Where the idea comes from.** Dandy's World: its floors have no known top, and the record
runs are around floor 400. Checked.

### 21. A team choice during the elevator ride (Agreed; how it looks is Open)

**Your answers.** To 21: fine, as long as it isn't too similar to Dandy's World. It should feel
like a new concept. To 24: cards in the elevator that the team votes on, and maybe all three
can be bad: the power is out, double the monsters, getting caught sends you back to the lobby.
More get added over time.

**One thing to notice.** On Nov 2 you cut cards with downsides. Your answer to 24 brings them
back, so they're back.

**What's agreed.** The ride takes about 20 seconds. During it the team is shown three choices,
everyone picks one, and the most picks wins. Choices can be bad. The list of choices grows over
time (idea 24). There is no paying to see three different ones, because Roblox treats paying
for a random result as a paid random item.

**My suggestion for making it its own thing (Open): the choice is the elevator's own
buttons.**

1. During the ride, three buttons light up on the elevator's panel. Each one is a version of
   the next floor.
2. Each button shows what that floor is like: the power is out, or there are twice the
   monsters, or anyone caught there goes back to the lobby, or twice as many doors are
   padlocked.
3. Each button also shows what that floor pays. A harder floor pays more coins at the gate.
4. Everyone presses one. The button with the most presses wins. A tie is settled at random.
5. The elevator stops at that floor. What the team chose lasts for that one floor, so a bad
   choice is over when the gate shuts.
6. Some rides, all three are bad, and the team picks the one it can live with.

**Why I think this is different enough.** In Dandy's World the team votes on a card. Here the
team is choosing where the elevator stops next, on the elevator's own panel, and what they
chose is a place they then have to get through.

**Where the idea comes from.** Lethal Company: the crew chooses which moon to land on. Each
moon has a risk level, and weather such as an eclipse that brings out more monsters. Dandy's
World: the vote itself, with the most votes winning and ties settled at random. Both checked.

**Why it's open.** You asked for it to feel new, and this is my attempt. If you would rather
have three cards on the wall, or a choice that lasts the rest of the climb, say so.

### 22. A vending machine in the elevator (Agreed, on every ride)

**Your answer.** Yes, but obviously not just after floors 2 and 4, since there will be many
more floors.

**How it stands now.**

1. The machine lights up on every ride after floor 1.
2. It shows three or four tools, each with a price in coins: a padlock for 6, say, or bolt
   cutters for 10. Those prices are guesses to start from.
3. You tap one to buy it with your own coins.
4. My default: what it stocks changes from ride to ride, so you can't count on bolt cutters
   being there.
5. The ride from the lobby up to floor 1 has neither the machine nor the choice. A new player
   should get to their first door fast, and nobody has any coins yet.

With tools rarer in units and wearing out (idea 2), the machine is where a team stocks back
up. The marker (idea 38) is sold here too.

**Where the idea comes from.** Dandy's World has a shop in its elevator. From memory.

### 23. Trapping a monster pays more at the gate (Changed)

**Your answer.** Trapping is worth doing because it makes it easier to search without being
hunted. What more is really needed? Maybe more coins in the elevator based on how many
monsters you trapped, like a multiplier.

**How it stands now.**

1. A trapped monster is out of the halls: for 90 seconds, or for the rest of the floor if you
   padlock the door. That is the reason to trap one.
2. A trapped monster still counts toward the floor's limit on how many monsters can be awake
   at once. The design doc says the opposite: a trapped monster frees up room, so "the next
   door can hold a fresh one". That would mean trapping gains the team nothing. This follows
   from the reason you gave, but you didn't answer it directly, so say if you disagree.
3. Your "maybe": when the gate shuts, each monster shut in a unit at that moment raises
   everyone's pay for the floor. My starting guess is a quarter more for each one. One trapped
   monster pays one and a quarter times the floor's coins, two pay one and a half times.
4. The perk for trapping, from the first version, is dropped.
5. The first time you trap each kind of monster is still stamped in your collection book, as
   the design doc has it.

**You dropped something like this before.** On Nov 9 you dropped a cash bonus for trapping.
This one is coins at the gate, and it's your own suggestion today. I'm noting it so it doesn't
come back without you noticing.

### 24. New monsters and new choices over time, on no fixed schedule (Changed)

**Your answer.** Don't make it a cadence. Some weeks, new choices for the elevator vote get
added. Monsters will definitely be added as the game goes on. But not necessarily one or both
every week.

**How it stands now.** There is no rule of the week and no board in the lobby announcing one.
Two lists grow over time: the monsters, each with its lowest floor (idea 20), and the choices
on the ride (idea 21). Neither is promised weekly.

### What we'd sell in Part 5

- **A starting tool, for cash, not Robux.** This is already in the design doc. In the lobby,
  during the countdown before a climb, you can spend cash to start with one tool of your
  choice. It costs cash every climb.
- **Extra slots, up to six** (199 to 299 Robux each as a first draft, bought once and kept
  forever). Everyone has three. A fourth, fifth and sixth can be bought. The first version
  argued for selling only one, because with six slots you could carry every tool. Now that
  finds share your slots, a bigger inventory fills with finds, and six makes sense.
- **Flashlight beam colours** (49 to 299 Robux). In a dark hall the beams are what everybody
  sees, so this is the cosmetic that shows the most.
- **Nothing on the ride's choices.** No paying to see three different ones.

---

## Part 6: After the climb

**How it works today.** After a climb you are back in the elevator in the lobby, with the
results on its wall: whether you made it or were caught, the floor you reached, your time, and
an "Again" button. Nothing is saved. There is no cash, and finds can't leave the building.

You answered "sure" to every idea in this part. They are as they were, changed only where an
answer elsewhere touches them.

### 25. The results screen values your finds one at a time (Agreed)

**How it stands now.** Each find that became yours during the climb comes up on the results
one at a time: its picture, its name, how rare it is, and what it is worth. The cash total
counts up with each one. Any coins you didn't spend are added at the end. After that there is
one line for each player, such as who freed the most friends, who opened the most doors, and
who shut a friend in a unit.

**Why.** It makes each find exciting twice: once when you open the door and see it, and once
when you learn what it was worth. It also happens at the moment a player decides whether to
press "Again".

**Where the idea comes from.** The storage-auction TV shows this setting comes from, where the
unit is opened first and valued afterwards. That is television, not a hit game. Lethal Company
does end each day with a report on how each player did; from memory.

### 26. A collection book with a page for every find (Agreed)

**How it stands now.** The design doc already has a book called the Catalog, which records the
monsters you have trapped and the sets you've finished. I'd add a page for every kind of find.
The first time one becomes yours, its page is stamped "New" on the results screen. Sets stay as
the design doc has them: groups of finds that belong together, such as a 1980s bedroom.
Finishing a set gives you a display piece for your unit. The design doc also puts Dale's notes
in the book; those go with Dale.

**Where the idea comes from.** Fisch: every fish you catch fills in its own entry in a book,
and finishing a section pays a reward. Checked.

### 27. Rare versions of ordinary finds (Agreed)

**How it stands now.** About one find in twenty turns up still sealed in its original
packaging. It is the same item, worth three times as much, shown in its packaging, with its own
stamp in the collection book.

**Where the idea comes from.** Fisch and Grow a Garden both have rare versions of ordinary
things that multiply what they're worth. Checked. The "still sealed" look is my own choice.

### 28. Selling and keeping without a menu (Agreed)

**How it stands now.** After the valuing in idea 25, the game sorts your finds for you.
Anything you already own a copy of, and anything common, is sold for cash on the spot. Anything
rare that you don't already own goes to your unit in the lobby, and you can sell it from there
later. Every kind of find gets its page stamped either way.

### 29. Your unit, and a shelf in the elevator to show finds off (Agreed)

**Your answer.** Sure, we can add it and see what happens.

**How it stands now.** The design doc plans a hall of units in the lobby, one for each player,
where your finds are on show and friends can walk in. You would spend cash to move up from a
small unit to a medium and a large one. That hall is a lot to build, so it comes after launch.
Until then, a shelf inside the elevator shows the three best finds of whoever is hosting that
elevator, which is the first player to step into it in the lobby.

**Where the idea comes from.** Lethal Company: things the crew buys are set out on the ship,
where everyone sees them between trips. From memory.

### 30. Perks: small advantages you own and pick before a climb (Agreed)

**How it stands now.** A perk is a small advantage that you own for good. Before a climb you
pick two of the perks you own, and you can't change them once the climb starts. Each perk
first has to be unlocked by doing something, and then you buy it with cash.

One change, because of your answer to 23: trapping a monster no longer unlocks a perk. Perks
are unlocked by reaching a floor for the first time (floor 10, floor 25) or by finishing a
set.

Perks to start with:

- Cutting a friend free takes half a second instead of one.
- Your flashlight reaches a little further.
- You carry the big find a little faster.
- The rattle of a door you open carries half as far.

They are small on purpose. A new player with no perks can still climb.

**Where the idea comes from.** Trinkets in Dandy's World: you use two at a time, you choose
them before the run starts, you buy them with what you earn from runs, and some have to be
unlocked first. Checked.

**So cash would buy four things:** a starting tool for each climb, perks, a bigger unit, and
cosmetics.

### What we'd sell in Part 6

- **Double cash** (299 to 399 Robux, bought once and kept forever). All the cash you earn is
  doubled. It would be offered at the counter and as a small button on the results screen.
- **Cash packs** (49 to 1,499 Robux). You buy cash with Robux. I would only sell these once
  perks and the starting tool exist, so that cash is for something. Once cash can be bought,
  nothing random can ever be sold for cash, because Roblox counts bought currency the same as
  Robux.
- **A starter pack** (99 Robux). It is shown once, after your first climb and never before:
  one beam colour, one wrap colour and some cash.
- **Decor for the elevator and for your unit** (99 to 499 Robux).

---

## Part 7: Reasons to come back tomorrow

### 31. Save the player's progress (Agreed)

**How it stands now.** Nothing is saved today. Cash, finds, the collection book, your best
floor and anything you have bought all need to be saved. Everything in Part 6 depends on it and
so does every product. Players never see this, but it has to be built first. Under the
project's rules it comes from Brix, the shared framework.

### 32. Your best floor, the Missing board and badges (Agreed)

**How it stands now.**

- **Best floor.** The highest floor you have reached, shown on a plaque and on the dial above
  your elevator. With no top floor (idea 20), this is the number the whole game points at.
- **The Missing board.** A board in the lobby. When a whole team is caught, their photos go up
  on it with the floor they were caught on, until their next climb.
- **Roblox badges.** The first version gave one for reaching the roof. There is no roof now.
  My default: badges for reaching floors 10, 25, 50 and 100, for each kind of monster trapped,
  and for each set finished.

### 33. A free door to open once a day (Agreed)

**How it stands now.** Once a day, in the lobby, you open one roll-up door, slow and loud, the
same as in a climb. Inside is a free find. On the seventh day in a row, the find is a better
one. It is never sold, and you can't buy more openings, because that would be paying for a
random result.

### 34. A small shelf of cosmetics that changes every week (Agreed)

**How it stands now.** Three cosmetics at the counter that are swapped for three different
ones each week. It gives a player a reason to look at the shop again.

### 35. A season pass, after launch (Maybe)

**Your answer.** Okay, maybe.

**How it stands now.** Not planned. If it happens, it is some time after launch: two rows of
rewards, one free and one paid, earned by climbing floors, with every reward shown up front so
nothing in it is random.

### 36. Private servers free, or nearly free (Agreed)

**How it stands now.** A private server lets a group of friends play in a server of their own.
This game spreads by friends bringing friends, so it would cost nothing or close to it.

### What we'd sell in Part 7

The weekly shelf (idea 34), and maybe later the season pass (idea 35). Everything else in this
part is free on purpose.

---

## New, from your answers

### 37. The shop as listed (Agreed for now)

**Your answer.** Good with the shop for now. We can always tweak.

**How it stands now.** The products and draft prices are the first version's. Two things have
changed because of other answers: extra slots go up to six, where the first version sold one
(Part 5), and the marker is sold for coins in the machine (idea 38). The whole list is in the
table below.

### 38. A marker for tagging doors (New, yours)

**Your idea.** A marker you can use to tag units on a floor. Say your inventory is full and you
find a padlock. Instead of dropping something, you tag the unit, so you know where to come back
to if you need it later.

**Your answer to my question.** It is bought with coins, in the machine.

**How it stands now, in order.**

1. The marker is a tool in the elevator's machine. My starting guess at a price is 4 coins.
2. It takes a slot, like any other tool.
3. With it in your hand, you face a unit's door and tap Mark. A bright mark goes on the door,
   and the whole team can see it from down the hall.
4. It runs out after a number of marks, like the other tools in idea 2. My starting guess is
   five.
5. My default: the mark also shows on the corner map. A hall is easy to lose in this
   building, and this is the team's own mark, not a hint from the game. Say if you'd rather it
   was on the door only.

**What players would use it for.** A unit with something in it they had no room for. A unit
with a sleeping monster that nobody should open. The unit a wrapped friend is in.

**Where the idea comes from.** Lethal Company: spray paint is bought in its store, players use
it to mark the way back, and a can runs dry. Checked.

### 39. A monster that takes your head (New, yours, Open)

**Your idea.** Some monsters take your head, wrap you up and throw you in a unit. While you're
caught, you see what the monster sees as it moves around the floor. You're stuck like that,
even going up floors, until your friends free you or you pay to free yourself.

**How it would go, as I understand it.**

1. One kind of monster, when it catches you, takes your head. Your body is wrapped and put in
   a unit, as with any other catch.
2. While you're caught, your screen shows the floor through that monster's eyes as it walks.
3. You stay like that, floor after floor, until a friend frees you or you buy Cut Free.

**What would need settling before it's built.**

- What a friend has to do to free you. Open your unit, as now? Or get your head back from the
  monster first?
- What you see is useful. A caught player who can say over voice chat where the monster is
  walking is helping the team, and your answer to 19 was that a caught player shouldn't be
  able to.
- Which monster does this.

**Where the idea comes from.** R.E.P.O.: a dead player's head is what's left of them, and a
teammate carries it back to bring them into the game again. Checked. Seeing through the
monster's eyes is yours, and I don't know a hit game that does it, so it is on the untested
list.

**Why it's open.** You called it a crazier idea. It isn't in the build order until you take it
up.

---

## The whole store on one page

| What it is | Price | Where the player sees it | Built in |
| --- | --- | --- | --- |
| Cut Free: free yourself now | 45 Robux, then 75 | The screen you see while caught | Step 3 |
| Free a Friend | 49 Robux | The screen you see while caught | Step 3 |
| Free Everyone | 149 Robux | When the whole team is caught, before the results | Step 3 |
| Wrap colours | 99 to 499 Robux | The counter | Step 3 |
| Extra slots: a fourth, fifth and sixth | 199 to 299 Robux each | The counter | Step 4 |
| Flashlight beam colours | 49 to 299 Robux | The counter | Step 4 |
| Double cash | 299 to 399 Robux | The counter, and the results screen | Step 5 |
| Cash packs | 49 to 1,499 Robux | The counter | Step 5 |
| Starter pack | 99 Robux | Once, after your first climb | Step 5 |
| Decor for the elevator and your unit | 99 to 499 Robux | The counter, and the weekly shelf | Step 5 |
| Season pass (maybe) | not priced | The lobby | After launch |
| Gift versions | the same | Beside each product | With each one |

The prices are the design doc's draft ranges. A starting tool, perks and a bigger unit cost
cash, not Robux. Tools in the machine, the marker among them, cost coins.

**The rules these follow.** All of them are already in the design doc or in your lobby and
store plan of Nov 11.

- Nothing random is ever sold, for Robux or for cash.
- Robux never sit beside a timer.
- Nothing a player buys makes the game worse for another player.
- Coins, the daily door and the choices on the ride are never sold.
- Nobody can pay to skip a floor.
- The shop never interrupts play.
- A purchase is never lost, even if saving fails or the player moves to another server.
- Any offer can be switched off without updating the game.
- Prices are read from Roblox and never typed into the game.

## What's out

**Cut by your answers:**

- The building as a character that watches, sends monsters or "comes for you".
- The five-second "don't move" moment, the clock that strikes, and the "closing time"
  announcement (the first version's 7, 8 and 9).
- Tagged doors, and three grades of door (4).
- Marks on the corner map for where the notes are (5).
- The timing tap on every door (6).
- A line telling the player what got them (16).
- Freeing yourself for nothing by holding a button (17).
- The map of the floor's lights for a caught player (19).
- The roof on floor 5, Dale's floor, and Dale (20).
- A copy of every find for everyone in the elevator, and the team's pile of finds (13, 15).
- A perk for trapping a monster (23).
- A rule of the week, and a monster every week (24).

**Dropped or put off, as in the first version. You didn't comment on these:**

- **Crouch-walking and sprinting.** Dropped (idea 11, which you agreed).
- **Trading finds between players.** Put off until well after launch. It brings scams, people
  selling items for real money, and extra care around young players.
- **Finds that are monsters in disguise, fake notes, the monster that moves walls, and the
  dolly.** Each adds a rule on top of a game whose basic rules nobody has played yet. Later.
- **The light board.** The design doc has one player standing at a board of the floor's
  lights in an office. I doubt anyone would stand there while friends open doors, and you
  turned down giving it to a caught player. I'd drop it.
- **The hall of units in the lobby.** After launch. The shelf in the elevator comes first
  (idea 29).
- **The stair chase.** Later, as one of the floors that play differently (idea 20).

## The order I'd build it in

Each step builds a piece of the game and the things sold with that piece together.

**Step 0. Play what's built with friends.** Before any of this, play the three floors that
exist with real people. Only you can run that. Nothing is sold.

**Step 1. Doors that pay, and things to carry.** Coins in most units, finds that go in your
slots, pay and keeping at the gate, the machine on the ride, tools that are rarer and wear out
if you say yes, about half the units, padlocked doors that always hold something good, the one
faint mark, saving, and a plain results screen that shows the cash you earned (ideas 1 to 5,
13, 15, 22, 31, and a first version of 25). Nothing is sold yet. But from here the game records
what every player earns and spends, so we know what things are worth before we put a price on
anything.

**Step 2. Monsters that mess with the floor.** The breaker, sleeping monsters that wake, the
wrong code that lets monsters out, and the tap when you shut a door on a sleeper (ideas 7, 9,
10 and 6). Then the second monster, once you've settled it (idea 12). Nothing is sold. It has
worked when a team that has lost its lights goes looking for the breaker without being told
to.

**Step 3. Getting caught.** Staying wrapped, being carried up floor after floor, and watching
while you wait (ideas 17 to 19). This is where the first products go on sale: Cut Free, Free a
Friend, Free Everyone and wrap colours. So this step also builds buying properly, so that a
purchase is never lost. It has worked when nobody quits a climb because they were caught.

**Step 4. The climb with no top.** Floors made by rules up to floor 100, monsters added by
lowest floor, the choice on the ride, more pay for trapping, the big find and the marker
(ideas 20, 21, 23, 14 and 38). On sale: a starting tool for cash, beam colours and extra
slots. It has worked when two climbs in a row feel different, and players talk about their
best floor.

**Step 5. After the climb.** Finds valued one at a time, the collection book, rare versions,
selling and keeping, the shelf in the elevator, and perks (ideas 25 to 30). On sale: double
cash, cash packs, the starter pack and decor. It has worked when players watch the results to
the end and change their perks between climbs.

**Step 6. Coming back.** Best floor, the Missing board, badges, the daily door and private
servers (ideas 32, 33 and 36). The design doc's plan to have Roblox save a short clip at the
big moments goes here too. On sale: the weekly shelf (idea 34), and maybe later the season
pass (idea 35). It has worked when players come back the next day without a friend asking
them to.

The monster you hide from (idea 8) and the monster that takes your head (idea 39) aren't in
any step. They wait for you.

## What we'd need to measure

The game records nothing today, so none of this can be seen yet.

- How many seconds pass between a player joining and opening their first door. The design doc
  wants 30 or fewer.
- How many doors a player opens in a minute, and how many of those gave them something.
- How often players are caught on each floor.
- How many floors a wrapped player is carried up before someone frees them.
- The floor each climb ends on.
- How often "Again" is pressed after a climb.
- Who buys each product, and where in the game they were when they bought it.

## What would change in the design doc

By the design doc's own section names. None of this has been written into it yet.

- **Lights.** "Every lit light tells the building where you are" comes out. So do the four
  ways to move. The lights are just lights. The breaker goes in.
- **Doors.** About half as many units. Coins in most of them. A padlocked door always holds
  something good. At most one faint mark for a note. A timing tap when you shut a door on a
  sleeping monster.
- **Getting kept.** A wrapped player is carried up floor after floor until freed, earns
  nothing and picks nothing up. Being left behind no longer puts you out of the climb.
- **Codes, the elevator and the roof.** A wrong code lets monsters out, one unit and then
  three, darkens the floor and locks the keypad for longer each time. The ride is about 20
  seconds, not 40. There is no roof.
- **The building.** No top floor. Floors are made by rules up to about floor 100 for launch.
  Each monster has a lowest floor. The building isn't a character. Dale and his floor come
  out.
- **Tools and traps.** Tools are rarer in units and wear out, if you say yes. A trapped
  monster still counts toward the floor's limit. Trapping raises the pay at the gate. The
  marker is new.
- **Meta.** Finds go in your own slots and become yours when the gate shuts. Everyone aboard
  is paid coins. Finds are valued on the results screen. Perks and the shelf in the elevator
  are new. Trading is put off.
- **Live ops.** No weekly monster and no weekly rule. Monsters and choices for the ride are
  added over time.
- **Monetization.** Extra slots up to six. Double cash from the day the store opens. A season
  pass is a maybe.

## Things you cut before that are back

So that none of them returns without you noticing.

- **A friend who is left behind turns up on the next floor (idea 18).** You cut it on Nov 2.
  You agreed it today.
- **Something that makes a floor worse the longer you stay (idea 9).** You cut a clock that
  ran across the whole climb on Nov 2. Today's version is yours: sleeping monsters wake after
  a while, with no clock shown.
- **A reward for trapping (idea 23).** You dropped a cash bonus on Nov 9. Today's version is
  your "maybe": more coins at the gate.
- **Choices on the ride that are bad for the team (ideas 21 and 24).** You cut cards with
  downsides on Nov 2. Your answer to 24 brings them back.

## Ideas with no hit game behind them

Your rule is that every mechanic names the hit game it comes from. These don't fully meet it.

Yours:

- **The big find shown only once the code is in (idea 14).** Carrying a heavy thing in both
  hands is proven. Showing it only when the countdown starts is new.
- **A monster that only moves in the light (idea 12).** Monsters with a rule that stops them
  are proven. This rule is new.
- **Seeing through the eyes of the monster that caught you (idea 39).**
- **More pay at the gate for trapped monsters (idea 23).**

Mine:

- **Each monster going after the thing that stops it (ideas 8 and 12).** The breaker has
  Phasmophobia behind it. Lights that get stuck on, and a monster that pulls open doors down,
  are my own.
- **Choosing the next floor on the elevator's buttons, with harder floors paying more (idea
  21).** Choosing where to go next by its risk is Lethal Company's. Putting it on an elevator
  between floors is mine.
- **Valuing finds one at a time on the results screen (idea 25).** It comes from television.
  You agreed it.
- **The "still sealed" look for rare finds (idea 27).** You agreed it.

## How sure I am about the games I've named

**Checked on the web on Nov 13, for the first version:**

- R.E.P.O.: a dead player's head is carried to the extraction point and they come back.
- Dandy's World: two trinkets at a time, chosen before the run, bought with its currency, some
  unlocked first; and timing taps on its machines.
- DOORS: gold turns into its lasting currency at the end of a run; the library's books and its
  hint paper.
- Lethal Company: more monsters as the day goes on.
- Fisch: rewards for filling in its book of fish.
- Fisch and Grow a Garden: rare versions that multiply what a thing is worth.

**Checked on the web on Nov 13, for this version:**

- DOORS: gold isn't shared in a normal run. Its wiki describes a plate in the shop for giving
  your gold to another player, and names Daily Runs as the mode where gold is shared. No page
  says it in one plain sentence, so call this very likely, not certain.
- DOORS: the flashlight runs down, and batteries are found in drawers.
- Dandy's World: the card vote happens on odd-numbered floors, the most votes win, and a tie
  is settled at random. Its floors have no known top, with record runs around floor 400. Its
  lasting currency is paid for things each player does (filling a machine, picking up a
  capsule).
- Phasmophobia: the ghost can switch off the breaker and the team has to switch it back on.
- Lethal Company: spray paint is bought in the store, used to mark the way, and runs dry.
  Pulling the apparatus cuts every light. Moons have risk levels and weather, and an eclipse
  brings out more monsters.

**Wrong in the first version, and fixed here:**

- It said Dandy's World pays every player for each floor the team clears. It doesn't.
- It put DOORS beside a shared pile of finds. DOORS doesn't share gold.
- It said the game has two slots. It has three.

**From memory, not checked. Check each one before leaning on it:**

- DOORS: gold in drawers and picking it up with a tap; Rush and its flickering lights;
  guessing the last digit in the library.
- Dandy's World: tapes spent at a shop in the elevator.
- Lethal Company: four slots shared by tools and scrap; two-handed items that slow you down;
  one monster that stops while you look at it and one that comes if you look too long; the
  end-of-day report on each player; purchases set out on the ship.
- Dead by Daylight: timing taps that come up on their own, and a missed one makes a noise the
  killer hears.
- Escape from Tarkov: marked rooms.
- Piggy and Flee the Facility: paying the players who escape.
- Fortnite: an item shop that changes on a schedule.
- Daily rewards with streaks being in most big Roblox games.

**Sources for the checked ones.**
[R.E.P.O. revive, PC Gamer](https://www.pcgamer.com/games/horror/repo-how-to-heal-and-revive/) ·
[R.E.P.O. revive, GamesRadar](https://www.gamesradar.com/games/horror/repo-revive) ·
[Dandy's World trinkets, wiki](https://dandys-world-robloxhorror.fandom.com/wiki/Trinkets) ·
[Dandy's World cards, wiki](https://dandys-world-robloxhorror.fandom.com/wiki/Cards) ·
[Dandy's World floors, wiki](https://dandys-world-robloxhorror.fandom.com/wiki/Floors) ·
[Dandy's World beginner's guide, Item Level](https://itemlevel.net/dandys-world-complete-beginners-guide/) ·
[DOORS Knobs, wiki](https://doors-game.fandom.com/wiki/Knobs) ·
[DOORS Gold, wiki](https://doors-game.fandom.com/wiki/Gold) ·
[DOORS Jeff Shop, wiki](https://doors-game.fandom.com/wiki/Jeff_Shop) ·
[DOORS Daily Runs, wiki](https://doors-game.fandom.com/wiki/Daily_Runs) ·
[DOORS items, Bloxodes](https://bloxodes.com/wiki/doors/items) ·
[Phasmophobia lights, wiki](https://phasmophobia.fandom.com/wiki/Light) ·
[Phasmophobia flashlight guide, Screen Rant](https://screenrant.com/phasmophobia-keep-flashlight-on-unequipped-guide/) ·
[Lethal Company spawn times, Steam](https://steamcommunity.com/app/1966720/discussions/0/3958162152971622445) ·
[Lethal Company spray paint, Prima Games](https://primagames.com/gaming/what-are-the-spray-cans-for-in-lethal-company-explained) ·
[Lethal Company weather, Prima Games](https://primagames.com/tips/lethal-company-all-weather-conditions-explained) ·
[Lethal Company moons, Pro Game Guides](https://progameguides.com/lethal-company/all-moons-weather-status-effects-in-lethal-company/) ·
[Lethal Company apparatus, Gamer Tweak](https://gamertweak.com/apparatus-easter-egg-lethal-company) ·
[Fisch mutations, Roblox Den](https://robloxden.com/game-codes/fisch/guides/fisch-mutations-guide-types-multipliers-and-how-to-get-them) ·
[Grow a Garden mutations, Sportskeeda](https://www.sportskeeda.com/roblox-news/all-mutations-grow-garden)

## Still open

Five things need your answer. Each is written out in full under its number.

1. **Idea 2: tools.** Rarer in units (about one in twelve, down from one in five) and wearing
   out after a set number of uses. Yes, no, or different numbers?
2. **Idea 12: the second monster.** Silent, only moves in light, follows the lights you set
   off, and makes lights stick on until someone flips the breaker off and on. Is this the
   monster to build next?
3. **Idea 21: the choice on the ride.** Three buttons for three versions of the next floor,
   harder ones paying more, lasting one floor. Or three cards on the wall?
4. **Idea 8: a monster you hide from.** Woken by noise, runs the halls, pulls open doors
   down. Keep it on the list for later, change it, or drop it?
5. **Idea 39: the monster that takes your head.** Yours. Take it up now, later, or not?

**Small things I picked so each idea was complete.** Say so if any is wrong; otherwise they
stand.

- Seven units in ten have coins (1).
- Not tapping counts as a miss when you shut a door on a sleeping monster (6).
- A monster pounding on a door breaks out after 90 seconds unless the door is padlocked (6
  and 9).
- A Mannequin gets keener on the breaker as floors go up, the breaker takes a one-second hold
  to switch on, and the elevator keeps its own light (7).
- Sleeping monsters start to wake after four minutes on floors 1 and 2 and six minutes above,
  three at a time, with three more every two minutes (9).
- The third wrong code and every one after opens five units (10).
- When the code goes in, the big find's unit opens by itself and shows on the corner map, no
  further than a 20-second carry from the elevator (14).
- Pay at the gate goes up a little each floor (15).
- When you're caught, the finds you carry drop where you stood, as tools do (15).
- A climb ends when every player is wrapped at the same moment (18).
- A trapped monster still counts toward the floor's limit (23).
- Each trapped monster adds a quarter to the floor's pay (23).
- The machine's stock changes from ride to ride (22).
- Perks are unlocked by reaching a floor for the first time or finishing a set (30).
- Badges at floors 10, 25, 50 and 100 (32).
- A player's mark on a door also shows on the corner map, the marker costs 4 coins and makes
  five marks (38).

## The list, with your answers

**Part 1: Opening doors**
1. Coins in most units, not all. **Changed.**
2. Coins are spent in the climb, and what's left becomes cash. **Agreed.** Tools rarer and
   wearing out: **Open.**
3. About half as many units on each floor. **Agreed.**
4. Two kinds of door: padlocked, and everything else. **Changed.**
5. At most one faint mark for a note, and nothing on the map. **Changed.**
6. A timing tap when you shut the door on a sleeping monster. **Changed.**

**Part 2: Monsters that mess with the floor**
7. The Mannequin cuts the power, and someone has to find the breaker. **Changed.**
8. A monster you hide from. **Open.**
9. Stay too long and the sleeping monsters start to wake. **Changed.**
10. A wrong code lets monsters out: one unit, then three. **Agreed, with your penalty.**
11. Keep one walking speed. **Agreed.**
12. The second monster: silent, and it only moves in the light. **Open.**

**Part 3: Getting to the elevator**
13. A find goes in one of your own slots. **Changed.**
14. One big find on each floor, shown only once the code is in. **Changed.**
15. Everyone aboard is paid coins, and your finds become yours when the gate shuts.
    **Changed.**

**Part 4: Getting caught**
16. Tell the player what got them. **Cut.**
17. No free way out: a friend, or Cut Free. **Changed.**
18. Left behind or still wrapped, you turn up on the next floor. **Agreed.**
19. While you wait: bang on the door, or watch your friends. **Changed.**

**Part 5: The whole climb**
20. No top floor: floors made by rules up to about 100, monsters by lowest floor. **Changed.**
21. A team choice on the ride, which can be bad. **Agreed.** Its look: **Open.**
22. A vending machine in the elevator, on every ride. **Agreed.**
23. Trapping a monster pays more at the gate. **Changed.**
24. New monsters and new choices over time, on no fixed schedule. **Changed.**

**Part 6: After the climb**
25. The results screen values your finds one at a time. **Agreed.**
26. A collection book with a page for every find. **Agreed.**
27. Rare versions of ordinary finds, worth three times as much. **Agreed.**
28. Selling and keeping without a menu. **Agreed.**
29. Your unit grows, and a shelf in the elevator shows the host's best three finds.
    **Agreed.**
30. Perks: small advantages you own, two picked before each climb. **Agreed.**

**Part 7: Coming back**
31. Save the player's progress. **Agreed.**
32. Best floor, the Missing board and badges. **Agreed.**
33. A free door to open once a day, with a seven-day streak. **Agreed.**
34. A small shelf of cosmetics that changes every week. **Agreed.**
35. A season pass, after launch. **Maybe.**
36. Private servers free, or nearly free. **Agreed.**

**New**
37. The shop as listed. **Agreed for now.**
38. A marker for tagging doors, bought with coins in the machine. **New, yours.**
39. A monster that takes your head, so you see through its eyes. **New, yours, Open.**
