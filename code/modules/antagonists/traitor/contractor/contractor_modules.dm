/obj/item/mod/module/energy_net/scorpion_hook
	name = "Scorpion Hook module"
	desc = "A module that launches a hook that allows the user to launch a hardlight hook towards a target and reel them in. \n\
		If you have a weapon or baton in your other hand, you'll use it on them."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_modules.dmi'
	icon_state = "harpoon"
	incompatible_modules = list(/obj/item/mod/module/energy_net/scorpion_hook)
	removable = FALSE
	projectile_type = /obj/projectile/hook/scorpion

/obj/item/mod/module/energy_net/scorpion_hook/on_activation(mob/activator)
	. = ..()
	RegisterSignal(mod.wearer, COMSIG_HOOK_FINISH, PROC_REF(hook_finish))

/obj/item/mod/module/energy_net/scorpion_hook/on_deactivation(mob/activator, display_message, deleting)
	. = ..()
	UnregisterSignal(mod.wearer, COMSIG_HOOK_FINISH)

/obj/item/mod/module/energy_net/scorpion_hook/proc/hook_finish(atom/movable/firer, mob/living/target)
	SIGNAL_HANDLER
	var/mob/firer_mob = firer
	if(!firer.Adjacent(target) || !istype(target))
		return
	var/obj/item/weapon = firer_mob.get_active_held_item()
	if(isnull(weapon))
		return
	INVOKE_ASYNC(weapon, PROC_REF(melee_attack_chain), firer_mob, target)

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
	incompatible_modules = list(/obj/item/mod/module/energy_net/snatcher)
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
	var/mob/living/target_living = target
	if(istype(target_living))
		target_living.apply_status_effect(/datum/status_effect/snatcher_net)

/datum/status_effect/snatcher_net
	id = "snatcher net"
	alert_type = /atom/movable/screen/alert/status_effect/snatcher_net
	duration =  -1
	var/shock_delay = 10 SECONDS
	var/time_to_disabling = 1 MINUTES
	var/net_icon = 'code/modules/antagonists/traitor/contractor/icons/net_obj.dmi'
	var/shock_timer
	var/mutable_appearance/default_overlay
	var/mutable_appearance/shock_overlay
	var/shocking = FALSE
	var/broken = FALSE

/datum/status_effect/snatcher_net/on_creation(mob/living/new_owner)
	var/flags = KEEP_APART|RESET_COLOR
	default_overlay = mutable_appearance(net_icon, icon_state = "net", layer = ABOVE_MOB_LAYER, appearance_flags = flags)
	shock_overlay = mutable_appearance(net_icon, icon_state = "spicy_net", layer = ABOVE_MOB_LAYER, appearance_flags = flags)
	return ..()

/datum/status_effect/snatcher_net/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS, PROC_REF(update_owner_overlay))
	RegisterSignal(owner, COMSIG_ATOM_EMP_ACT, PROC_REF(emp_act))
	owner.update_appearance(UPDATE_OVERLAYS)
	owner.add_movespeed_modifier(/datum/movespeed_modifier/net_slowdown)
	delayed_shock()
	addtimer(CALLBACK(src, PROC_REF(disable_net)), time_to_disabling)

/datum/status_effect/snatcher_net/proc/update_owner_overlay(atom/source, list/overlays)
	SIGNAL_HANDLER
	if(shocking && !broken)
		overlays += shock_overlay
	else
		overlays += default_overlay

/datum/status_effect/snatcher_net/Destroy(force)
	. = ..()
	QDEL_NULL(default_overlay)
	QDEL_NULL(shock_overlay)

/datum/status_effect/snatcher_net/on_remove()
	UnregisterSignal(owner, COMSIG_ATOM_UPDATE_OVERLAYS)
	UnregisterSignal(owner, COMSIG_ATOM_EMP_ACT)
	deltimer(shock_timer)
	owner.update_appearance(UPDATE_OVERLAYS)
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/net_slowdown)
	owner.visible_message(span_warning("The snatcher net around [owner] vaporizes itself into ash."), span_warning("The snatcher net around you vaporizes itself into ash!"))
	do_sparks(number = 5, cardinal_only = TRUE, source = src)
	new /obj/effect/decal/cleanable/ash(get_turf(owner))

/datum/status_effect/snatcher_net/proc/delayed_shock()
	shock_timer = addtimer(CALLBACK(src, PROC_REF(shock_victim)), shock_delay, TIMER_STOPPABLE)

/datum/status_effect/snatcher_net/proc/emp_act(atom/target, severity, protection)
	SIGNAL_HANDLER
	deltimer(shock_timer)
	disable_net()

/datum/status_effect/snatcher_net/proc/disable_net()
	default_overlay.alpha = 128
	broken = TRUE
	owner.update_appearance(UPDATE_OVERLAYS)

/datum/status_effect/snatcher_net/proc/shock_victim()
	if(QDELETED(owner))
		return
	shocking = TRUE
	owner.electrocute_act(shock_damage = 5, source = src, siemens_coeff = 1, flags = SHOCK_KNOCKDOWN)
	do_sparks(number = 5, cardinal_only = TRUE, source = src)
	owner.visible_message(span_danger("The snatcher net glows and shocks [owner]!"), span_userdanger("The snatcher net glows and shocks you!"))
	owner.update_appearance(UPDATE_OVERLAYS)
	delayed_shock()
	addtimer(CALLBACK(src, PROC_REF(stop_shocking)), 5 SECONDS)

/datum/status_effect/snatcher_net/proc/stop_shocking()
	shocking = FALSE
	owner.update_appearance(UPDATE_OVERLAYS)

/atom/movable/screen/alert/status_effect/snatcher_net
	name = "Snatcher Net"
	overlay_icon = /datum/status_effect/snatcher_net::net_icon
	overlay_state = "spicy_net"
	desc = "The snatcher net is electrocuting you! Click on this alert or resist to break free!"
	use_user_hud_icon = TRUE

/// special variant of the butcher hook that forces the firer to hit the target with their active weapon
/obj/projectile/hook/scorpion
	name = "scorpion hook"

/obj/projectile/hook/scorpion/on_hit(atom/target, blocked, pierce_hit)
	if(isitem(target))
		return
	var/atom/movable/movable = astype(target, /atom/movable)
	if((movable && !movable.anchored) || !target.density)
		return ..()
	. = ..()
	var/mob/living/hook_firer = firer
	if(!istype(hook_firer))
		return ..()
	REMOVE_TRAIT(hook_firer, TRAIT_IMMOBILIZED, REF(src))
	var/datum/zipline_and_move/zipline = new
	zipline.begin_zipline(hook_firer, target)

/datum/movespeed_modifier/net_slowdown
	multiplicative_slowdown = 4

