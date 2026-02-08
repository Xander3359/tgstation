// /datum/contractor_bounty
// 	var/datum/weakref/target_ref
// 	var/image/cached_image
// 	var/is_head = FALSE
// 	var/payout = 0

// /datum/contractor_bounty/New(mob/target)
// 	. = ..()
// 	target_ref = WEAKREF(target)
// 	is_head = target.job
// 	INVOKE_ASYNC(src, PROC_REF(cache_image), target)

// /datum/contractor_bounty/proc/cache_image(mob/target)
// 	var/mutable_appearance/icon = new(target)
// 	icon.dir = SOUTH
// 	cached_image = icon2base64(getFlatIcon(icon))

// /datum/contractor_bounty/proc/can_claim(mob/user)
// 	return TRUE

// /datum/contractor_bounty/proc/to_ui_data()
// 	var/mob/target = target_ref?.resolve()
// 	return list(
// 		"name" = target?.name || "Unknown Target",
// 		"is_head" = is_head,
// 		"bounty_reward" = payout,
// 		"mugshot_icon" = cached_image,
// 	)

// /datum/contractor_bounty_handler
// 	var/list/bounty_targets = list()
// 	var/bounty_target_number = 4
// 	var/high_bounty = 30
// 	var/low_bounty = 10
// 	var/refresh_time = 20 MINUTES

// /datum/contractor_bounty_handler/New()
// 	. = ..()
// 	pick_bounty_targets()

// /datum/contractor_bounty_handler/proc/pick_bounty_targets()
// 	bounty_targets.Cut()
// 	var/list/potential_targets = GLOB.human_list.Copy()
// 	var/index = 0
// 	while(index < bounty_target_number)
// 		index++
// 		var/mob/target = pick(potential_targets)
// 		potential_targets -= target
// 		if(!get_turf(target))
// 			if(!length(potential_targets))
// 				CRASH("Not enough valid targets to pick bounty targets from!")
// 			index = max(0, index - 1)
// 			continue
// 		var/datum/contractor_bounty = new(target)
// 		bounty_targets[WEAKREF(target)] += contractor_bounty

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
	handler.add_uplink(src)

// TODO: move this to a login act
/datum/component/uplink/contractor/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	var/datum/antagonist/traitor/traitor_user = IS_TRAITOR(user)
	if(!isnull(traitor_user) && isnull(traitor_user.uplink_handler.contractor_state))
		traitor_user.uplink_handler.contractor_state = new()
		user.playsound_local(user, 'sound/music/antag/contractstartup.ogg', 100, FALSE)

/datum/component/uplink/contractor/Destroy()
	. = ..()
	handler.remove_uplink(src)

/datum/component/uplink/contractor/ui_data(mob/user)
	. = ..()
	.["allow_dangerous_extract"] = allow_dangerous_extract()

/datum/component/uplink/contractor/ui_data(mob/user)
	. = ..()
	.["error"] = error
	var/datum/antagonist/traitor/traitor = user?.mind?.has_antag_datum(/datum/antagonist/traitor)
	var/datum/contractor_state/contract_state = traitor?.uplink_handler?.contractor_state

	.["redeemable_tc"] = contract_state?.contract_TC_to_redeem || 0
	.["refresh_time"] = timeleft(handler.contract_refresh_timer)

/datum/component/uplink/contractor/ui_static_data(mob/user)
	. = ..()
	var/list/bounty_data = list()
	for(var/datum/syndicate_contract/bounty in handler.assigned_contracts)
		var/mob/target = bounty.contract.target
		if(QDELETED(target))
			continue
		bounty_data += list(bounty.to_ui_data())

	.["bounty_targets"] = bounty_data
	.["high_bounty"] = handler.highest_payout
	.["low_bounty"] = handler.lowest_payout

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
	if(.)
		return
	var/mob/living/user = usr
	var/datum/antagonist/traitor/traitor = user?.mind?.has_antag_datum(/datum/antagonist/traitor)
	var/datum/contractor_state/contract_state = traitor?.uplink_handler?.contractor_state
	if(isnull(contract_state))
		return

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
			if (contract_state.current_contract.status != CONTRACT_STATUS_EXTRACTING)
				if (contract_state.current_contract.handle_extraction(user))
					user.playsound_local(user, 'sound/effects/confirmdropoff.ogg', 100, TRUE)
					contract_state.current_contract.status = CONTRACT_STATUS_EXTRACTING
					// program_open_overlay = "contractor-extracted"
				else
					user.playsound_local(user, 'sound/machines/uplink/uplinkerror.ogg', 50)
					error = "Either both you or your target aren't at the dropoff location, or the pod hasn't got a valid place to land. Clear space, or make sure you're both inside."
			else
				user.playsound_local(user, 'sound/machines/uplink/uplinkerror.ogg', 50)
				error = "Already extracting... Place the target into the pod. If the pod was destroyed, this contract is no longer possible."
			return TRUE
		if("contract_abort")
			var/contract_id = contract_state.current_contract.id
			contract_state.current_contract = null
			handler.assigned_contracts[contract_id].status = CONTRACT_STATUS_ABORTED
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
