#define CONTRACTOR_CASE_RECHARGE_RATE (0.1 * STANDARD_CELL_CHARGE)

/obj/item/storage/contractor_gun_case
	name = "contractor gun case"
	desc = "A proprietary Cybersun case for securing and maintaining a Raijin Horizon rifle package."
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_case.dmi'
	icon_state = "case_idle"
	inhand_icon_state = "infiltrator_case"
	lefthand_file = 'icons/mob/inhands/equipment/toolbox_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/toolbox_righthand.dmi'
	storage_type = /datum/storage/contractor_gun_case
	/// Whether the case lid is currently open.
	var/case_opened = FALSE

/obj/item/storage/contractor_gun_case/Initialize(mapload)
	. = ..()
	RegisterSignal(atom_storage, COMSIG_STORAGE_STORED_ITEM, PROC_REF(on_storage_updated))
	RegisterSignal(atom_storage, COMSIG_STORAGE_REMOVED_ITEM, PROC_REF(on_storage_updated))
	atom_storage.set_locked(STORAGE_FULLY_LOCKED)
	update_processing()
	update_appearance()

/obj/item/storage/contractor_gun_case/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(atom_storage)
		UnregisterSignal(atom_storage, list(COMSIG_STORAGE_STORED_ITEM, COMSIG_STORAGE_REMOVED_ITEM))
	return ..()

/obj/item/storage/contractor_gun_case/PopulateContents()
	new /obj/item/gun/energy/gauss_rifle(src)
	new /obj/item/stock_parts/power_store/gauss_nanites(src)

/obj/item/storage/contractor_gun_case/attack_hand(mob/user, list/modifiers)
	if(!case_opened)
		open_case(user)
		return TRUE

	close_case()
	return TRUE

/obj/item/storage/contractor_gun_case/attack_self(mob/user, modifiers)
	if(!case_opened)
		open_case(user)
		return TRUE

	atom_storage.open_storage(user)
	return TRUE

/obj/item/storage/contractor_gun_case/update_icon_state()
	. = ..()
	var/has_gun = !!get_stored_gun()
	if(case_opened)
		icon_state = has_gun ? "case_open" : "case_open_empty"
		return
	icon_state = has_gun ? "case_idle" : "case_off"

/obj/item/storage/contractor_gun_case/process(seconds_per_tick)
	var/has_activity = FALSE
	var/recharge_amount = CONTRACTOR_CASE_RECHARGE_RATE * seconds_per_tick

	var/obj/item/stock_parts/power_store/gauss_nanites/stored_battery = get_stored_battery()
	if(stored_battery && stored_battery.charge < stored_battery.maxcharge)
		if(stored_battery.give(recharge_amount))
			has_activity = TRUE
			stored_battery.update_appearance()

	var/obj/item/gun/energy/gauss_rifle/stored_gun = get_stored_gun()
	if(stored_gun?.cell && stored_gun.cell.charge < stored_gun.cell.maxcharge)
		if(stored_gun.cell.give(recharge_amount))
			has_activity = TRUE
			stored_gun.recharge_newshot(TRUE)
			stored_gun.update_appearance()
			stored_gun.emit_ammo_signal()

	if(!has_activity)
		STOP_PROCESSING(SSobj, src)

/obj/item/storage/contractor_gun_case/proc/open_case(mob/user)
	case_opened = TRUE
	atom_storage.set_locked(STORAGE_NOT_LOCKED)
	update_appearance()
	flick("case_opening", src)
	atom_storage.open_storage(user)

/obj/item/storage/contractor_gun_case/proc/close_case()
	case_opened = FALSE
	atom_storage.set_locked(STORAGE_FULLY_LOCKED)
	update_appearance()

/obj/item/storage/contractor_gun_case/proc/get_stored_gun()
	return locate(/obj/item/gun/energy/gauss_rifle) in contents

/obj/item/storage/contractor_gun_case/proc/get_stored_battery()
	return locate(/obj/item/stock_parts/power_store/gauss_nanites) in contents

/obj/item/storage/contractor_gun_case/proc/on_storage_updated(datum/source)
	SIGNAL_HANDLER

	update_processing()
	update_appearance()

/obj/item/storage/contractor_gun_case/proc/update_processing()
	if(get_stored_battery() || get_stored_gun())
		START_PROCESSING(SSobj, src)
		return
	STOP_PROCESSING(SSobj, src)

/datum/storage/contractor_gun_case
	max_slots = 5
	max_specific_storage = WEIGHT_CLASS_BULKY
	max_total_storage = WEIGHT_CLASS_BULKY + WEIGHT_CLASS_NORMAL * 3

/datum/storage/contractor_gun_case/New(atom/parent, max_slots, max_specific_storage, max_total_storage, rustle_sound, remove_rustle_sound)
	. = ..()
	set_holdable(list(/obj/item/gun/energy/gauss_rifle, /obj/item/stock_parts/power_store/gauss_nanites))

/datum/storage/contractor_gun_case/can_insert(obj/item/to_insert, mob/user, messages = TRUE, force = STORAGE_NOT_LOCKED)
	. = ..()
	if(!.)
		return FALSE

	if(istype(to_insert, /obj/item/gun/energy/gauss_rifle) && locate(/obj/item/gun/energy/gauss_rifle) in real_location)
		if(messages && user)
			user.balloon_alert(user, "already has gun!")
		return FALSE

	if(istype(to_insert, /obj/item/stock_parts/power_store/gauss_nanites) && locate(/obj/item/stock_parts/power_store/gauss_nanites) in real_location)
		if(messages && user)
			user.balloon_alert(user, "already has battery!")
		return FALSE

	return TRUE

#undef CONTRACTOR_CASE_RECHARGE_RATE
