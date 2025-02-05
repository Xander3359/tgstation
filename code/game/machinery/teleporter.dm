/obj/machinery/teleport
	name = "teleport"
	icon = 'icons/obj/machines/teleporter.dmi'
	density = TRUE

/obj/machinery/teleport/hub
	name = "teleporter hub"
	desc = "It's the hub of a teleporting machine."
	icon_state = "tele0"
	base_icon_state = "tele"
	circuit = /obj/item/circuitboard/machine/teleporter_hub
	var/accuracy = 0
	var/obj/machinery/teleport/station/power_station
	var/calibrated = FALSE//Calibration prevents mutation

/obj/machinery/teleport/hub/Initialize(mapload)
	. = ..()
	link_power_station()

/obj/machinery/teleport/hub/Destroy()
	if (power_station)
		power_station.teleporter_hub = null
		power_station = null
	return ..()

/obj/machinery/teleport/hub/RefreshParts()
	. = ..()
	var/A = 0
	for(var/datum/stock_part/matter_bin/matter_bin in component_parts)
		A += matter_bin.tier
	accuracy = A

/obj/machinery/teleport/hub/examine(mob/user)
	. = ..()
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Success chance is <b>[70 + (accuracy * 10)]%</b>.")

/obj/machinery/teleport/hub/proc/link_power_station()
	if(power_station)
		return
	for(var/direction in GLOB.cardinals)
		power_station = locate(/obj/machinery/teleport/station, get_step(src, direction))
		if(power_station)
			power_station.link_console_and_hub()
			break
	return power_station

/obj/machinery/teleport/hub/Bumped(atom/movable/AM)
	if(is_centcom_level(z))
		to_chat(AM, span_warning("You can't use this here!"))
		return
	if(is_ready())
		teleport(AM)

/obj/machinery/teleport/hub/attackby(obj/item/W, mob/user, params)
	if(default_deconstruction_screwdriver(user, "tele-o", "tele0", W))
		if(power_station?.engaged)
			power_station.engaged = 0 //hub with panel open is off, so the station must be informed.
			update_appearance()
		return
	if(default_deconstruction_crowbar(W))
		return
	return ..()

