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

/// Multiplier for escape time when using wirecutters or a sharp item
#define SNATCHER_TOOL_MULTIPLIER 0.5

/datum/status_effect/snatcher_net
	id = "snatcher net"
	alert_type = /atom/movable/screen/alert/status_effect/snatcher_net
	duration = -1
	var/shock_delay = 10 SECONDS
	var/time_to_disabling = 1 MINUTES
	var/resist_timer = 5 SECONDS
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
	RegisterSignal(owner, COMSIG_LIVING_RESIST, PROC_REF(on_resist))
	RegisterSignal(owner, COMSIG_ATOM_TOOL_ACT(TOOL_WIRECUTTER), PROC_REF(on_cut))
	RegisterSignal(owner, COMSIG_ATOM_ATTACKBY, PROC_REF(on_attackby))
	RegisterSignal(owner, COMSIG_CARBON_PRE_MISC_HELP, PROC_REF(on_help))
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
	UnregisterSignal(owner, list(
		COMSIG_ATOM_UPDATE_OVERLAYS,
		COMSIG_ATOM_EMP_ACT,
		COMSIG_LIVING_RESIST,
		COMSIG_ATOM_TOOL_ACT(TOOL_WIRECUTTER),
		COMSIG_ATOM_ATTACKBY,
		COMSIG_CARBON_PRE_MISC_HELP,
	))
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

/datum/status_effect/snatcher_net/proc/on_resist(mob/living/source)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(try_escape), source)

/// Signal proc for [COMSIG_ATOM_TOOL_ACT] with [TOOL_WIRECUTTER]
/datum/status_effect/snatcher_net/proc/on_cut(mob/living/source, mob/user, obj/item/tool)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(try_escape), user, tool)
	return ITEM_INTERACT_BLOCKING

/// Signal proc for [COMSIG_ATOM_ATTACKBY], checks for sharp items
/datum/status_effect/snatcher_net/proc/on_attackby(mob/living/source, obj/item/weapon, mob/living/attacker, list/modifiers)
	SIGNAL_HANDLER
	if(!weapon.get_sharpness())
		return
	INVOKE_ASYNC(src, PROC_REF(try_escape), attacker, weapon)
	return COMPONENT_CANCEL_ATTACK_CHAIN

/// Signal proc for [COMSIG_CARBON_PRE_MISC_HELP], allows someone to free the victim with combat mode off
/datum/status_effect/snatcher_net/proc/on_help(mob/living/carbon/source, mob/living/helper)
	SIGNAL_HANDLER
	if(DOING_INTERACTION(helper, REF(src)))
		return
	INVOKE_ASYNC(src, PROC_REF(try_escape), helper)
	return COMPONENT_BLOCK_MISC_HELP

/**
 * Attempts a do_after to escape from the net.
 *
 * user - the mob attempting to break free. Can be the owner or a helper.
 * tool - an optional tool (wirecutters or sharp item) that speeds up escape.
 */
/datum/status_effect/snatcher_net/proc/try_escape(mob/living/user, obj/item/tool)
	if(user.incapacitated || HAS_TRAIT(user, TRAIT_HANDS_BLOCKED))
		return
	var/is_self = (user == owner)
	var/escape_time = resist_timer * (tool ? SNATCHER_TOOL_MULTIPLIER : 1)

	if(tool)
		user.visible_message(
			span_notice("[user] starts cutting the snatcher net [is_self ? "off [user.p_them()]self" : "off [owner]"] with [tool]..."),
			span_notice("You start cutting the snatcher net [is_self ? "off yourself" : "off [owner]"] with [tool]..."),
		)
		tool.play_tool_sound(owner)
	else
		user.visible_message(
			span_notice("[user] starts tearing the snatcher net [is_self ? "off [user.p_them()]self" : "off [owner]"]..."),
			span_notice("You start tearing the snatcher net [is_self ? "off yourself" : "off [owner]"]..."),
		)

	if(!do_after(user, escape_time, owner, interaction_key = REF(src)))
		to_chat(user, span_warning("You fail to remove the snatcher net!"))
		return

	tool?.play_tool_sound(owner)
	user.visible_message(
		span_notice("[user] successfully removes the snatcher net from [is_self ? "[user.p_them()]self" : "[owner]"]!"),
		span_notice("You successfully remove the snatcher net from [is_self ? "yourself" : "[owner]"]!"),
	)
	qdel(src)

/atom/movable/screen/alert/status_effect/snatcher_net
	name = "Snatcher Net"
	overlay_icon = /datum/status_effect/snatcher_net::net_icon
	overlay_state = "spicy_net"
	desc = "The snatcher net is electrocuting you! Click on this alert or resist to break free!"
	use_user_hud_icon = TRUE
	clickable_glow = TRUE

/atom/movable/screen/alert/status_effect/snatcher_net/Click(location, control, params)
	. = ..()
	if(!.)
		return
	if(!isliving(owner))
		return
	var/datum/status_effect/snatcher_net/net_effect = attached_effect
	if(!istype(net_effect))
		return
	net_effect.try_escape(owner)

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

#undef SNATCHER_TOOL_MULTIPLIER

