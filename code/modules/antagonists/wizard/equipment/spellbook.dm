/datum/spellbook_entry
	var/name = "Entry Name"

	var/spell_type = null
	var/desc = ""
	var/category = "Offensive"
	var/cost = 2
	var/refundable = TRUE
	var/surplus = -1 // -1 for infinite, not used by anything atm
	var/obj/effect/proc_holder/spell/S = null //Since spellbooks can be used by only one person anyway we can track the actual spell
	var/buy_word = "Learn"
	var/limit //used to prevent a spellbook_entry from being bought more than X times with one wizard spellbook
	var/list/no_coexistance_typecache //Used so you can't have specific spells together

/datum/spellbook_entry/New()
	..()
	no_coexistance_typecache = typecacheof(no_coexistance_typecache)

/datum/spellbook_entry/proc/IsAvailible() // For config prefs / gamemode restrictions - these are round applied
	return TRUE

/datum/spellbook_entry/proc/CanBuy(mob/living/carbon/human/user,obj/item/spellbook/book) // Specific circumstances
	if(book.uses<cost || limit == 0)
		return FALSE
	for(var/spell in user.mind.spell_list)
		if(is_type_in_typecache(spell, no_coexistance_typecache))
			return FALSE
	return TRUE

/datum/spellbook_entry/proc/Buy(mob/living/carbon/human/user,obj/item/spellbook/book) //return TRUE on success
	if(!S || QDELETED(S))
		S = new spell_type()
	//Check if we got the spell already
	for(var/obj/effect/proc_holder/spell/aspell in user.mind.spell_list)
		if(initial(S.name) == initial(aspell.name)) // Not using directly in case it was learned from one spellbook then upgraded in another
			if(aspell.spell_level >= aspell.level_max)
				to_chat(user,  span_warning("This spell cannot be improved further!"))
				return FALSE
			else
				aspell.name = initial(aspell.name)
				aspell.spell_level++
				aspell.charge_max = round(initial(aspell.charge_max) - aspell.spell_level * (initial(aspell.charge_max) - aspell.cooldown_min)/ aspell.level_max)
				if(aspell.charge_max < aspell.charge_counter)
					aspell.charge_counter = aspell.charge_max
				switch(aspell.spell_level)
					if(1)
						to_chat(user, span_notice("You have improved [aspell.name] into Efficient [aspell.name]."))
						aspell.name = "Efficient [aspell.name]"
					if(2)
						to_chat(user, span_notice("You have further improved [aspell.name] into Quickened [aspell.name]."))
						aspell.name = "Quickened [aspell.name]"
					if(3)
						to_chat(user, span_notice("You have further improved [aspell.name] into Free [aspell.name]."))
						aspell.name = "Free [aspell.name]"
					if(4)
						to_chat(user, span_notice("You have further improved [aspell.name] into Instant [aspell.name]."))
						aspell.name = "Instant [aspell.name]"
				if(aspell.spell_level >= aspell.level_max)
					to_chat(user, span_warning("This spell cannot be strengthened any further!"))
				SSblackbox.record_feedback("nested tally", "wizard_spell_improved", 1, list("[name]", "[aspell.spell_level]"))
				return TRUE
	//No same spell found - just learn it
	SSblackbox.record_feedback("tally", "wizard_spell_learned", 1, name)
	user.mind.AddSpell(S)
	to_chat(user, span_notice("You have learned [S.name]."))
	return TRUE

/datum/spellbook_entry/proc/CanRefund(mob/living/carbon/human/user,obj/item/spellbook/book)
	if(!refundable)
		return FALSE
	if(!S)
		S = new spell_type()
	for(var/obj/effect/proc_holder/spell/aspell in user.mind.spell_list)
		if(initial(S.name) == initial(aspell.name))
			return TRUE
	return FALSE

