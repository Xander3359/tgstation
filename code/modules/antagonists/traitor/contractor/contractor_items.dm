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
	worn_icon_state = "handcuffs" // XANTODO, Make contractor cuffs block succumbing
	handcuff_icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_handcuffs.dmi'
	handcuff_icon_state = "handcuffs_worn"
