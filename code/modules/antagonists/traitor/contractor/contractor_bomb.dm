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

/obj/item/contractor_bomb/Initialize(mapload)
	. = ..()
	plastic_overlay = mutable_appearance(icon, "Mob bombactivated", HIGH_OBJ_LAYER)
	for(var/datum/contractor_wire/new_cable as anything in subtypesof(/datum/contractor_wire))
		cable_icons += list(new_cable.name = image(icon = new_cable.cable_icon, icon_state = new_cable.cable_icon_state))
		cable_list += list(new_cable.name = new new_cable(src))

	// Assign the functions to each cable
	var/list/cable_assignment = cable_list.Copy()
	var/datum/contractor_wire/modified_cable
	for(var/loop in 1 to 2)
		modified_cable = cable_list[pick_n_take(cable_assignment)]
		modified_cable.explosive_cable = TRUE
	modified_cable = cable_list[pick_n_take(cable_assignment)]
	modified_cable.defusal_cable = TRUE

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
		next_beep = world.time + 10

	if(active && ((detonation_timer <= world.time)))// || explode_now))
		active = FALSE
		update_appearance()
		try_detonate(TRUE)

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
	detonation_timer = world.time + (det_time * 10)
	next_beep = world.time
	START_PROCESSING(SSobj, src)
	return TRUE

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
			qdel(src)
			return
		else
			bad_defusal = TRUE

	if(chosen_wire.defusal_cable)
		//XANTODO DEBUG
		to_chat(world, "defusal cable cut")
		defuse()

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

/obj/item/contractor_bomb/proc/try_detonate()
	explosion(src, 10, 10, 10, 10)

/obj/item/contractor_bomb/proc/seconds_remaining()
	if(active)
		. = max(0, round((detonation_timer - world.time) / 10))

	else
		. = det_time

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