/datum/spellbook_entry/proc/Refund(mob/living/carbon/human/user,obj/item/spellbook/book) //return point value or -1 for failure
	var/area/wizard_station/A = GLOB.areas_by_type[/area/wizard_station]
	if(!(user in A.contents))
		to_chat(user, span_warning("You can only refund spells at the wizard lair!"))
		return -1
	if(!S)
		S = new spell_type()
	var/spell_levels = 0
	for(var/obj/effect/proc_holder/spell/aspell in user.mind.spell_list)
		if(initial(S.name) == initial(aspell.name))
			spell_levels = aspell.spell_level
			user.mind.spell_list.Remove(aspell)
			qdel(S)
			return cost * (spell_levels+1)
	return -1
/datum/spellbook_entry/proc/GetInfo()
	if(!S)
		S = new spell_type()
	var/dat =""
	dat += "<b>[initial(S.name)]</b>"
	if(S.charge_type == "recharge")
		dat += " Cooldown:[S.charge_max/10]"
	dat += " Cost:[cost]<br>"
	dat += "<i>[S.desc][desc]</i><br>"
	dat += "[S.clothes_req?"Requires wizard garb.":"Can be cast without wizard garb."]<br>"
	return dat

/datum/spellbook_entry/fireball
	name = "Fireball"
	spell_type = /obj/effect/proc_holder/spell/aimed/fireball

/datum/spellbook_entry/magicm
	name = "Magic Missile"
	spell_type = /obj/effect/proc_holder/spell/targeted/projectile/magic_missile
	category = "Defensive"

/datum/spellbook_entry/disintegrate
	name = "Smite"
	spell_type = /obj/effect/proc_holder/spell/targeted/touch/disintegrate

/datum/spellbook_entry/disabletech
	name = "Disable Tech"
	spell_type = /obj/effect/proc_holder/spell/targeted/emplosion/disable_tech
	category = "Defensive"
	cost = 1

/datum/spellbook_entry/repulse
	name = "Repulse"
	spell_type = /obj/effect/proc_holder/spell/aoe_turf/repulse
	category = "Defensive"

/datum/spellbook_entry/lightningPacket
	name = "Thrown Lightning"
	spell_type = /obj/effect/proc_holder/spell/targeted/conjure_item/spellpacket
	category = "Defensive"

/datum/spellbook_entry/timestop
	name = "Time Stop"
	spell_type = /obj/effect/proc_holder/spell/aoe_turf/timestop
	category = "Defensive"

/datum/spellbook_entry/smoke
	name = "Smoke"
	spell_type = /obj/effect/proc_holder/spell/targeted/smoke
	category = "Defensive"
	cost = 1

/datum/spellbook_entry/blind
	name = "Blind"
	spell_type = /obj/effect/proc_holder/spell/pointed/trigger/blind
	cost = 1

/datum/spellbook_entry/mindswap
	name = "Mindswap"
	spell_type = /obj/effect/proc_holder/spell/pointed/mind_transfer
	category = "Mobility"

/datum/spellbook_entry/forcewall
	name = "Force Wall"
	spell_type = /obj/effect/proc_holder/spell/targeted/forcewall
	category = "Defensive"
	cost = 1

/datum/spellbook_entry/blink
	name = "Blink"
	spell_type = /obj/effect/proc_holder/spell/targeted/turf_teleport/blink
	category = "Mobility"

/datum/spellbook_entry/teleport
	name = "Teleport"
	spell_type = /obj/effect/proc_holder/spell/targeted/area_teleport/teleport
	category = "Mobility"

/datum/spellbook_entry/mutate
	name = "Mutate"
	spell_type = /obj/effect/proc_holder/spell/targeted/genetic/mutate

/datum/spellbook_entry/jaunt
	name = "Ethereal Jaunt"
	spell_type = /obj/effect/proc_holder/spell/targeted/ethereal_jaunt
	category = "Mobility"

/datum/spellbook_entry/knock
	name = "Knock"
	spell_type = /obj/effect/proc_holder/spell/aoe_turf/knock
	category = "Mobility"
	cost = 1

