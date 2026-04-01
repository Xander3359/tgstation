#define DAMAGE_ON_IMPACT 20

/obj/item/grapple_gun
	name = "grapple gun"
	desc = "A small specialised airgun capable of launching a climbing hook into a distant rock face and pulling the user toward it via motorised zip-line. A handy tool for traversing the craggy landscape of lavaland!"
	icon = 'icons/obj/mining.dmi'
	icon_state = "grapple_gun"
	lefthand_file = 'icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/guns_righthand.dmi'
	inhand_icon_state = "gun"
	item_flags = NOBLUDGEON
	///overlay when the hook is retracted
	var/static/mutable_appearance/hook_overlay = mutable_appearance(icon = 'icons/obj/mining.dmi', icon_state = "grapple_gun_hooked")
	///is the hook retracted
	var/hooked = TRUE
	///the beam we draw from user to projectile while in flight
	var/datum/beam/projectile_beam
	///our user currently ziplining
	var/datum/weakref/zipliner
	///the active zipline datum handling our movement
	var/datum/zipline_and_move/active_zipline

/obj/item/grapple_gun/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/item/grapple_gun/Destroy()
	QDEL_NULL(active_zipline)
	QDEL_NULL(projectile_beam)
	zipliner = null
	return ..()

/obj/item/grapple_gun/ranged_interact_with_atom(atom/target, mob/living/user, list/modifiers)
	if(isgroundlessturf(target))
		return NONE
	if(target == user || !hooked)
		return NONE

	if(!lavaland_equipment_pressure_check(get_turf(user)) && !(obj_flags & EMAGGED))
		user.balloon_alert(user, "gun mechanism won't work here!")
		return ITEM_INTERACT_BLOCKING
	if(get_dist(user, target) > 9)
		user.balloon_alert(user, "too far away!")
		return ITEM_INTERACT_BLOCKING

	var/turf/attacked_atom = get_turf(target)
	if(isnull(attacked_atom))
		return ITEM_INTERACT_BLOCKING

	var/list/turf_list = (get_line(user, attacked_atom) - get_turf(src))
	for(var/turf/singular_turf as anything in turf_list)
		if(ischasm(singular_turf))
			continue
		if(!singular_turf.is_blocked_turf())
			continue
		attacked_atom = singular_turf
		break

	if(attacked_atom.IsReachableBy(user))
		return ITEM_INTERACT_BLOCKING

	var/atom/bullet = fire_projectile(/obj/projectile/grapple_hook, attacked_atom, 'sound/items/weapons/zipline_fire.ogg')
	projectile_beam = user.Beam(bullet, icon_state = "zipline_hook", maxdistance = 9, layer = BELOW_MOB_LAYER)
	hooked = FALSE
	RegisterSignal(bullet, COMSIG_PROJECTILE_SELF_ON_HIT, PROC_REF(on_grapple_hit))
	RegisterSignal(bullet, COMSIG_PREQDELETED, PROC_REF(on_grapple_fail))
	zipliner = WEAKREF(user)
	update_appearance()
	return ITEM_INTERACT_SUCCESS

/obj/item/grapple_gun/emag_act(mob/user, obj/item/card/emag/emag_card)
	. = ..()
	if(obj_flags & EMAGGED)
		return FALSE
	balloon_alert(user, "pressure settings overloaded")
	obj_flags |= EMAGGED
	return TRUE

/obj/item/grapple_gun/proc/on_grapple_hit(datum/source, atom/movable/firer, atom/target, Angle)
	SIGNAL_HANDLER

	UnregisterSignal(source, list(COMSIG_PROJECTILE_ON_HIT, COMSIG_PREQDELETED))
	QDEL_NULL(projectile_beam)
	UnregisterSignal(source, list(COMSIG_PROJECTILE_SELF_ON_HIT, COMSIG_PREQDELETED))
	QDEL_NULL(zipline)
	var/mob/living/user = zipliner?.resolve()
	if(isnull(user) || isnull(target))
		cancel_hook()
		return

	active_zipline = new
	active_zipline.begin_zipline(user, target, CALLBACK(src, PROC_REF(on_zipline_end)))

/obj/item/grapple_gun/proc/on_grapple_fail(datum/source)
	SIGNAL_HANDLER
	cancel_hook()

/// Called by the zipline datum when ziplining ends, resets gun state.
/obj/item/grapple_gun/proc/on_zipline_end()
	active_zipline = null
	zipliner = null
	hooked = TRUE
	update_appearance()

/// Cancels any active hook or zipline.
/obj/item/grapple_gun/proc/cancel_hook()
	QDEL_NULL(projectile_beam)
	if(active_zipline)
		QDEL_NULL(active_zipline)
	else
		on_zipline_end()

/obj/item/grapple_gun/update_overlays()
	. = ..()
	if(hooked)
		. += hook_overlay

/obj/projectile/grapple_hook
	name = "grapple hook"
	icon_state = "grapple_hook"
	damage = 0
	range = 9
	speed = 10
	can_hit_turfs = TRUE
	hitsound = 'sound/items/weapons/zipline_hit.ogg'

