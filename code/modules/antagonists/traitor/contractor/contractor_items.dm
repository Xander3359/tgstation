// Pinpointer
/obj/item/pinpointer/crew/contractor
	name = "contractor pinpointer"
	desc = "A handheld tracking device that locks onto certain signals. Ignores suit sensors, but is much less accurate."
	icon_state = "pinpointer_syndicate"
	worn_icon_state = "pinpointer_black"
	minimum_range = 25
	has_owner = TRUE
	ignore_suit_sensor_level = TRUE

/obj/item/restraints/handcuffs/contractor
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_handcuffs.dmi'
	icon_state = "handcuffs"
	worn_icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_handcuffs.dmi'
	worn_icon_state = "handcuffs"
	handcuff_icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_handcuffs.dmi'
	handcuff_icon_state = "handcuffs_worn"

/obj/item/restraints/handcuffs/contractor/equipped(mob/living/user, slot)
	. = ..()
	UnregisterSignal(user, list(SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION), COMSIG_LIVING_TRY_SUCCUMB))
	if(slot == ITEM_SLOT_HANDCUFFED)
		RegisterSignal(user, SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION), PROC_REF(on_enter_crit))
		RegisterSignal(user, COMSIG_LIVING_TRY_SUCCUMB, PROC_REF(on_succumb_attempt))

/obj/item/restraints/handcuffs/contractor/on_uncuffed(datum/source, mob/living/wearer)
	. = ..()
	UnregisterSignal(wearer, list(SIGNAL_ADDTRAIT(TRAIT_CRITICAL_CONDITION), COMSIG_LIVING_TRY_SUCCUMB))

/obj/item/restraints/handcuffs/contractor/proc/on_enter_crit(mob/owner)
	SIGNAL_HANDLER
	if(!owner?.reagents.has_reagent(/datum/reagent/medicine/epinephrine) && !owner?.reagents.has_reagent(/datum/reagent/medicine/c2/penthrite))
		to_chat(owner, "[src]'s heart monitor starts beeping, trying to keep [owner.p_them()] alive.") // ANNETODO
		owner.reagents.add_reagent(/datum/reagent/medicine/epinephrine, 10)
		owner.reagents.add_reagent(/datum/reagent/medicine/coagulant, 2)

/obj/item/restraints/handcuffs/contractor/proc/on_succumb_attempt()
	SIGNAL_HANDLER
	return SUCCUMB_PREVENTED // Can't succumb if you are in cuffs, helps prevent victims griefing the contractor

// Emag
/obj/item/card/emag/doorjack/contractor
	name = "contractor emag" // ANNETODO
	desc = "funny emag for contractors"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_emag.dmi'
	icon_state = "contractor_emag"
	charges = 5
	max_charges = 5
	airlock_breaker = FALSE

/obj/item/card/emag/doorjack/contractor/use_charge(mob/user)
	. = ..()
	flick("contractor_emag_active", src)

/obj/item/card/emag/doorjack/contractor/can_emag(atom/target, mob/user)
	for(var/list/subtypelist in type_whitelist)
		if(target.type in subtypelist)
			if(charges <= 0) // This card only needs charges when used on doors
				return FALSE
	return TRUE

// Contractor implant
/obj/item/implanter/contractor
	name = "implanter (contractor)"
	imp_type = /obj/item/implant/explosive/contractor

/obj/item/implant/explosive/contractor
	actions_types = list(/datum/action/item_action/contractor_detonator)
	hidden_implant = TRUE

/// Opens the remote detonation suite instead of self-detonating like a normal explosive implant.
/obj/item/implant/explosive/contractor/ui_action_click(mob/user, actiontype)
	if(istype(actiontype, /datum/action/item_action/contractor_detonator))
		ui_interact(imp_in)
		return
	return ..()

/// Resolves the contractor state (and its tracked bomb implants) belonging to the implantee.
/obj/item/implant/explosive/contractor/proc/get_contractor_state()
	var/datum/antagonist/traitor/traitor = imp_in?.mind?.has_antag_datum(/datum/antagonist/traitor)
	return traitor?.uplink_handler?.contractor_state

/obj/item/implant/explosive/contractor/ui_state(mob/user)
	return GLOB.conscious_state

/obj/item/implant/explosive/contractor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BombImplantDetonator")
		ui.set_autoupdate(TRUE)
		ui.open()

/obj/item/implant/explosive/contractor/ui_data(mob/user)
	var/list/data = list()
	var/list/bombs = list()
	var/datum/contractor_state/state = get_contractor_state()
	for(var/obj/item/contractor_bomb/bomb as anything in state?.bomb_implants)
		if(QDELETED(bomb))
			continue
		bombs += list(bomb.to_ui_data())
	data["bombs"] = bombs
	return data

/obj/item/implant/explosive/contractor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("arm")
			var/datum/contractor_state/contractor_state = get_contractor_state()
			var/obj/item/contractor_bomb/bomb = locate(params["ref"]) in contractor_state?.bomb_implants
			if(QDELETED(bomb) || bomb.active)
				return TRUE
			bomb.arm()
			return TRUE

/datum/action/item_action/contractor_detonator
	name = "Remote Detonation Suite"
	check_flags = NONE