/datum/spellbook_entry/fleshtostone
	name = "Flesh to Stone"
	spell_type = /obj/effect/proc_holder/spell/targeted/touch/flesh_to_stone

/datum/spellbook_entry/summonitem
	name = "Summon Item"
	spell_type = /obj/effect/proc_holder/spell/targeted/summonitem
	category = "Assistance"
	cost = 1

/datum/spellbook_entry/lichdom
	name = "Bind Soul"
	spell_type = /obj/effect/proc_holder/spell/targeted/lichdom
	category = "Defensive"

/datum/spellbook_entry/teslablast
	name = "Tesla Blast"
	spell_type = /obj/effect/proc_holder/spell/targeted/tesla

/datum/spellbook_entry/lightningbolt
	name = "Lightning Bolt"
	spell_type = /obj/effect/proc_holder/spell/aimed/lightningbolt
	cost = 1

/datum/spellbook_entry/lightningbolt/Buy(mob/living/carbon/human/user,obj/item/spellbook/book) //return TRUE on success
	. = ..()
	ADD_TRAIT(user, TRAIT_TESLA_SHOCKIMMUNE, "lightning_bolt_spell")

/datum/spellbook_entry/lightningbolt/Refund(mob/living/carbon/human/user, obj/item/spellbook/book)
	. = ..()
	REMOVE_TRAIT(user, TRAIT_TESLA_SHOCKIMMUNE, "lightning_bolt_spell")

/datum/spellbook_entry/barnyard
	name = "Barnyard Curse"
	spell_type = /obj/effect/proc_holder/spell/pointed/barnyardcurse

/datum/spellbook_entry/charge
	name = "Charge"
	spell_type = /obj/effect/proc_holder/spell/targeted/charge
	category = "Assistance"
	cost = 1

/datum/spellbook_entry/shapeshift
	name = "Wild Shapeshift"
	spell_type = /obj/effect/proc_holder/spell/targeted/shapeshift
	category = "Assistance"
	cost = 1

/datum/spellbook_entry/tap
	name = "Soul Tap"
	spell_type = /obj/effect/proc_holder/spell/self/tap
	category = "Assistance"
	cost = 1

/datum/spellbook_entry/spacetime_dist
	name = "Spacetime Distortion"
	spell_type = /obj/effect/proc_holder/spell/spacetime_dist
	category = "Defensive"
	cost = 1

/datum/spellbook_entry/the_traps
	name = "The Traps!"
	spell_type = /obj/effect/proc_holder/spell/aoe_turf/conjure/the_traps
	category = "Defensive"
	cost = 1


/datum/spellbook_entry/item
	name = "Buy Item"
	refundable = FALSE
	buy_word = "Summon"
	var/item_path= null


/datum/spellbook_entry/item/Buy(mob/living/carbon/human/user,obj/item/spellbook/book)
	new item_path(get_turf(user))
	SSblackbox.record_feedback("tally", "wizard_spell_learned", 1, name)
	return TRUE

/datum/spellbook_entry/item/GetInfo()
	var/dat =""
	dat += "<b>[name]</b>"
	dat += " Cost:[cost]<br>"
	dat += "<i>[desc]</i><br>"
	if(surplus>=0)
		dat += "[surplus] left.<br>"
	return dat

/datum/spellbook_entry/item/scryingorb
	name = "Scrying Orb"
	desc = "An incandescent orb of crackling energy. Using it will allow you to release your ghost while alive, allowing you to spy upon others and talk to the deceased. In addition, buying it will permanently grant you X-ray vision."
	item_path = /obj/item/scrying
	category = "Defensive"

/datum/spellbook_entry/item/necrostone
	name = "A Necromantic Stone"
	desc = "A Necromantic stone is able to resurrect three dead individuals as skeletal thralls for you to command."
	item_path = /obj/item/necromantic_stone
	category = "Assistance"

