
/datum/outfit/contractor_debug
	name = "Debug Contractor"
	back = /obj/item/mod/control/pre_equipped/contractor
	backpack_contents = list(
		/obj/item/storage/box/syndicate/contract_kit,
		/obj/item/storage/contractor_gun_case,
		/obj/item/uplink/contractor
	)

ADMIN_VERB(make_me_a_contractor, R_DEBUG|R_SPAWN, "Make Me A Contractor", "Dresses your mob in a contractor modsuit (with built in uplink) holding a contract kit box and a contractor gun case, and grants the traitor antag datum.", ADMIN_CATEGORY_DEBUG)
	var/mob/living/carbon/human/contractor = user.mob
	if(!ishuman(contractor))
		to_chat(user, span_warning("You need to be a human mob to receive contractor gear."))
		return
	if(isnull(contractor.mind))
		to_chat(user, span_warning("Your mob has no mind to attach the traitor antag datum to."))
		return

	// Leave contractor_state for the uplink to build on first open, so the hub generates contracts.
	if(isnull(IS_TRAITOR(contractor)))
		contractor.mind.add_antag_datum(/datum/antagonist/traitor)

	for(var/obj/item/equipped in contractor.get_equipped_items())
		qdel(equipped)
	contractor.equipOutfit(/datum/outfit/contractor_debug)

	to_chat(user, span_notice("You are now a contractor, decked out in a contractor modsuit holding a contract kit and gun case."))
	log_admin("[key_name(user)] used Make Me A Contractor on themselves.")
	message_admins("[key_name_admin(user)] used Make Me A Contractor on themselves.")

ADMIN_VERB(spawn_contractor_bomb_victim, R_DEBUG|R_SPAWN, "Spawn Contractor Bomb Victim", "Spawns a human with a contractor bomb planted on them, linked to your traitor antag datum so you can remotely detonate it.", ADMIN_CATEGORY_DEBUG)
	var/mob/living/carbon/human/contractor = user.mob
	if(!ishuman(contractor))
		to_chat(user, span_warning("You need to be a human mob to act as the controlling contractor."))
		return
	if(isnull(contractor.mind))
		to_chat(user, span_warning("Your mob has no mind to attach the traitor antag datum to."))
		return

	var/datum/antagonist/traitor/traitor = IS_TRAITOR(contractor)
	if(isnull(traitor))
		traitor = contractor.mind.add_antag_datum(/datum/antagonist/traitor)
	if(isnull(traitor.uplink_handler))
		to_chat(user, span_warning("You have no uplink handler to store the contractor state on - give yourself an uplink first."))
		return
	if(isnull(traitor.uplink_handler.contractor_state))
		traitor.uplink_handler.contractor_state = new()
	var/datum/contractor_state/contractor_state = traitor.uplink_handler.contractor_state

	if(!(locate(/obj/item/implant/explosive/contractor) in contractor.implants))
		var/obj/item/implant/explosive/contractor/detonator_implant = new()
		detonator_implant.implant(contractor)

	var/mob/living/carbon/human/victim = new(get_turf(contractor))
	var/obj/item/contractor_bomb/bomb = new(victim)
	bomb.attach_to(victim, contractor_state)

	to_chat(user, span_notice("Spawned [victim] with a contractor bomb linked to your detonation suite."))
	log_admin("[key_name(user)] spawned a contractor bomb victim ([key_name(victim)]) linked to their contractor state.")
	message_admins("[key_name_admin(user)] spawned a contractor bomb victim ([ADMIN_LOOKUPFLW(victim)]) linked to their contractor state.")
