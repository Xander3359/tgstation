/obj/item/contractor_bomb
	name = "ANNETODO"
	desc = "ANNETODO"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bomb.dmi'
	icon_state = "bomb"
	/// What the charge is stuck to
	var/mob/living/carbon/human/owner = null
	/// Is the bomb counting down?
	var/active = FALSE
	///How long it takes for a grenade to explode after being armed
	var/det_time = 2 MINUTES // XANTODO Should be like 10 minutes
	/// The timer for the bomb.
	var/detonation_timer
	/// What sound do we make as we beep down the timer?
	var/beepsound = 'sound/items/timer.ogg'
	/// When do we beep next?
	var/next_beep
	/// If true, will explode when the next boom cable is cut
	var/bad_defusal = FALSE
	/// C4 overlay to put on owner
	var/mutable_appearance/plastic_overlay
	/// List of cables belonging to the bomb, used for defusal
	var/list/cable_list
	/// Cable icons
	var/list/cable_icons

	//---- Explosion variables, can be changed by the defusal process
	var/ex_dev = 1
	var/ex_heavy = 2
	var/ex_light = 4
	var/ex_flame = 2
	/// If true, will end the round
	var/is_nuclear = FALSE

/obj/item/contractor_bomb/Initialize(mapload)
	. = ..()
	plastic_overlay = mutable_appearance(icon, "Mob bombactivated", HIGH_OBJ_LAYER)
	for(var/datum/contractor_wire/new_cable as anything in subtypesof(/datum/contractor_wire))
		cable_icons += list(new_cable.name = image(icon = new_cable.cable_icon, icon_state = new_cable.cable_icon_state))
		cable_list += list(new_cable.name = new new_cable(src))
	add_cable_functions()


/// Assign a function to several cables (Leaving the rest as empty duds)
/obj/item/contractor_bomb/proc/add_cable_functions()
	var/list/cable_assignment = cable_list.Copy()
	var/datum/contractor_wire/modified_cable

	// 2 Explosive cables needed to detonate
	for(var/loop in 1 to 2)
		modified_cable = cable_list[pick_n_take(cable_assignment)]
		modified_cable.explosive_cable = TRUE

		//XANTODO DEBUG
		to_chat(world, "[modified_cable.name] explosive cable")

	// 1 Cable to defuse the bomb
	modified_cable = cable_list[pick_n_take(cable_assignment)]
	modified_cable.defusal_cable = TRUE

	//XANTODO DEBUG
	to_chat(world, "[modified_cable.name] defusal cable")

	// 2 Cables that add time to the countdown
	for(var/loop in 1 to 2)
		modified_cable = cable_list[pick_n_take(cable_assignment)]
		modified_cable.time_adder = TRUE

		//XANTODO DEBUG
		to_chat(world, "[modified_cable.name] time adder cable")

	// 1 Cable that removes time from the countdown
	modified_cable = cable_list[pick_n_take(cable_assignment)]
	modified_cable.time_remover = TRUE

	//XANTODO DEBUG
	to_chat(world, "[modified_cable.name] time remover cable")

/obj/item/contractor_bomb/Destroy()
	cable_list = null
	cable_icons = null
	plastic_overlay = null
	owner = null
	return ..()

/obj/item/contractor_bomb/process(seconds_per_tick)
	if(!active)
		return

	for(var/obj/effect/forcefield/cosmic_field/potential_field as anything in GLOB.active_cosmic_fields)
		if(get_dist(potential_field, src) < 3)
			new /obj/effect/temp_visual/revenant(get_turf(src))
			defuse()
			return

	if(!isnull(next_beep) && (next_beep <= world.time))
		var/volume
		switch(seconds_remaining())
			if(0 to 5)
				volume = 50
			if(5 to 10)
				volume = 40
			if(10 to 15)
				volume = 30
			if(15 to 20)
				volume = 20
			if(20 to 25)
				volume = 10
			else
				volume = 5
		playsound(get_turf(src), beepsound, volume, FALSE)
		next_beep = world.time + 1 SECONDS

	if(active && ((detonation_timer <= world.time)))// || explode_now))
		active = FALSE
		update_appearance()
		try_detonate(TRUE)

