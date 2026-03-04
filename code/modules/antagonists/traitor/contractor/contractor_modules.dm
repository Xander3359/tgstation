/obj/item/mod/module/energy_net/scorpion_hook
	name = "Scorpion Hook module"
	desc = "A module that launches a hook that allows the user to launch a hardlight hook towards a target and reel them in. \n\
		If you have a weapon or baton in your other hand, you'll use it on them."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_modules.dmi'
	icon_state = "hook"
	removable = FALSE
	projectile_type = /obj/projectile/hook/scorpion

/obj/item/mod/module/laughing_gas
	name = "Laughing Gas module"
	desc = "A module that releases a cloud of of smoke that causes victims that inhale the gas it to roll on the ground and laugh hysterically for a few seconds, blinding them."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_modules.dmi'
	icon_state = "gas"
	removable = FALSE

/obj/item/mod/module/energy_net/snatcher
	name = "SNATCHER module"
	desc = "'Seizure of Notable Assets, Targets and Critical Human Enemy Resources'. \n\
		The module launches a net that traps the target and eventually electrocutes them with a less-than-lethal shock. \n\
		Simple and clean. Can be destroyed quickly with a decent melee weapon."
	incompatible_modules = list(/obj/item/mod/module/energy_net, /obj/item/mod/module/energy_net/snatcher)
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_modules.dmi'
	icon_state = "net"
	cooldown_time = 2 SECONDS
	removable = FALSE
	projectile_type = /obj/projectile/snatcher

/obj/projectile/snatcher
	name = "hardlight net"
	icon = 'code/modules/antagonists/traitor/contractor/icons/net_proj.dmi'
	icon_state = "net"
	hitsound = 'sound/items/fulton/fultext_deploy.ogg'
	hitsound_wall = 'sound/items/fulton/fultext_deploy.ogg'
	damage = 20
	damage_type = STAMINA

/obj/projectile/snatcher/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(ismob(target))
		new /obj/snatcher_net(get_turf(target), target)

/obj/snatcher_net
	name = "snatcher net"
	icon = 'code/modules/antagonists/traitor/contractor/icons/net_obj.dmi'
	icon_state = "net"
	max_integrity = 50
	layer = ABOVE_MOB_LAYER
	appearance_flags = KEEP_APART|RESET_COLOR
	var/shock_delay = 7 SECONDS
	// var/stun_time = 5 SECONDS
	// var/datum/movement_detector/tracker
	var/mob/living/victim
	var/shock_timer

/obj/snatcher_net/Initialize(mapload, mob/living/carbon/target)
	. = ..()
	ADD_TRAIT(src, TRAIT_INVERTED_DEMOLITION, INNATE_TRAIT)
	QDEL_IN(src, 1 MINUTES)
	if(!istype(target) || target.has_movespeed_modifier(/datum/movespeed_modifier/net_slowdown))
		return
	forceMove(target)
	// var/mutable_appearance/new_halo_overlay = mutable_appeDarance(src.appearance, appearance_flags)
	target.add_overlay(src)
	target.add_movespeed_modifier(/datum/movespeed_modifier/net_slowdown)
	victim = target
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(delete_self))
	// tracker = new(target, CALLBACK(src, PROC_REF(move_react)))
	delayed_shock(target)

/obj/snatcher_net/Destroy(force)
	. = ..()
	victim.cut_overlay(src)
	victim.remove_movespeed_modifier(/datum/movespeed_modifier/net_slowdown)
	victim = null
	// QDEL_NULL(tracker)

/obj/snatcher_net/proc/delayed_shock(mob/living/carbon/target)
	shock_timer = addtimer(CALLBACK(src, PROC_REF(shock_victim), target), shock_delay, TIMER_STOPPABLE)

/obj/snatcher_net/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	deltimer(shock_timer)
	alpha = 150

/obj/snatcher_net/proc/shock_victim(mob/living/carbon/target)
	if(QDELETED(src) || !istype(target))
		return
	flick("spicy_net", src)
	// target.Stun(stun_time * cell.charge / cell.max_charge)
	target.electrocute_act(shock_damage = 5, source = src, siemens_coeff = 1, flags = SHOCK_KNOCKDOWN)
	do_sparks(number = 5, cardinal_only = TRUE, source = src)
	target.visible_message(span_danger("[src] glows and shocks [target]!"), span_userdanger("[src] glows and shocks you!"))
	delayed_shock(target)

/obj/snatcher_net/proc/delete_self()
	SIGNAL_HANDLER
	qdel(src)

// /obj/snatcher_net/proc/move_react(atom/movable/master, atom/mover, atom/oldloc, direction)
// 	SIGNAL_HANDLER
// 	glide_size = master.glide_size
// 	abstract_move(get_turf(master))

/// special variant of the butcher hook that forces the firer to hit the target with their active weapon
/obj/projectile/hook/scorpion
	name = "scorpion hook"

/obj/projectile/hook/scorpion/finish_callback(atom/movable/firer, atom/movable/victim)
	var/mob/firer_mob = firer
	if(!firer.Adjacent(victim) || !istype(firer_mob))
		return
	var/obj/item/weapon = firer_mob.get_active_held_item()
	if(isnull(weapon))
		return
	weapon.melee_attack_chain(firer_mob, victim)
	// firer_mob.do_attack_animation(victim)

/datum/movespeed_modifier/net_slowdown
	multiplicative_slowdown = 4
