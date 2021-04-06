----------------------------------------------------------
--BIO GEN
--[[
Biography.

Who is the character for this life?
Displayed on Char_tab.'

Gives sense of character.

Each life is a chance to behave different, try new strategies, methods, modes of being.
The traits suggested are a primer to do things different than your normal patterns.

"[Outgoing] and [diligent],
 [Bob] had lived a [miserable] life,
until one day [he][picked a fight with the wrong people].... "


]]


local random = math.random

----------------------------------------------------------
local gender = {
   male= "he",
   female= "she"
}

--Big Five
--(try to make sure different than virtues!)
local personality = {
  --openness
  "Conventional",
  "Unconventional",
  "Practical",
  "Imaginative",
  "Unadventurous",
  "Adventurous",
  "Traditional",
  "Rebellious",

  --conscientiousness
  "Organized",
  "Disorganized",
  "Goal-driven",
  "Impulsive",
  "Dutiful",
  "Careless",
  "Precise",
  "Slapdash",

  --extraversion
  "Shy",
  "Gregarious",
  "Quiet",
  "Outgoing",
  "Withdrawn",
  "Sociable",
  "Reserved",
  "Expressive",

  --agreableness
  "Pleasant",
  "Argumentative",
  "Good-natured",
  "Critical",
  "Soft-hearted",
  "Suspicious",
  "Gullible",
  "Cynical",

  --neuroticism
  "Calm",
  "Neurotic",
  "Steady",
  "Unstable",
  "Self-satisfied",
  "Moody",
  "Complacent",
  "Paranoid"

}

--Misc Virtues
local virtue = {
  "courageous",
  "temperate",
  "charitable",
  "extravagant",
  "magnaminous",
  "patient",
  "honest",
  "witty",
  "friendly",
  "modest",
  "just",
  "ambitious",
  "assertive",
  "benevolent",
  "brave",
  "caring",
  "chaste",
  "cautious",
  "fastidious",
  "committed",
  "compasionate",
  "confident",
  "considerate",
  "contented",
  "cooperative",
  "courteous",
  "creative",
  "curious",
  "defiant",
  "dependable",
  "determined",
  "devoted",
  "diligent",
  "discerning",
  "discrete",
  "disciplined",
  "eloquent",
  "empathic",
  "enthusiastic",
  "faithful",
  "flexible",
  "focused",
  "tolerant",
  "forgiving",
  "strong",
  "frugal",
  "gentle",
  "graceful",
  "grateful",
  "helpful",
  "honorable",
  "hopeful",
  "humble",
  "comical",
  "idealistic",
  "virtuous",
  "impartial",
  "industrious",
  "innocent",
  "joyful",
  "kind",
  "knowledgeable",
  "loving",
  "loyal",
  "noble",
  "dignified",
  "merciful",
  "moderate",
  "peaceful",
  "persistent",
  "prudent",
  "purposeful",
  "reliable",
  "resolute",
  "resourceful",
  "respectful",
  "responsible",
  "reverent",
  "righteous",
  "selfless",
  "sensitive",
  "contemplative",
  "sincere",
  "sober",
  "spontaneous",
  "steadfast",
  "tactful",
  "thrifty",
  "tough",
  "tranquil",
  "trusting",
  "trustworthy",
  "understanding",
  "vigorous",
  "wise",
  "zealous"

}


--State of former life
--(ought to contrast with the world of Exile)
local life = {
  --good
  "a good",
  "a happy",
  "a pleasant",
  "an enjoyable",

  --dull
  "a boring",
  "an uneventful",
  "a mediocre",
  "a dull",
  "a humdrum",

  --easy
  "a comfortable",
  "a satisfied",
  "a soft",
  "an easy",

  --normal
  "a normal",
  "an average",
  "an unremarkable",

  --small
  "a restricted",
  "a narrow-horizoned",
  "a homely",
  "a constricted",

  --not good
  "a frustrated",
  "an empty",
  "an unfulfilling",
  "a sorrowful",
  "a mournful",
  "a long-suffering",

  --work
  "an overburdened",
  "a hardworking",
  "a slave-like",

  --social
  "a family centred",
  "a communal",
  "a self-centred",
  "a selfless",
  "a solitary",
  "a low-born",
  "an aristocratic",

  --moral
  "a well respected",
  "an upstanding",
  "a patriotic",
  "an honorable",

  --wasted
  "a dissapated",
  "a dissolute",
  "a slothful",
  "an indulgent",
  "a misspent",

  --weird
  "an eccentric",
  "an oddball",
  "a strange"


}


