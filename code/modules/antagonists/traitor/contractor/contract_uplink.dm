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
	var/static/datum/contractor_hub/handler

/datum/component/uplink/contractor/Initialize(owner, lockable, enabled, uplink_flag, starting_tc, has_progression, datum/uplink_handler/uplink_handler_override)
	. = ..()
	if(isnull(handler))
		handler = new()
	handler.add_uplink(src)

/datum/component/uplink/contractor/Destroy()
	. = ..()
	handler.remove_uplink(src)

/datum/component/uplink/contractor/ui_data(mob/user)
	. = ..()
	.["allow_dangerous_extract"] = allow_dangerous_extract()

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
	.["refresh_time"] = timeleft(handler.contract_refresh_timer)

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
