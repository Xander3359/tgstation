
/obj/item/gun/ballistic/gauss_rifle
	name = "Raijin Horizon Gauss Rifle"
	desc = "The Raijin is a gauss type weapon designed more for utility and subterfuge rather than protracted combat engagements. \n\
		Scoped and suppressed. Chambered in 2mm FM (ferromagnetic), \n\
		the weapon is slow to fire but fires a high velocity, high impact, high penetration round. \n\
		Has an implant restricted firing pin similar to nuclear operatives, and can only be fired by users with the Cybersun authorization implant. \n\
		This implant is injected upon picking up the gun for the first time. \n\
		The case contains the gun, and comes with a number of customizable magazines. \n\
		A magazine can be swapped to a different ammunition type before being inserted into the gun. \n\
		Each projectile type expends more 'ammunition' from the magazine, which acts more like a battery than a traditional magazine. \n\
		Recharging these magazines requires either using a recharger, or the weapon case that came with the gun."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_item.dmi'
	lefthand_file = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_inhand_left.dmi'
	righthand_file = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_inhand_right.dmi'
	icon_state = "contractor_gun"
	inhand_icon_state = "contractor_gun"
	base_icon_state = "contractor_gun"
	weapon_weight = WEAPON_HEAVY
	accepted_magazine_type = /obj/item/ammo_box/magazine/gauss
	w_class = WEIGHT_CLASS_BULKY
	bolt_type = BOLT_TYPE_OPEN
	SET_BASE_PIXEL(-16, 0)
	var/fire_mode_switch_sound = SFX_FIRE_MODE_SWITCH
	var/ammo_mode = 0
	var/ammo_type = list(
		/obj/item/ammo_casing/gauss,
		/obj/item/ammo_casing/gauss/emp,
		/obj/item/ammo_casing/gauss/gyro,
		/obj/item/ammo_casing/gauss/antimatter,
		/obj/item/ammo_casing/gauss/thermite,
	)

/obj/item/gun/ballistic/gauss_rifle/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/gun/ballistic/gauss_rifle/attack_self(mob/living/user)
	if(length(ammo_type) > 1)
		select_fire(user)
		return

/obj/item/gun/ballistic/gauss_rifle/proc/select_fire(mob/living/user)
	ammo_mode++
	if (ammo_mode > length(ammo_type))
		ammo_mode = 1
	var/obj/item/ammo_casing/gauss/shot = ammo_type[ammo_mode]
	if(!isnull(shot) && !ispath(shot))
		CRASH("Invalid ammo type in gauss rifle: " + shot.type)
	fire_sound = shot.fire_sound
	fire_delay = shot.delay
	if (shot.select_name && user)
		balloon_alert(user, "set to [shot.select_name]")
	chambered = null
	recharge_newshot(TRUE)
	update_appearance()
	if(fire_mode_switch_sound)
		playsound(src, fire_mode_switch_sound, 50, TRUE)

/obj/item/gun/ballistic/gauss_rifle/balloon_alert_pixel_y_offset()
	return 0

/obj/item/ammo_box/magazine/gauss
	name = "Raijin Horizon Gauss Magazine"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities."
	caliber = CALIBER_GAUSS
	max_ammo = 5
	icon_state = ".50mag"
	ammo_type = /obj/item/ammo_casing/gauss

/obj/item/ammo_box/magazine/gauss/emp
	name = "Raijin Horizon Smart EMP Gauss Magazine"
	color = COLOR_BLUE
	ammo_type = /obj/item/ammo_casing/gauss/emp

/obj/item/ammo_box/magazine/gauss/gyro
	name = "Raijin Horizon Gyre Gauss Magazine"
	color = COLOR_YELLOW
	ammo_type = /obj/item/ammo_casing/gauss/gyro

/obj/item/ammo_box/magazine/gauss/antimatter
	name = "Raijin Horizon Antimatter Gauss Magazine"
	color = COLOR_PURPLE
	ammo_type = /obj/item/ammo_casing/gauss/antimatter

/obj/item/ammo_box/magazine/gauss/thermite
	name = "Raijin Horizon Red Sun Gauss Magazine"
	color = COLOR_RED
	ammo_type = /obj/item/ammo_casing/gauss/thermite

/obj/item/ammo_casing/gauss
	name = "standard gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile delivers enough kinetic energy into an impacted surface to liquify surrounding organic matter it passes through or render vehicles inoperable if aimed towards an engine block or battery pack."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard"
	caliber = CALIBER_GAUSS
	projectile_type = /obj/projectile/bullet/gauss
	var/select_name = "standard"

/obj/item/ammo_casing/gauss/emp
	name = "smart EMP gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile unleashes its energy payload as ionized radiation bursts upon impact with a solid surface, disrupting electronic devices and synthetic lifeforms. \n\
		While the impact shatters the otherwise frail containment shell for the internal catalystic discharge array, causing no real harm to organic flesh, the resulting ionized particles fry machinery with ease. \n\
		The specialized resonation of these particles is particularly suited to shutting down Area Power Controller modules, rendering them completely inoperable for large periods of time. \n\
		It also has a tendency to prime electronic munitions and transfer valves, resulting in what Cybersun agents call a 'spontaneous clusterfuck' scenario. Use with care."
	icon_state = "emp"
	projectile_type = /obj/projectile/bullet/gauss/emp
	select_name = "smart EMP"

