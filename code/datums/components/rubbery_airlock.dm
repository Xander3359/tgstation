/// Component that makes an airlock "rubbery" — bouncing mobs that bump into it.
/// Applied by the contractor glue dart's status effect.
/datum/component/rubbery_airlock
	/// Trait that grants immunity to the bounce effect.
	var/immunity_trait

/datum/component/rubbery_airlock/Initialize(immunity_trait)
	if(!istype(parent, /obj/machinery/door/airlock))
		return COMPONENT_INCOMPATIBLE
	src.immunity_trait = immunity_trait
	var/obj/machinery/door/airlock/door = parent
	door.visible_message(span_warning("[door] is coated in a rubbery substance!"))
	RegisterSignal(parent, COMSIG_ATOM_BUMPED, PROC_REF(on_bumped))

/datum/component/rubbery_airlock/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_ATOM_BUMPED)

/datum/component/rubbery_airlock/proc/on_bumped(datum/source, atom/movable/bumped_atom)
	SIGNAL_HANDLER
	if(!isliving(bumped_atom))
		return
	var/mob/living/victim = bumped_atom

	if(immunity_trait && HAS_TRAIT(victim, immunity_trait))
		return

	// Bounce the victim away from the door
	var/bounce_dir = get_dir(parent, victim)
	if(!bounce_dir)
		bounce_dir = victim.dir
	var/turf/target_turf = get_ranged_target_turf(victim, bounce_dir, 7)
	victim.visible_message(
		span_danger("[victim] bounces off [parent]!"),
		span_userdanger("You bounce off [parent] at high speed!"),
	)
	victim.throw_at(target_turf, 7, 4, spin = TRUE)
