/datum/surgery_operation/limb/contractor_bomb_defusal
	name = "prepare for bomb defusal"
	desc = "Get ready for a fun time." // ANNETODO
	operation_flags = OPERATION_NOTABLE
	implements = list(
		TOOL_HEMOSTAT = 2.25,
		TOOL_WIRECUTTER = 0.25,
		/obj/item/kitchen/fork = 0.01,
		/obj/item/nuke_core = 1.25,
	)
	time = 8 SECONDS
	preop_sound = 'sound/items/handling/surgery/retractor1.ogg'
	success_sound = 'sound/items/handling/surgery/retractor2.ogg'
	all_surgery_states_required = SURGERY_SKIN_OPEN|SURGERY_ORGANS_CUT

/datum/surgery_operation/limb/contractor_bomb_defusal/all_required_strings()
	return list("the patient must have an implanted bomb") + ..()

/datum/surgery_operation/limb/contractor_bomb_defusal/state_check(obj/item/bodypart/limb)
	if(locate(/obj/item/contractor_bomb) in limb.contents)
		return TRUE

/datum/surgery_operation/limb/contractor_bomb_defusal/on_preop(obj/item/bodypart/limb, mob/living/surgeon, obj/item/tool, list/operation_args)
	if(istype(tool, /obj/item/kitchen/fork))
		display_results(
			surgeon,
			limb.owner,
			span_notice("You begin sticking a fork in the bomb... what?"),
			span_notice("[surgeon] begins sticking a fork in the bomb's access panel... is this a good idea?"),
			span_notice("[surgeon] begins sticking a fork where it doesn't belong."),
		)
		return

	if(istype(tool, /obj/item/nuke_core) || istype(tool, /obj/item/nuke_core_container))
		display_results(
			surgeon,
			limb.owner,
			span_notice("You start transferring the nuke core into the bomb"),
			span_notice("[surgeon] begins inserting a nuke core inside the bomb's core"), // ANNETODO
			span_notice("[surgeon] begins inserting a nuke core inside the bomb's core"), // ANNETODO
		)
		return

	display_results(
		surgeon,
		limb.owner,
		span_notice("You begin to stretch [limb.owner]'s windpipe, trying your best to avoid nearby blood vessels..."),
		span_notice("[surgeon] begins to stretch [limb.owner]'s windpipe, taking care to avoid any nearby blood vessels."),
		span_notice("[surgeon] begins to stretch [limb.owner]'s windpipe."),
	)
	display_pain(limb.owner, "You feel an agonizing stretching sensation in your neck!")

/datum/surgery_operation/limb/contractor_bomb_defusal/tool_check(obj/item/tool)
	if(istype(tool, /obj/item/nuke_core_container))
		var/obj/item/nuke_core_container/container
		if(!container.core)
			return FALSE
	return ..()

/datum/surgery_operation/limb/contractor_bomb_defusal/on_success(obj/item/bodypart/limb, mob/living/surgeon, obj/item/tool, list/operation_args)
	var/obj/item/contractor_bomb/bomb = locate() in limb.contents
	if(!bomb)
		return

	if(istype(tool, /obj/item/kitchen/fork))
		bomb.get_forked()
		display_results(
			surgeon,
			limb.owner,
			span_notice("You just stuck a fork in the access panel... wow!"),
			span_notice("[surgeon] succeeds at sticking a fork in the access panel of the bomb. You get an omnious feeling"),
			span_notice("[surgeon] has stuck a fork in the access panel."),
		)
		qdel(tool)
		return

	if(istype(tool, /obj/item/nuke_core))
		bomb.transfer_core(tool)
		return
	if(istype(tool, /obj/item/nuke_core_container))
		var/obj/item/nuke_core_container/container = tool
		bomb.transfer_core(container.core)
		return

	display_results(
		surgeon,
		limb.owner,
		span_notice("You stretch [limb.owner]'s windpipe with [tool], managing to avoid the nearby blood vessels."),
		span_notice("[surgeon] succeeds at stretching [limb.owner]'s windpipe with [tool], avoiding the nearby blood vessels."),
		span_notice("[surgeon] finishes stretching [limb.owner]'s windpipe.")
	)
	bomb.perform_defusal(surgeon)
