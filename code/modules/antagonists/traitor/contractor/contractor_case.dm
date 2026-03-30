#define CONTRACTOR_CASE_RECHARGE_RATE (0.1 * STANDARD_CELL_CHARGE)
#define CONTRACTOR_CASE_OPENING_DELAY (0.6 SECONDS)

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
	/// Whether the case has been unlocked from its default inert mode.
	var/case_unlocked = FALSE
	/// Prevents interactions while the opening animation is playing.
	COOLDOWN_DECLARE(opening_cooldown)

/obj/item/storage/contractor_gun_case/Initialize(mapload)
	. = ..()
	var/matrix/offset = matrix()
	offset.Translate(-8, 0)
	transform = offset
	register_context()
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
	if(interaction_locked(user))
		return TRUE

	if(!case_unlocked)
		unlock_case()
		return TRUE

	if(!case_opened)
		open_case(user)
		return TRUE

	close_case()
	return TRUE

/obj/item/storage/contractor_gun_case/attack_self(mob/user, modifiers)
	if(interaction_locked(user))
		return TRUE

	if(!case_unlocked)
		unlock_case()
		return TRUE

	if(!case_opened)
		open_case(user)
		return TRUE

	atom_storage.open_storage(user)
	return TRUE

/obj/item/storage/contractor_gun_case/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	if(loc != user && user.can_perform_action(src, FORBID_TELEKINESIS_REACH | ALLOW_RESTING))
		user.put_in_hands(src)
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

	return SECONDARY_ATTACK_CONTINUE_CHAIN

/obj/item/storage/contractor_gun_case/add_context(atom/source, list/context, obj/item/held_item, mob/user)
	. = ..()
	context[SCREENTIP_CONTEXT_LMB] = case_opened ? "Close case" : (case_unlocked ? "Open case" : "Unlock case")
	context[SCREENTIP_CONTEXT_RMB] = "Pick up"
	context[SCREENTIP_CONTEXT_ALT_LMB] = case_unlocked ? "Lock case" : "Unlock case"
	return CONTEXTUAL_SCREENTIP_SET

/obj/item/storage/contractor_gun_case/click_alt(mob/user)
	if(interaction_locked(user))
		return CLICK_ACTION_BLOCKING

	if(case_opened)
		return
	if(case_unlocked)
		lock_case()
		balloon_alert(user, "case locked")
		return CLICK_ACTION_SUCCESS
	unlock_case()
	balloon_alert(user, "case unlocked")
	return CLICK_ACTION_SUCCESS

/obj/item/storage/contractor_gun_case/update_icon_state()
	. = ..()
	if(case_opened)
		icon_state = get_stored_gun() ? "case_open" : "case_open_empty"
		return

	icon_state = case_unlocked ? "case_idle" : "case_off"

/obj/item/storage/contractor_gun_case/proc/unlock_case()
	case_unlocked = TRUE
	COOLDOWN_START(src, opening_cooldown, CONTRACTOR_CASE_OPENING_DELAY)
	flick("case_opening", src)
	update_appearance()

/obj/item/storage/contractor_gun_case/proc/interaction_locked(mob/user)
	if(COOLDOWN_FINISHED(src, opening_cooldown))
		return FALSE
	if(user)
		balloon_alert(user, "wait...")
	return TRUE

/obj/item/storage/contractor_gun_case/proc/lock_case()
	case_unlocked = FALSE
	case_opened = FALSE
	atom_storage.set_locked(STORAGE_FULLY_LOCKED)
	update_appearance()

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
	animated = FALSE
	click_alt_open = FALSE

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

/datum/storage/contractor_gun_case/on_mousedrop_onto(datum/source, atom/over_object, mob/user)
	if(ismecha(user.loc) || user.incapacitated || !user.canUseStorage())
		return NONE

	if(over_object == user)
		if(!user.can_perform_action(parent, FORBID_TELEKINESIS_REACH | ALLOW_RESTING))
			return NONE
		INVOKE_ASYNC(user, TYPE_PROC_REF(/mob, put_in_hands), parent)
		return COMPONENT_CANCEL_MOUSEDROP_ONTO

	return ..()

#undef CONTRACTOR_CASE_RECHARGE_RATE
#undef CONTRACTOR_CASE_OPENING_DELAY
