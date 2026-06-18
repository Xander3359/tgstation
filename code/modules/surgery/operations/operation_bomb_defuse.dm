/datum/surgery_operation/limb/contractor_bomb_defusal
	name = "prepare for bomb defusal"
	desc = "Get ready for a fun time." // ANNETODO
	operation_flags = OPERATION_NOTABLE
	implements = list(
		TOOL_HEMOSTAT = 2.25,
		TOOL_WIRECUTTER = 0.25,
		/obj/item/kitchen/fork = 0.01,
	)
	time = 8 SECONDS
	preop_sound = 'sound/items/handling/surgery/retractor1.ogg'
	success_sound = 'sound/items/handling/surgery/retractor2.ogg'
	all_surgery_states_required = SURGERY_SKIN_OPEN|SURGERY_ORGANS_CUT

/datum/surgery_operation/limb/contractor_bomb_defusal/get_default_radial_image()
	return image(icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bomb.dmi', icon_state = "bomb_hatch_open")

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

	display_results(
		surgeon,
		limb.owner,
		span_notice("You begin to mess around with the electronics within the bomb."),
		span_notice("[surgeon] begins to mess with the wires inside the bomb, opening the hatch to get better access."),
		span_notice("[surgeon] begins to mess with the wires trapped inside the bomb."),
	)
	bomb.perform_defusal(surgeon)
