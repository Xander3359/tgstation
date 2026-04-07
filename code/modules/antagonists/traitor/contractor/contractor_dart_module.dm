#define DART_TYPE_CAMERA "camera"
#define DART_TYPE_GLUE "glue"
#define DART_TYPE_TRIPWIRE "tripwire"
#define DART_MODULE_IMMUNITY_TRAIT "contractor_dart_module_immunity"

GLOBAL_LIST_EMPTY(camera_dart_audio_logs)

#define CAMERA_DART_AUDIO_MAX_ENTRIES 30

/proc/add_camera_dart_audio_entry(mob/living/tracker, mob/living/target, message)
	if(!tracker || !target || !length(message))
		return
	var/tracker_ref = REF(tracker)
	var/list/audio_log = GLOB.camera_dart_audio_logs[tracker_ref]
	if(!islist(audio_log))
		audio_log = list()
		GLOB.camera_dart_audio_logs[tracker_ref] = audio_log
	audio_log += "[target.name]: [message]"
	if(length(audio_log) > CAMERA_DART_AUDIO_MAX_ENTRIES)
		audio_log.Cut(1, length(audio_log) - CAMERA_DART_AUDIO_MAX_ENTRIES + 1)

/proc/get_camera_dart_audio_log(mob/living/tracker)
	if(!tracker)
		return list()
	var/list/audio_log = GLOB.camera_dart_audio_logs[REF(tracker)]
	if(!islist(audio_log))
		return list()
	return audio_log.Copy()

/datum/contractor_dart_type
	/// Unique ID used for selection and cooldown bookkeeping.
	var/id
	/// User-facing display name.
	var/name = "Dart"
	/// Projectile fired by this dart type.
	var/projectile_path = /obj/projectile/dart
	/// Icon file used by the radial menu.
	var/radial_icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_dart_projectiles.dmi'
	/// Icon state used by the radial menu.
	var/radial_icon_state = "dart"
	/// Cooldown length after firing. Zero means no cooldown.
	var/cooldown_duration = 0
	/// Alert text shown when on cooldown.
	var/cooldown_alert_name = "dart"
	/// Per-module-instance cooldown state for this dart.
	COOLDOWN_DECLARE(cooldown)

/datum/contractor_dart_type/proc/is_on_cooldown()
	return cooldown_duration && !COOLDOWN_FINISHED(src, cooldown)

/datum/contractor_dart_type/proc/get_radial_choice(obj/item/mod/module/dart_gun/module)
	var/datum/radial_menu_choice/choice = new
	choice.image = image(icon = radial_icon, icon_state = radial_icon_state)
	choice.name = name
	if(is_on_cooldown())
		choice.name += " (COOLDOWN)"
		choice.image.color = "#888888"
	return choice

/datum/contractor_dart_type/proc/can_fire(obj/item/mod/module/dart_gun/module, mob/activator)
	if(!is_on_cooldown())
		return TRUE
	module.balloon_alert(activator, "[cooldown_alert_name] on cooldown!")
	return FALSE

/datum/contractor_dart_type/proc/on_fire(obj/item/mod/module/dart_gun/module)
	if(cooldown_duration)
		COOLDOWN_START(src, cooldown, cooldown_duration)

/datum/contractor_dart_type/camera
	id = DART_TYPE_CAMERA
	name = "Camera Dart"
	projectile_path = /obj/projectile/dart/camera
	radial_icon_state = "dart"
	cooldown_duration = 10 SECONDS
	cooldown_alert_name = "camera dart"

/datum/contractor_dart_type/glue
	id = DART_TYPE_GLUE
	name = "Glue Dart"
	projectile_path = /obj/projectile/dart/glue
	radial_icon_state = "glue_closed"
	cooldown_duration = 35 SECONDS
	cooldown_alert_name = "glue dart"

/datum/contractor_dart_type/tripwire
	id = DART_TYPE_TRIPWIRE
	name = "Tripwire Dart"
	projectile_path = /obj/projectile/dart/tripwire
	radial_icon_state = "tripwire"

