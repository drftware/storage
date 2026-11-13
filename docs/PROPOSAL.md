# Proposal: what I'd change in the game, and what we'd sell at each point

_Written Nov 13 after going through the design doc and the code, then rewritten the same day in
plain language. Nothing in here is decided and nothing is built. The design doc stays the plan
until you say yes to something here._

## How to read this

There are 36 ideas, numbered, in seven parts. The parts follow a climb in order: opening doors,
the lights, getting to the elevator, getting caught, the climb as a whole, what happens after
it, and reasons to come back the next day.

Each part starts by saying how that piece of the game works today, so you can see what I'm
reacting to. Each idea then says what I'd change, what a player would see and do, why I think
it's better, and which hit game it's taken from. Each part ends with what we would sell at that
point in the game, or says we'd sell nothing there and why.

You can answer by number: "keep 1, cut 6, change 9 so that…". There's a list at the very end for
marking up.

Words I use:

- **Monsters.** The docs and the code call them keepers. You haven't picked a name, so I say
  monsters.
- **Caught.** When a monster gets you. On screen the game says "Kept".
- **Finds.** The items sitting in units: a lamp, a box of records.
- **Quarters.** Coins you would pick up during a climb. They are new in this proposal (ideas 1
  and 2).
- **Cash.** The money you keep between climbs. The design doc has it; the game doesn't yet.
- **Robux.** Real money.
- **The corner map.** The small map of the floor in the corner of the screen.
- **The counter.** The shop desk in the lobby.

## The short version

What's built is very well made. The gaps I see are all about what the player gets out of it.

1. **Most doors give you nothing.** Four units in ten are empty, and the items in the others
   can't be picked up. Opening a door is the thing you do most, and it usually ends with nothing
   in your hands.
2. **The building doesn't come for you.** The lights turn on when you move, but no monster is
   sent because of it, and the one monster in the game stops whenever light is on it. A player
   who keeps moving is safe.
3. **Nothing lasts.** When a climb ends you see your floor and your time. There's no cash, no
   items and nothing saved, so your second climb is your first one again.

The ideas go at those three, in that order. The things we'd sell sit inside them, each at the
moment a player would want it, so the store gets built alongside the game and not added on at
the end.

---

## Part 1: Opening doors

**How it works today.** A floor has about 60 storage units on floors 1 and 2, and about 80 on
the floors above. Opening a door takes two seconds and makes a loud rattle that monsters can
hear. The game decides what's inside at the moment the door opens. Out of every 100 doors, 40
have nothing in them, 25 have a find, 20 have a tool, 10 have a sleeping monster and 5 have a
monster that's awake. The notes with the code's digits are different: they are put in
particular units when the floor is built.

Two things about that bother me. The finds can't be picked up or taken out of the building, so
65 doors in every 100 give you nothing you can use. And apart from the padlocked ones, every
door looks the same from the hall, so there's no choosing between them. The only way to find
the notes is to open every door in turn.

### 1. Put a few quarters in every unit, so no door is a waste

**What I'd change.** Every unit would have one to three quarters lying on its floor. You tap
them to pick them up, and a small count on your screen goes up. The unit can still hold a find,
a tool, a note or a monster as well, exactly as now. The only thing that goes away is the
completely empty unit.

**Why.** A door that might hold nothing at all teaches players to stop caring about doors. A
door that always pays a little, and sometimes pays a lot or goes badly wrong, is one people
keep opening.

**Where the idea comes from.** DOORS. Most drawers in its rooms have a few gold coins in them,
and players open every drawer because of it.

### 2. Quarters are spent during the climb, and whatever is left becomes cash

**What I'd change.** Quarters only exist inside one climb. You spend them at a vending machine
in the elevator between floors (idea 22), which sells tools. Each player has their own
quarters. Any you still have when the climb ends are turned into cash, which is the money you
keep (Part 6). Quarters are never sold for Robux. The design doc already says so.

**Why.** It gives the coins from idea 1 a use within minutes of picking them up. It also gives
the player a small decision while the climb is still going: spend them now on bolt cutters, or
hold on to them for cash afterwards.

**Where the idea comes from.** Dandy's World. You pick up tapes on each floor and spend them at
a shop in the elevator. The design doc already takes its vending machine from there.

### 3. About half as many units on each floor

**What I'd change.** About 30 units on floors 1 and 2 instead of 60, and about 40 on the floors
above instead of 80. The halls would stay as long as they are now, with stretches of blank wall
where the removed units were, so there is still room to be chased.

**Why.** Three reasons. Once every door pays something (idea 1), fewer doors makes each payment
feel like more. Once doors look different from each other (idea 4), there have to be few enough
of them that picking one is a real choice. And fewer units is less for a phone to draw: the
roadmap already notes how heavy a floor is to draw from its elevator lobby.

**Where the idea comes from.** No particular game. It is a number to tune, and 30 and 40 are my
starting guesses.

### 4. Three kinds of door you can tell apart from the hall

**What I'd change.**

- **A plain door** looks as it does now. The unit has quarters, and the usual chances of
  something more.
- **A tagged door** has a bright paper auction tag hanging on it. The players are in the
  building because they won an auction, so a tag fits the story. A tagged unit always has a
  find in it. It is also twice as likely as a plain unit to have a monster in it.
- **A padlocked door** is already in the game. It needs bolt cutters, and it has the best finds
  and the highest chance of a monster. It stays as it is.

About one door in five would be tagged, to start with.

**What the player sees.** Walking down a hall, you spot a tag two doors along. You know there
is something worth having behind it, and you know it is the most likely door in the hall to
have a monster. So the team has a small decision to make at that door, instead of just working
down the row.

**Why.** Opening a door is a bet. A bet is more fun when you can see the odds before you make
it.

**Where the idea comes from.** Fortnite's treasure chests glow and hum, so you know one is
close and go looking for it. Escape from Tarkov has locked "marked rooms" that every player
knows hold its best loot, which is already the reason the padlocked units work the way they do.

### 5. Clues to where the notes are

**How it works today.** A floor has two notes (floors 1 and 2) or four (the floors above), each
in a different section of the floor. Nothing tells you where. You find them by opening
everything.

