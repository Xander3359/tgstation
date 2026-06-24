/datum/contractor_hub
	///List of all available syndicate contracts that can be taken.
	var/list/datum/syndicate_contract/assigned_contracts = list()

	///List of all people currently used as targets, to not roll doubles.
	var/list/assigned_targets = list()
	/// Time in seconds between contract refreshes.
	var/refresh_time = 10 MINUTES
	/// list of uplinks that need to be updated when contracts change, also used to decide if we want to refresh contracts
	var/list/linked_uplinks = list()
	/// timer for refreshing contracts
	var/contract_refresh_timer

	var/highest_payout = 0
	var/lowest_payout = 0
	var/dangerous_extract_pop = 30

/datum/contractor_hub/proc/add_uplink(datum/component/uplink/contractor/uplink)
	linked_uplinks += WEAKREF(uplink)
	if(!length(assigned_contracts))
		create_contracts()
		get_highest_lowest()
		wait_for_refresh()

/datum/contractor_hub/proc/remove_uplink(datum/component/uplink/contractor/uplink)
	linked_uplinks -= WEAKREF(uplink)
	if(!length(linked_uplinks))
		refresh_needed()

/datum/contractor_hub/proc/wait_for_refresh()
	if(isnull(contract_refresh_timer))
		contract_refresh_timer = addtimer(CALLBACK(src, PROC_REF(refresh_contracts)), refresh_time, TIMER_STOPPABLE)

/datum/contractor_hub/proc/refresh_needed()
	if(length(linked_uplinks))
		return
	deltimer(contract_refresh_timer)
	contract_refresh_timer = null

/datum/contractor_hub/proc/refresh_contracts()
	create_contracts()
	get_highest_lowest()
	wait_for_refresh()
	refresh_uplink_data()

/datum/contractor_hub/proc/refresh_uplink_data()
	for(var/datum/weakref/uplink_ref as anything in linked_uplinks)
		var/datum/component/uplink/contractor/uplink = uplink_ref.resolve()
		if(isnull(uplink))
			continue
		uplink.update_static_data_for_all_viewers()

/datum/contractor_hub/proc/get_highest_lowest()
	highest_payout = 0
	lowest_payout = 0
	for(var/datum/syndicate_contract/contract in assigned_contracts)
		var/total_payout = contract.contract.payout + contract.contract.payout_bonus
		if(total_payout > highest_payout)
			highest_payout = total_payout
		if(lowest_payout == 0 || total_payout < lowest_payout)
			lowest_payout = total_payout

/datum/contractor_hub/proc/create_contracts(list/to_generate = list(CONTRACT_PAYOUT_MEDIUM, CONTRACT_PAYOUT_SMALL, CONTRACT_PAYOUT_SMALL))
#ifndef TESTING
	//What the fuck
	if(length(to_generate) > length(GLOB.manifest.locked))
		to_generate.Cut(1, length(GLOB.manifest.locked))
#endif
	// We don't want the sum of all the payouts to be under this amount
	var/lowest_TC_threshold = 30

	var/total = 0
	var/lowest_paying_sum = 0
	var/datum/syndicate_contract/lowest_paying_contract

	// Randomise order, so we don't have contracts always in payout order.
	to_generate = shuffle(to_generate)

	// Support contract generation happening multiple times
	var/start_index = 1
	if (assigned_contracts.len != 0)
		start_index = assigned_contracts.len + 1

	// Generate contracts, and find the lowest paying.
	for(var/i in 1 to to_generate.len)
		var/datum/syndicate_contract/contract_to_add = new(assigned_targets, to_generate[i])
		var/contract_payout_total = contract_to_add.contract.payout + contract_to_add.contract.payout_bonus

		assigned_targets.Add(contract_to_add.contract.target)

		if (!lowest_paying_contract || (contract_payout_total < lowest_paying_sum))
			lowest_paying_sum = contract_payout_total
			lowest_paying_contract = contract_to_add

		total += contract_payout_total
		contract_to_add.id = start_index
		assigned_contracts.Add(contract_to_add)

		start_index++

	// If the threshold for TC payouts isn't reached, boost the lowest paying contract
	if (total < lowest_TC_threshold)
		lowest_paying_contract.contract.payout_bonus += (lowest_TC_threshold - total)


// /datum/contractor_hub/proc/create_contract(type)
// 	var/datum/syndicate_contract/contract_to_add = new(assigned_targets, type)
// 	contract_to_add.id = assigned_contracts.len + 1
// 	assigned_targets += contract_to_add.contract.target
// 	return contract_to_add