/// Dart gun MOD module. Fires specialized darts with unique effects.
/// Right-click on the action button to select dart type via radial menu.
/obj/item/mod/module/dart_gun
	name = "Dart Gun module"
	desc = "A module that launches a number of specialized darts, each with unique functions. \
		Right-click on the action button to choose which dart type to use."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_modules.dmi'
	icon_state = "dart"
	removable = FALSE
	module_type = MODULE_ACTIVE
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 3
	incompatible_modules = list(/obj/item/mod/module/dart_gun)
	required_slots = list(ITEM_SLOT_GLOVES)
	/// Currently selected dart type
	var/selected_dart = DART_TYPE_CAMERA
	/// Maximum number of active tripwire traps
	var/max_tripwires = 3
	/// List of active tripwire traps
	var/list/active_tripwires = list()
	/// Supported dart datum typepaths for this module.
	var/list/dart_typepaths = list(
		/datum/contractor_dart_type/camera,
		/datum/contractor_dart_type/glue,
		/datum/contractor_dart_type/tripwire,
	)
	/// Instanced dart metadata, keyed by dart ID.
	var/list/dart_types

/obj/item/mod/module/dart_gun/proc/get_dart_types()
	if(dart_types)
		return dart_types
	dart_types = list()
	for(var/dart_typepath in dart_typepaths)
		var/datum/contractor_dart_type/dart = new dart_typepath
		dart_types[dart.id] = dart
	return dart_types

/obj/item/mod/module/dart_gun/proc/get_dart_type(dart_type)
	return get_dart_types()[dart_type]

/obj/item/mod/module/dart_gun/on_select(mob/activator)
	return ..()

/obj/item/mod/module/dart_gun/on_equip()
	. = ..()
	if(mod?.wearer)
		ADD_TRAIT(mod.wearer, DART_MODULE_IMMUNITY_TRAIT, REF(src))

/obj/item/mod/module/dart_gun/on_unequip()
	if(mod?.wearer)
		REMOVE_TRAIT(mod.wearer, DART_MODULE_IMMUNITY_TRAIT, REF(src))
	return ..()

/obj/item/mod/module/dart_gun/proc/show_dart_radial(mob/user)
	var/list/choices = list()
	for(var/dart_type in get_dart_types())
		var/datum/contractor_dart_type/dart = get_dart_type(dart_type)
		choices[dart_type] = dart.get_radial_choice(src)

	var/selected = show_radial_menu(user, user, choices, tooltips = TRUE, require_near = FALSE)
	if(!selected)
		return
	selected_dart = selected
	var/datum/contractor_dart_type/selected_type = get_dart_type(selected_dart)
	balloon_alert(user, "[selected_type.name] selected")

/obj/item/mod/module/dart_gun/on_use(mob/activator)
	var/datum/contractor_dart_type/dart = get_dart_type(selected_dart)
	if(!dart)
		return
	if(!dart.can_fire(src, activator))
		return

	var/obj/projectile/dart/new_dart = new dart.projectile_path(mod.wearer.loc, src)
	new_dart.firer = mod.wearer
	new_dart.fired_from = src
	new_dart.aim_projectile(get_ranged_target_turf(mod.wearer, mod.wearer.dir, new_dart.range), mod.wearer)
	playsound(src, 'sound/items/weapons/gun/general/heavy_shot_suppressed.ogg', 30, TRUE)
	INVOKE_ASYNC(new_dart, TYPE_PROC_REF(/obj/projectile, fire))
	drain_power(use_energy_cost)
	dart.on_fire(src)

/obj/item/mod/module/dart_gun/proc/remove_tripwire(datum/source)
	SIGNAL_HANDLER
	active_tripwires -= source

/datum/action/item_action/mod/pinnable/module/dart_gun

/datum/action/item_action/mod/pinnable/module/dart_gun/do_effect(trigger_flags)
	if(trigger_flags & TRIGGER_SECONDARY_ACTION)
		var/obj/item/mod/module/dart_gun/dart_module = module
		if(istype(dart_module))
			dart_module.show_dart_radial(owner)
		return
	return ..()

/obj/projectile/dart
	name = "dart"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_dart_projectiles.dmi'
	icon_state = "dart"
	damage = 1
	range = 9
	hitsound = 'sound/items/weapons/gun/general/heavy_shot_suppressed.ogg'
	/// Reference to the dart gun module
	var/datum/weakref/dart_module

/obj/projectile/dart/Initialize(mapload, obj/item/mod/module/dart_gun/source_module)
	. = ..()
	if(source_module)
		dart_module = WEAKREF(source_module)

/// Phasic invisible dart that allows tracking the target. Doesn't warn the victim on hit.
/obj/projectile/dart/camera
	name = "camera dart"
	alpha = 50
	icon_state = "dart"
	hitsound = null
	projectile_phasing = PASSTABLE | PASSGLASS | PASSGRILLE | PASSMACHINE | PASSSTRUCTURE | PASSDOORS

