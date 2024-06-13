/obj/item/organ/internal/heart/cybernetic/anomalock
	name = "experimental cybernetic heart"
	desc = ""
	icon_state = "brain" //XANTODO - Replace placeholder sprite
	///Cooldown for the activation of the organ
	var/survival_cooldown = 5 MINUTES
	///Stores current time of when the organ was last activated
	var/last_activation = -5 MINUTES //We should be off cooldown even if world.time is 0
	///Maximum amount of time the organ will remain "active"
	var/active_duration = 30 SECONDS
	///If our organ is currently active
	var/active = FALSE

/obj/item/organ/internal/heart/cybernetic/anomalock/on_mob_insert(mob/living/carbon/organ_owner, special, movement_flags)
	. = ..()
	ADD_TRAIT(organ_owner, TRAIT_SHOCKIMMUNE, REF(src))
	organ_owner.AddElement(/datum/element/empprotection, EMP_PROTECT_SELF|EMP_PROTECT_CONTENTS)
	organ_owner.apply_status_effect(/datum/status_effect/stabilized/yellow, organ_owner, REF(src))

/obj/item/organ/internal/heart/cybernetic/anomalock/on_mob_remove(mob/living/carbon/organ_owner, special)
	. = ..()
	REMOVE_TRAIT(organ_owner, TRAIT_SHOCKIMMUNE, REF(src))
	organ_owner.RemoveElement(/datum/element/empprotection, EMP_PROTECT_SELF|EMP_PROTECT_CONTENTS)
	organ_owner.remove_status_effect(/datum/status_effect/stabilized/yellow)
	tesla_zap(source = organ_owner, zap_range = 20, power = 2.5e5, cutoff = 1e3)
	qdel(src)

/obj/item/organ/internal/heart/cybernetic/anomalock/attack(mob/living/target_mob, mob/living/user, params)
	if(target_mob == user && istype(target_mob))
		playsound(user,'sound/effects/singlebeat.ogg',40,TRUE)
		user.temporarilyRemoveItemFromInventory(src, TRUE)
		Insert(user)
		user.apply_damage(50, BRUTE, BODY_ZONE_CHEST)
		user.emote("scream")
		return TRUE
	return ..()

/obj/item/organ/internal/heart/cybernetic/anomalock/attack_self(mob/user, modifiers)
	. = ..()
	if(.)
		return

	return attack(user, user, modifiers)

/obj/item/organ/internal/heart/cybernetic/anomalock/on_life(seconds_per_tick, times_fired)
	. = ..()
	if(owner.blood_volume < BLOOD_VOLUME_NORMAL)
		owner.blood_volume += 2.5 * seconds_per_tick
	if(owner.health <= owner.crit_threshold && world.time > last_activation + survival_cooldown)
		last_activation = world.time
		activate_survival(owner)
	if(active && owner.health < owner.crit_threshold)
		owner.heal_overall_damage(2, 2)

///Does a few things to try to help you live whatever you may be going through
/obj/item/organ/internal/heart/cybernetic/anomalock/proc/activate_survival(mob/living/carbon/organ_owner)
	organ_owner.add_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	organ_owner.gain_trauma(/datum/brain_trauma/special/tenacity)
	REMOVE_TRAIT(src, TRAIT_CRITICAL_CONDITION, STAT_TRAIT)
	active = TRUE
	organ_owner.reagents.add_reagent(/datum/reagent/medicine/coagulant, 5)
	organ_owner.add_filter("emp_shield", 2, outline_filter(1, "#639BFF"))
	addtimer(CALLBACK(src, PROC_REF(stop_survival), organ_owner), active_duration)

///Stops the positive effects we've gotten from the organ
/obj/item/organ/internal/heart/cybernetic/anomalock/proc/stop_survival(mob/living/carbon/organ_owner)
	organ_owner.cure_trauma_type(/datum/brain_trauma/special/tenacity)
	organ_owner.remove_movespeed_mod_immunities(type, /datum/movespeed_modifier/damage_slowdown)
	active = FALSE
	organ_owner.remove_filter("emp_shield")