// XANTODO : Currently sticking the bomb on someone by stealing C4 code, should be done automatically when the victim is kidnapped
/obj/item/contractor_bomb/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	if(!ishuman(interacting_with))
		return ..()
	return plant_c4(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING

/obj/item/contractor_bomb/proc/plant_c4(mob/living/carbon/human/bomb_target, mob/living/user)
	if(bomb_target != user && HAS_TRAIT(user, TRAIT_PACIFISM) && isliving(bomb_target))
		to_chat(user, span_warning("You don't want to harm other living beings!"))
		return FALSE

	to_chat(user, span_notice("You start planting [src]. The timer is set to [det_time]..."))

	if(!do_after(user, 3 SECONDS, target = bomb_target))
		return FALSE
	if(!user.temporarilyRemoveItemFromInventory(src))
		return FALSE
	owner = bomb_target
	active = TRUE

	message_admins("[ADMIN_LOOKUPFLW(user)] planted [name] on [owner.name] at [ADMIN_VERBOSEJMP(owner)] with [det_time] second fuse")
	user.log_message("planted [name] on [owner.name] with a [det_time] second fuse.", LOG_ATTACK)
	var/icon/target_icon = icon(bomb_target.icon, bomb_target.icon_state)
	target_icon.Blend(icon(icon, icon_state), ICON_OVERLAY)
	var/mutable_appearance/bomb_target_image = mutable_appearance(target_icon)
	notify_ghosts(
		"[user.real_name] has planted \a [src] on [owner] with a [det_time] second fuse!",
		source = bomb_target,
		header = "Explosive Planted",
		alert_overlay = bomb_target_image,
		notify_flags = NOTIFY_CATEGORY_NOFLASH,
	)
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	forceMove(bomb_target.get_bodypart(BODY_ZONE_CHEST))
	plastic_overlay.layer = FLOAT_LAYER
	owner.add_overlay(plastic_overlay)
	to_chat(user, span_notice("You plant the bomb. Timer counting down from [det_time]."))
	detonation_timer = world.time + det_time
	next_beep = world.time
	START_PROCESSING(SSobj, src)
	return TRUE

/// Sticking a fork in the bomb has very interesting results
/obj/item/contractor_bomb/proc/get_forked()
	bad_defusal = TRUE
	ex_dev = 5
	ex_heavy = 10
	ex_light = 20
	ex_flame = 20
	detonation_timer = world.time + 30 SECONDS

/// Sticking a plutonium core will make the bomb end the round
/obj/item/contractor_bomb/proc/transfer_core(obj/item/nuke_core/core)
	if(core.type != /obj/item/nuke_core) // No subtypes here
		return
	is_nuclear = TRUE
	qdel(core)

/// The bomb defusal minigame
/obj/item/contractor_bomb/proc/perform_defusal(mob/surgeon)
	var/selection = show_radial_menu(surgeon, owner, cable_icons, require_near = TRUE)
	if(!selection)
		return
	var/datum/contractor_wire/chosen_wire = cable_list[selection]
	if(chosen_wire.cut)
		return
	cable_icons -= selection

	if(chosen_wire.explosive_cable)
		//XANTODO DEBUG
		to_chat(world, "explosive cable cut")

		if(bad_defusal)
			try_detonate()
			return
		else
			bad_defusal = TRUE
			ex_dev = 5
			ex_heavy = 10
			ex_light = 20
			ex_flame = 20
			detonation_timer = world.time + 30 SECONDS // No math here, you can either benefit or suffer from this

	if(chosen_wire.defusal_cable)
		//XANTODO DEBUG
		to_chat(world, "defusal cable cut")
		defuse()

	if(chosen_wire.time_adder)
		detonation_timer += 2 MINUTES
		//XANTODO DEBUG
		to_chat(world, "delay cable cut")

	if(chosen_wire.time_remover)
		detonation_timer = max((world.time + 30 SECONDS), (detonation_timer - 2 MINUTES)) // Tries to reduce the timer by 2 minutes but minimum 30 second fuse remaining
		//XANTODO DEBUG
		to_chat(world, "speedup cable cut")

	chosen_wire.cable_icon_state = initial(chosen_wire.cable_icon_state) + "_cut"
	chosen_wire.cut = TRUE
	cable_icons += list(chosen_wire.name = image(icon = chosen_wire.cable_icon, icon_state = chosen_wire.cable_icon_state))
	surgeon.playsound_local(surgeon, 'sound/items/tools/wirecutter.ogg', 50, 0)
	if(active)
		perform_defusal(surgeon) // Loop until defusal, cancellation or explosion

/obj/item/contractor_bomb/proc/defuse()
	active = FALSE
	//examinable_countdown = TRUE
	detonation_timer = null
	next_beep = null
	//countdown.stop()
	STOP_PROCESSING(SSobj, src)
	owner.cut_overlay(plastic_overlay)
	owner.updateappearance(UPDATE_OVERLAYS)
	owner.temporarilyRemoveItemFromInventory(src, TRUE)
	forceMove(get_turf(src))
	update_appearance()

/// Causes an explosion and eradicates our explodee from existence
/obj/item/contractor_bomb/proc/try_detonate()
	if(is_nuclear)
		nuclear_explosion()
		return FALSE

	var/obj/item/organ/brain/to_delete = locate(/obj/item/organ/brain) in owner.organs
	if(to_delete)
		to_delete.Remove(owner)
		qdel(to_delete)

	var/obj/item/organ/heart/cybernetic/anomalock/funny_organ = locate(/obj/item/organ/heart/cybernetic/anomalock) in owner.organs
	if(funny_organ?.core)
		new /obj/energy_ball(src)

	explosion(src, ex_dev, ex_heavy, ex_light, ex_flame)
	qdel(src)

/obj/item/contractor_bomb/proc/seconds_remaining()
	if(active)
		. = max(0, round((detonation_timer - world.time) / 10))

	else
		. = det_time



// XANTODO CHECK ON NUKING

/**
 * Begins the process of exploding the bomb.
 * [proc/nuclear_explosion] -> [proc/actually_explode] -> [proc/really_actually_explode])
 *
 * Goes through a few timers and plays a cinematic.
 */
/obj/item/contractor_bomb/proc/nuclear_explosion()
	update_appearance()
	sound_to_playing_players('sound/announcer/alarm/nuke_alarm.ogg', 70)

	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_NUKE_DEVICE_DETONATING, src)

	if(SSticker.HasRoundStarted())
		SSticker.roundend_check_paused = TRUE
	addtimer(CALLBACK(src, PROC_REF(actually_explode)), 10 SECONDS)
	return TRUE