/datum/spellbook_entry/item/contract
	name = "Contract of Apprenticeship"
	desc = "A magical contract binding an apprentice wizard to your service, using it will summon them to your side."
	item_path = /obj/item/antag_spawner/contract
	category = "Assistance"

/datum/spellbook_entry/item/bloodbottle
	name = "Bottle of Blood"
	desc = "A bottle of magically infused blood, the smell of which will attract extradimensional beings when broken. Be careful though, the kinds of creatures summoned by blood magic are indiscriminate in their killing, and you yourself may become a victim."
	item_path = /obj/item/antag_spawner/slaughter_demon
	limit = 3
	category = "Assistance"

/datum/spellbook_entry/item/battlemage
	name = "Battlemage Armour"
	desc = "An ensorceled suit of armour, protected by a powerful shield. The shield can completely negate sixteen attacks before being permanently depleted."
	item_path = /obj/item/clothing/suit/space/hardsuit/shielded/wizard
	limit = 1
	category = "Defensive"

/datum/spellbook_entry/item/battlemage/Buy(mob/living/carbon/human/user,obj/item/spellbook/book)
	. = ..()
	if(.)
		new /obj/item/clothing/shoes/sandal/magic(get_turf(user)) //In case they've lost them.
		new /obj/item/clothing/gloves/combat/wizard(get_turf(user))//To complete the outfit

/datum/spellbook_entry/item/battlemage_charge
	name = "Battlemage Armour Charges"
	desc = "A powerful defensive rune, it will grant eight additional charges to a suit of battlemage armour."
	item_path = /obj/item/wizard_armour_charge
	category = "Defensive"
	cost = 1

/datum/spellbook_entry/item/warpwhistle
	name = "Warp Whistle"
	desc = "A strange whistle that will transport you to a distant safe place. There is a window of vulnerability at the beginning of every use."
	item_path = /obj/item/warpwhistle
	category = "Mobility"
	cost = 1

/datum/spellbook_entry/summon
	name = "Summon Stuff"
	category = "Rituals"
	refundable = FALSE
	buy_word = "Cast"
	var/active = FALSE

/datum/spellbook_entry/summon/CanBuy(mob/living/carbon/human/user,obj/item/spellbook/book)
	return ..() && !active

/datum/spellbook_entry/summon/GetInfo()
	var/dat =""
	dat += "<b>[name]</b>"
	if(cost>0)
		dat += " Cost:[cost]<br>"
	else
		dat += " No Cost<br>"
	dat += "<i>[desc]</i><br>"
	if(active)
		dat += "<b>Already cast!</b><br>"
	return dat

/datum/spellbook_entry/summon/ghosts
	name = "Summon Ghosts"
	desc = "Spook the crew out by making them see dead people. Be warned, ghosts are capricious and occasionally vindicative, and some will use their incredibly minor abilities to frustrate you."
	cost = 0

/datum/spellbook_entry/summon/ghosts/IsAvailible()
	if(!SSticker.mode)
		return FALSE
	else
		return TRUE

/datum/spellbook_entry/summon/ghosts/Buy(mob/living/carbon/human/user, obj/item/spellbook/book)
	SSblackbox.record_feedback("tally", "wizard_spell_learned", 1, name)
	new /datum/round_event/wizard/ghost()
	active = TRUE
	to_chat(user, span_notice("You have cast summon ghosts!"))
	playsound(get_turf(user), 'sound/effects/ghost2.ogg', 50, TRUE)
	return TRUE

/datum/spellbook_entry/summon/guns
	name = "Summon Guns"
	desc = "Nothing could possibly go wrong with arming a crew of lunatics just itching for an excuse to kill you. There is a good chance that they will shoot each other first."

/datum/spellbook_entry/summon/guns/IsAvailible()
	if(!SSticker.mode) // In case spellbook is placed on map
		return FALSE
	if(istype(SSticker.mode, /datum/game_mode/dynamic)) // Disable events on dynamic
		return FALSE
	return !CONFIG_GET(flag/no_summon_guns)

