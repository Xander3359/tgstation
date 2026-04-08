/datum/uplink_category/contractor
	name = "Contractor"
	weight = 10

/datum/uplink_item/bundles_tc/contract_kit
	name = "Contract Kit"
	desc = "The Syndicate have offered you the chance to become a contractor, take on kidnapping contracts for TC \
		and cash payouts. Upon purchase, you'll be granted your own contract uplink embedded within the supplied \
		tablet computer. Additionally, you'll be granted standard contractor gear to help with your mission - \
		comes supplied with the tablet, specialised space suit, chameleon jumpsuit and mask, agent card, \
		and a specialised contractor baton."
	item = /obj/item/storage/box/syndicate/contract_kit
	category = /datum/uplink_category/contractor
	cost = 20
	purchasable_from = UPLINK_CONTRACTOR
	population_minimum = TRAITOR_POPULATION_LOWPOP

/datum/uplink_item/bundles_tc/contract_kit/purchase(mob/user, datum/uplink_handler/uplink_handler, atom/movable/source)
	. = ..()
	for(var/uplink_items in subtypesof(/datum/uplink_item/contractor))
		var/datum/uplink_item/uplink_item = new uplink_items
		uplink_handler.extra_purchasable += uplink_item

/datum/uplink_item/contractor
	restricted = TRUE
	category = /datum/uplink_category/contractor
	purchasable_from = NONE //they will be added to extra_purchasable
	uplink_item_flags = UPLINK_CONTRACTOR

/datum/uplink_item/contractor/pinpointer
	name = "Contractor Pinpointer"
	desc = "A pinpointer that finds targets even without active suit sensors. \
		Due to taking advantage of an exploit within the system, it can't pinpoint \
		to the same accuracy as the traditional models. \
		Becomes permanently locked to the user that first activates it."
	item = /obj/item/pinpointer/crew/contractor
	limited_stock = 2
	cost = 1

/datum/uplink_item/contractor/extraction_kit
	name = "Fulton Extraction Kit"
	desc = "For getting your target across the station to those difficult dropoffs. \
		Place the beacon somewhere secure, and link the pack. \
		Activating the pack on your target will send them over to the beacon - \
		make sure they're not just going to run away though!"
	item = /obj/item/storage/box/contractor/fulton_extraction
	limited_stock = 1
	cost = 1

/datum/uplink_item/contractor/partner
	name = "Contractor Reinforcement"
	desc = "A reinforcement operative will be sent to aid you in your goals, \
		they are paid separately, and will not take a cut from your profits."
	item = /obj/item/antag_spawner/loadout/contractor
	limited_stock = 1
	cost = 2


// The whole fucking category is TODO | XANTODO | JAKETODO | ANNETODO zzzzzzzzzzzz

/datum/uplink_item/contractor/XANTODO // Oh yeah I'm TODOING the type path :)
	restricted = FALSE
	purchasable_from = ALL
	category = /datum/uplink_category/contractor

/datum/uplink_item/contractor/XANTODO/baton_cuffing
	name = "Baton cuffing upgrade"
	desc = "Gives your baton the ability to cuff victims"
	cost = 0
	item = /obj/item/baton_upgrade/cuffing

/datum/uplink_item/contractor/XANTODO/baton_nodrop
	name = "Baton nodrop upgrade"
	desc = "After many years of advanced RND research, involving a ton of manpower from multiple scientists of all types of branches. \
			Turns out the best way to not lose a baton is by simply putting a strap on your wrist..."
	cost = 0
	item = /obj/item/baton_upgrade/nodrop

/datum/uplink_item/contractor/XANTODO/laughing_gas
	name = "Laughing gas module"
	desc = "ANNETODO"
	cost = 0
	item = /obj/item/mod/module/laughing_gas

/datum/uplink_item/contractor/XANTODO/snatcher
	name = "snatcher module"
	desc = "ANNETODO"
	cost = 0
	item = /obj/item/mod/module/energy_net/snatcher

/datum/uplink_item/contractor/XANTODO/scorpion_hook
	name = "Scorpion hook module"
	desc = "ANNETODO"
	cost = 0
	item = /obj/item/mod/module/energy_net/scorpion_hook