/obj/projectile/dart/camera/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(!isliving(target))
		return
	var/mob/living/victim = target
	var/obj/item/implant/contractor/camera_dart/new_implant = new()
	if(isliving(firer))
		new_implant.tracker_ref = WEAKREF(firer)
	new_implant.implant(victim, null, TRUE, TRUE)

/// A microscopic surveillance implant fired by the camera dart.
/// Silently embeds in the victim, relaying heard speech to the contractor. After
/// 10-15 minutes the foreign body begins causing occasional itching.
/obj/item/implant/contractor/camera_dart
	name = "camera implant"
	desc = "A microscopic surveillance microimplant."
	actions_types = null
	implant_flags = NONE
	implant_info = "A microscopic surveillance device embedded by a specialized dart. \
		Relays ambient audio and allows remote tracking. Causes mild localized \
		irritation after extended integration with surrounding tissue."
	implant_lore = "An ultra-compact surveillance microimplant delivered via contractor dart gun. \
		Completely passive once embedded - no activations, no alerts on the host's end."
	/// Weakref to the contractor who fired the dart
	var/datum/weakref/tracker_ref
	/// Timer ID for the initial itch delay
	var/itch_timer_id

/obj/item/implant/contractor/camera_dart/implant(mob/living/target, mob/user, silent = FALSE, force = FALSE)
	. = ..()
	if(!.)
		return
	RegisterSignal(imp_in, COMSIG_MOVABLE_HEAR, PROC_REF(relay_hearing))
	// Begin itching after 10-15 minutes of implantation
	itch_timer_id = addtimer(CALLBACK(src, PROC_REF(do_itch)), rand(10 MINUTES, 15 MINUTES), TIMER_STOPPABLE|TIMER_DELETE_ME)

/obj/item/implant/contractor/camera_dart/removed(mob/living/source, silent, special)
	UnregisterSignal(source, COMSIG_MOVABLE_HEAR)
	if(itch_timer_id)
		deltimer(itch_timer_id)
		itch_timer_id = null
	return ..()

/obj/item/implant/contractor/camera_dart/proc/relay_hearing(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	var/mob/living/tracker = tracker_ref?.resolve()
	if(isnull(tracker))
		return
	var/message = hearing_args[HEARING_RAW_MESSAGE]
	if(!message)
		return
	add_camera_dart_audio_entry(tracker, imp_in, message)

/// Called after the initial delay, then repeats periodically to simulate foreign-body irritation.
/obj/item/implant/contractor/camera_dart/proc/do_itch()
	itch_timer_id = null
	if(QDELETED(src) || !imp_in)
		return
	imp_in.itch()
	// Schedule next itch in 1-3 minutes
	itch_timer_id = addtimer(CALLBACK(src, PROC_REF(do_itch)), rand(1 MINUTES, 3 MINUTES), TIMER_STOPPABLE|TIMER_DELETE_ME)

/// Dart that covers the victim in sticky resin, taping their mouth shut, reducing speed, and causing sticking.
/obj/projectile/dart/glue
	name = "glue dart"
	icon_state = "glue_closed"
	damage = 0

/obj/projectile/dart/glue/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	// Leave a spent glue decal where it hit
	new /obj/effect/decal/cleanable/glue_splat(get_turf(target))

	if(!isliving(target))
		return
	var/mob/living/victim = target
	victim.apply_status_effect(/datum/status_effect/glue_dart)

/// Glue splat decal left where a glue dart hits
/obj/effect/decal/cleanable/glue_splat
	name = "glue splat"
	desc = "A sticky glob of hardened resin."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_dart_projectiles.dmi'
	icon_state = "glue"

/// Status effect from glue dart - sticky resin covering the victim
/datum/status_effect/glue_dart
	id = "glue_dart"
	duration = 30 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/glue_dart
	/// Leash component currently keeping us stuck to another mob
	var/datum/weakref/applied_leash_ref

/datum/movespeed_modifier/glue_slowdown
	multiplicative_slowdown = 2


/datum/status_effect/glue_dart/on_creation(mob/living/new_owner)
	return ..()

/datum/status_effect/glue_dart/on_apply()
	. = ..()
	// Slow the victim down
	owner.add_movespeed_modifier(/datum/movespeed_modifier/glue_slowdown)
	ADD_TRAIT(owner, TRAIT_MUTE, TRAIT_STATUS_EFFECT(id))

	// Register signals for sticking mechanics
	RegisterSignal(owner, COMSIG_MOVABLE_BUMP, PROC_REF(on_bump))
	RegisterSignal(owner, COMSIG_ATOM_ATTACKBY, PROC_REF(on_pickup_attempt))
	RegisterSignal(owner, COMSIG_COMPONENT_CLEAN_ACT, PROC_REF(on_cleaned))

	owner.visible_message(
		span_danger("[owner] is covered in sticky resin!"),
		span_userdanger("You are covered in sticky resin! Your movements are slowed and your mouth is sealed!"),
	)

/datum/status_effect/glue_dart/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/glue_slowdown)
	REMOVE_TRAIT(owner, TRAIT_MUTE, TRAIT_STATUS_EFFECT(id))
	UnregisterSignal(owner, list(COMSIG_MOVABLE_BUMP, COMSIG_ATOM_ATTACKBY, COMSIG_COMPONENT_CLEAN_ACT))

	var/datum/component/leash/applied_leash = applied_leash_ref?.resolve()
	if(applied_leash)
		qdel(applied_leash)
	applied_leash_ref = null

	owner.visible_message(
		span_notice("The sticky resin on [owner] dissolves away."),
		span_notice("The sticky resin covering you dissolves away."),
	)