/datum/spellbook_entry/summon/guns/Buy(mob/living/carbon/human/user,obj/item/spellbook/book)
	SSblackbox.record_feedback("tally", "wizard_spell_learned", 1, name)
	rightandwrong(SUMMON_GUNS, user, 10)
	active = TRUE
	playsound(get_turf(user), 'sound/magic/castsummon.ogg', 50, TRUE)
	to_chat(user, span_notice("You have cast summon guns!"))
	return TRUE

/datum/spellbook_entry/summon/magic
	name = "Summon Magic"
	desc = "Share the wonders of magic with the crew and show them why they aren't to be trusted with it at the same time."

/datum/spellbook_entry/summon/magic/IsAvailible()
	if(!SSticker.mode) // In case spellbook is placed on map
		return FALSE
	if(istype(SSticker.mode, /datum/game_mode/dynamic)) // Disable events on dynamic
		return FALSE
	return !CONFIG_GET(flag/no_summon_magic)

/datum/spellbook_entry/summon/magic/Buy(mob/living/carbon/human/user,obj/item/spellbook/book)
	SSblackbox.record_feedback("tally", "wizard_spell_learned", 1, name)
	rightandwrong(SUMMON_MAGIC, user, 10)
	active = TRUE
	playsound(get_turf(user), 'sound/magic/castsummon.ogg', 50, TRUE)
	to_chat(user, span_notice("You have cast summon magic!"))
	return TRUE

/datum/spellbook_entry/summon/events
	name = "Summon Events"
	desc = "Give Murphy's law a little push and replace all events with special wizard ones that will confound and confuse everyone. Multiple castings increase the rate of these events."
	cost = 2
	limit = 1
	var/times = 0

/datum/spellbook_entry/summon/events/IsAvailible()
	if(!SSticker.mode) // In case spellbook is placed on map
		return FALSE
	if(istype(SSticker.mode, /datum/game_mode/dynamic)) // Disable events on dynamic
		return FALSE
	return !CONFIG_GET(flag/no_summon_events)

/datum/spellbook_entry/summon/events/Buy(mob/living/carbon/human/user,obj/item/spellbook/book)
	SSblackbox.record_feedback("tally", "wizard_spell_learned", 1, name)
	summonevents()
	times++
	playsound(get_turf(user), 'sound/magic/castsummon.ogg', 50, TRUE)
	to_chat(user, span_notice("You have cast summon events."))
	return TRUE

/datum/spellbook_entry/summon/events/GetInfo()
	. = ..()
	if(times>0)
		. += "You cast it [times] times.<br>"
	return .

/datum/spellbook_entry/summon/curse_of_madness
	name = "Curse of Madness"
	desc = "Curses the sectors, warping the minds of everyone within, causing lasting traumas. Warning: this spell can affect you if not cast from a safe distance."
	cost = 4

/datum/spellbook_entry/summon/curse_of_madness/Buy(mob/living/carbon/human/user, obj/item/spellbook/book)
	SSblackbox.record_feedback("tally", "wizard_spell_learned", 1, name)
	active = TRUE
	var/message = stripped_input(user, "Whisper a secret truth to drive your victims to madness.", "Whispers of Madness")
	if(!message)
		return FALSE
	curse_of_madness(user, message)
	to_chat(user, span_notice("You have cast the curse of insanity!"))
	playsound(user, 'sound/magic/mandswap.ogg', 50, TRUE)
	return TRUE

/obj/item/spellbook
	name = "spell book"
	desc = "An unearthly tome that glows with power."
	icon = 'icons/obj/library.dmi'
	icon_state ="book"
	throw_speed = 2
	throw_range = 5
	w_class = WEIGHT_CLASS_TINY
	var/uses = 10
	var/temp = null
	var/tab = null
	var/mob/living/carbon/human/owner
	var/list/datum/spellbook_entry/entries = list()
	var/list/categories = list()