/obj/machinery/teleport/hub/proc/teleport(atom/movable/M as mob|obj, turf/T)
	var/obj/machinery/computer/teleporter/com = power_station.teleporter_console
	if (QDELETED(com))
		return
	var/atom/target
	if(com.target_ref)
		target = com.target_ref.resolve()
	if (!target)
		com.target_ref = null
		visible_message(span_alert("Cannot authenticate locked on coordinates. Please reinstate coordinate matrix."))
		return
	if(!ismovable(M))
		return
	var/turf/start_turf = get_turf(M)
	if(!do_teleport(M, target, channel = TELEPORT_CHANNEL_BLUESPACE))
		return
	playsound(loc, SFX_PORTAL_ENTER, 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	use_energy(active_power_usage)
	new /obj/effect/temp_visual/portal_animation(start_turf, src, M)
	if(!calibrated && ishuman(M) && prob(30 - ((accuracy) * 10))) //oh dear a problem
		var/mob/living/carbon/human/human = M
		if(!(human.mob_biotypes & (MOB_ROBOTIC|MOB_MINERAL|MOB_UNDEAD|MOB_SPIRIT)))
			var/datum/species/species_to_transform = /datum/species/fly
			if(check_holidays(MOTH_WEEK))
				species_to_transform = /datum/species/moth
			if(human.dna && human.dna.species.id != initial(species_to_transform.id))
				to_chat(M, span_hear("You hear a buzzing in your ears."))
				human.set_species(species_to_transform)
				human.log_message("was turned into a [initial(species_to_transform.name)] through [src].", LOG_GAME)
	calibrated = FALSE

/obj/machinery/teleport/hub/update_icon_state()
	icon_state = "[base_icon_state][panel_open ? "-o" : (is_ready() ? 1 : 0)]"
	return ..()

/obj/machinery/teleport/hub/proc/is_ready()
	. = !panel_open && !(machine_stat & (BROKEN|NOPOWER)) && power_station && power_station.engaged && !(power_station.machine_stat & (BROKEN|NOPOWER))

/obj/machinery/teleport/station
	name = "teleporter station"
	desc = "The power control station for a bluespace teleporter. Used for toggling power, and can activate a test-fire to prevent malfunctions."
	icon_state = "controller"
	base_icon_state = "controller"
	circuit = /obj/item/circuitboard/machine/teleporter_station
	var/engaged = FALSE
	var/obj/machinery/computer/teleporter/teleporter_console
	var/obj/machinery/teleport/hub/teleporter_hub
	var/list/linked_stations = list()
	var/efficiency = 0

/obj/machinery/teleport/station/Initialize(mapload)
	. = ..()
	link_console_and_hub()

/obj/machinery/teleport/station/RefreshParts()
	. = ..()
	var/E
	for(var/datum/stock_part/capacitor/C in component_parts)
		E += C.tier
	efficiency = E - 1

/obj/machinery/teleport/station/examine(mob/user)
	. = ..()
	if(!panel_open)
		. += span_notice("The panel is <i>screwed</i> in, obstructing the linking device and wiring panel.")
	else
		. += span_notice("The <i>linking</i> device is now able to be <i>scanned</i> with a multitool.")
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: This station can be linked to <b>[efficiency]</b> other station(s).")

/obj/machinery/teleport/station/proc/link_console_and_hub()
	for(var/direction in GLOB.cardinals)
		teleporter_hub = locate(/obj/machinery/teleport/hub, get_step(src, direction))
		if(teleporter_hub)
			teleporter_hub.link_power_station()
			break
	for(var/direction in GLOB.cardinals)
		teleporter_console = locate(/obj/machinery/computer/teleporter, get_step(src, direction))
		if(teleporter_console)
			teleporter_console.link_power_station()
			break
	return teleporter_hub && teleporter_console


/obj/machinery/teleport/station/Destroy()
	if(teleporter_hub)
		teleporter_hub.power_station = null
		teleporter_hub.update_appearance()
		teleporter_hub = null
	if (teleporter_console)
		teleporter_console.power_station = null
		teleporter_console = null
	return ..()

/obj/machinery/teleport/station/multitool_act(mob/living/user, obj/item/multitool/tool)
	. = NONE

	if(panel_open)
		tool.set_buffer(src)
		balloon_alert(user, "saved to multitool buffer")
		return ITEM_INTERACT_SUCCESS

	if(!istype(tool.buffer, /obj/machinery/teleport/station) || tool.buffer == src)
		return ITEM_INTERACT_BLOCKING

	if(linked_stations.len < efficiency)
		linked_stations.Add(tool.buffer)
		tool.set_buffer(null)
		balloon_alert(user, "data uploaded from buffer")
		return ITEM_INTERACT_SUCCESS

/obj/machinery/teleport/station/attackby(obj/item/W, mob/user, params)
	if(default_deconstruction_screwdriver(user, "controller-o", "controller", W))
		update_appearance()
		return

	else if(default_deconstruction_crowbar(W))
		return
	else
		return ..()

/obj/machinery/teleport/station/interact(mob/user)
	toggle(user)

/obj/machinery/teleport/station/proc/toggle(mob/user)
	if(machine_stat & (BROKEN|NOPOWER) || !teleporter_hub || !teleporter_console )
		return
	if (teleporter_console.target_ref?.resolve())
		if(teleporter_hub.panel_open || teleporter_hub.machine_stat & (BROKEN|NOPOWER))
			to_chat(user, span_alert("The teleporter hub isn't responding."))
		else
			engaged = !engaged
			use_energy(active_power_usage)
			to_chat(user, span_notice("Teleporter [engaged ? "" : "dis"]engaged!"))
	else
		teleporter_console.target_ref = null
		to_chat(user, span_alert("No target detected."))
		engaged = FALSE
	teleporter_hub.update_appearance()
	add_fingerprint(user)

/obj/machinery/teleport/station/power_change()
	. = ..()
	if(teleporter_hub)
		teleporter_hub.update_appearance()

/obj/machinery/teleport/station/update_icon_state()
	if(panel_open)
		icon_state = "[base_icon_state]-o"
		return ..()
	if(machine_stat & (BROKEN|NOPOWER))
		icon_state = "[base_icon_state]-p"
		return ..()
	if(teleporter_console?.calibrating)
		icon_state = "[base_icon_state]-c"
		return ..()
	icon_state = base_icon_state
	return ..()

/obj/machinery/teleport/syndicate_gate
	icon = 'icons/obj/machines/teleporter_multitile.dmi'
	icon_state = "teleporter_off"
	pixel_x = -32
	///Tracks wether the portal is active or not, used to toggle the sprite
	var/activated = FALSE
	///When a painting targets us as their signal, we save them as our return target
	var/atom/return_target
	///Internal timer to prevent audio spam.
	var/next_beep = 0

/obj/machinery/teleport/syndicate_gate/Destroy()
	GLOB.active_syndicate_gates -= src
	return_target = null
	return ..()

/obj/machinery/teleport/syndicate_gate/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_PAINTING_SET_TARGET, PROC_REF(on_target_set))
	RegisterSignals(src, list(COMSIG_QDELETING, COMSIG_MACHINERY_BROKEN, COMSIG_PAINTING_CUT_CONNECTIONS), PROC_REF(remove_connections))