/// When the glued victim bumps into a dense object or another person, they stick to them
/datum/status_effect/glue_dart/proc/on_bump(datum/source, atom/bumped_atom)
	SIGNAL_HANDLER
	if(!isliving(bumped_atom))
		return
	var/mob/living/other = bumped_atom
	// Stick together - start pulling each other
	if(!owner.pulling)
		INVOKE_ASYNC(src, PROC_REF(stick_to_mob), other)

/datum/status_effect/glue_dart/proc/stick_to_mob(mob/living/other)
	var/datum/component/leash/current_leash = applied_leash_ref?.resolve()
	if(current_leash)
		qdel(current_leash)
	var/datum/component/leash/new_leash = owner.AddComponent(/datum/component/leash, owner = other, distance = 1)
	applied_leash_ref = WEAKREF(new_leash)
	owner.visible_message(
		span_warning("[owner] sticks to [other]!"),
		span_warning("You stick to [other] from the resin!"),
	)

/// Objects picked up by the target require extra time to remove
/datum/status_effect/glue_dart/proc/on_pickup_attempt(datum/source, obj/item/weapon, mob/living/attacker)
	SIGNAL_HANDLER
	return // sticky items handled by the status effect duration

/// Washed off by soap/showers and similar clean effects.
/datum/status_effect/glue_dart/proc/on_cleaned(datum/source, clean_types)
	SIGNAL_HANDLER

	if(owner.remove_status_effect(/datum/status_effect/glue_dart))
		return COMPONENT_CLEANED | COMPONENT_CLEANED_GAIN_XP

/atom/movable/screen/alert/status_effect/glue_dart
	name = "Sticky Resin"
	desc = "You are covered in sticky resin! Your mouth is sealed and your movement is slowed. Can be washed off."

/// Dart that embeds a mine into a wall and projects a laser tripwire beam up to 3 tiles into the open.
/obj/projectile/dart/tripwire
	name = "tripwire dart"
	icon_state = "tripwire"
	damage = 0
	range = 15

/obj/projectile/dart/tripwire/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	// Can only attach to walls and windows
	var/turf/target_turf = get_turf(target)
	if(!isclosedturf(target_turf) && !locate(/obj/structure/window) in target_turf)
		if(firer)
			to_chat(firer, span_warning("The tripwire dart can only attach to walls or windows!"))
		return

	var/obj/item/mod/module/dart_gun/dart_mod = dart_module?.resolve()
	if(!dart_mod)
		return

	// Expire oldest mine if we're at the limit
	while(length(dart_mod.active_tripwires) >= dart_mod.max_tripwires)
		var/obj/structure/contractor_tripwire_mine/oldest = dart_mod.active_tripwires[1]
		qdel(oldest)

	// Determine beam direction: from wall toward the firer (into open space)
	var/beam_dir = SOUTH
	if(firer)
		var/raw_dir = get_dir(target_turf, get_turf(firer))
		if(raw_dir & NORTH)
			beam_dir = NORTH
		else if(raw_dir & SOUTH)
			beam_dir = SOUTH
		else if(raw_dir & EAST)
			beam_dir = EAST
		else
			beam_dir = WEST

	// Mine is placed on the first open turf adjacent to the wall
	var/turf/mine_turf = get_step(target_turf, beam_dir)
	if(!mine_turf || !istype(mine_turf, /turf/open))
		if(firer)
			to_chat(firer, span_warning("No room to place the tripwire mine!"))
		return

	var/obj/structure/contractor_tripwire_mine/mine = new(mine_turf, beam_dir)
	dart_mod.active_tripwires += mine
	RegisterSignal(mine, COMSIG_QDELETING, TYPE_PROC_REF(/obj/item/mod/module/dart_gun, remove_tripwire))

