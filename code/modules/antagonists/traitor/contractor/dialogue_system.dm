/datum/dialogue_sound
	/// The sound file path to play.
	var/sound_path
	/// Volume for playback.
	var/volume = 50
	var/vary = FALSE
	/// Assigned by the owning dialogue component instance.
	var/channel = 0
	/// Estimated end time for the currently playing line on each dialogue channel.
	var/static/list/channel_busy_until = list()
	/// Volume preference for dialogue lines.
	var/datum/preference/numeric/volume/volume_preference = /datum/preference/numeric/volume/sound_dialogue
	/// Multiplier on sound length to determine line cooldown.
	var/length_multiplier = 1.5
	/// Flat delay added after the length-based cooldown.
	var/bonus_delay = 0
	COOLDOWN_DECLARE(line_cooldown)

/// Plays sound only to the specified player.
/datum/dialogue_sound/local

/datum/dialogue_sound/short
	length_multiplier = 1
	bonus_delay = 0

/datum/dialogue_sound/long
	length_multiplier = 1.3
	bonus_delay = 5

/datum/dialogue_sound/local/short
	length_multiplier = 1
	bonus_delay = 0

/datum/dialogue_sound/local/long
	length_multiplier = 1.3
	bonus_delay = 5

/datum/dialogue_sound/New(sound_path, volume, vary)
	. = ..()
	if(!sound_path)
		CRASH("Must provide a sound path to dialogue sound!")
	src.sound_path = sound_path
	if(!isnull(volume))
		src.volume = volume
	if(!isnull(vary))
		src.vary = vary

/datum/dialogue_sound/proc/delayed_play(mob/player, atom/location, delay)
	addtimer(CALLBACK(src, PROC_REF(play), player, location), delay, TIMER_UNIQUE)

/datum/dialogue_sound/proc/get_sound_length()
	return SSsounds.get_sound_length(sound_path)

/datum/dialogue_sound/proc/mark_cooldown()
	COOLDOWN_START(src, line_cooldown, max(round((get_sound_length() * length_multiplier) + bonus_delay, 1), 1))

/datum/dialogue_sound/proc/can_play(mob/player, atom/location)
	if(!location)
		return FALSE
	if(!COOLDOWN_FINISHED(src, line_cooldown))
		return FALSE
	return TRUE

/datum/dialogue_sound/proc/prepare_playback(mob/player)
	if(player && channel)
		player.stop_sound_channel(channel)

/datum/dialogue_sound/proc/is_channel_busy()
	if(!channel)
		return FALSE
	return world.time < (channel_busy_until["[channel]"] || 0)

/datum/dialogue_sound/proc/mark_channel_busy()
	if(!channel)
		return
	channel_busy_until["[channel]"] = world.time + get_sound_length()

/datum/dialogue_sound/proc/debug_to_chat(mob/player, message, is_warning = FALSE)
#ifdef TESTING
	if(!player)
		return
	if(is_warning)
		to_chat(player, span_warning(message))
	else
		to_chat(player, span_notice(message))
#endif

/datum/dialogue_sound/proc/fade_interrupting_line(mob/player)
	if(!player || !channel)
		return 0

	var/fade_duration = 1 SECONDS
	debug_to_chat(player, "[src]: fade start on channel [channel], duration [fade_duration] ticks.")
	var/fade_steps = 5
	var/step_delay = max(round(fade_duration / fade_steps, 1), 1)
	for(var/step in 1 to fade_steps)
		var/step_volume = round(volume * (1 - (step / fade_steps)), 1)
		addtimer(CALLBACK(player, TYPE_PROC_REF(/mob, set_sound_channel_volume), channel, step_volume), step * step_delay)

	addtimer(CALLBACK(player, TYPE_PROC_REF(/mob, stop_sound_channel), channel), fade_duration)
	debug_to_chat(player, "[src]: stop queued for channel [channel] at +[fade_duration] ticks.")
	return fade_duration

/datum/dialogue_sound/proc/play_after_fade(mob/player, atom/location)
	debug_to_chat(player, "[src]: play_after_fade fired on channel [channel] at world.time=[world.time].")
	if(!can_play(player, location))
		debug_to_chat(player, "[src]: play_after_fade aborted (can_play returned FALSE).", TRUE)
		return FALSE
	return execute_playback(player, location)

/datum/dialogue_sound/proc/emit_sound(mob/player, atom/location)
	playsound(location, sound_path, volume, vary, channel = channel, volume_preference = volume_preference)

/datum/dialogue_sound/local/can_play(mob/player, atom/location)
	if(!player)
		return FALSE
	return ..()

/datum/dialogue_sound/local/emit_sound(mob/player, atom/location)
	player.playsound_local(location, sound_path, volume, vary, channel = channel, volume_preference = volume_preference)