#define NUKE_RADIUS 127

/obj/item/contractor_bomb/proc/actually_explode()
	var/detonation_status
	var/turf/bomb_location = get_turf(src)
	var/area/nuke_area = get_area(bomb_location)

	// The nuke was on the station zlevel
	if(bomb_location && is_station_level(bomb_location.z))
		// Nuke missed, it's in space
		if(istype(nuke_area, /area/space))
			detonation_status = DETONATION_NEAR_MISSED_STATION

		// Nuke missed, it'stoo far from the station
		else if((bomb_location.x < (128 - NUKE_RADIUS)) \
			|| (bomb_location.x > (128 + NUKE_RADIUS)) \
			|| (bomb_location.y < (128 - NUKE_RADIUS)) \
			|| (bomb_location.y > (128 + NUKE_RADIUS)))

			detonation_status = DETONATION_NEAR_MISSED_STATION

		// Confirming good hits, the nuke hit the station
		else
			SSlag_switch.set_measure(DISABLE_NON_OBSJOBS, TRUE)
			detonation_status = DETONATION_HIT_STATION
			GLOB.station_was_nuked = TRUE

	// The nuke was on the syndicate base
	else if(bomb_location.onSyndieBase())
		detonation_status = DETONATION_HIT_SYNDIE_BASE

	// The nuke was somewhere wacky - deep space, mining z, centcom? Whatever
	else
		detonation_status = DETONATION_MISSED_STATION

	// Now go play the cinematic
	GLOB.station_nuke_source = detonation_status
	really_actually_explode(detonation_status)
	SSticker.roundend_check_paused = FALSE

	return detonation_status