/obj/item/ammo_casing/gauss/gyro
	name = "gyre gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile deliberately slows itself down to generate power through internal gyroscopes to charge a secondary power capacitor payload. \n\
		Upon impact, this triggers the transformer system to direct the stored charge into the impacted surface. \n\
		Used against organic targets, this induces cardiac and synaptic disruption. \n\
		In other words, it switches people off like a light switch for a moment, possibly rendering them completely helpless with enough generated power or repeat exposure. \n\
		Do not overuse on targets intended to be taken in alive."
	icon_state = "gyro"
	projectile_type = /obj/projectile/bullet/gauss/gyro
	select_name = "gyre"

/obj/item/ammo_casing/gauss/antimatter
	name = "antimatter gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile contains a translocated microscopic antimatter sliver into which the additional kinetic energy is diverted into upon impact with a surface. \n\
		This destabilization creates what is effectively a localized eruption of energy, blossoming outwards in a flash of light. \n\
		Against flesh or steel, the effect is often devastating and gruesome, leading this round to be viewed less as a weapon of war and more as a weapon of terror. \n\
		Cybersun is not above using this round when the situation calls for either need."
	icon_state = "antimatter"
	projectile_type = /obj/projectile/bullet/gauss/antimatter
	select_name = "antimatter"

/obj/item/ammo_casing/gauss/thermite
	name = "red sun gauss round"
	desc = "This magazine flash-fabricates microcartridge assemblies through self-replicating nanites. \n\
		These assemblies self-destructively supercharge the rail capacitors used in gauss weaponry. \n\
		This causes the contained ferromagnetic payload to launch itself along the rail system, out towards a target at extreme velocities. \n\
		The projectile embeds itself into a surface before unleashing a rapid buildup of thermal energy through a microfusion cascade. \n\
		In organics, this causes massive atrophic mutilation through rapid carbonization. \n\
		In inorganics, this often is capable of eventually eating through the thickest of hulls. \n\
		When salvage, or body recovery, is a luxury able to be afforded, Cybersun arms their shocktroopers with this round."
	icon_state = "thermite"
	projectile_type = /obj/projectile/bullet/gauss/thermite
	select_name = "red sun"

/obj/projectile/bullet/gauss
	name = "standard gauss round"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard_projectile"
	damage = 40
	armour_penetration = 35
	speed = 2
	wound_bonus = -20

/obj/projectile/bullet/gauss/emp
	name = "smart EMP gauss round"
	icon_state = "emp_projectile"
	damage = 0
	speed = 3
	wound_bonus = CANT_WOUND
	sharpness = NONE
	embed_type = null

//TODO: guarantee malfunctions on mechs
/obj/projectile/bullet/gauss/emp/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	empulse(target, 3, 5, emp_source = src)
	// Gauss EMP rounds are designed to keep APCs disabled for extended periods
	for(var/obj/machinery/power/apc/apc in range(2, target))
		addtimer(CALLBACK(apc, TYPE_PROC_REF(/obj/machinery/power/apc, reset), APC_RESET_EMP), 5 MINUTES, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_NO_HASH_WAIT)

/obj/projectile/bullet/gauss/gyro
	name = "gyre gauss round"
	icon_state = "gyro_projectile"
	damage_type = STAMINA
	armor_flag = ENERGY
	armour_penetration = 35
	speed = 1.5
	damage_falloff_tile = -5
	range = 20
	wound_bonus = CANT_WOUND
	sharpness = NONE
	embed_type = null

/obj/projectile/bullet/gauss/gyro/reduce_range()
	. = ..()
	damage = min(damage, 50)

/obj/projectile/bullet/gauss/gyro/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/victim = target
		victim.electrocute_act(stamina * 0.2, src, flags = SHOCK_KNOCKDOWN|SHOCK_DELAY_STUN|SHOCK_NOGLOVES)
		do_sparks(5, TRUE, target)

/// TODO: flash_act on 3x3 on hit, rare chance to remove organs if has severe wound
/obj/projectile/bullet/gauss/antimatter
	name = "antimatter gauss round"
	icon_state = "antimatter_projectile"
	damage = 15
	armour_penetration = 100
	speed = 3
	wound_bonus = 40
	embed_type = null

/obj/projectile/bullet/gauss/thermite
	name = "red sun gauss round"
	icon_state = "thermite_projectile"
	damage = 30
	damage_type = BURN
	armour_penetration = 35
	speed = 2
	wound_bonus = -10
	embed_type = /datum/embedding/gauss_thermite

/obj/projectile/bullet/gauss/thermite/on_hit(atom/target, blocked = 0, pierce_hit)
	. = ..()
	var/turf/hit_turf = get_turf(target)
	if(hit_turf)
		hit_turf.AddComponent(/datum/component/thermite, 50)
		hit_turf.fire_act(2000)

/datum/embedding/gauss_thermite
	embed_chance = 100
	fall_chance = 1
	pain_chance = 15
	pain_mult = 3
	// ignore_throwspeed_threshold = TRUE
	rip_time = 1.5 SECONDS
	pain_stam_pct = 0
	var/overtime_damage = 5

/datum/embedding/gauss_thermite/set_owner(mob/living/carbon/victim, obj/item/bodypart/target_limb)
	. = ..()
	owner.add_shared_particles(/particles/smoke/burning/small)

/datum/embedding/gauss_thermite/stop_embedding()
	owner?.remove_shared_particles(/particles/smoke/burning/small)
	return ..()

/// Applies ongoing burn damage from the microfusion cascade while embedded
/datum/embedding/gauss_thermite/process_effect(seconds_per_tick)
	owner_limb.take_damage(overtime_damage * seconds_per_tick, BURN, src)
	return FALSE
