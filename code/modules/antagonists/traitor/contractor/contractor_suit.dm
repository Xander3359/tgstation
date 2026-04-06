/datum/mod_theme/contractor
	name = "contractor"
	desc = ""
	extended_desc = ""
	ui_theme = "syndicate"
	activation_step_time = 1
	default_skin = "contractor"
	complexity_max = 25
	armor_type = /datum/armor/mod_theme_contractor
	variants = list(
		"contractor" = list(
			/obj/item/clothing/head/mod = list(
				UNSEALED_LAYER = NECK_LAYER,
				UNSEALED_CLOTHING = SNUG_FIT,
				SEALED_CLOTHING = THICKMATERIAL|STOPSPRESSUREDAMAGE|BLOCK_GAS_SMOKE_EFFECT|HEADINTERNALS,
				UNSEALED_INVISIBILITY = HIDEFACIALHAIR,
				SEALED_INVISIBILITY = HIDEMASK|HIDEEARS|HIDEEYES|HIDEFACE|HIDEHAIR|HIDESNOUT,
				SEALED_COVER = HEADCOVERSMOUTH|HEADCOVERSEYES|PEPPERPROOF,
				UNSEALED_MESSAGE = HELMET_UNSEAL_MESSAGE,
				SEALED_MESSAGE = HELMET_SEAL_MESSAGE,
			),
			/obj/item/clothing/suit/mod = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				SEALED_INVISIBILITY = HIDEJUMPSUIT,
				UNSEALED_MESSAGE = CHESTPLATE_UNSEAL_MESSAGE,
				SEALED_MESSAGE = CHESTPLATE_SEAL_MESSAGE,
			),
			/obj/item/clothing/gloves/mod = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				CAN_OVERSLOT = TRUE,
				UNSEALED_MESSAGE = GAUNTLET_UNSEAL_MESSAGE,
				SEALED_MESSAGE = GAUNTLET_SEAL_MESSAGE,
			),
			/obj/item/clothing/shoes/mod = list(
				UNSEALED_CLOTHING = THICKMATERIAL,
				SEALED_CLOTHING = STOPSPRESSUREDAMAGE,
				CAN_OVERSLOT = TRUE,
				UNSEALED_MESSAGE = BOOT_UNSEAL_MESSAGE,
				SEALED_MESSAGE = BOOT_SEAL_MESSAGE,
			),
		),
		)
	inbuilt_modules = list(/obj/item/mod/module/infiltrator/contractor, /obj/item/mod/module/hearing_protection, /obj/item/mod/module/contractor_uplink)

/datum/armor/mod_theme_contractor
	melee = 30
	bullet = 30
	laser = 40
	energy = 50
	bomb = 40
	bio = 100
	fire = 100
	acid = 100
	wound = 25

/obj/item/mod/control/pre_equipped/contractor
	theme = /datum/mod_theme/contractor
	applied_cell = /obj/item/stock_parts/power_store/cell/super
	applied_modules = list(
		/obj/item/mod/module/storage/syndicate,
		/obj/item/mod/module/chameleon,
		/obj/item/mod/module/shock_absorber,
		/obj/item/mod/module/emp_shield,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/hat_stabilizer/syndicate,
		/obj/item/mod/module/visor/thermal,
		/obj/item/mod/module/criminalcapture,
	)

/obj/item/mod/control/pre_equipped/contractor/Initialize(mapload, new_theme, new_skin, new_core)
	. = ..()
	ADD_TRAIT(src, TRAIT_CONTRABAND_BLOCKER, INNATE_TRAIT)

/obj/item/mod/control/pre_equipped/contractor/debugsuit
	applied_modules = list(
		/obj/item/mod/module/storage/syndicate,
		/obj/item/mod/module/chameleon,
		/obj/item/mod/module/shock_absorber,
		/obj/item/mod/module/emp_shield,
		/obj/item/mod/module/magnetic_harness,
		/obj/item/mod/module/hat_stabilizer/syndicate,
		/obj/item/mod/module/visor/thermal,
		/obj/item/mod/module/dart_gun
		/obj/item/mod/module/energy_net/snatcher,
		/obj/item/mod/module/energy_net/scorpion_hook,
		/obj/item/mod/module/laughing_gas,
	)
	default_pins = list(
		/obj/item/mod/module/dart_gun
		/obj/item/mod/module/energy_net/snatcher,
		/obj/item/mod/module/energy_net/scorpion_hook,
		/obj/item/mod/module/laughing_gas,
	)