/obj/item/spellbook/examine(mob/user)
	. = ..()
	if(owner)
		. += {"There is a small signature on the front cover: "[owner]"."}
	else
		. += "It appears to have no author."

/obj/item/spellbook/Initialize()
	. = ..()
	prepare_spells()

/obj/item/spellbook/proc/prepare_spells()
	var/entry_types = subtypesof(/datum/spellbook_entry) - /datum/spellbook_entry/item - /datum/spellbook_entry/summon
	for(var/T in entry_types)
		var/datum/spellbook_entry/E = new T
		if(E.IsAvailible())
			entries |= E
			categories |= E.category
		else
			qdel(E)
	tab = categories[1]

/obj/item/spellbook/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/antag_spawner/contract))
		var/obj/item/antag_spawner/contract/contract = O
		if(contract.used)
			to_chat(user, span_warning("The contract has been used, you can't get your points back now!"))
		else
			to_chat(user, span_notice("You feed the contract back into the spellbook, refunding your points."))
			uses += 2
			for(var/datum/spellbook_entry/item/contract/CT in entries)
				if(!isnull(CT.limit))
					CT.limit++
			qdel(O)
	else if(istype(O, /obj/item/antag_spawner/slaughter_demon))
		to_chat(user, span_notice("On second thought, maybe summoning a demon is a bad idea. You refund your points."))
		uses += 2
		for(var/datum/spellbook_entry/item/bloodbottle/BB in entries)
			if(!isnull(BB.limit))
				BB.limit++
		qdel(O)

/obj/item/spellbook/proc/GetCategoryHeader(category)
	var/dat = ""
	switch(category)
		if("Offensive")
			dat += "Spells and items geared towards debilitating and destroying.<BR><BR>"
			dat += "Items are not bound to you and can be stolen. Additionally they cannot typically be returned once purchased.<BR>"
			dat += "For spells: the number after the spell name is the cooldown time.<BR>"
			dat += "You can reduce this number by spending more points on the spell.<BR>"
		if("Defensive")
			dat += "Spells and items geared towards improving your survivability or reducing foes' ability to attack.<BR><BR>"
			dat += "Items are not bound to you and can be stolen. Additionally they cannot typically be returned once purchased.<BR>"
			dat += "For spells: the number after the spell name is the cooldown time.<BR>"
			dat += "You can reduce this number by spending more points on the spell.<BR>"
		if("Mobility")
			dat += "Spells and items geared towards improving your ability to move. It is a good idea to take at least one.<BR><BR>"
			dat += "Items are not bound to you and can be stolen. Additionally they cannot typically be returned once purchased.<BR>"
			dat += "For spells: the number after the spell name is the cooldown time.<BR>"
			dat += "You can reduce this number by spending more points on the spell.<BR>"
		if("Assistance")
			dat += "Spells and items geared towards bringing in outside forces to aid you or improving upon your other items and abilities.<BR><BR>"
			dat += "Items are not bound to you and can be stolen. Additionally they cannot typically be returned once purchased.<BR>"
			dat += "For spells: the number after the spell name is the cooldown time.<BR>"
			dat += "You can reduce this number by spending more points on the spell.<BR>"
		if("Challenges")
			dat += "The Wizard Federation typically has hard limits on the potency and number of spells brought to the sector based on risk.<BR>"
			dat += "Arming the station against you will increases the risk, but will grant you one more charge for your spellbook.<BR>"
		if("Rituals")
			dat += "These powerful spells change the very fabric of reality. Not always in your favour.<BR>"
	return dat