**What I'd change.** Two clues, one from far away and one from close up.

- **On the corner map,** each section of the floor that still has an unfound note in it is
  marked. When someone finds that note, the mark goes away. This tells the team which part of
  the floor to search. It doesn't tell them which door.
- **On the door itself,** a unit with a note inside has a small pencil mark on its door frame.
  In the story Dale hid the notes, so it is his mark. You can only see it from a few steps
  away, with your flashlight on it.

**What the player sees.** The map shows there is still a note in the east section. You walk
its halls with your flashlight on the door frames, find the pencil mark, and open that door.

**Why.** It makes searching something you can be good at. Today a careful player and a careless
one both end up opening every door.

**Where the idea comes from.** The library in DOORS, at door 50. The books that hold the code
stick out from the shelves a little, and a sheet of paper tells you what order the digits go
in. You search by looking, not by trying everything.

**The risk.** It could make floors too quick. If it does, the pencil mark gets fainter on
higher floors, or isn't there at all up there.

### 6. A timing tap that opens a door quietly (untested)

**What I'd change.** As a door rises, a small bar shows on screen with a marker moving across
it. If you tap while the marker is inside the highlighted part of the bar, the door finishes
opening without its rattle, so monsters nearby don't hear it. If you miss, or don't bother, the
door opens loudly, the same as it does today. You can never do worse than you do now.

**Why.** Opening a door is the thing a player does most, and right now there is no skill in it.

**Where the idea comes from.** Dead by Daylight has a timing tap while you repair a generator,
and Dandy's World has one while you work a machine.

**Why I'm unsure.** Neither game puts it on something you do as often as you open doors here,
and it could get tiring. The game also already lets you peek under a door quietly to check for
a monster, so this might be one thing too many. I'd build it last in this part, or not at all.

### What we'd sell in Part 1

Nothing. This part is what gives cash a reason to exist, and everything we sell later depends
on players wanting cash and finds.

One thing has to be built alongside it that players won't see: saving (idea 31). Quarters that
turn into cash need somewhere to be kept.

---

## Part 2: The lights, and the building coming for you

**How it works today.** The hall lights are motion lights. They come on when you move under
them and go out a few seconds after you stop. The design doc says that each light that comes on
tells the building where something is, and the building sends a monster to look. That second
half isn't built. The lights come on, and nothing is sent.

The only monster in the game is the Mannequin, which can only move while no light is on it.
Your flashlight never runs out. Put those together and light is only ever good for you: a
player who keeps moving, or keeps a flashlight on the Mannequin, is safe. The line planned for
the thumbnail is "Don't move. The lights are watching." Right now the game plays the opposite
way.

The design doc also has four ways to move (standing still, crouch-walking, walking and
sprinting), each one setting off a different number of lights. The game has one walking speed
and none of the others.

**My worry about building it the way the design doc says.** If every light you walk under calls
a monster, then walking is what gets punished, and walking is most of what you do on a floor. I
think players would end up crouch-walking everywhere at half speed, which is slow. I also think
a danger that never switches off stops feeling like danger after ten minutes.

I could be wrong. The design doc's version sets up a real squeeze: move and the building sees
you, stand still and the Mannequin closes in. Nobody has played it yet, because it isn't built.
So ideas 7 to 9 are my alternative, and at the end of this part I say how you could try the
design doc's version first.

### 7. A "don't move" moment about once a minute

I've been calling this the inspection.

**What the player sees, in order.**

1. The PA speakers click and a voice says "Inspection." The small sensor domes on the ceiling
   turn red (they are already in the game, one beside each light), and the hall lights go out.
2. For the next five seconds, if you move while you are in a hall, the dome above you catches
   it, and the nearest monster heads for that spot.
3. If you stand still, nothing happens. If you are inside a unit you can move as you like,
   because there are no sensors inside units. That is already the design doc's rule.
4. After five seconds the lights come back and the domes go back to normal.

This would happen about every 75 seconds. Outside of those five seconds the lights never call a
monster, so the rest of the time you can walk around freely.

**What it does with the Mannequin.** The Mannequin moves when it is dark, and an inspection
makes it dark. So for those five seconds the Mannequin can walk and you can't. Your flashlight
still stops it, and turning on the spot wouldn't count as moving. So if the Mannequin is close,
you stand where you are and turn to keep your beam on it until the lights come back. I think
those would be the scariest five seconds in the game. But putting those two rules together is
my own idea and I don't know a game that does it, so it is on the untested list at the end.

**Why.** Everyone on the floor gets the same warning at the same moment and has to react.
Somebody shouts "don't move". It is short enough to stay tense every time it happens. And it
makes the thumbnail line true inside the first two minutes of play.

**Where the idea comes from.** Red Light, Green Light, one of the best-known rules on Roblox:
freeze when you're told to, and moving gets you caught. And Rush in DOORS: the lights flicker
as a warning, and you have a few seconds to react before it arrives.

**What this changes.** Your first idea for this game was that the lights are always watching.
This makes them watch for five seconds at a time. That is why it is the first of the four big
decisions in `OWNER.md`.

### 8. A "get inside" moment, from floor 3 up

I've been calling this the clock striking.

**What the player sees, in order.**

1. Somewhere on the floor a clock starts to wind up. The sound gets louder over four seconds.
2. The clock strikes, and every light on the floor flashes on at once.
3. Anyone standing in a hall at that moment has been seen. Every monster that is loose on the
   floor heads for them.
4. Anyone inside a unit with the door pulled down is fine.

It would happen once or twice on each floor, starting on floor 3.

**Why.** It asks for the opposite reaction to idea 7. In an inspection you freeze where you
are. When the clock winds up, you run for the nearest open unit and pull the door down. Two
different warnings with two different answers keep either one from getting stale. This one also
makes players pay attention to which units near them are open.

**Where the idea comes from.** The design doc's own list of monsters has one called
Grandfather: a clock whose chime flashes every light, with the rule "be inside a unit when it
chimes". Your note of Nov 10 says the list of monsters is being rethought, and names Rush in
DOORS as the hit-game version of that rule. I'm suggesting we keep the rule and make it
something the building does, so no monster has to be built for it.

