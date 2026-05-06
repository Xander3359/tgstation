/datum/surgery_operation/limb/contractor_bomb_defusal
	name = "prepare for bomb defusal"
	desc = "Get ready for a fun time." // ANNETODO
	operation_flags = OPERATION_NOTABLE
	implements = list(
		TOOL_HEMOSTAT = 2.25,
		TOOL_WIRECUTTER = 0.25,
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
	display_results(
		surgeon,
		limb.owner,
		span_notice("You begin to stretch [limb.owner]'s windpipe, trying your best to avoid nearby blood vessels..."),
		span_notice("[surgeon] begins to stretch [limb.owner]'s windpipe, taking care to avoid any nearby blood vessels."),
		span_notice("[surgeon] begins to stretch [limb.owner]'s windpipe."),
	)
	display_pain(limb.owner, "You feel an agonizing stretching sensation in your neck!")

/datum/surgery_operation/limb/contractor_bomb_defusal/on_success(obj/item/bodypart/limb, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		limb.owner,
		span_notice("You stretch [limb.owner]'s windpipe with [tool], managing to avoid the nearby blood vessels."),
		span_notice("[surgeon] succeeds at stretching [limb.owner]'s windpipe with [tool], avoiding the nearby blood vessels."),
		span_notice("[surgeon] finishes stretching [limb.owner]'s windpipe.")
	)
	var/obj/item/contractor_bomb/bomb = locate() in limb.contents
	bomb?.perform_defusal(surgeon)
