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
