
/datum/component/uplink/contractor
	name = "contractor uplink"
	ui_name = "ContractorUplink"
	ui_autoupdate = TRUE
	var/static/datum/contractor_hub/handler
	var/error = ""

/datum/component/uplink/contractor/Initialize(owner, lockable, enabled, uplink_flag, starting_tc, has_progression, datum/uplink_handler/uplink_handler_override)
	. = ..()
	if(isnull(handler))
		handler = new()
	RegisterSignal(parent, COMSIG_MODULE_USED, PROC_REF(relay_ui))

/// Opens the UI for the mob that activated the mod module
/datum/component/uplink/contractor/proc/relay_ui(datum/source, mob/activator)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(ui_interact), activator)

// TODO: move this to a login act
/datum/component/uplink/contractor/ui_interact(mob/user, datum/tgui/ui)
	var/datum/antagonist/traitor/traitor_user = IS_TRAITOR(user)
	// Set up the hub before ..() opens the UI, else the first static data has no contracts and payouts read 0.
	if(!isnull(traitor_user) && isnull(traitor_user.uplink_handler.contractor_state))
		handler.add_uplink(src)
		traitor_user.uplink_handler.contractor_state = new()
		user.playsound_local(user, 'sound/music/antag/contractstartup.ogg', 100, FALSE)
	return ..()

/datum/component/uplink/contractor/ui_state(mob/user)
	return GLOB.conscious_state

/datum/component/uplink/contractor/Destroy()
	. = ..()
	handler.remove_uplink(src)

/datum/component/uplink/contractor/ui_data(mob/user)
	var/list/data = ..()
	data["allow_dangerous_extract"] = allow_dangerous_extract()
	data["error"] = error

	var/datum/antagonist/traitor/traitor = user?.mind?.has_antag_datum(/datum/antagonist/traitor)
	var/datum/contractor_state/contract_state = traitor?.uplink_handler?.contractor_state
	data["redeemable_tc"] = contract_state?.contract_TC_to_redeem || 0

	data["refresh_time"] = timeleft(handler.contract_refresh_timer)

	return data

/datum/component/uplink/contractor/ui_static_data(mob/user)
	var/list/data = ..()
	var/list/bounty_data = list()
	for(var/datum/syndicate_contract/bounty in handler.assigned_contracts)
		var/mob/target = bounty.contract.target
		if(QDELETED(target))
			continue
		bounty_data += list(bounty.to_ui_data())

	data["bounty_targets"] = bounty_data
	data["high_bounty"] = handler.highest_payout
	data["low_bounty"] = handler.lowest_payout

	//data["bomb_list"] = handler.contractor_state.bomb_implants // XANTODO Figure out how to handle this?

	return data

/datum/component/uplink/contractor/proc/allow_dangerous_extract()
	if(length(GLOB.joined_player_list) < handler.dangerous_extract_pop)
		return FALSE
	return TRUE

/datum/component/uplink/contractor/ui_assets(mob/user)
	. = ..()
	. += list(
		get_asset_datum(/datum/asset/simple/contractor),
	)

/datum/asset/simple/contractor
	assets = list(
		"coin1.png" = 'icons/ui/antags/contractor/coin1.png',
		"coin2.png" = 'icons/ui/antags/contractor/coin2.png',
		"coin3.png" = 'icons/ui/antags/contractor/coin3.png',
		"coin4.png" = 'icons/ui/antags/contractor/coin4.png',
	)