### 9. A floor gets more dangerous if the team stays too long

I've been calling this closing time.

**What I'd change.** Each floor allows a fair amount of time: four minutes on floors 1 and 2,
six minutes on the floors above. If the team is still on the floor when that runs out, the PA
announces closing time. From then on, inspections (idea 7) come twice as often, and once a
minute one of the sleeping monsters on the floor wakes up and starts walking the halls. It
keeps getting worse until the team leaves.

**Why.** If every door pays (idea 1), the smart thing to do is open all of them, slowly and
safely. Something has to push the other way, so that "one more unit" is a risk the team argues
about. A team that moves at a good pace would never hear the announcement.

**Where the idea comes from.** Lethal Company. More monsters come out the later in the day it
gets, and the ship leaves at midnight whether you are on it or not.

**You cut something like this before.** On Nov 2 you cut a clock that ran across the whole
climb, because no hit game had one. This clock runs for one floor and starts again on the next,
which is how Lethal Company's day works. If what you disliked was any clock that punishes slow
play, cut this one too.

### 10. A wrong code should cost the team something

**How it works today.** If you type a wrong code, an alarm sounds for three and a half seconds
and every light on the floor comes on. Because the Mannequin can't move in light, that freezes
it for about seven seconds. So a wrong code makes the team safer.

That opens a trick. The design puts one note on every floor in a unit with an awake monster in
it, so that no floor is finished without a chase. But once the team has three of the four
digits, the last one can only be one of ten numbers. They can stand at the keypad and try all
ten. Each wrong try costs three and a half seconds and freezes the Mannequin. They never have
to go near the guarded note.

**What I'd change.**

- On a wrong code the hall lights go out for the length of the alarm, instead of coming on.
- Every loose monster heads for the keypad. The design doc already says this.
- The keypad stays locked for longer each time on the same floor: 3.5 seconds after the first
  wrong code, 7 after the second, 14 after the third.

Guessing the last digit is still allowed. It becomes a gamble.

**Where the idea comes from.** The library in DOORS again. Players are allowed to guess the
last digit of the code there, but they do it with a monster walking the room.

### 11. Keep one walking speed

**What I'd change.** Nothing in the game. I'd take the four ways to move out of the design doc.
The game has one walking speed and plays well with it. With ideas 7 and 8 in place,
crouch-walking and sprinting aren't needed for the lights any more, and that is two fewer
buttons on a phone.

### 12. The next monster should be one that light doesn't stop

**What I'd change.** Today the only monster stops whenever light is on it, so there is never
anything a player has to run away from. Whichever monster gets built next, I'd make it one that
ignores light, and I'd make it the one that comes when an inspection catches somebody moving.
Which monster that is belongs to your Nov 10 note about rethinking the list. I am only saying
what gap the second one should fill.

### What we'd sell in Part 2

Nothing, now or later. These are the rules that decide whether you get caught. If Robux could
soften them, anyone who didn't pay would feel the game was rigged against them.

### If you would rather keep the lights always watching

Build it the way the design doc says, with a monster sent to every light that comes on, and
judge it in the first run with friends before you decide on ideas 7 to 9. The lights already
report every time one comes on. Nothing listens to that report yet, so it could be tried
without much work.

---

## Part 3: Getting to the elevator, and what you take with you

**How it works today.** When the right code goes into the keypad, the elevator gate opens and a
30-second countdown starts. At zero the gate shuts and the elevator leaves. Anyone not inside
is left behind. The moment that is meant to make this game is the last friend sprinting for the
gate.

In practice the keypad is right beside the elevator, so a careful team gathers there first and
then types the code. Nobody is far away when the countdown starts, so the 30 seconds rarely
catch anyone. And there is nothing to carry, because finds can't be taken.

### 13. Small finds are picked up with a tap and shared by the team

**What I'd change.** Small finds (a lamp, a box of records, a toaster) are picked up with one
tap. They go into one pile for the whole team, shown as a count on screen. They don't use up
either of your two tool slots and they don't slow you down.

**Why.** It is quick, it works on a phone, there is no inventory screen to manage, and friends
aren't racing each other for items.

**Where the idea comes from.** DOORS, where gold is picked up with one tap.

### 14. One big find on each floor, carried in both hands

**What I'd change.** From floor 2 up, each floor has one big find somewhere on it: a jukebox,
say, or an arcade machine. It is worth several times what a small find is. To take it you pick
it up in both hands. While you carry it you walk slower than any monster and you can't use a
tool. You can put it down whenever you like. It only counts if it is set down inside the
elevator before the gate shuts.

**What the player sees.** The team finds a jukebox at the far end of the floor. Somebody has to
carry it back, slowly, while a friend walks beside them keeping a flashlight on the Mannequin.
If the code has already gone in, they have 30 seconds to get a jukebox to the elevator.

**Why.** This is what puts people out on the floor when the countdown starts, and the 30
seconds only work if someone is out there. It is one per floor and no more, so the game stays
an escape. Your note of Nov 11 says the climb is "an escape, not a haul".

**Where the idea comes from.** Lethal Company: the big items take both hands and slow you
down, and only what gets back to the ship counts. The design doc also already has the rule
that carrying a big find is the one thing that makes you slower than a monster.

### 15. Everyone in the elevator gets their own copy of what's in it

**What I'd change.** When the gate shuts, the game looks at what is inside the elevator: the
team's pile of small finds, and the big find if it made it. Every player in the elevator gets
their own copy of each one. If four players get a jukebox aboard, all four of them now own a
jukebox. A player who isn't in the elevator gets nothing from that floor.

**Why.** Nobody argues about who keeps the jukebox, and nobody runs ahead to grab things before
their friends do. It also means being left behind costs you something, even with a way back
into the climb (idea 18).

**Where the idea comes from.** Dandy's World pays every player for each floor the team clears,
whoever did the work. Lethal Company counts everything on the ship for the whole crew.

### What we'd sell in Part 3

Nothing. The design doc has a rule that Robux never sit beside a timer. Selling extra seconds
on the gate would be selling the game's best moment.