/obj/item/spellbook/proc/wrap(content)
	var/dat = ""
	dat +="<html><head><meta http-equiv='Content-Type' content='text/html; charset=UTF-8'><title>Spellbook</title></head>"
	dat += {"
	<head>
		<style type="text/css">
			body { font-size: 80%; font-family: 'Lucida Grande', Verdana, Arial, Sans-Serif; }
			ul#tabs { list-style-type: none; margin: 30px 0 0 0; padding: 0 0 0.3em 0; }
			ul#tabs li { display: inline; }
			ul#tabs li a { color: #42454a; background-color: #dedbde; border: 1px solid #c9c3ba; border-bottom: none; padding: 0.3em; text-decoration: none; }
			ul#tabs li a:hover { background-color: #f1f0ee; }
			ul#tabs li a.selected { color: #000; background-color: #f1f0ee; font-weight: bold; padding: 0.7em 0.3em 0.38em 0.3em; }
			div.tabContent { border: 1px solid #c9c3ba; padding: 0.5em; background-color: #f1f0ee; }
			div.tabContent.hide { display: none; }
		</style>
	</head>
	"}
	dat += {"[content]</body></html>"}
	return dat

/obj/item/spellbook/attack_self(mob/user)
	if(!owner)
		to_chat(user, span_notice("You bind the spellbook to yourself."))
		owner = user
		return
	if(user != owner)
		to_chat(user, span_warning("The [name] does not recognize you as its owner and refuses to open!"))
		return
	user.set_machine(src)
	var/dat = ""

	dat += "<ul id=\"tabs\">"
	var/list/cat_dat = list()
	for(var/category in categories)
		cat_dat[category] = "<hr>"
		dat += "<li><a [tab==category?"class=selected":""] href='byond://?src=[REF(src)];page=[category]'>[category]</a></li>"

	dat += "<li><a><b>Points remaining : [uses]</b></a></li>"
	dat += "</ul>"

	var/datum/spellbook_entry/E
	for(var/i=1,i<=entries.len,i++)
		var/spell_info = ""
		E = entries[i]
		spell_info += E.GetInfo()
		if(E.CanBuy(user,src))
			spell_info+= "<a href='byond://?src=[REF(src)];buy=[i]'>[E.buy_word]</A><br>"
		else
			spell_info+= "<span>Can't [E.buy_word]</span><br>"
		if(E.CanRefund(user,src))
			spell_info+= "<a href='byond://?src=[REF(src)];refund=[i]'>Refund</A><br>"
		spell_info += "<hr>"
		if(cat_dat[E.category])
			cat_dat[E.category] += spell_info

	for(var/category in categories)
		dat += "<div class=\"[tab==category?"tabContent":"tabContent hide"]\" id=\"[category]\">"
		dat += GetCategoryHeader(category)
		dat += cat_dat[category]
		dat += "</div>"

	user << browse(wrap(dat), "window=spellbook;size=700x500")
	onclose(user, "spellbook")
	return

/obj/item/spellbook/Topic(href, href_list)
	. = ..()

	if(usr.stat != CONSCIOUS || HAS_TRAIT(usr, TRAIT_HANDS_BLOCKED))
		return
	if(!ishuman(usr))
		return TRUE
	var/mob/living/carbon/human/H = usr

	if(H.mind.special_role == "apprentice")
		temp = "If you got caught sneaking a peek from your teacher's spellbook, you'd likely be expelled from the Wizard Academy. Better not."
		return

	var/datum/spellbook_entry/E = null
	if(loc == H || (in_range(src, H) && isturf(loc)))
		H.set_machine(src)
		if(href_list["buy"])
			E = entries[text2num(href_list["buy"])]
			if(E && E.CanBuy(H,src))
				if(E.Buy(H,src))
					if(E.limit)
						E.limit--
					uses -= E.cost
		else if(href_list["refund"])
			E = entries[text2num(href_list["refund"])]
			if(E && E.refundable)
				var/result = E.Refund(H,src)
				if(result > 0)
					if(!isnull(E.limit))
						E.limit += result
					uses += result
		else if(href_list["page"])
			tab = sanitize(href_list["page"])
	attack_self(H)
	return
