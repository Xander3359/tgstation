/obj/item/mod/module/infiltrator/contractor
	name = "Cybersun combat module"
	desc = "XANTODO Combat module description"
	traits_to_add = list(TRAIT_SILENT_FOOTSTEPS, TRAIT_UNKNOWN_APPEARANCE, TRAIT_UNKNOWN_VOICE, TRAIT_HEAD_INJURY_BLOCKED, TRAIT_FASTMED, TRAIT_QUICK_CARRY, TRAIT_FAST_CUFFING)
	required_slots = list(ITEM_SLOT_FEET, ITEM_SLOT_HEAD, ITEM_SLOT_OCLOTHING, ITEM_SLOT_GLOVES)
	/// Reference to the strong pull component
	var/datum/weakref/pull_component_weakref

/obj/item/mod/module/infiltrator/contractor/on_part_activation()
	. = ..()
	var/datum/component/strong_pull/pull_component = pull_component_weakref?.resolve()
	if(pull_component)
		stack_trace("[mod.wearer] already has a pull component.")
		QDEL_NULL(pull_component_weakref)
	to_chat(mod.wearer, span_notice("You feel the gauntlets activate as soon as you fit them on, making your pulls stronger!"))
	pull_component_weakref = WEAKREF(mod.wearer.AddComponent(/datum/component/strong_pull))

/obj/item/mod/module/infiltrator/contractor/on_part_deactivation(deleting)
	. = ..()
	var/datum/component/strong_pull/pull_component = pull_component_weakref?.resolve()
	if(!pull_component)
		return
	to_chat(pull_component.parent, span_warning("You have lost the grip power of [src.name]!"))
	QDEL_NULL(pull_component_weakref)

/obj/item/mod/module/contractor_uplink
	name = "Contractor Uplink"
	desc = "XANTODO Con uplink description"
	required_slots = list(ITEM_SLOT_GLOVES)
	module_type = MODULE_USABLE

/obj/item/mod/module/contractor_uplink/Initialize(mapload)
	. = ..()
	AddComponent(
		/datum/component/uplink/contractor, \
		lockable = FALSE, \
		enabled = TRUE, \
		uplink_flag = UPLINK_CONTRACTOR, \
		starting_tc = 0, \
	)

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
	desc = "A module that releases a cloud of smoke that causes victims that inhale the gas to roll on the ground and laugh hysterically for a few seconds, blinding them."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_modules.dmi'
	icon_state = "gas"
	removable = FALSE
	module_type = MODULE_USABLE
	cooldown_time = 20 SECONDS
	use_energy_cost = DEFAULT_CHARGE_DRAIN * 5
	incompatible_modules = list(/obj/item/mod/module/laughing_gas)

/obj/item/mod/module/laughing_gas/on_use(mob/activator)
	do_smoke(3, src, get_turf(mod.wearer), smoke_type = /datum/effect_system/fluid_spread/smoke/laughing, effect_type = /obj/effect/particle_effect/fluid/smoke/laughing)
	playsound(mod.wearer, 'sound/effects/spray.ogg', 50, TRUE)
	drain_power(use_energy_cost)

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

/// special variant of the butcher hook that forces the firer to hit the target with their active weapon (miner grappling hook + butcher hook + changeling tentacle)
/obj/projectile/hook/scorpion
	name = "scorpion hook"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_hook.dmi'
	icon_state = "hook"
	hook_icon_state = "loose"
	pull_in_hook_icon_state = "zipline_hook"
	icon_state_variants = 2
	damage = 0
	range = 10

/obj/projectile/hook/scorpion/on_hit(atom/target, blocked, pierce_hit)
	if(isitem(target))
		return
	var/atom/movable/movable = astype(target, /atom/movable)
	if((!isnull(movable) && !movable.anchored) || !target.density)
		return ..()
	. = ..()
	var/mob/living/hook_firer = firer
	if(!istype(hook_firer))
		return ..()
	REMOVE_TRAIT(hook_firer, TRAIT_IMMOBILIZED, REF(src))
	var/datum/zipline_and_move/zipline = new(launch_delay = 0, throw_speed = 2, range = 10)
	zipline.begin_zipline(hook_firer, target)

/datum/movespeed_modifier/net_slowdown
	multiplicative_slowdown = 4


