/obj/item/contractor_bomb
	name = "ANNETODO"
	desc = "ANNETODO"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bomb.dmi'
	icon_state = "bomb"
	/// The icon state for the bomb that is planted on a mob
	var/planted_icon_state = "mob_bomb"
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
	/// If true, the explosion is tripled in size and bypasses maxcap restriction
	var/is_nuclear = FALSE
	/// Cached base64 mugshot of the owner, generated for the detonation suite UI
	var/cached_mugshot

/obj/item/contractor_bomb/Initialize(mapload)
	. = ..()
	plastic_overlay = mutable_appearance(icon, planted_icon_state, HIGH_OBJ_LAYER)
	for(var/datum/contractor_wire/new_cable as anything in subtypesof(/datum/contractor_wire))
		cable_icons += list(new_cable.name = image(icon = new_cable.cable_icon, icon_state = new_cable.cable_icon_state))
		cable_list += list(new_cable.name = new new_cable(src))
	add_cable_functions()

/obj/item/contractor_bomb/update_icon_state()
	. = ..()
	if(active)
		icon_state = "bomb_active"
		planted_icon_state = "mob_" + icon_state

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

/// Plants the bomb on our victim and adds it to the contractor's bomb UI
/obj/item/contractor_bomb/proc/attach_to(mob/living/carbon/human/victim, datum/contractor_state/controlling_state)
	owner = victim
	forceMove(victim.get_bodypart(BODY_ZONE_CHEST))
	plastic_overlay.layer = FLOAT_LAYER
	victim.add_overlay(plastic_overlay)
	RegisterSignal(victim, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_item_interact))

	if(isnull(controlling_state))
		arm()
		return

	controlling_state.bomb_implants += src

/// Lets you install a nuclear core if the victim is clicked on with the core/container while the bomb is glued on
/obj/item/contractor_bomb/proc/on_item_interact(atom/source, mob/living/user, obj/item/tool, list/modifiers)
	SIGNAL_HANDLER

	if(istype(tool, /obj/item/nuke_core))
		INVOKE_ASYNC(src, PROC_REF(install_core), user, tool, source)
		return ITEM_INTERACT_SUCCESS

	else if(istype(tool, /obj/item/nuke_core_container))
		var/obj/item/nuke_core_container/container = tool
		INVOKE_ASYNC(src, PROC_REF(install_core), user, container.core, source)
		return ITEM_INTERACT_SUCCESS

	else
		return NONE

/// Installs the nuke core into the bomb after a do_after
/obj/item/contractor_bomb/proc/install_core(mob/living/user, obj/item/nuke_core/core, atom/target)
	if(!do_after(user, 5 SECONDS, target))
		return
	transfer_core(core)

// XANTODO: SECOND REMINDER THIS WHOLE PROC IS PLACEHOLDER JUST FOR TESTING SHIT OUT DO NOT LEAVE THIS IN
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
	//active = TRUE

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
	RegisterSignal(bomb_target, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(on_item_interact))
	return TRUE
// XANTODO: SECOND REMINDER THIS WHOLE PROC IS PLACEHOLDER JUST FOR TESTING SHIT OUT DO NOT LEAVE THIS IN
// DON'T LEAVE THIS IN  ^^^^^^^^^^^^^^^^^^^^^

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

/// Begins defusing the bomb
/obj/item/contractor_bomb/proc/perform_defusal(mob/defuser)
	if(active) // If the bomb is already active, we are more lenient
		defusal_loop(defuser)
		return

	// ANNETODO: Maybe you want a better prompt?
	if(tgui_alert(defuser, "Are you sure you want to attempt to defuse the bomb while inactive? The difficulty will be higher", "Attempt Defuse?", list("Try my luck", "Cancel"), 10 SECONDS) != "Try my luck")
		return
	// Arms the bomb and gives you the negative effects of cutting a bomb wire. It effectively means you still have 2 explosive cables but only need to hit 1 to explode
	arm()
	bad_defusal = TRUE
	ex_dev = 5
	ex_heavy = 10
	ex_light = 20
	ex_flame = 20
	detonation_timer = world.time + 30 SECONDS
	defusal_loop(defuser)

/// Shows the radial menu, performs the cut on the selected wire
/obj/item/contractor_bomb/proc/defusal_loop(mob/defuser)
	var/selection = show_radial_menu(defuser, owner, cable_icons, require_near = TRUE)
	if(!selection)
		return
	var/datum/contractor_wire/chosen_wire = cable_list[selection]
	if(chosen_wire.cut)
		return
	cut_wire(chosen_wire)

/// Cuts the selected wire, will perform effects based on the wire (or be a dud)
/obj/item/contractor_bomb/proc/cut_wire(datum/contractor_wire/chosen_wire, mob/defuser)
	cable_icons -= chosen_wire.name

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
	defuser.playsound_local(defuser, 'sound/items/tools/wirecutter.ogg', 50, 0)
	if(active)
		defusal_loop(defuser) // Loop until defusal, cancellation or explosion

/obj/item/contractor_bomb/proc/defuse()
	active = FALSE
	detonation_timer = null
	next_beep = null
	STOP_PROCESSING(SSobj, src)
	owner.cut_overlay(plastic_overlay)
	owner.updateappearance(UPDATE_OVERLAYS)
	owner.temporarilyRemoveItemFromInventory(src, TRUE)
	forceMove(get_turf(src))
	update_appearance()