/// Lightweight datum that handles ziplining a user to a target for the grapple gun.
/datum/zipline_and_move
	/// Weakref to the user being ziplined
	var/datum/weakref/user_ref
	/// Weakref to the target we're ziplining toward
	var/datum/weakref/target_ref
	/// The beam drawn between user and target
	var/datum/beam/zipline
	/// Ziplining sound
	var/datum/looping_sound/zipline/zipline_sound
	/// The user's original transform matrix
	var/matrix/initial_matrix
	/// Delay before the user is launched towards the target
	var/launch_delay = 1.5 SECONDS
	/// Timer ID for the launch delay
	var/grapple_timer_id
	/// How fast to throw the user towards the target
	var/throw_speed = 1
	/// maximum range we throw up to/render beam for
	var/range = 9
	/// Callback invoked when the zipline ends
	var/datum/callback/on_end
	/// Traits applied to the user during zipline
	var/static/list/traits_on_zipline = list(
		TRAIT_IMMOBILIZED,
		TRAIT_MOVE_FLOATING,
		TRAIT_FORCED_STANDING,
	)

/datum/zipline_and_move/New(launch_delay, throw_speed, range)
	. = ..()
	if(!isnull(launch_delay))
		src.launch_delay = launch_delay
	if(!isnull(throw_speed))
		src.throw_speed = throw_speed
	if(!isnull(range))
		src.range = range

/datum/zipline_and_move/Destroy(force)
	end_zipline()
	return ..()

/// Sets up the zipline beam, signals, and launch timer.
/datum/zipline_and_move/proc/begin_zipline(mob/living/user, atom/target)
	user_ref = WEAKREF(user)
	target_ref = WEAKREF(target)
	zipline_sound = new(user)
	zipline = user.Beam(target, icon_state = "zipline_hook", maxdistance = range, layer = BELOW_MOB_LAYER)
	RegisterSignal(user, COMSIG_MOVABLE_MOVED, PROC_REF(determine_distance))
	RegisterSignal(user, COMSIG_MOVABLE_PRE_THROW, PROC_REF(apply_throw_traits))
	if(launch_delay)
		grapple_timer_id = addtimer(CALLBACK(src, PROC_REF(launch_user)), launch_delay, TIMER_STOPPABLE)
	else
		INVOKE_ASYNC(src, PROC_REF(launch_user))

/datum/zipline_and_move/proc/determine_distance(atom/movable/source)
	SIGNAL_HANDLER

	if(isnull(zipline))
		return
	var/atom/target = zipline.target
	if(isnull(target))
		return
	if(get_dist(source, target) > zipline.max_distance)
		qdel(src)

/datum/zipline_and_move/proc/apply_throw_traits(mob/living/source, list/arguements)
	SIGNAL_HANDLER
	var/atom/target_atom = arguements[1]
	if(isnull(target_atom))
		return
	var/dir_to_turn = get_angle(source, target_atom)
	if(dir_to_turn > 175 && dir_to_turn < 190)
		dir_to_turn = 0
	source.add_traits(traits_on_zipline, LEAPING_TRAIT)
	initial_matrix = source.transform
	animate(source, transform = matrix().Turn(dir_to_turn), time = 0.1 SECONDS)

/datum/zipline_and_move/proc/launch_user()
	var/mob/living/user = user_ref?.resolve()
	var/atom/target_atom = target_ref?.resolve()
	if(isnull(user) || isnull(target_atom) || user.buckled)
		qdel(src)
		return
	zipline_sound.start()
	new /obj/effect/temp_visual/mook_dust(user.drop_location())
	RegisterSignal(user, COMSIG_MOVABLE_IMPACT, PROC_REF(strike_target))
	user.throw_at(target = target_atom, range = range, speed = throw_speed, spin = FALSE, gentle = TRUE, callback = CALLBACK(src, PROC_REF(post_land)))

/datum/zipline_and_move/proc/strike_target(mob/living/source, mob/living/victim, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER

	if(!istype(victim))
		return

	victim.apply_damage(DAMAGE_ON_IMPACT)
	playsound(victim, 'sound/effects/hit_kick.ogg', 50)
	var/turf/target_turf = get_ranged_target_turf(victim, source.dir, 3)
	if(isnull(target_turf))
		return
	victim.throw_at(target = target_turf, speed = 1, spin = TRUE, range = 3)

/datum/zipline_and_move/proc/post_land()
	var/mob/living/user = user_ref?.resolve()
	if(!isnull(user))
		user.transform = initial_matrix
		user.remove_traits(traits_on_zipline, LEAPING_TRAIT)
		new /obj/effect/temp_visual/mook_dust(user.drop_location())
	qdel(src)

/// Cleans up all zipline state - signals, beams, timers, sound.
/datum/zipline_and_move/proc/end_zipline()
	var/mob/living/user = user_ref?.resolve()
	if(!isnull(user))
		UnregisterSignal(user, list(COMSIG_MOVABLE_IMPACT, COMSIG_MOVABLE_MOVED, COMSIG_MOVABLE_PRE_THROW))
	QDEL_NULL(zipline)
	user_ref = null
	target_ref = null
	if(grapple_timer_id)
		deltimer(grapple_timer_id)
	grapple_timer_id = null
	zipline_sound?.stop()
	QDEL_NULL(zipline_sound)
	initial_matrix = null

#undef DAMAGE_ON_IMPACT
