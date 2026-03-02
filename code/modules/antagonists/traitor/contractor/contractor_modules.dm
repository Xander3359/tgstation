/obj/item/mod/module/scorpion_hook
	name = "Scorpion Hook module"
	desc = "A module that launches a hook that allows the user to launch a hardlight hook towards a target and reel them in. \n\
		If you have a weapon or baton in your other hand, you'll use it on them."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_modules.dmi'
	icon_state = "hook"
	removable = FALSE

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
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_modules.dmi'
	icon_state = "net"
	hitsound = 'sound/items/fulton/fultext_deploy.ogg'

/obj/snatcher_net/Initialize(mapload, mob/target)
	. = ..()


/obj/projectile/hook/contractor
	name = "contractor hook"
