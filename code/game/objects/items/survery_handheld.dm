/obj/item/survey_handheld
	name = "Survey Handheld"
	desc = "A small tool designed for collecting and correlating information on planetary conditions."
	icon = 'icons/obj/item/survey_handheld.dmi'
	icon_state = "survey"
	//all of these vars are assigned by the mission that creates us.
	///how many scans does this handheld want?
	var/scans_required
	///how many scans does this handheld have
	var/scan_tally = 0
	///what the target of our scanning is.
	var/atom/scan_target

/obj/item/survey_handheld/examine(mob/user)
	. = ..()
	if(scans_required)
		. += span_notice("The scanner reports [scan_tally] of [scans_required] scans have been completed.")

/obj/item/survey_handheld/attack_obj(obj/O, mob/living/user)
	. = ..()
	if(istype(O, scan_target) && scan_tally < scans_required)
		if(O?:mission_scanned == TRUE)
			to_chat(user, span_notice("[O] has already been scanned"))
			playsound(src, 'sound/machines/buzz-sigh.ogg', 20)
			return FALSE
		user.visible_message(span_notice("[user] begins scanning the [O]."), span_notice("You begin scanning [O]."), span_notice("Analytic rustles quickly start and stop"))
		if(do_after(user, 3 SECONDS, O, show_progress = TRUE))
			if(increment_scan())
				to_chat(user, span_notice("You add [O] to the scanner's databank"))
				playsound(src, 'sound/machines/whirr_beep.ogg', 20)
				O?:mission_scanned = TRUE
	if(istype(O, /obj/structure/geyser))
		var/obj/structure/geyser/scan_target = O
		to_chat(user, "[scan_target] is producing [scan_target.reagent_id.name]!")
	return

/obj/item/survey_handheld/proc/increment_scan()
	scan_tally += 1
	if(scan_tally == scans_required)
		say("Sufficient samples gathered. Scanner ready for turn in!")
	return TRUE
	var/static/list/z_active = list()
	var/static/list/z_history = list()
	var/active = FALSE
	var/survey_value = 650
	var/survey_delay = 4 SECONDS

/obj/item/survey_handheld/advanced
	name = "Advanced Survey Handheld"
	desc = "An advanced survey scanner specialized in collecting large amounts of information on unique environments."
	icon_state = "survey-adv"
	survey_value = 1300
	survey_delay = 3 SECONDS

/obj/item/survey_handheld/elite
	name = "Experimental Survey Handheld"
	desc = "An experimental survey scanner utilizing deep radar techniques to quickly ascertain information on its locale."
	icon_state = "survey-elite"
	survey_value = 2400
	survey_delay = 2 SECONDS

/obj/item/survey_handheld/exp
	name = "Bluespace Survey Handheld"
	desc = "An improvement on even the Experimental version version; this handheld was designed to be extremely fast and accurate in collecting data, with compressed internal parts."
	icon_state = "survey-elite"
	survey_value = 5000
	survey_delay = 2 SECONDS

/obj/item/survey_handheld/attack_self(mob/user)
	if(active)
		return

	var/turf/src_turf = get_turf(src)

	var/my_z = "[virtual_z()]"
	if(z_active[my_z])
		flick(icon_state + "-corrupted", src)
		playsound(src, 'sound/machines/buzz-sigh.ogg', 20)
		src_turf.visible_message(span_warning("Warning: interference detected in current sector"))
		return

	if(!z_history[my_z])
		z_history[my_z] = 1

	active = TRUE
	z_active[my_z] = TRUE
	while(user.get_active_held_item() == src)
		to_chat(user, span_notice("You begin to scan your surroundings with [src]."))

		var/penalty = 1 - (z_history[my_z] - 1) * 0.05 // You lose five percent of value and are five percent slower
		if(!penalty || penalty < 0.20) // If you are below 20% value, do nothing and abort
			flick(icon_state + "-corrupted", src)
			playsound(src, 'sound/machines/buzz-sigh.ogg', 20)
			src_turf.visible_message(span_warning("Warning: unable to locate valuable information in current sector."))
			break

		if(!do_after(user, survey_delay / penalty, src))
			flick(icon_state + "-corrupted", src)
			playsound(src, 'sound/machines/buzz-sigh.ogg', 20)
			src_turf.visible_message(span_warning("Warning: results corrupted. Please try again."))
			break

		flick(icon_state + "print", src)
		playsound(src, 'sound/machines/whirr_beep.ogg', 20)
		src_turf.visible_message(span_notice("Data recorded and enscribed to research packet."))
		z_history[my_z]++

		var/obj/item/result = new /obj/item/research_notes(null, survey_value * penalty, pick(list("astronomy", "physics", "planets", "space")))

		var/obj/item/research_notes/notes = locate() in get_turf(user)
		if(notes)
			notes.merge(result)
		else if(!user.put_in_hands(result) && istype(user.get_inactive_held_item(), /obj/item/research_notes))
			var/obj/item/research_notes/research = user.get_inactive_held_item()
			research.merge(result)
			continue

	active = FALSE
	z_active[my_z] = FALSE

/datum/design/survey_handheld
	name = "Survey Handheld"
	id = "survey-handheld"
	build_type = AUTOLATHE
	build_path = /obj/item/survey_handheld
	materials = list(
		/datum/material/iron = 2000,
		/datum/material/glass = 1000,
	)
	category = list("initial", "Tools")

/datum/design/survey_handheld_advanced
	name = "Advanced Survey Handheld"
	id = "survey-handheld-advanced"
	build_type = PROTOLATHE
	build_path = /obj/item/survey_handheld/advanced
	materials = list(
		/datum/material/iron = 3000,
		/datum/material/glass = 2000,
		/datum/material/gold = 2000,
	)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/survey_handheld_elite
	name = "Elite Survey Handheld"
	id = "survey-handheld-elite"
	build_type = PROTOLATHE
	build_path = /obj/item/survey_handheld/elite
	materials = list(
		/datum/material/iron = 5000,
		/datum/material/silver = 5000,
		/datum/material/gold = 3000,
		/datum/material/uranium = 3000,
		/datum/material/diamond = 2000,
	)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE


/datum/design/survey_handheld_exp
	name = "Experimental Survey Handheld"
	id = "survey-handheld-exp"
	build_type = PROTOLATHE
	build_path = /obj/item/survey_handheld/exp
	materials = list(
		/datum/material/iron = 5000,
		/datum/material/silver = 5000,
		/datum/material/gold = 3000,
		/datum/material/uranium = 3000,
		/datum/material/diamond = 3000,
		/datum/material/bluespace = 3000,
	)
	category = list("Tool Designs")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/obj/structure/anomaly
	name = "Defaultic Bind"
	desc = "The truly unexpected anomaly. Let a coder know if you see this!"
	max_integrity = 300