---

## Part 4: When a monster catches you

**How it works today.** A monster that catches you wraps you in shrink-wrap and puts you in a
unit somewhere on the floor. It is dark in there. You can bang on the door so your friends can
find you, which also draws monsters. A friend who opens your unit holds a button for one second
and you are free. If nobody comes within two and a half minutes, the building padlocks your
unit, and then a friend needs bolt cutters to get you out.

When the elevator leaves without you, whether you were caught or just late, you are out for
the rest of the climb. You watch your friends play. The design doc's plan is to sell the way
back in (Cut Free). If you are playing alone, one catch ends the climb, because nobody is there
to free you.

**The problem.** In a ten-floor climb of about 50 minutes, a player left behind on floor 2
could be watching for 40 minutes. Most people won't. They'll leave, and their friends often
leave with them. The best moments in this game need the group together.

### 16. Tell the player what got them

**What I'd change.** One line on the screen you see when you're caught, saying what caused it:
"You moved during an inspection", or "It heard the door".

**Why.** A player who knows why they were caught learns the rule. A player who doesn't thinks
the game cheated.

**Where the idea comes from.** DOORS shows a short explanation after each death: what killed
you, and how to survive it next time.

### 17. A slow, loud way to free yourself

**What I'd change.** While you're wrapped, you can hold a button to strain against the wrap.
The first time in a climb it takes 25 seconds of holding. Each time after that it takes 15
seconds longer: 40, then 55. It is loud the whole time, so monsters nearby hear it. It stops
working once your unit has been padlocked. After that you need a friend with bolt cutters, as
now. A friend cutting you free still takes one second, so being rescued is always much better.

**Why.** It makes playing alone possible. And it gives a caught player something to do other
than wait.

**Where the idea comes from.** Dead by Daylight lets a player on a hook try to get themselves
off it, slowly and with risk. That is a loose fit: theirs is a gamble and this is a wait.

### 18. A friend who is left behind turns up on the next floor

**What I'd change.** If the elevator leaves without you, you watch your friends during the
ride, as now. When they arrive at the next floor, you are on it too: wrapped, inside one of
that floor's units. You bang on the door, they find you and cut you free, the same as any other
rescue. If they don't find you before that floor's gate shuts, you are carried up again to the
floor after it. You come back with empty hands, and you got none of the finds from the floor
you missed.

**Why.** Nobody sits out the rest of a climb. It turns a friend who was lost into a rescue on
the next floor, which is a better moment than watching. And it fits a line the design doc
already has about the building: "Everything it keeps goes up."

**Where the idea comes from.** R.E.P.O. When a player dies, their head is left where they
fell. A teammate carries it to the extraction point and the player is back. Lethal Company
brings dead players back when the ship takes off.

**You cut this before.** On Nov 2 you cut this exact rule because no hit game did it. I think
R.E.P.O. now counts as one. It is your call, and it is the second of the four big decisions in
`OWNER.md`.

### 19. Something to do while you wait to be rescued

**What I'd change.** While you're wrapped in a unit, you can bring up a map of the floor that
shows every hall light and which ones are on right now. You can't tell what turned a light on,
only that something did. You tap a spot on that map and a mark shows up there on your friends'
corner maps, as a way of saying "something is moving over here".

The design doc already has this map. It calls it the office light board, and puts it in an
office on the floor for one player to stand at. I doubt anyone would choose to stand in an
office while their friends open doors. Someone who is stuck waiting would use it.

**Where the idea comes from.** Among Us lets players who are out keep doing tasks that help
their team. Marking spots for friends is my own addition, so it is on the untested list.

### What we'd sell in Part 4

This is where the first real money is. All of it is offered only on the screen you see while
you're caught. Nothing ever pops up over play.

- **Cut Free** (45 Robux, then 75 if you buy it again in the same climb). It frees you right
  now, without the noise, on the floor you're on, with your tools. If you were left behind, it
  puts you standing in the elevator when it reaches the next floor, tools in hand, instead of
  wrapped in a unit waiting to be found.
- **Free a Friend** (49 Robux). You pay to free a friend who is caught, from wherever you are
  standing.
- **Free Everyone** (149 Robux). It frees every caught player at once. If the whole team has
  been caught, it is offered before the results screen, and the climb carries on from that
  floor.
- **Wrap colours** (99 to 499 Robux). The colour or pattern of the shrink-wrap you get wrapped
  in. It is what your friends see when they find you.
- **Gift versions** of each, so one player can buy for another. DOORS and 99 Nights in the
  Forest both sell these.

The prices are the design doc's drafts, taken from what other games charged on Nov 2.

**What this does to the money, honestly.** With ideas 17 and 18, nobody has to pay to keep
playing. What Robux buys is time (skipping 25 noisy seconds, or skipping the wait to be found),
keeping your tools, and not missing a floor's finds. Fewer people will buy that than would buy
"pay or sit out for half an hour". My bet is that a game where friends stay together to the end
keeps more players for more days, and that those players buy more cosmetics and passes. I can't
prove that. It is a real trade and it's yours to make.

---

## Part 5: The shape of a whole climb

**How it works today.** The plan is ten floors in about 50 minutes. Three floors are built. The
elevator ride between floors takes just under ten seconds, and there is nothing to do during
it. There is one difficulty.

### 20. Put the roof on floor 5 for launch

**What I'd change.** A full climb at launch is five floors and takes about 20 to 25 minutes.

- **Floors 1 and 2** are short, with two notes each. They teach doors, quarters and the "don't
  move" moment (idea 7).
- **Floors 3 and 4** are full size, with four notes each. They add the "get inside" moment
  (idea 8), a note behind a padlock, and the second monster (idea 12). The design doc starts
  padlocked notes on floor 6; I'd bring them down.
- **Floor 5** is Dale's floor, as the design doc has it, if Dale survives your rethink of the
  monsters. The last digit of the code is pinned to him. To read it the team has to trap him,
  using the trap that is already in the game: saw a hole between two units, lead him into one,
  crawl through the hole and slam the door on him. After that, the roof.

Floors 6 to 10, the stairwell chase and the ending where you cut the power all come later, as
updates. The design doc already plans for the building to get taller over time.

