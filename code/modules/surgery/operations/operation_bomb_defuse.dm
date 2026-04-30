/datum/surgery_operation/organ/bomb_defusal
	name = "prepare for bomb defusal"
	desc = "Get ready for a fun time." // ANNETODO
	operation_flags = OPERATION_NOTABLE
	implements = list(
		TOOL_HEMOSTAT = 1,
		TOOL_WIRECUTTER = 2.25,
	)
	time = 8 SECONDS
	preop_sound = 'sound/items/handling/surgery/retractor1.ogg'
	success_sound = 'sound/items/handling/surgery/retractor2.ogg'
	target_type = /obj/item/organ/contractor_bomb
	all_surgery_states_required = SURGERY_SKIN_OPEN|SURGERY_ORGANS_CUT

/datum/surgery_operation/organ/bomb_defusal/all_required_strings()
	return list("the patient must have an implanted bomb") + ..()

/datum/surgery_operation/organ/bomb_defusal/state_check(obj/item/organ/organ)
	return TRUE

/datum/surgery_operation/organ/bomb_defusal/on_preop(obj/item/organ/lungs/organ, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		organ.owner,
		span_notice("You begin to stretch [organ.owner]'s windpipe, trying your best to avoid nearby blood vessels..."),
		span_notice("[surgeon] begins to stretch [organ.owner]'s windpipe, taking care to avoid any nearby blood vessels."),
		span_notice("[surgeon] begins to stretch [organ.owner]'s windpipe."),
	)
	display_pain(organ.owner, "You feel an agonizing stretching sensation in your neck!")

/datum/surgery_operation/organ/bomb_defusal/on_success(obj/item/organ/lungs/organ, mob/living/surgeon, obj/item/tool, list/operation_args)
	var/datum/quirk/item_quirk/asthma/asthma = organ.owner.get_quirk(/datum/quirk/item_quirk/asthma)
	if(isnull(asthma))
		return

	display_results(
		surgeon,
		organ.owner,
		span_notice("You stretch [organ.owner]'s windpipe with [tool], managing to avoid the nearby blood vessels."),
		span_notice("[surgeon] succeeds at stretching [organ.owner]'s windpipe with [tool], avoiding the nearby blood vessels."),
		span_notice("[surgeon] finishes stretching [organ.owner]'s windpipe.")
	)
	//show_radial_menu(surgeon, organ.owner, src) XANTODO Make it a radial menu defuse game when you complete the surgery

/datum/surgery_operation/organ/bomb_defusal/on_failure(obj/item/organ/lungs/organ, mob/living/surgeon, obj/item/tool, list/operation_args)
	var/datum/quirk/item_quirk/asthma/asthma = organ.owner.get_quirk(/datum/quirk/item_quirk/asthma)
	if(isnull(asthma))
		return

	display_results(
		surgeon,
		organ.owner,
		span_warning("You stretch [organ.owner]'s windpipe with [tool], but accidentally clip a few arteries!"),
		span_warning("[surgeon] succeeds at stretching [organ.owner]'s windpipe with [tool], but accidentally clips a few arteries!"),
		span_warning("[surgeon] finishes stretching [organ.owner]'s windpipe, but screws up!"),
	)

	organ.owner.losebreath++

	if(prob(30))
		organ.owner.cause_wound_of_type_and_severity(WOUND_SLASH, organ.bodypart_owner, WOUND_SEVERITY_MODERATE, WOUND_SEVERITY_CRITICAL, WOUND_PICK_LOWEST_SEVERITY, tool)
	organ.bodypart_owner.receive_damage(brute = 10, wound_bonus = tool.wound_bonus, sharpness = SHARP_EDGED, damage_source = tool)