/datum/component/uplink/contractor/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(!.)
		return
	var/mob/living/user = usr
	var/datum/antagonist/traitor/traitor = user?.mind?.has_antag_datum(/datum/antagonist/traitor)
	if(isnull(traitor))
		error = "Unauthorized user."
		return
	var/datum/contractor_state/contract_state = traitor.uplink_handler?.contractor_state
	if(isnull(traitor.uplink_handler))
		error = "Criticial error #521."
		return

	if(isnull(traitor.uplink_handler.contractor_state))
		traitor.uplink_handler.contractor_state = new()

	switch(action)
		if("contract_accept")
			var/contract_id = text2num(params["contract_id"])
			handler.assigned_contracts[contract_id].status = CONTRACT_STATUS_ACTIVE
			contract_state.current_contract = handler.assigned_contracts[contract_id]
			// program_open_overlay = "contractor-contract"
			return TRUE

		// if("PRG_login")
		// 	var/datum/antagonist/traitor/traitor_user = user.mind.has_antag_datum(/datum/antagonist/traitor)
		// 	if(!traitor_user)
		// 		error = "UNAUTHORIZED USER"
		// 		return TRUE
		// 	traitor_data = traitor_user
		// 	if(!traitor_data.uplink_handler.contractor_hub)
		// 		traitor_data.uplink_handler.contractor_hub = new
		// 		traitor_data.uplink_handler.contractor_hub.create_contracts(traitor_user.owner)
		// 		user.playsound_local(user, 'sound/music/antag/contractstartup.ogg', 100, FALSE)
		// 		program_open_overlay = "contractor-contractlist"
		// 	return TRUE

		if("call_extraction")
			var/extraction_type = params["extraction_type"]
			var/contract_id = text2num(params["contract_id"])
			var/datum/syndicate_contract/contract_holder = handler.assigned_contracts[contract_id]
			if(isnull(contract_holder))
				user.playsound_local(user, 'sound/machines/uplink/uplinkerror.ogg', 50)
				error = "Contract not found. It may have been removed or expired."
				return TRUE
			var/area/dropoff_area = get_turf(user)
			if(isnull(dropoff_area))
				user.playsound_local(user, 'sound/machines/uplink/uplinkerror.ogg', 50)
				error = "Invalid dropoff location, request IT support."
				return TRUE
			if (contract_holder.status != CONTRACT_STATUS_EXTRACTING)
				if (contract_holder.handle_extraction(user, extraction_type))
					user.playsound_local(user, 'sound/effects/confirmdropoff.ogg', 100, TRUE)
					contract_holder.status = CONTRACT_STATUS_EXTRACTING
					// program_open_overlay = "contractor-extracted"
				else
					user.playsound_local(user, 'sound/machines/uplink/uplinkerror.ogg', 50)
					error = "Either both you or your target aren't at the dropoff location, or the pod hasn't got a valid place to land. Clear space, or make sure you're both inside."
			else
				user.playsound_local(user, 'sound/machines/uplink/uplinkerror.ogg', 50)
				error = "Already extracting... Place the target into the pod. If the pod was destroyed, this contract is no longer possible."
			return TRUE

		if("contract_abort")
			var/contract_id = text2num(params["contract_id"])
			var/datum/syndicate_contract/contract_holder = handler.assigned_contracts[contract_id]
			contract_holder.status = CONTRACT_STATUS_ABORTED
			// program_open_overlay = "contractor-contractlist"
			return TRUE

		if("redeem_tc")
			if (contract_state.contract_TC_to_redeem)
				var/obj/item/stack/telecrystal/crystals = new /obj/item/stack/telecrystal(get_turf(user), contract_state.contract_TC_to_redeem)
				if(ishuman(user))
					var/mob/living/carbon/human/H = user
					if(H.put_in_hands(crystals))
						to_chat(H, span_notice("Your payment materializes into your hands!"))
					else
						to_chat(user, span_notice("Your payment materializes onto the floor."))
				contract_state.contract_TC_payed_out += contract_state.contract_TC_to_redeem
				contract_state.contract_TC_to_redeem = 0
				return TRUE
			else
				user.playsound_local(user, 'sound/machines/uplink/uplinkerror.ogg', 50)
			return TRUE

		if ("clear_error")
			error = ""
			return TRUE

		// if("PRG_set_first_load_finished")
		// 	first_load = FALSE
		// 	return TRUE
		// if("PRG_toggle_info")
		// 	info_screen = !info_screen
		// 	return TRUE