--what went wrong
local woe = {
  --bad business
  "made a bad bargain",
  "made a deal with the wrong people",
  "sold out and got screwed",
  "was made an offer too good to be true",
  "saw a fantastic opportunity",
  "took a gamble",
  "found a new way to make a living",

  --emotion
  "lost all hope",
  "fell into despair",
  "discovered a great passion",
  "found a source of great joy",
  "was provoked to anger",
  "lashed out",
  "snapped",
  "couldn't take it anymore",
  "decided love was dead",
  "felt like the world didn't care",
  "was disgusted by life",
  "became obsessed",

  --fight the power
  "stood up for the truth",
  "spoke truth to power",
  "took a stand",
  "picked a fight with the wrong people",
  "raged against the machine",
  "fought for justice",
  "gave everything for the cause",
  "rose up against the oppressor",

  --wrong type of person/corruption
  "got persecuted by the intolerant",
  "refused to conform",
  "refused to hide anymore",
  "chose to live differently",
  "saw things others did not see",

  --life change
  "decided not live that way anymore",
  "thought life needed shaking up",
  "made a few minor changes",
  "had an epiphany",
  "took up a new hobby",

  --crime
  "got in too deep",
  "chose the wrong path",
  "thought no one would notice",
  "got caught",
  "got snitched on",
  "screwed up a sure thing",

  --poverty
  "fell on hard times",
  "done what needed to be done",
  "did what it took to feed the family",

  --politics
  "picked the wrong side",
  "took a chance to grab power",
  "ended up on the losing side of history",
  "offended a powerful man",
  "offended a powerful woman",
  "provoked the jealousy a rival",

  --random acts
  "was just passing by when",
  "had an accident",
  "was mistaken for someone else",
  "was imprisoned on false charges",
  "got caught up in someone else's mess",
  "witnessed what was supposed to be a secret",

  --one stupid mistake
  "made one bad decision",
  "said one wrong thing",
  "gave into temptation",
  "had a momentary lapse of judgement",
  "started something too big",
  "lost control",
  "followed bad advice",
  "had too much to drink",
  "learnt the truth too late",
  "committed a simple indiscretion",
  "had a great idea",
  "misjudged the situation entirely",

  --romance/family
  "fell in love",
  "had an affair",
  "gave everything for love",
  "had a son",
  "had a daughter",
  "discovered a long lost relative",
  "got mixed up in a love triangle",

  --weird
  "got involved with a travelling magician",
  "met a man with two heads",
  "found a bird that could predict the future",
  "ate some weird beans",
  "tried to learn the flute",
  "was given a secret map",
  "discovered a secret chamber",
  "saw a ghost",
  "recieved a vision from the other side",
  "had a dream that explained everything",
  "built a perpetual motion machine",
  "learned the meaning of life"



}




lore.generate_bio = function(player)
  local text = ""

  local meta = player:get_meta()
  local gend = player_api.get_gender(player)

  local persona = personality[random(#personality)]
  local virt = virtue[random(#virtue)]
  local your_name = meta:get_string("char_name")
  local lif = life[random(#life)]
  local your_woe = woe[random(#woe)]


  text =
    "\n "..persona.." and "..virt..","..
    "\n "..your_name.." had lived "..lif.." life,"..
    "\n until one day "..gender[gend].." "..your_woe.."...."

    meta:set_string("bio", text)

  return text
end