**Why.** With ten floors, most players wouldn't see the roof for weeks. With five, a good team
reaches it in one sitting and wants to do it again the same evening. It is also about half the
building work before launch. The design doc already asks this as an open question ("Roof at
floor 10, or lower?").

**Where the idea comes from.** DOORS puts its first big set piece at door 50, halfway: a hunt
for a code with one monster hunting you. Floor 5 here is the same thing.

**This is the third of the four big decisions in `OWNER.md`.**

### 21. A team vote during the elevator ride

**What I'd change.** The ride would take about 20 seconds. The design doc says 40, which I
think is a long time to stand in a box. The game has just under 10, which is too short to do
anything.

On the rides after floor 1 and after floor 3, three cards appear on the elevator wall. Each
card names one advantage. Every player taps the card they want, and the card with the most
votes wins. The whole team then has that advantage until the climb ends.

Every card is an advantage and nothing else. No card makes anything worse. You cut the version
with downsides on Nov 2.

Cards to start with (the first two are the design doc's own examples):

- The gate stays open five seconds longer: 35 seconds instead of 30.
- Everyone's flashlight beam is wider.
- The first door each player opens on every floor opens silently.
- Freeing yourself from the wrap takes half as long (idea 17).
- Tagged doors show on the corner map (idea 4).

**Why.** Two climbs with different cards play differently. It is also a decision the whole team
makes together during a calm moment, which is when friends talk.

**Where the idea comes from.** Dandy's World has a card vote in its elevator between floors.
The design doc already names it.

### 22. A vending machine in the elevator

**What I'd change.** On the rides after floor 2 and after floor 4, a vending machine in the
elevator wall lights up. It shows three or four tools, each with a price in quarters: a padlock
for 6, say, or bolt cutters for 10. Those prices are guesses to start from. You tap one to buy
it with your own quarters.

The ride from the lobby up to floor 1 has neither the vote nor the machine. A new player should
get to their first door fast, and nobody has any quarters yet.

**Why.** It is what the quarters from idea 1 are for. It lets a team that is short of a tool
fix that before the next floor.

**Where the idea comes from.** Dandy's World has a shop in its elevator on the rides that don't
have the card vote. The design doc already names this too.

### 23. Make trapping a monster worth doing

**How it works today.** You can trap a monster in a unit by slamming the door on it. It bangs
on the door and breaks out after 90 seconds, unless you padlock the door. The design doc says
two things about trapping. The first time you trap each kind of monster is recorded in your
collection book, with no other reward. And a trapped monster doesn't count toward the floor's
limit on how many monsters can be awake at once, so "the next door can hold a fresh one".

**What I'd change.** Two things.

- **A trapped monster still counts toward the floor's limit.** As the design doc has it,
  trapping one monster makes room for another to wake up, so the trap gains the team nothing.
  With this change, trapping buys 90 quieter seconds, or a quieter rest of the floor if the
  door is padlocked. The limit itself isn't built yet, so this is a change to the plan.
- **The first time you trap each kind of monster unlocks one perk** that you can then buy with
  cash. Perks are in idea 30. For example, trapping the Mannequin might unlock a flashlight
  that reaches further.

**You dropped something like this before.** On Nov 9 you dropped a cash bonus for trapping.
This isn't cash, but it is still a reward for trapping. Say if that's still too much.

**Where the idea comes from.** In Dandy's World some trinkets (its version of perks) can't be
bought until you have done a particular thing to unlock them.

### 24. A new rule each week, instead of a new monster each week

**What I'd change.** The design doc plans a new monster every Saturday. Every monster needs a
model, animations, sounds and testing. I don't think that can be done well every week. Instead,
a board in the lobby would announce one rule that changes every climb for that week: "The power
is out, so every floor is dark", or "Inspections come twice as often". A new monster would
arrive with each batch of new floors.

**Where the idea comes from.** DOORS has modifiers, which are rules a player can switch on to
change a run. The design doc's own weekly plan already has a smaller rule change on Tuesdays.

### What we'd sell in Part 5

- **A starting tool, for cash, not Robux.** This is already in the design doc. In the lobby,
  during the countdown before a climb, you can spend cash to start with one tool of your
  choice. It is the main thing cash is for (Part 6), and it costs cash every climb.
- **A third tool slot** (199 to 299 Robux, bought once and kept forever). You carry three tools
  instead of two. Your note says to sell slots up to six. I would sell one. Choosing which
  tools to bring is part of the game, and with six slots you carry everything. That question is
  already in `OWNER.md`.
- **Flashlight beam colours** (49 to 299 Robux). In a dark hall the beams are what everybody
  sees, so this is the cosmetic that shows the most.
- **Nothing on the cards.** There would be no paying to draw three new cards. Roblox treats
  paying for a random result as a paid random item, and those come with rules about showing the
  odds and about young players.

---

## Part 6: After the climb

**How it works today.** After a climb you are back in the elevator in the lobby, with the
results on its wall: whether you made it or were caught, the floor you reached, your time, and
an "Again" button. Nothing is saved. There is no cash, and finds can't leave the building.

### 25. The results screen values your finds one at a time

**What I'd change.** Each find the team got out comes up on the results one at a time: its
picture, its name, how rare it is, and what it is worth. The cash total counts up with each
one. Any quarters you didn't spend are added at the end. After that there is one line for each
player, such as who freed the most friends, who opened the most doors, and who shut a friend
in a unit.

**Why.** It makes each find exciting twice: once when you open the door and see it, and once
when you learn what it was worth. It also happens at the moment players are happiest, which is
the moment they decide whether to press "Again".

**Where the idea comes from.** The storage-auction TV shows this game's setting comes from,
where the unit is opened first and valued afterwards. That is television and not a hit game, so
it is on the untested list. Lethal Company does end each day with a report on how each player
did.

### 26. A collection book with a page for every find

**What I'd change.** The design doc already has a book called the Catalog. It records the
monsters you have trapped, Dale's notes, and sets. I'd add a page for every kind of find. The
first time you bring one out of the building, its page is stamped "New" on the results screen.

Sets stay as the design doc has them: groups of finds that belong together, such as a 1980s
bedroom or a diner. Finishing a set gives you a display piece for your unit.

**Why.** It gives a player a reason to want one particular find, and a reason to climb again
when they didn't get it.

**Where the idea comes from.** Fisch. Every fish you catch fills in its own entry in a book,
and finishing a section of the book pays a reward.

### 27. Rare versions of ordinary finds

**What I'd change.** About one find in twenty turns up still sealed in its original packaging.
It is the same item, worth three times as much, shown in its packaging, with its own stamp in
the collection book.

**Why.** Any ordinary find might turn out to be the special one, so common finds stay worth
looking at.

**Where the idea comes from.** Fisch and Grow a Garden. Both have rare versions of ordinary
things that multiply what they're worth. The "still sealed" look is my own choice, so that part
is on the untested list.

### 28. Selling and keeping without a menu

**What I'd change.** After the valuing in idea 25, the game sorts your finds for you. Anything
you already own a copy of, and anything common, is sold for cash on the spot. Anything rare
that you don't already own goes to your unit in the lobby, and you can sell it from there
later if you want. Every kind of find gets its page stamped in the collection book either way.

**Why.** Nobody wants to manage an inventory screen on a phone between climbs.

### 29. Your unit, and a shelf in the elevator to show finds off

**What I'd change.** The design doc plans a hall of units in the lobby, one for each player,
where your finds are on show and friends can walk in. The unit is already modelled in three
sizes. You would spend cash to move up from small to medium to large, so you can show more.

That hall is a lot to build, so I would do it after launch. Until then, a shelf inside the
elevator would show the three best finds of whoever is hosting that elevator, which is the
first player to step into it in the lobby. Everyone who rides with them sees it on every climb.

**Why.** A find nobody else ever sees isn't worth much to the player who owns it.

**Where the idea comes from.** Lethal Company. Things the crew buys are set out on the ship,
where everyone sees them between trips.

### 30. Perks: small advantages you own and pick before a climb

**What I'd change.** A perk is a small advantage that you own for good. Before a climb you
pick two of the perks you own to use, and you can't change them once the climb starts. Each
perk first has to be unlocked by doing something, such as trapping the Mannequin or finishing a
set. Then you buy it with cash.

Perks to start with:

- Cutting a friend free takes half a second instead of one.
- Your flashlight reaches a little further.
- You carry the big find a little faster.
- The rattle of a door you open carries half as far.

They are small on purpose. A new player with no perks can still reach the roof.

**Why.** Cash needs things to be spent on, or selling finds means nothing. Perks also make
what you've collected change how your next climb plays, and they give players goals between
climbs ("I need to trap the Mannequin to unlock that one").

**Where the idea comes from.** Trinkets in Dandy's World. You use two at a time, you choose
them before the run starts, you buy them with the money you earn from runs, and some have to
be unlocked first.

**So cash would buy four things:** a starting tool for each climb, perks, a bigger unit, and
cosmetics.

### What we'd sell in Part 6

- **Double cash** (299 to 399 Robux, bought once and kept forever). All the cash you earn is
  doubled. The default in `OWNER.md` is not to sell this at launch. I would sell it from the
  day the store opens. In a co-op game it doesn't hurt anyone else, and it is the easiest thing
  to want after watching your cash count up on the results. It would be offered at the counter
  and as a small button on the results screen.
- **Cash packs** (49 to 1,499 Robux). You buy cash with Robux. I would only sell these once
  perks and the starting tool exist, so that cash is for something. Once cash can be bought,
  nothing random can ever be sold for cash either. The design doc already says this, because
  Roblox counts bought currency the same as Robux.
- **A starter pack** (99 Robux). It is shown once, after your first climb and never before:
  one beam colour, one wrap colour and some cash.
- **Decor for the elevator and for your unit** (99 to 499 Robux).

---

## Part 7: Reasons to come back tomorrow

### 31. Save the player's progress

**What I'd change.** Nothing is saved today. Cash, finds, the collection book, your best floor
and anything you have bought all need to be saved. Everything in Part 6 depends on it and so
does every product. Players never see this, but it has to be built first. Under the project's
rules it comes from Brix, the shared framework.

### 32. Your best floor, the Missing board and badges

**What I'd change.** All three are in the design doc, and none has a ticket in the roadmap.

- **Best floor.** The highest floor you have reached, shown on a plaque and on the dial above
  your elevator. It is the number friends compare.
- **The Missing board.** A board in the lobby. When a whole team is caught, their photos go up
  on it with the floor they were caught on, until their next climb.
- **Roblox badges** for reaching the roof the first time, for each kind of monster trapped, and
  for each set finished.

### 33. A free door to open once a day

**What I'd change.** The design doc has this as the "free daily sealed lot". Once a day, in the
lobby, you open one roll-up door, slow and loud, the same as in a climb. Inside is a free find.
I'd add a streak: on the seventh day in a row, the find is a better one.

It is never sold, and you can't buy more openings. That would be paying for a random result.

**Where the idea comes from.** Daily rewards with streaks are in most of the big Roblox games.

### 34. A small shelf of cosmetics that changes every week

**What I'd change.** Three cosmetics at the counter that are swapped for three different ones
each week. It gives a player a reason to look at the shop again.

**Where the idea comes from.** Fortnite's item shop, which changes what it sells on a schedule.

### 35. A season pass, after launch

**What I'd change.** Some time after launch: two rows of rewards, one free and one paid. You
earn your way along them by climbing floors. Every reward is shown up front, so nothing in it
is random. I haven't put a price on it.

### 36. Private servers free, or nearly free

**What I'd change.** A private server lets a group of friends play in a server of their own.
This game spreads by friends bringing friends, so I'd make that cost nothing or close to it.
The design doc also notes that Roblox pays the developer a share of what a new player spends
when they arrive through your share link.

### What we'd sell in Part 7

The weekly shelf (idea 34), and later the season pass (idea 35). Everything else in this part
is free on purpose.

---

## The whole store on one page

| What it is | Robux | Where the player sees it | Built in |
| --- | --- | --- | --- |
| Cut Free: free yourself now | 45, then 75 | The screen you see while caught | Step 3 |
| Free a Friend | 49 | The screen you see while caught | Step 3 |
| Free Everyone | 149 | When the whole team is caught, before the results | Step 3 |
| Wrap colours | 99 to 499 | The counter | Step 3 |
| A third tool slot | 199 to 299 | The counter | Step 4 |
| Flashlight beam colours | 49 to 299 | The counter | Step 4 |
| Double cash | 299 to 399 | The counter, and the results screen | Step 5 |
| Cash packs | 49 to 1,499 | The counter | Step 5 |
| Starter pack | 99 | Once, after your first climb | Step 5 |
| Decor for the elevator and your unit | 99 to 499 | The counter, and the weekly shelf | Step 5 |
| Season pass | not priced | The lobby | After launch |
| Gift versions | the same | Beside each product | With each one |

The prices are the design doc's draft ranges. A starting tool, perks and a bigger unit cost
cash, not Robux.

**The rules these follow.** All of them are already in the design doc or in your lobby and
store plan of Nov 11.

- Nothing random is ever sold, for Robux or for cash.
- Robux never sit beside a timer.
- Nothing a player buys makes the game worse for another player.
- Quarters, the daily door and the cards on the ride are never sold.
- Nobody can pay to skip a floor.
- The shop never interrupts play.
- A purchase is never lost, even if saving fails or the player moves to another server.
- Any offer can be switched off without updating the game.
- Prices are read from Roblox and never typed into the game.

## What I'd drop or put off

- **Crouch-walking and sprinting.** Drop them from the design doc (idea 11).
- **Trading finds between players.** Put it off until well after launch. It brings scams, people
  selling items for real money, and extra care around young players. The design doc already
  lists "trading at launch, or later?" as an open question.
- **Finds that are monsters in disguise, fake notes, the monster that moves walls, and the
  dolly.** Each one adds a rule on top of a game whose basic rules haven't been played by
  anyone yet. They can come with the later floors.
- **Floors 6 to 10, the stairwell chase and the ending where you cut the power.** After launch,
  as updates (idea 20).
- **A new monster every week.** A new rule every week instead (idea 24).
- **The light board as a post for a player who is still free.** It becomes something a caught
  player uses (idea 19).
- **The hall of units in the lobby.** After launch. The shelf in the elevator comes first
  (idea 29).

## The order I'd build it in

Each step builds a piece of the game and the things sold with that piece together.

**Step 0. Play what's built with friends.** Before any of this, play the three floors that
exist with real people. Only you can run that. If they ask for another go, the base is fun and
these ideas are improvements to it. If they don't, what they say will tell us more than this
document does. Nothing is sold.

**Step 1. Doors that pay.** Quarters in every unit, small finds you can take, tagged doors,
about half the units, clues to the notes, everyone in the elevator getting a copy, saving, and
a results screen that shows the cash you earned (ideas 1 to 5, 13, 15, 31, and a plain first
version of 25). Nothing is sold yet. But from here the game records what every player earns and
spends, so we know what things are worth before we put a price on anything. It has worked when
players open more doors a minute than they do now and go for the tagged doors first.

**Step 2. The building's warnings.** The "don't move" moment, the wrong code that costs
something, and closing time. Then the "get inside" moment and the second monster (ideas 7, 9,
10, then 8 and 12). Nothing is sold. It has worked when somebody shouts "don't move" without
having been told the rule.

**Step 3. Getting caught.** What got you, freeing yourself, turning up on the next floor, and
the map for a caught player (ideas 16 to 19). This is where the first products go on sale: Cut
Free, Free a Friend, Free Everyone and wrap colours. So this step also builds buying properly,
so that a purchase is never lost. It has worked when nobody quits a climb because they were
caught.

**Step 4. The shape of the climb.** The roof on floor 5, the vote and the vending machine on
the ride, trapping, and the big find (ideas 20 to 23, and 14). On sale: a starting tool for
cash, beam colours and the third tool slot. It has worked when two climbs in a row feel
different.

**Step 5. After the climb.** Finds valued one at a time, the collection book, rare versions,
selling and keeping, the shelf in the elevator, and perks (ideas 25 to 30). On sale: double
cash, cash packs, the starter pack and decor. It has worked when players watch the results to
the end and change their perks between climbs.

**Step 6. Coming back.** Best floor, the Missing board, badges, the daily door, the weekly rule
and private servers (ideas 24, 32, 33 and 36). The design doc's plan to have Roblox save a
short clip at the big moments goes here too. On sale: the weekly shelf, and later the season
pass (ideas 34 and 35). It has worked when players come back the next day without a friend
asking them to.

The timing tap (idea 6) isn't in any step. It only gets built if you want it.

## What we'd need to measure

The game records nothing today, so none of this can be seen yet.

- How many seconds pass between a player joining and opening their first door. The design doc
  wants 30 or fewer.
- How many doors a player opens in a minute, and how many of those gave them something.
- How often players are caught on each floor, and what caused it each time.
- How many players get left behind, and how many minutes they spend waiting.
- How often "Again" is pressed after a climb.
- Who buys each product, and where in the game they were when they bought it.

## What would change in the design doc if you say yes

By the design doc's own section names:

- **Lights.** "Every lit light always calls a monster" becomes the five-second inspection. The
  four ways to move come out.
- **Doors.** Empty units go. Quarters and tagged doors come in. About half as many units.
- **Getting kept.** Being left behind no longer puts you out of the climb. Freeing yourself is
  new. The light board moves to the caught player.
- **Codes, the elevator and the roof.** A wrong code darkens the floor and locks the keypad for
  longer each time. The ride is about 20 seconds, not 40.
- **The building.** The roof is on floor 5 at launch, and the building grows from there.
- **Tools and traps.** A trapped monster still counts toward the floor's limit. Trapping
  unlocks a perk. I don't know whether the design doc's limit rule was ever your own choice.
- **Meta.** Everyone in the elevator gets a copy of each find. Finds are valued on the results
  screen. Perks are new. The shelf in the elevator is new. Trading is put off.
- **Live ops.** A weekly rule replaces the weekly monster.
- **Monetization.** Double cash and a season pass are added. Everything else is the same list,
  placed where it gets used.

## Three things you cut before that this brings back

I'm listing these so that none of them slips back in without you noticing.

- **A friend who is left behind turns up on the next floor (idea 18).** You cut it on Nov 2
  because no hit game did it. I think R.E.P.O. does now.
- **A clock that makes things worse (idea 9).** You cut one that ran across the whole climb on
  Nov 2. This one runs for a single floor, as Lethal Company's day does.
- **A reward for trapping (idea 23).** You dropped a cash bonus on Nov 9. This is the stamp in
  the collection book that the design doc already has, plus the right to buy one perk.

## Ideas with no hit game behind them

Your rule is that every mechanic names the hit game it comes from. These five don't fully meet
it. None of them gets built unless you take it up.

- **The timing tap on doors (idea 6).** Timing taps are proven. Putting one on something you do
  this often isn't.
- **The Mannequin walking during an inspection (idea 7).** Each half is proven. Putting them
  together is mine.
- **Valuing finds one at a time on the results screen (idea 25).** It comes from television.
- **The "still sealed" look for rare finds (idea 27).** Rare versions that are worth more are
  proven. This look for them is mine.
- **A caught player marking spots for friends (idea 19).** Giving players who are out
  something to do is proven. Marking a map is mine.

## How sure I am about the games I've named

**Checked on the web on Nov 13:**

- R.E.P.O.: a dead player's head is carried to the extraction point and they come back.
- Dandy's World: two trinkets at a time, chosen before the run, bought with its currency, some
  unlocked first; and timing taps on its machines.
- DOORS: gold turns into its lasting currency at the end of a run; a 30-second shop before a
  run; the library's books and its hint paper.
- Lethal Company: more monsters as the day goes on, and the ship leaves at midnight.
- Fisch: rewards for filling in its book of fish.
- Fisch and Grow a Garden: rare versions that multiply what a thing is worth.

**From memory, not checked. Check each one before leaning on it:**

- DOORS: gold in drawers and picking it up with a tap; Rush and its flickering lights; the
  explanation after each death; guessing the last digit in the library; modifiers.
- Dandy's World: tapes spent at a shop in the elevator; every player paid for each floor.
- Lethal Company: two-handed items that slow you down; dead players coming back when the ship
  takes off; the end-of-day report on each player; purchases set out on the ship.
- Dead by Daylight: timing taps on generators; getting yourself off a hook.
- Fortnite: chests that glow and hum; an item shop that changes on a schedule.
- Escape from Tarkov: marked rooms.
- Among Us: players who are out still doing tasks.
- Red Light, Green Light being one of the best-known rules on Roblox.
- Daily rewards with streaks being in most big Roblox games.

**Sources for the checked ones.**
[R.E.P.O. revive, PC Gamer](https://www.pcgamer.com/games/horror/repo-how-to-heal-and-revive/) ·
[R.E.P.O. revive, GamesRadar](https://www.gamesradar.com/games/horror/repo-revive) ·
[Dandy's World trinkets, wiki](https://dandys-world-robloxhorror.fandom.com/wiki/Trinkets) ·
[Dandy's World trinkets, Pro Game Guides](https://progameguides.com/roblox/all-trinkets-in-dandys-world-and-how-to-get-them/) ·
[DOORS Knobs, wiki](https://doors-game.fandom.com/wiki/Knobs) ·
[Lethal Company spawn times, Steam](https://steamcommunity.com/app/1966720/discussions/0/3958162152971622445) ·
[Fisch mutations, Roblox Den](https://robloxden.com/game-codes/fisch/guides/fisch-mutations-guide-types-multipliers-and-how-to-get-them) ·
[Grow a Garden mutations, Sportskeeda](https://www.sportskeeda.com/roblox-news/all-mutations-grow-garden)

## The list, for marking up

Write keep, change or cut beside each.

**Part 1: Opening doors**
1. A few quarters in every unit, so no door is a waste.
2. Quarters are spent during the climb, and whatever is left becomes cash.
3. About half as many units on each floor.
4. Three kinds of door you can tell apart: plain, tagged and padlocked.
5. Clues to where the notes are: a mark on the map, and a pencil mark on the door frame.
6. A timing tap that opens a door quietly (untested).

**Part 2: The lights**
7. A "don't move" moment about once a minute.
8. A "get inside" moment, from floor 3 up.
9. A floor gets more dangerous if the team stays too long.
10. A wrong code costs the team something.
11. Keep one walking speed.
12. The next monster is one that light doesn't stop.

**Part 3: Getting to the elevator**
13. Small finds are picked up with a tap and shared by the team.
14. One big find on each floor, carried in both hands.
15. Everyone in the elevator gets their own copy of what's in it.

**Part 4: Getting caught**
16. Tell the player what got them.
17. A slow, loud way to free yourself.
18. A friend who is left behind turns up on the next floor.
19. A map of the floor's lights for a caught player, who can mark spots for friends.
- Sold here: Cut Free, Free a Friend, Free Everyone, wrap colours.

**Part 5: The whole climb**
20. The roof on floor 5 for launch.
21. A team vote on three cards during the ride.
22. A vending machine in the elevator.
23. Trapping a monster: it still counts toward the floor's limit, and it unlocks a perk.
24. A new rule each week, instead of a new monster each week.
- Sold here: a starting tool (for cash), a third tool slot, flashlight beam colours.

**Part 6: After the climb**
25. The results screen values your finds one at a time.
26. A collection book with a page for every find.
27. Rare versions of ordinary finds, worth three times as much.
28. Selling and keeping without a menu.
29. Your unit grows, and a shelf in the elevator shows the host's best three finds.
30. Perks: small advantages you own, two picked before each climb.
- Sold here: double cash, cash packs, a starter pack, decor.

**Part 7: Coming back**
31. Save the player's progress.
32. Best floor, the Missing board and badges.
33. A free door to open once a day, with a seven-day streak.
34. A small shelf of cosmetics that changes every week.
35. A season pass, after launch.
36. Private servers free, or nearly free.
