

/obj/item/organ/contractor_bomb
	name = "ANNETODO"
	desc = "ANNETODO"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_bomb.dmi'
	icon_state = "bomb"
	organ_flags = ORGAN_ORGANIC | ORGAN_UNREMOVABLE
	/// What the charge is stuck to
	var/atom/target = null
	///How long it takes for a grenade to explode after being armed
	var/det_time = 5 SECONDS
	/// C4 overlay to put on target
	var/mutable_appearance/plastic_overlay

/obj/item/organ/contractor_bomb/Initialize(mapload)
	. = ..()
	plastic_overlay = mutable_appearance(icon, "Mob bombactivated", HIGH_OBJ_LAYER)

/obj/item/organ/contractor_bomb/interact_with_atom(atom/interacting_with, mob/living/user, list/modifiers)
	// Here lies C4 ghosts. We hardly knew ye
	if(isdead(interacting_with))
		return NONE
	return plant_c4(interacting_with, user) ? ITEM_INTERACT_SUCCESS : ITEM_INTERACT_BLOCKING

/obj/item/organ/contractor_bomb/proc/plant_c4(atom/bomb_target, mob/living/user)
	if(bomb_target != user && HAS_TRAIT(user, TRAIT_PACIFISM) && isliving(bomb_target))
		to_chat(user, span_warning("You don't want to harm other living beings!"))
		return FALSE

	to_chat(user, span_notice("You start planting [src]. The timer is set to [det_time]..."))

	if(!do_after(user, 3 SECONDS, target = bomb_target))
		return FALSE
	if(!user.temporarilyRemoveItemFromInventory(src))
		return FALSE
	target = bomb_target
	//active = TRUE

	message_admins("[ADMIN_LOOKUPFLW(user)] planted [name] on [target.name] at [ADMIN_VERBOSEJMP(target)] with [det_time] second fuse")
	user.log_message("planted [name] on [target.name] with a [det_time] second fuse.", LOG_ATTACK)
	var/icon/target_icon = icon(bomb_target.icon, bomb_target.icon_state)
	target_icon.Blend(icon(icon, icon_state), ICON_OVERLAY)
	var/mutable_appearance/bomb_target_image = mutable_appearance(target_icon)
	notify_ghosts(
		"[user.real_name] has planted \a [src] on [target] with a [det_time] second fuse!",
		source = bomb_target,
		header = "Explosive Planted",
		alert_overlay = bomb_target_image,
		notify_flags = NOTIFY_CATEGORY_NOFLASH,
	)

	if(isitem(bomb_target)) //your crappy throwing star can't fly so good with a giant brick of c4 on it.
		var/obj/item/thrown_weapon = bomb_target
		thrown_weapon.throw_speed = max(1, (thrown_weapon.throw_speed - 3))
		thrown_weapon.throw_range = max(1, (thrown_weapon.throw_range - 3))
		thrown_weapon.get_embed()?.embed_chance = 0
	else if(isliving(bomb_target))
		Insert(bomb_target)
		plastic_overlay.layer = FLOAT_LAYER

	target.add_overlay(plastic_overlay)
	to_chat(user, span_notice("You plant the bomb. Timer counting down from [det_time]."))
	//addtimer(CALLBACK(src, PROC_REF(detonate)), det_time*10)
	return TRUE




