/datum/dialogue_sound/proc/execute_playback(mob/player, atom/location, should_prepare = TRUE)
	if(should_prepare)
		prepare_playback(player)
	emit_sound(player, location)
	mark_cooldown()
	mark_channel_busy()
	return TRUE

/datum/dialogue_sound/proc/play(mob/player, atom/location)
	if(!can_play(player, location))
		debug_to_chat(player, "[src]: play aborted (can_play returned FALSE).", TRUE)
		return FALSE
	if(is_channel_busy())
		var/fade_duration = fade_interrupting_line(player)
		if(!fade_duration)
			fade_duration = 1 SECONDS
		debug_to_chat(player, "[src]: channel busy, scheduling play_after_fade in [fade_duration + 1] ticks.")
		addtimer(CALLBACK(src, PROC_REF(play_after_fade), player, location), fade_duration + 1, TIMER_UNIQUE)
		return TRUE
	debug_to_chat(player, "[src]: channel free, executing playback now.")
	return execute_playback(player, location)

/datum/component/dialogue_system
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Last channel candidate used when allocating dialogue channels.
	var/static/next_dialogue_channel = CHANNEL_HIGHEST_AVAILABLE
	/// Tracks channels currently allocated by active dialogue systems.
	var/static/list/allocated_dialogue_channels = list()
	/// Unique channel for this dialogue system instance.
	var/dialogue_channel
	/// Sounds played when the parent is picked up.
	var/list/pickup_sounds
	/// Sounds played when the parent is dropped.
	var/list/dropped_sounds

/datum/component/dialogue_system/Initialize()
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	setup_sound_lists()
	dialogue_channel = allocate_dialogue_channel()
	apply_dialogue_channel()

/datum/component/dialogue_system/Destroy(force)
	release_dialogue_channel()
	return ..()

/datum/component/dialogue_system/proc/setup_sound_lists()
	pickup_sounds = list()
	dropped_sounds = list()

/datum/component/dialogue_system/proc/allocate_dialogue_channel()
	var/start_channel = next_dialogue_channel
	while(next_dialogue_channel in allocated_dialogue_channels)
		next_dialogue_channel--
		if(next_dialogue_channel < 1)
			next_dialogue_channel = CHANNEL_HIGHEST_AVAILABLE
		if(next_dialogue_channel == start_channel)
			CRASH("No free sound channels available for dialogue_system.")

	var/chosen_channel = next_dialogue_channel
	allocated_dialogue_channels += chosen_channel
	next_dialogue_channel--
	if(next_dialogue_channel < 1)
		next_dialogue_channel = CHANNEL_HIGHEST_AVAILABLE
	return chosen_channel

/datum/component/dialogue_system/proc/release_dialogue_channel()
	if(dialogue_channel)
		allocated_dialogue_channels -= dialogue_channel
	dialogue_channel = null

/datum/component/dialogue_system/proc/apply_channel_to_sound_list(list/sounds)
	for(var/datum/dialogue_sound/sound as anything in sounds)
		sound.channel = dialogue_channel

/datum/component/dialogue_system/proc/apply_dialogue_channel()
	if(!dialogue_channel)
		return
	apply_channel_to_sound_list(pickup_sounds)
	apply_channel_to_sound_list(dropped_sounds)

/datum/component/dialogue_system/proc/get_available_sounds(list/source_sounds, mob/player, atom/location)
	. = list()
	for(var/datum/dialogue_sound/sound as anything in source_sounds)
		if(sound.can_play(player, location))
			. += sound

/datum/component/dialogue_system/RegisterWithParent()
	if(length(pickup_sounds))
		RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(on_pickup))
	if(length(dropped_sounds))
		RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))

/datum/component/dialogue_system/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ITEM_PICKUP, COMSIG_ITEM_DROPPED))

/datum/component/dialogue_system/proc/on_pickup(obj/item/source, mob/taker)
	SIGNAL_HANDLER

	var/datum/dialogue_sound/sound = pick(get_available_sounds(pickup_sounds, taker, parent))
	sound?.play(taker, parent)

/datum/component/dialogue_system/proc/on_dropped(obj/item/source, mob/user)
	SIGNAL_HANDLER

	var/datum/dialogue_sound/sound = pick(get_available_sounds(dropped_sounds, user, parent))
	sound?.play(user, parent)

/// Raijin Horizon Gauss Rifle dialogue component.
/datum/component/dialogue_system/contractor_gun
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Job-title keyed kidnapped sound pools (e.g. JOB_HEAD_OF_PERSONNEL => list(...)).
	var/list/kidnapped_sounds_by_rank
	/// Ammo-casing-type keyed mode swap sound pools.
	var/list/mode_swap_sounds_by_ammo_type
	/// Weakref to the mob currently holding the parent, used to register/unregister kidnap signals.
	var/datum/weakref/current_holder_ref