/// Causes an explosion and eradicates our explodee from existence
/obj/item/contractor_bomb/proc/try_detonate()
	if(is_nuclear)
		// These values are hard set instead of being x3, because it is forced to be the maximum size variant.
		// I don't want to see a contractor add a nuke core to the bomb just for it to be 1 deva *3
		ex_dev = 20
		ex_heavy = 40
		ex_light = 60
		ex_flame = 60

	var/obj/item/organ/brain/to_delete = locate(/obj/item/organ/brain) in owner.organs
	if(to_delete)
		to_delete.Remove(owner)
		qdel(to_delete)

	var/obj/item/organ/heart/cybernetic/anomalock/funny_organ = locate(/obj/item/organ/heart/cybernetic/anomalock) in owner.organs
	if(funny_organ?.core)
		new /obj/energy_ball(src)

	explosion(src, ex_dev, ex_heavy, ex_light, ex_flame, ignorecap = is_nuclear)
	qdel(src)

/obj/item/contractor_bomb/proc/seconds_remaining()
	if(active)
		. = max(0, round((detonation_timer - world.time) / 10))
	else
		. = det_time

/// Arms the bomb, starting the countdown to detonation. Cannot be disarmed once armed.
/obj/item/contractor_bomb/proc/arm()
	if(active)
		return FALSE
	active = TRUE
	detonation_timer = world.time + det_time
	next_beep = world.time
	START_PROCESSING(SSobj, src)
	if(!isnull(owner))
		owner.investigate_log("had their contractor bomb implant remotely armed.", INVESTIGATE_DEATHS)
		message_admins("[ADMIN_LOOKUPFLW(owner)]'s contractor bomb implant was remotely armed at [ADMIN_VERBOSEJMP(owner)].")
	return TRUE

/// Builds a base64 mugshot of the owner for the detonation suite UI, cached after first use.
/obj/item/contractor_bomb/proc/get_mugshot()
	if(!isnull(cached_mugshot))
		return cached_mugshot
	if(isnull(owner))
		return null
	var/mutable_appearance/portrait = new(owner)
	portrait.dir = SOUTH
	cached_mugshot = icon2base64(getFlatIcon(portrait))
	return cached_mugshot

/// Returns a list of fluff vitals + status for the detonation suite UI.
/// Blood pressure, blood oxygen and pulse are simulated from blood volume and
/// crit state with a little randomization - it is flavor, not a real readout.
/obj/item/contractor_bomb/proc/to_ui_data()
	var/list/data = list(
		"ref" = REF(src),
		"armed" = active,
		"nuclear" = is_nuclear,
		"time_left" = active ? max(0, detonation_timer - world.time) : 0,
		"fuse_length" = det_time,
		"mugshot" = get_mugshot(),
	)

	var/mob/living/carbon/human/victim = owner
	if(!istype(victim))
		data["name"] = "Signal Lost"
		data["rank"] = "Unknown"
		data["location"] = "Unknown"
		data["dead"] = TRUE
		data["stat_text"] = "NO SIGNAL"
		data["blood_pressure"] = "--/--"
		data["blood_oxygen"] = 0
		data["pulse"] = 0
		data["brute"] = 0
		data["burn"] = 0
		data["tox"] = 0
		data["oxy"] = 0
		data["max_health"] = 100
		return data

	var/is_dead = (victim.stat == DEAD)
	var/blood_pct = clamp(round((victim.blood_volume / BLOOD_VOLUME_NORMAL) * 100), 0, 100)
	var/oxy = round(victim.get_oxy_loss())
	// Health as a 0..1 vitality factor blending blood volume and overall health.
	var/vitality = clamp(((blood_pct / 100) + (victim.health / victim.maxHealth)) / 2, 0, 1)

	data["name"] = victim.real_name
	data["rank"] = victim.mind?.assigned_role?.title || victim.job || "Unknown"
	data["location"] = get_area_name(victim, format_text = TRUE) || "Unknown"
	data["dead"] = is_dead
	data["brute"] = round(victim.get_brute_loss())
	data["burn"] = round(victim.get_fire_loss())
	data["tox"] = round(victim.get_tox_loss())
	data["oxy"] = oxy
	data["max_health"] = victim.maxHealth

	switch(victim.stat)
		if(CONSCIOUS)
			data["stat_text"] = "CONSCIOUS"
		if(SOFT_CRIT)
			data["stat_text"] = "PAIN CRIT"
		if(UNCONSCIOUS, HARD_CRIT)
			data["stat_text"] = "CRITICAL"
		if(DEAD)
			data["stat_text"] = "FLATLINE"
		else
			data["stat_text"] = "UNKNOWN"

	if(is_dead)
		data["blood_pressure"] = "0/0"
		data["blood_oxygen"] = 0
		data["pulse"] = 0
		return data

	// Pulse climbs as vitality drops (shock/tachycardia), with a little jitter.
	data["pulse"] = clamp(round(64 + (1 - vitality) * 90 + rand(-4, 4)), 0, 220)
	// Blood oxygen saturation falls with blood loss and oxygen damage.
	data["blood_oxygen"] = clamp(round(99 - (100 - blood_pct) * 0.4 - oxy * 0.3 + rand(-2, 2)), 0, 100)
	// Systolic / diastolic pressures scale with vitality.
	var/systolic = clamp(round(118 * vitality + 12 + rand(-6, 6)), 0, 200)
	var/diastolic = clamp(round(76 * vitality + 8 + rand(-4, 4)), 0, 140)
	data["blood_pressure"] = "[systolic]/[diastolic]"
	return data

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