/// The mine body that anchors the tripwire beam to a wall face.
/// Screwdriver opens the cover; empty hand on an open mine disarms it.
/obj/structure/contractor_tripwire_mine
	name = "tripwire mine"
	desc = "A small mine projecting a near-invisible tripwire beam. Unscrew the cover, then disarm with bare hands."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_tripwire.dmi'
	icon_state = "mine-closed"
	anchored = TRUE
	density = FALSE
	max_integrity = 40
	/// Direction the beam extends (away from the wall)
	var/beam_dir = SOUTH
	/// Beam datum handling line rendering and crossed checks.
	var/datum/beam/tripwire_beam
	/// Whether the cover has been unscrewed
	var/opened = FALSE

/obj/structure/contractor_tripwire_mine/Initialize(mapload, in_beam_dir)
	. = ..()
	beam_dir = in_beam_dir
	// Face the mine toward the wall (opposite of beam direction)
	dir = REVERSE_DIR(beam_dir)
	// Find the furthest open turf up to 3 tiles out for the beam endpoint.
	var/turf/current_turf = get_turf(src)
	var/turf/end_turf
	for(var/i in 1 to 3)
		current_turf = get_step(current_turf, beam_dir)
		if(!current_turf || !istype(current_turf, /turf/open))
			break
		end_turf = current_turf

	if(end_turf)
		tripwire_beam = Beam(
			BeamTarget = end_turf,
			icon_state = "middle",
			icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_tripwire.dmi',
			time = INFINITY,
			maxdistance = 4,
			beam_type = /obj/effect/ebeam/reacting,
			emissive = FALSE,
			layer = BELOW_OBJ_LAYER,
		)
		RegisterSignal(tripwire_beam, COMSIG_BEAM_ENTERED, PROC_REF(on_beam_entered))

	// Fade the mine and beam to near-invisible together.
	animate(src, alpha = 30, time = 10 SECONDS)
	if(tripwire_beam?.visuals)
		animate(tripwire_beam.visuals, alpha = 30, time = 10 SECONDS)
	for(var/obj/effect/ebeam/seg as anything in tripwire_beam?.elements)
		animate(seg, alpha = 30, time = 10 SECONDS)

/obj/structure/contractor_tripwire_mine/Destroy()
	if(tripwire_beam)
		UnregisterSignal(tripwire_beam, COMSIG_BEAM_ENTERED)
		qdel(tripwire_beam)
		tripwire_beam = null
	return ..()

/obj/structure/contractor_tripwire_mine/proc/on_beam_entered(datum/source, obj/effect/ebeam/beam_segment, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!isliving(arrived))
		return
	var/mob/living/victim = arrived
	if(HAS_TRAIT(victim, DART_MODULE_IMMUNITY_TRAIT))
		return
	trigger(victim)

/obj/structure/contractor_tripwire_mine/attackby(obj/item/weapon, mob/user, params)
	if(weapon.tool_behaviour == TOOL_SCREWDRIVER)
		opened = !opened
		icon_state = opened ? "mine-open" : "mine-closed"
		to_chat(user, span_notice("You [opened ? "unscrew the mine's cover" : "close the mine back up"]."))
		return
	return ..()

/obj/structure/contractor_tripwire_mine/attack_hand(mob/user, list/modifiers)
	if(opened)
		to_chat(user, span_notice("You carefully disarm the tripwire mine."))
		qdel(src)
		return
	to_chat(user, span_warning("The casing is closed. Use a screwdriver to open it first."))
	return ..()

/// Triggers the mine: lube the victim's turf, then self-destruct.

/obj/structure/contractor_tripwire_mine/proc/trigger(mob/living/victim)
	visible_message(span_danger("[victim] triggers a tripwire!"))
	playsound(src, 'sound/machines/buzz/buzz-sigh.ogg', 50, TRUE)
	var/turf/victim_turf = get_turf(victim)
	if(victim_turf)
		victim_turf.AddComponent(/datum/component/wet_floor, TURF_WET_SUPERLUBE, 100, 0, 30 SECONDS)
	qdel(src)

#undef DART_TYPE_CAMERA
#undef DART_TYPE_GLUE
#undef DART_TYPE_TRIPWIRE
#undef DART_MODULE_IMMUNITY_TRAIT
#undef CAMERA_DART_AUDIO_MAX_ENTRIES
