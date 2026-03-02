
/obj/item/gun/ballistic/gauss_rifle
	name = "Raijin Horizon Gauss Rifle"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_item.dmi'
	lefthand_file = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_inhand_left.dmi'
	righthand_file = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_inhand_right.dmi'
	icon_state = "contractor_gun"
	inhand_icon_state = "contractor_gun"
	base_icon_state = "contractor_gun"
	weapon_weight = WEAPON_HEAVY
	accepted_magazine_type = /obj/item/ammo_box/magazine/gauss
	w_class = WEIGHT_CLASS_BULKY
	bolt_type = BOLT_TYPE_NO_BOLT
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

/obj/item/gun/ballistic/gauss_rifle/attack_self(mob/living/user as mob)
	. = ..()
	if(.)
		return

	if(length(ammo_type) > 1)
		select_fire(user)

// /obj/item/gun/ballistic/gauss_rifle/click_alt(mob/user)
// 	. = ..()
// 	current_index++
// 	if(current_index > length(modes))
// 		current_index = 1
// 	current_mode = modes[current_index]
// 	update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/gauss_rifle/proc/select_fire(mob/living/user)
	ammo_mode++
	if (ammo_mode > length(ammo_type))
		ammo_mode = 1
	var/obj/item/ammo_casing/gauss/shot = ammo_type[ammo_mode]
	if(!isnull(shot) && !istype(shot))
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

// /obj/item/gun/ballistic/gauss_rifle/update_icon_state()
// 	. = ..()
// 	if(current_mode == "standard")
// 		icon_state = initial(icon_state)
// 		inhand_icon_state = initial(inhand_icon_state)
// 		return
// 	if(current_mode in modes)
// 		var/new_icon = "[base_icon_state]_[current_mode]"
// 		icon_state = new_icon
// 		inhand_icon_state = new_icon

/obj/item/ammo_box/magazine/gauss
	name = "Raijin Horizon Gauss Magazine"
	caliber = CALIBER_GAUSS
	max_ammo = 5
	icon_state = ".50mag"
	ammo_type = /obj/item/ammo_casing/gauss

/obj/item/ammo_box/magazine/gauss/emp
	name = "Raijin Horizon EMP Gauss Magazine"
	color = COLOR_BLUE
	ammo_type = /obj/item/ammo_casing/gauss/emp

/obj/item/ammo_box/magazine/gauss/gyro
	name = "Raijin Horizon Gyro-stabilized Gauss Magazine"
	color = COLOR_YELLOW
	ammo_type = /obj/item/ammo_casing/gauss/gyro

/obj/item/ammo_box/magazine/gauss/antimatter
	name = "Raijin Horizon Antimatter Gauss Magazine"
	color = COLOR_PURPLE
	ammo_type = /obj/item/ammo_casing/gauss/antimatter

/obj/item/ammo_box/magazine/gauss/thermite
	name = "Raijin Horizon Thermite Gauss Magazine"
	color = COLOR_RED
	ammo_type = /obj/item/ammo_casing/gauss/thermite

/obj/item/ammo_casing/gauss
	name = "gauss round"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard"
	caliber = CALIBER_GAUSS
	projectile_type = /obj/projectile/bullet/gauss
	var/select_name = "gauss"

/obj/item/ammo_casing/gauss/emp
	name = "EMP gauss round"
	icon_state = "emp"
	projectile_type = /obj/projectile/bullet/gauss/emp
	select_name = "emp"

/obj/item/ammo_casing/gauss/gyro
	name = "gyro-stabilized gauss round"
	icon_state = "gyro"
	projectile_type = /obj/projectile/bullet/gauss/gyro
	select_name = "gyro"

/obj/item/ammo_casing/gauss/antimatter
	name = "antimatter gauss round"
	icon_state = "antimatter"
	projectile_type = /obj/projectile/bullet/gauss/antimatter
	select_name = "antimatter"

/obj/item/ammo_casing/gauss/thermite
	name = "thermite gauss round"
	icon_state = "thermite"
	projectile_type = /obj/projectile/bullet/gauss/thermite
	select_name = "thermite"

/obj/projectile/bullet/gauss
	name = "standard gauss round"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bullets.dmi'
	icon_state = "standard_projectile"

/obj/projectile/bullet/gauss/emp
	name = "EMP gauss round"
	icon_state = "emp_projectile"

/obj/projectile/bullet/gauss/gyro
	name = "gyro-stabilized gauss round"
	icon_state = "gyro_projectile"

/obj/projectile/bullet/gauss/antimatter
	name = "antimatter gauss round"
	icon_state = "antimatter_projectile"

/obj/projectile/bullet/gauss/thermite
	name = "thermite gauss round"
	icon_state = "thermite_projectile"
