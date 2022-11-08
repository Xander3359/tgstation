// Default values for blood cult spells
/datum/action/cooldown/spell/touch/blood_cult_spell
	name = "Generic Name" // Name of the spell
	desc = "Generic Description" // Description of the spell itself
	icon_icon = 'icons/mob/actions/actions_cult.dmi'
	background_icon_state = "bg_demon"
	buttontooltipstyle = "cult"
	// Icon of the spell
	button_icon_state = "carve"
	school = SCHOOL_EVOCATION
	// If we want the spell to have a cooldown, set to anything but 0
	cooldown_time = 0 SECONDS
	// What the cultist says when they cast the spell
	invocation = "Hello"
	// Allows being able to cast the spell without saying anything.
	invocation_type = INVOCATION_WHISPER
	// Mimes can cast it. Chaplains can cast it. Anyone can cast it, so long as they have a hand. (This makes invocation_type only for flavor)
	spell_requirements = SPELL_CASTABLE_WITHOUT_INVOCATION
	// If this spell has a cost, how much should it cost
	var/spell_blood_cost

// BLOOD RITES //
/datum/action/cooldown/spell/touch/blood_cult_spell/rites
	name = "Blood Rites"
	desc = "Empowers your hand to absorb blood from mobs or from the floor, used to cast Blood spells."
	invocation = "Fel'th Dol Ab'orod!"
	button_icon_state = "manip"
	default_button_position = DEFAULT_BLOODSPELLS // Places it in the default spell position.
	hand_path = /obj/item/melee/touch_attack/Rites_Hand

/obj/item/melee/touch_attack/Rites_Hand
	name = "Blood Rite Aura"
	desc = "Absorbs blood from anything you touch. Touching cultists and constructs can heal them. Use in-hand to cast an advanced rite."
	inhand_icon_state = "disintegrate"
	icon = 'icons/mob/actions/actions_cult.dmi'
	icon_state = "hand"
	color = COLOR_BLOOD_RITES
	var/datum/antagonist/bloodcult/cult_datum

/obj/item/melee/touch_attack/Rites_Hand/Initialize(mapload, datum/action/cooldown/spell/spell)
	. = ..()
	cult_datum = IS_CULTIST(spell.owner)

/obj/item/melee/touch_attack/Rites_Hand/Destroy(force)
	cult_datum = null
	return ..()

// TODO : Make Blood rites heal constructs (Does it heal constructs in the old code?)
/obj/item/melee/touch_attack/Rites_Hand/afterattack(atom/target, mob/living/carbon/human/user, proximity)
	. = ..()
	if(!proximity)
		return // If you click on something that isn't in your 1-tile radius, this stops
	if(istype(target, /obj/effect/decal/cleanable/blood))
		return blood_draw(target, user) // If you click on blood on the floor, this will cast blood_draw Spell
	if(!ishuman(target))
		return // If the target you clicked on isnt a human, this stops
	var/mob/living/carbon/human/human_target = target
	if(NOBLOOD in human_target.dna.species.species_traits)
		to_chat(user,span_warning("Blood rites do not work on species with no blood!"))
		return // If the target has no usable blood level, this stops, and tells the caster why it stopped in chat
	if(IS_CULTIST(human_target))
		return heal_touch(target, user) // If the target is a cultist, this will stop and cast Heal_Touch Spell
	if(human_target.stat == DEAD) // Blood Rites can only drain living
		to_chat(user,span_warning("[human_target.p_their(TRUE)] blood has stopped flowing, you'll have to find another way to extract it."))
		return
	if(human_target.blood_volume <= BLOOD_VOLUME_SAFE) // Blood Rites can only drain if they have enough blood
		to_chat(user, span_warning("[human_target.p_theyre(TRUE)] missing too much blood - you cannot drain [human_target.p_them()] further!"))
		return
	// After all the checks, this will drain the blood of the target to give blood rites charges
	to_chat(user, span_cultitalic("Your blood rite gains 50 charges from draining [human_target]'s blood."))
	human_target.blood_volume -= 100
	cult_datum.adjust_stored_blood(50)
	user.Beam(human_target, icon_state= "drainbeam", time = 1 SECONDS)
	playsound(get_turf(human_target), 'sound/magic/enter_blood.ogg', 50)
	human_target.visible_message(span_danger("[user] drains some of [human_target]'s blood!"))
	new /obj/effect/temp_visual/cult/sparks(get_turf(human_target))