/datum/component/dialogue_system/contractor_gun/setup_sound_lists()
	. = ..()
	pickup_sounds = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_4.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_pickup/on_pickup_5.ogg'),
	)
	dropped_sounds = list(
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_1.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_2.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_3.ogg'),
		new /datum/dialogue_sound('sound/items/weapons/contractor_gun/on_dropped/on_dropped_4.ogg'),
	)
	kidnapped_sounds_by_rank = list(
		JOB_HEAD_OF_PERSONNEL = list(
			new /datum/dialogue_sound/local('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_1.ogg'),
			new /datum/dialogue_sound/local('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_2.ogg'),
			new /datum/dialogue_sound/local('sound/items/weapons/contractor_gun/kidnapped/hop/kidnapped_3.ogg'),
		),
	)
	mode_swap_sounds_by_ammo_type = list(
		/obj/item/ammo_casing/energy/gauss = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/Mode Swap Normal 1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/Mode Swap Normal 1_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/Mode Swap Normal 1_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/Mode Swap Normal 2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/Mode Swap Normal 3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_normal/Mode Swap Normal 4_take1.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/emp = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/Mode Swap EMP 1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/Mode Swap EMP 2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/Mode Swap EMP 3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/Mode Swap EMP 3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/Mode Swap EMP 4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_emp/Mode Swap EMP 4_take2.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/gyro = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/Mode Swap Gyre 1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/Mode Swap Gyre 2_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/Mode Swap Gyre 3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/Mode Swap Gyre 4_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_gyre/Mode Swap Gyre 4_take2.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/antimatter = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/Mode Swap Anti 1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/Mode Swap Anti 2_take4.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/Mode Swap Anti 4_take3.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/Mode Swap Anti 4_take4.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_anti/Mode Swap Anti 4_take5.ogg'),
		),
		/obj/item/ammo_casing/energy/gauss/thermite = list(
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/Mode Swap Thermal 1_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/Mode Swap Thermal 2_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/Mode Swap Thermal 3_take1.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/Mode Swap Thermal 3_take2.ogg'),
			new /datum/dialogue_sound('sound/items/weapons/contractor_gun/mode_swap_thermal/Mode Swap Thermal 4_take2.ogg'),
		),
	)

/datum/component/dialogue_system/contractor_gun/apply_dialogue_channel()
	. = ..()
	for(var/list/sounds_for_rank as anything in kidnapped_sounds_by_rank)
		apply_channel_to_sound_list(sounds_for_rank)
	for(var/list/sounds_for_mode as anything in mode_swap_sounds_by_ammo_type)
		apply_channel_to_sound_list(sounds_for_mode)

/datum/component/dialogue_system/contractor_gun/RegisterWithParent()
	. = ..()
	RegisterSignal(parent, COMSIG_GAUSS_RIFLE_MODE_CHANGED, PROC_REF(on_mode_changed))

/datum/component/dialogue_system/contractor_gun/Destroy(force)
	_unregister_holder()
	return ..()

/datum/component/dialogue_system/contractor_gun/proc/_unregister_holder()
	var/mob/prev_holder = current_holder_ref?.resolve()
	if(prev_holder)
		UnregisterSignal(prev_holder, COMSIG_CONTRACTOR_KIDNAPPED)
	current_holder_ref = null

/datum/component/dialogue_system/contractor_gun/UnregisterFromParent()
	_unregister_holder()
	UnregisterSignal(parent, COMSIG_GAUSS_RIFLE_MODE_CHANGED)
	return ..()

/datum/component/dialogue_system/contractor_gun/on_pickup(obj/item/source, mob/taker)
	_unregister_holder()
	current_holder_ref = WEAKREF(taker)
	RegisterSignal(taker, COMSIG_CONTRACTOR_KIDNAPPED, PROC_REF(on_kidnapped))
	return ..()

/datum/component/dialogue_system/contractor_gun/on_dropped(obj/item/source, mob/user)
	_unregister_holder()
	return ..()

/// Called when the contractor successfully kidnaps a target.
/datum/component/dialogue_system/contractor_gun/proc/on_kidnapped(mob/source, mob/living/victim)
	SIGNAL_HANDLER

	var/victim_rank = victim?.mind?.assigned_role?.title
	var/list/sounds_for_rank = kidnapped_sounds_by_rank?[victim_rank]
	var/datum/dialogue_sound/sound = pick(get_available_sounds(sounds_for_rank, victim, parent))
	sound?.delayed_play(victim, parent, 3 SECONDS)

/datum/component/dialogue_system/contractor_gun/proc/on_mode_changed(obj/item/gun/energy/gauss_rifle/source, mob/living/user, obj/item/ammo_casing/energy/new_mode)
	SIGNAL_HANDLER

	var/list/sounds_for_mode = mode_swap_sounds_by_ammo_type?[new_mode.type]
	var/datum/dialogue_sound/sound = pick(get_available_sounds(sounds_for_mode, user, parent))
	sound?.play(user, parent)