/obj/machinery/teleport/syndicate_gate/Bumped(mob/living/user)
	if(!ishuman(user))
		return //Otherwise the sparks keep making the sound spam
	if(!return_target)
		if(next_beep <= world.time)
			next_beep = world.time + (2 SECONDS)
			playsound(src, 'sound/machines/scanbuzz.ogg', 100, FALSE)
		return

	if(user.mind.has_antag_datum(/datum/antagonist/satellite_agent))
		var/confirmation = tgui_alert(user, "Are you sure you wish to leave the satellite, this should only be a last resort to help a field agent", "WARNING", list("Teleport?", "cancel"))
		if(confirmation != "Teleport?")
			return
		if(!Adjacent(user))
			return

	var/actual_target = return_target
	if(!(locate(/obj/item/implant/gate_authorization) in user.implants) || return_target == "Random Teleport")
		actual_target = get_random_station_turf() //Good luck
	do_teleport(user, actual_target, forced = TRUE)

///When a painting sets us as their teleport target, we save them as a reference so we may return to it
/obj/machinery/teleport/syndicate_gate/proc/on_target_set(datum/source, atom/return_painting)
	SIGNAL_HANDLER
	remove_connections(src)
	return_target = return_painting
	update_appearance(UPDATE_ICON)

///Removes any active return_target
/obj/machinery/teleport/syndicate_gate/proc/remove_connections(datum/source)
	SIGNAL_HANDLER
	if(!return_target)
		update_appearance(UPDATE_ICON)
		return

	if(!istext(return_target))
		var/atom/old_return_target = return_target
		return_target = null
		SEND_SIGNAL(old_return_target, COMSIG_GATE_CUT_CONNECTIONS, src)
	update_appearance(UPDATE_ICON)

/obj/machinery/teleport/syndicate_gate/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(!(src in GLOB.active_syndicate_gates))
		GLOB.active_syndicate_gates += src
		user.balloon_alert(user, "activated")
		activated = TRUE
		update_appearance(UPDATE_ICON)
		return

	if(return_target)
		var/confirmation = tgui_alert(user, "This will cut the link to any other teleporter, are you sure?", "WARNING", list("DISABLE", "cancel"))
		if(confirmation != "DISABLE")
			return

	GLOB.active_syndicate_gates -= src
	user.balloon_alert(user, "deactivated")
	activated = FALSE
	remove_connections(src)
	update_appearance(UPDATE_ICON)

/obj/machinery/teleport/syndicate_gate/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return .

	if(!activated)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(return_target)
		attack_hand(user, modifiers)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	var/list/targets = list("Random Teleport" = "Random Teleport")
	for(var/obj/structure/sign/painting/syndicate_teleporter/potential_target in GLOB.active_syndicate_paintings)
		if(potential_target.integrity_compromised)
			continue

		var/list/area_index = list()
		var/area/target_area = get_area(potential_target)
		targets[avoid_assoc_duplicate_keys(format_text(target_area.name), area_index)] = potential_target

	var/target_input = tgui_input_list(user, "Where to launch to?", "Set Teleporter?", sort_list(targets))
	if(!target_input)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN
	return_target = targets[target_input]
	if(!istext(return_target))
		SEND_SIGNAL(return_target, COMSIG_GATE_SET_TARGET, src)
	update_appearance(UPDATE_ICON)
	user.balloon_alert(user, "target set")
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/machinery/teleport/syndicate_gate/update_icon_state()
	. = ..()
	if(return_target)
		icon_state = "teleporter_active"
	else if(activated)
		icon_state = "teleporter_on"
	else
		icon_state = "teleporter_off"