/obj/item/melee/touch_attack/Rites_Hand/proc/blood_draw(atom/target, mob/living/carbon/human/user)
	var/temp = 0
	var/turf/T = get_turf(target)
	if(T)
		for(var/obj/effect/decal/cleanable/blood/B in view(T, 2))
			if(B.blood_state == BLOOD_STATE_HUMAN)
				if(B.bloodiness == 100) //Bonus for "pristine" bloodpools, also to prevent cheese with footprint spam
					temp += 30
				else
					temp += max((B.bloodiness**2)/800,1)
				new /obj/effect/temp_visual/cult/turf/floor(get_turf(B))
				qdel(B)
		for(var/obj/effect/decal/cleanable/trail_holder/TH in view(T, 2))
			qdel(TH)
		if(temp)
			user.Beam(T,icon_state="drainbeam", time = 15)
			new /obj/effect/temp_visual/cult/sparks(get_turf(user))
			playsound(T, 'sound/magic/enter_blood.ogg', 50)
			to_chat(user, span_cultitalic("Your blood rite has gained [round(temp)] charge\s from blood sources around you!"))
			cult_datum.adjust_stored_blood(max(1, round(temp)))

/obj/item/melee/touch_attack/Rites_Hand/proc/heal_touch(atom/target, mob/living/carbon/human/user)
	var/mob/living/carbon/human/human_target = target
	if(human_target.stat == DEAD)
		to_chat(user,span_warning("Blood rites do not work on species with no blood!"))
		return
	// Restoring Blood to cultists that are under the safe threshold
	if(human_target.blood_volume < BLOOD_VOLUME_SAFE)
		var/blood_restored = BLOOD_VOLUME_SAFE - human_target.blood_volume
		if(cult_datum.stored_blood*2 < blood_restored)
			human_target.blood_volume += cult_datum.stored_blood*2
			to_chat(user,span_danger("You use the last of your blood rites to restore what blood you could!"))
			cult_datum.adjust_stored_blood(-cult_datum.stored_blood)
			return
		else
			human_target.blood_volume = BLOOD_VOLUME_SAFE
			cult_datum.adjust_stored_blood(-round(blood_restored/2))
			to_chat(user,span_warning("Your blood rites have restored [human_target == user ? "your" : "[human_target.p_their()]"] blood to safe levels!"))
	// Healing Cultists that have damage dealt to them
	var/total_damage = human_target.getBruteLoss() + human_target.getFireLoss() + human_target.getToxLoss() + human_target.getOxyLoss()
	if(total_damage == 0)
		to_chat(user,span_cult("That cultist doesn't require healing!"))
	if(human_target.stat == DEAD)
		to_chat(user,span_warning("Only a revive rune can bring back the dead!"))
		return
	else
		var/ratio = cult_datum.stored_blood/total_damage
		if(human_target == user)
			to_chat(user,span_cult("<b>Your blood healing is far less efficient when used on yourself!</b>"))
			ratio *= 0.35 // Healing is half as effective if you can't perform a full heal
			cult_datum.adjust_stored_blood(-round(total_damage)) // Healing is 65% more "expensive" even if you can still perform the full heal
		if(ratio > 1)
			ratio = 1
			cult_datum.adjust_stored_blood(-round(total_damage))
			human_target.visible_message(span_warning("[human_target] is fully healed by [human_target==user ? "[human_target.p_their()]":"[human_target]'s"] blood magic!"))
		else
			human_target.visible_message(span_warning("[human_target] is partially healed by [human_target==user ? "[human_target.p_their()]":"[human_target]'s"] blood magic."))
			cult_datum.adjust_stored_blood(-cult_datum.stored_blood)
		ratio *= -1
		human_target.adjustOxyLoss((total_damage*ratio) * (human_target.getOxyLoss() / total_damage), 0)
		human_target.adjustToxLoss((total_damage*ratio) * (human_target.getToxLoss() / total_damage), 0)
		human_target.adjustFireLoss((total_damage*ratio) * (human_target.getFireLoss() / total_damage), 0)
		human_target.adjustBruteLoss((total_damage*ratio) * (human_target.getBruteLoss() / total_damage), 0)
		human_target.updatehealth()
		playsound(get_turf(human_target), 'sound/magic/staff_healing.ogg', 25)
		new /obj/effect/temp_visual/cult/sparks(get_turf(human_target))
		user.Beam(human_target, icon_state="sendbeam", time = 15)

/obj/item/melee/touch_attack/Rites_Hand/attack_self(mob/user, modifiers)
	if(SEND_SIGNAL(src, COMSIG_ITEM_ATTACK_SELF, user) & COMPONENT_CANCEL_ATTACK_CHAIN)
		return TRUE
	interact(user)
	var/static/list/spells = list(
		"Ritual Knife (30)" = image(icon = 'icons/obj/cult/items_and_weapons.dmi', icon_state = "render"),
		"Bloody Halberd (150)" = image(icon = 'icons/obj/cult/items_and_weapons.dmi', icon_state = "occultpoleaxe0"),
		"Blood Bolt Barrage (300)" = image(icon = 'icons/obj/weapons/guns/ballistic.dmi', icon_state = "arcane_barrage"),
		"Blood Beam (500)" = image(icon = 'icons/obj/weapons/items_and_weapons.dmi', icon_state = "disintegrate"),
		"Eldritch Longsword (300)" = image(icon = 'icons/obj/cult/items_and_weapons.dmi', icon_state = "cultblade")
		)
	var/choice = show_radial_menu(user, src, spells, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE)
	if(!check_menu(user))
		to_chat(user, span_cultitalic("You decide against conducting a greater blood rite."))
		return
	switch(choice)
		if("Ritual Knife (30)")
			if(cult_datum.stored_blood < BLOOD_DAGGER_COST)
				to_chat(user, span_cultitalic("You need [BLOOD_DAGGER_COST] charges to perform this rite."))
			else
				cult_datum.adjust_stored_blood(-BLOOD_DAGGER_COST)
				qdel(src)
				var/obj/item/melee/cultblade/dagger/new_dagger = new(src)
				user.put_in_hand(new_dagger)
				if(user.put_in_hands(new_dagger))
					to_chat(user, span_cultitalic("A [new_dagger.name] appears in your hand!"))
		if("Eldritch Longsword (300)")
			if(cult_datum.stored_blood < ELDRITCH_LONGSWORD_COST)
				to_chat(user, span_cultitalic("You need [ELDRITCH_LONGSWORD_COST] charges to perform this rite."))
			else
				cult_datum.adjust_stored_blood(-ELDRITCH_LONGSWORD_COST)
				qdel(src)
				var/obj/item/melee/cultblade/sword/new_sword = new(src)
				user.put_in_hand(new_sword)
				if(user.put_in_hands(new_sword))
					to_chat(user, span_cultitalic("A [new_sword.name] appears in your hand!"))
		if("Bloody Halberd (150)")
			if(cult_datum.stored_blood < BLOOD_HALBERD_COST)
				to_chat(user, span_cultitalic("You need [BLOOD_HALBERD_COST] charges to perform this rite."))
			else
				cult_datum.adjust_stored_blood(-BLOOD_HALBERD_COST)
				var/turf/current_position = get_turf(user)
				qdel(src)
				var/datum/action/innate/blood_cult/halberd/halberd_act_granted = new(user)
				var/obj/item/melee/cultblade/halberd/rite = new(current_position)
				halberd_act_granted.Grant(user, rite)
				rite.halberd_act = halberd_act_granted
				if(user.put_in_hands(rite))
					to_chat(user, span_cultitalic("A [rite.name] appears in your hand!"))
				else
					user.visible_message(span_warning("A [rite.name] appears at [user]'s feet!"), \
						span_cultitalic("A [rite.name] materializes at your feet."))
		if("Blood Bolt Barrage (300)")
			if(cult_datum.stored_blood < BLOOD_BARRAGE_COST)
				to_chat(user, span_cultitalic("You need [BLOOD_BARRAGE_COST] charges to perform this rite."))
			else
				var/obj/rite = new /obj/item/gun/ballistic/rifle/enchanted/arcane_barrage/blood()
				cult_datum.adjust_stored_blood(-BLOOD_BARRAGE_COST)
				qdel(src)
				if(user.put_in_hands(rite))
					to_chat(user, span_cult("<b>Your hands glow with power!</b>"))
				else
					to_chat(user, span_cultitalic("You need a free hand for this rite!"))
					qdel(rite)
		if("Blood Beam (500)")
			if(cult_datum.stored_blood < BLOOD_BEAM_COST)
				to_chat(user, span_cultitalic("You need [BLOOD_BEAM_COST] charges to perform this rite."))
			else
				var/obj/rite = new /obj/item/blood_beam()
				cult_datum.adjust_stored_blood(-BLOOD_BEAM_COST)
				qdel(src)
				if(user.put_in_hands(rite))
					to_chat(user, span_cultlarge("<b>Your hands glow with POWER OVERWHELMING!!!</b>"))
				else
					to_chat(user, span_cultitalic("You need a free hand for this rite!"))
					qdel(rite)

/obj/item/melee/touch_attack/Rites_Hand/proc/check_menu(mob/living/user)
	if(!istype(user))
		CRASH("The Blood Rites manipulator radial menu was accessed by something other than a valid user.")
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

// STUN SPELL //
/datum/action/cooldown/spell/touch/blood_cult_spell/stun
	name = "Stun" // Name of the spell
	desc = "Will stun and mute a weak-minded victim on contact." // Description of the spell itself
	button_icon_state = "carve"
	invocation = "Fuu ma'jin!"
	// If we want the spell to have a cooldown, set to anything but 0
	cooldown_time = 0 SECONDS
	spell_blood_cost = 30
	default_button_position = "6:10,4:-2"
	hand_path = /obj/item/melee/touch_attack/Stun_Hand

/datum/action/cooldown/spell/touch/blood_cult_spell/stun/can_cast_spell(feedback = TRUE)
	var/datum/antagonist/bloodcult/cult_datum = IS_CULTIST(owner)
	if(cult_datum.stored_blood < spell_blood_cost)
		if(feedback)
			to_chat(owner, span_warning("You need least [spell_blood_cost] unit\s of blood to cast this!"))
		return FALSE
	return ..() && !!IS_CULTIST(owner)

/obj/item/melee/touch_attack/Stun_Hand
	name = "Stunning Aura"
	desc = "Will stun and mute a weak-minded victim on contact."
	color = RUNE_COLOR_RED
	inhand_icon_state = "disintegrate"
	icon = 'icons/mob/actions/actions_cult.dmi'
	icon_state = "hand"
	var/datum/antagonist/bloodcult/cult_datum

/datum/action/cooldown/spell/touch/blood_cult_spell/stun/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	var/datum/antagonist/bloodcult/cult_datum = IS_CULTIST(owner)
	if(!ishuman(victim))
		return FALSE
	var/mob/living/carbon/human/human_target = victim
	if(IS_CULTIST(human_target) || human_target.stat == DEAD)
		return FALSE
	if(human_target.can_block_magic(antimagic_flags))
		victim.visible_message(
			span_danger("The spell bounces off of [victim]!"),
			span_danger("The spell bounces off of you!"),
		)
		return FALSE
	if(HAS_TRAIT(human_target, TRAIT_MINDSHIELD))
		victim.visible_message(
			span_danger("[victim]\s mind is too strong to be affected."),
			span_danger("Your mindshield repels the spell."),
		)
		return FALSE
	if(IS_CULTIST(caster))
		caster.visible_message(span_warning("[caster] holds up [caster.p_their()] hand, which explodes in a flash of red light!"), \
		span_cultitalic("You attempt to stun [human_target] with the spell!"))
		var/mob/living/living_user = caster
		living_user.mob_light(_range = 3, _color = LIGHT_COLOR_BLOOD_MAGIC, _duration = 0.2 SECONDS)
	if(IS_HERETIC(human_target))
		to_chat(caster, span_warning("Some force greater than you intervenes! [human_target] is protected by the Forgotten Gods!"))
		to_chat(human_target, span_warning("You are protected by your faith to the Forgotten Gods."))
		var/old_color = human_target.color
		human_target.color = rgb(0, 128, 0)
		animate(human_target, color = old_color, time = 1 SECONDS, easing = EASE_IN)
	else
		to_chat(caster, span_cultitalic("In a brilliant flash of red, [human_target] falls to the ground!"))
		human_target.Paralyze(16 SECONDS)
		human_target.flash_act(1, TRUE)
		if(issilicon(human_target))
			var/mob/living/silicon/silicon_target = victim
			silicon_target.emp_act(EMP_HEAVY)
		else if(iscarbon(human_target))
			var/mob/living/carbon/carbon_target = victim
			carbon_target.silent += 6
			carbon_target.adjust_stutter(30 SECONDS)
			carbon_target.adjust_timed_status_effect(30 SECONDS, /datum/status_effect/speech/slurring/cult)
			carbon_target.set_jitter_if_lower(30 SECONDS)
		cult_datum.adjust_stored_blood(-spell_blood_cost)
		return TRUE

// TWISTED CONSTRUCTION
/datum/action/cooldown/spell/touch/blood_cult_spell/twist
	name = "Twisted Construction"
	desc = "Can turn airlocks into cult airlocks and plasteel into runed metal." // Description of the spell itself
	button_icon_state = "transmute"
	invocation = "Ethra p'ni dedol!"
	// If we want the spell to have a cooldown, set to anything but 0
	cooldown_time = 0 SECONDS
	spell_blood_cost = 50
	default_button_position = "6:42,4:-2"
	hand_path = /obj/item/melee/touch_attack/Twist_Hand
	var/datum/antagonist/bloodcult/cult_datum

/datum/action/cooldown/spell/touch/blood_cult_spell/twist/can_cast_spell(feedback = TRUE)
	var/datum/antagonist/bloodcult/cult_datum = IS_CULTIST(owner)
	if(cult_datum.stored_blood < spell_blood_cost)
		if(feedback)
			to_chat(owner, span_warning("You need least [spell_blood_cost] unit\s of blood to cast this!"))
		return FALSE
	return ..() && !!IS_CULTIST(owner)

/obj/item/melee/touch_attack/Twist_Hand
	name = "Twisting Aura"
	desc = "Corrupts c ain metalic objects on contact."
	color = COLOR_BLACK
	inhand_icon_state = "disintegrate"
	icon = 'icons/mob/actions/actions_cult.dmi'
	icon_state = "hand"
	var/datum/antagonist/bloodcult/cult_datum

/datum/action/cooldown/spell/touch/blood_cult_spell/twist/cast_on_hand_hit(obj/item/melee/touch_attack/hand, atom/victim, mob/living/carbon/caster)
	var/turf/T = get_turf(victim)
	if(istype(victim, /obj/item/stack/sheet/iron))
		var/obj/item/stack/sheet/candidate = victim
		if(candidate.use(IRON_TO_CONSTRUCT_SHELL_CONVERSION))
			to_chat(caster, span_warning("A dark cloud emanates from your hand and swirls around the iron, twisting it into a construct shell!"))
			new /obj/structure/constructshell(T)
			SEND_SOUND(caster, sound('sound/effects/magic.ogg',0,1,25))
		else
			to_chat(caster, span_warning("You need [IRON_TO_CONSTRUCT_SHELL_CONVERSION] iron to produce a construct shell!"))
			return
	else if(istype(victim, /obj/item/stack/sheet/plasteel))
		var/obj/item/stack/sheet/plasteel/candidate = victim
		var/quantity = candidate.amount
		if(candidate.use(quantity))
			new /obj/item/stack/sheet/runed_metal(T,quantity)
			to_chat(caster, span_warning("A dark cloud emanates from you hand and swirls around the plasteel, twisting it into runed metal!"))
			SEND_SOUND(caster, sound('sound/effects/magic.ogg',0,1,25))
	else if(istype(victim,/mob/living/silicon/robot))
		var/mob/living/silicon/robot/candidate = victim
		if(candidate.mmi || candidate.shell)
			caster.visible_message(span_danger("A dark cloud emanates from [caster]'s hand and swirls around [candidate]!"))
			playsound(T, 'sound/machines/airlock_alien_prying.ogg', 80, TRUE)
			var/prev_color = candidate.color
			candidate.color = "black"
			if(do_after(caster, 90, candidate))
				candidate.undeploy()
				candidate.emp_act(EMP_HEAVY)
				var/construct_class = show_radial_menu(caster, src, GLOB.construct_radial_images, custom_check = CALLBACK(src, .proc/check_menu, caster), require_near = TRUE, tooltips = TRUE)
				if(!check_menu(caster))
					return
				if(QDELETED(candidate))
					return
				candidate.grab_ghost()
				caster.visible_message(span_danger("The dark cloud recedes from what was formerly [candidate], revealing a\n [construct_class]!"))
				make_new_construct_from_class(construct_class, THEME_CULT, candidate, caster, FALSE, T)
				candidate.mmi = null
				qdel(candidate)
			else
				candidate.color = prev_color
				return
		else
			to_chat(caster, span_warning("A dark cloud emanates from you hand and swirls around [candidate] - twisting it into a construct shell!"))
			new /obj/structure/constructshell(T)
			SEND_SOUND(caster, sound('sound/effects/magic.ogg',0,1,25))
			qdel(candidate)
	else if(istype(victim, /obj/machinery/door/airlock))
		playsound(T, 'sound/machines/airlockforced.ogg', 50, TRUE)
		do_sparks(5, TRUE, victim)
		if(do_after(caster, 50, victim))
			if(QDELETED(victim))
				return
			victim.narsie_act()
			caster.visible_message(span_warning("Black ribbons suddenly emanate from [caster]'s hand and cling to the airlock - twisting and corrupting it!"))
			SEND_SOUND(caster, sound('sound/effects/magic.ogg',0,1,25))
			cult_datum.adjust_stored_blood(-spell_blood_cost)
		else
			return
	else if(istype(victim,/obj/item/soulstone))
		var/obj/item/soulstone/candidate = victim
		if(candidate.corrupt())
			to_chat(caster, span_warning("You corrupt [candidate]!"))
			SEND_SOUND(caster, sound('sound/effects/magic.ogg',0,1,25))
	else
		to_chat(caster, span_warning("The spell will not work on [victim]!"))
		return
	..()


/datum/action/cooldown/spell/touch/blood_cult_spell/twist/proc/check_menu(mob/caster)
	if(!istype(caster))
		CRASH("The cult construct selection radial menu was accessed by something other than a valid caster.")
	if(caster.incapacitated() || !caster.Adjacent(src))
		return FALSE
	return TRUE

