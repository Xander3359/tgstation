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
	cooldown_time = 15 SECONDS
	removable = FALSE
	projectile_type = /obj/projectile/snatcher

/obj/projectile/snatcher
	name = "hardlight net"
	hitsound = 'sound/items/fulton/fultext_deploy.ogg'
	hitsound_wall = 'sound/items/fulton/fultext_deploy.ogg'
	icon = 'icons/obj/clothing/modsuit/mod_modules.dmi'

/obj/projectile/snatcher/on_hit(atom/target, blocked, pierce_hit)
	. = ..()
	if(ismob(target))
		new /obj/snatcher_net(get_turf(target), target)

/obj/snatcher_net
	name = "snatcher net"
	icon = 'code/modules/antagonists/traitor/contractor/icons/net_obj.dmi'
	icon_state = "net"
	max_integrity = 25
	var/shock_delay = 2 SECONDS
	// var/stun_time = 5 SECONDS
	var/datum/movement_detector/tracker
	var/obj/item/stock_parts/power_store/cell
	var/mob/victim

/obj/snatcher_net/Initialize(mapload, mob/target)
	. = ..()
	if(!istype(target))
		return
	cell = new(src)
	target.add_movespeed_modifier(/datum/movespeed_modifier/net_slowdown)
	victim = target
	RegisterSignal(target, COMSIG_QDELETING, PROC_REF(delete_self))
	tracker = new(target, CALLBACK(src, PROC_REF(move_react)))
	glide_size = target.glide_size
	addtimer(CALLBACK(src, PROC_REF(shock_victim), target), shock_delay)

/obj/snatcher_net/Destroy(force)
	. = ..()
	victim.remove_movespeed_modifier(/datum/movespeed_modifier/net_slowdown)
	victim = null
	QDEL_NULL(tracker)
	QDEL_NULL(cell)

/obj/snatcher_net/proc/shock_victim(mob/target)
	if(QDELETED(src) || cell.charge <= 0 || !istype(target))
		return
	icon_state = "spicy_net"
	// target.Stun(stun_time * cell.charge / cell.max_charge)
	electrocute_mob(target, cell, src, 1)
	do_sparks(5, TRUE, src)
	target.visible_message(span_danger("[src] glows and shocks [target]!"), span_userdanger("[src] glows and shocks you!"))

/obj/snatcher_net/proc/delete_self()
	SIGNAL_HANDLER
	qdel(src)

/obj/snatcher_net/proc/move_react(atom/movable/master, atom/mover, atom/oldloc, direction)
	SIGNAL_HANDLER
	abstract_move(get_turf(master))

/obj/projectile/hook/scorpion
	name = "scorpion hook"

/datum/movespeed_modifier/net_slowdown
	multiplicative_slowdown = 4