#undef NUKE_RADIUS

/obj/item/contractor_bomb/proc/really_actually_explode(detonation_status)
	var/cinematic = get_cinematic_type(detonation_status)
	if(!isnull(cinematic))
		play_cinematic(cinematic, world)

	var/drop_level = TRUE
	switch(detonation_status)
		if(DETONATION_HIT_STATION)
			nuke_effects(SSmapping.levels_by_trait(ZTRAIT_STATION))
			drop_level = FALSE

		if(DETONATION_HIT_SYNDIE_BASE)
			priority_announce(
				"Long Range Scanners indicate that the nuclear device has detonated on a previously unknown base, we assume \
				the base to be of Syndicate Origin. Good work crew.",
				"Nuclear Operations Command",
			)

			var/datum/turf_reservation/syndicate_base = SSmapping.lazy_load_template(LAZY_TEMPLATE_KEY_NUKIEBASE)
			ASYNC
				for(var/turf/turf as anything in syndicate_base.reserved_turfs)
					for(var/mob/living/about_to_explode in turf)
						nuke_gib(about_to_explode, src)
					CHECK_TICK

		else
			priority_announce(
				"Long Range Scanners indicate that the nuclear device has detonated; however seismic activity on the station \
				is minimal. We anticipate that the device has not detonated on the station itself.",
				"Nuclear Operations Command",
			)

	if(drop_level)
		SSsecurity_level.set_level(SEC_LEVEL_RED)
	qdel(src)
	return TRUE

/// Cause nuke effects to the passed z-levels.
/obj/item/contractor_bomb/proc/nuke_effects(list/affected_z_levels)
	INVOKE_ASYNC(GLOBAL_PROC, GLOBAL_PROC_REF(callback_on_everyone_on_z), affected_z_levels, CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(nuke_gib)), src)

/// Gets what type of cinematic this nuke showcases depending on where we detonated.
/obj/item/contractor_bomb/proc/get_cinematic_type(detonation_status)
	if(isnull(detonation_status))
		return /datum/cinematic/nuke/self_destruct_miss

	return /datum/cinematic/nuke/self_destruct

// XANTODO CHECK ON NUKING ^^^


/datum/contractor_wire
	var/name = "cable"
	var/cable_icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bomb.dmi'
	var/cable_icon_state = null
	/// If the cable is cut, we give it the cut icon state
	var/cut = FALSE
	/// If the cable causes an explosion when cut
	var/explosive_cable = FALSE
	/// Cutting this cable will defuse the bomb
	var/defusal_cable = FALSE
	/// Cutting this cable will add time to the countdown
	var/time_adder = FALSE
	/// Cutting this cable will remove time from the countdown
	var/time_remover = FALSE

/datum/contractor_wire/white
	name = "white cable"
	cable_icon_state = "white"

/datum/contractor_wire/yellow
	name = "yellow cable"
	cable_icon_state = "yellow"

/datum/contractor_wire/red
	name = "red cable"
	cable_icon_state = "red"

/datum/contractor_wire/green
	name = "green cable"
	cable_icon_state = "green"

/datum/contractor_wire/blue
	name = "blue cable"
	cable_icon_state = "blue"

/datum/contractor_wire/purple
	name = "purple cable"
	cable_icon_state = "purple"

/datum/contractor_wire/brown
	name = "brown cable"
	cable_icon_state = "brown"

/datum/contractor_wire/orange
	name = "orange cable"
	cable_icon_state = "orange"

/datum/contractor_wire/pink
	name = "pink cable"
	cable_icon_state = "pink"

/datum/contractor_wire/darkblue
	name = "darkblue cable"
	cable_icon_state = "darkblue"


// XANTODO BOX OF DEBUG AHAHAHAHA
/obj/item/storage/box/XANDER/PopulateContents()
	new /obj/item/debug/human_spawner(src)
	new /obj/item/contractor_bomb(src)
	new /obj/item/storage/backpack/duffelbag/syndie/surgery(src)
	new /obj/item/storage/box/syndicate/contract_kit(src)
	new /obj/item/wirecutters(src)
	new /obj/item/kitchen/fork(src)
	new /obj/item/nuke_core(src)

