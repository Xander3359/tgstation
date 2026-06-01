/datum/dialogue_sound
	/// The sound file path to play.
	var/sound_path
	/// Volume for playback.
	var/volume = 50
	var/vary = FALSE
	/// Assigned by the owning dialogue component instance.
	var/channel = 0
	/// Volume preference for dialogue lines.
	var/datum/preference/numeric/volume/volume_preference = /datum/preference/numeric/volume/sound_dialogue
	/// Multiplier on sound length to determine line cooldown.
	var/length_multiplier = 1.5
	/// Flat delay added after the length-based cooldown.
	var/bonus_delay = 2 SECONDS
	/// Cached line length from rust-g/SSsounds.
	var/cached_sound_length = 1 SECONDS
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

	var/sound_len = SSsounds.get_sound_length(sound_path)
	if(!sound_len)
		stack_trace("dialogue_sound failed to get sound length for [sound_path]. Falling back to 1 second.")
	else
		cached_sound_length = sound_len

/datum/dialogue_sound/proc/delayed_play(mob/player, atom/location, delay)
	addtimer(CALLBACK(src, PROC_REF(play), player, location), delay, TIMER_UNIQUE)

/datum/dialogue_sound/proc/get_sound_length()
	return cached_sound_length

/datum/dialogue_sound/proc/mark_cooldown()
	COOLDOWN_START(src, line_cooldown, max(round((cached_sound_length * length_multiplier) + bonus_delay, 1), 1))

/datum/dialogue_sound/proc/can_play(mob/player, atom/location)
	if(!location)
		return FALSE
	if(!COOLDOWN_FINISHED(src, line_cooldown))
		return FALSE
	return TRUE

/datum/dialogue_sound/proc/prepare_playback(mob/player)
	if(player && channel)
		player.stop_sound_channel(channel)

/datum/dialogue_sound/proc/emit_sound(mob/player, atom/location)
	playsound(location, sound_path, volume, vary, channel = channel, volume_preference = volume_preference)

/datum/dialogue_sound/local/can_play(mob/player, atom/location)
	if(!player)
		return FALSE
	return ..()

/datum/dialogue_sound/local/emit_sound(mob/player, atom/location)
	player.playsound_local(location, sound_path, volume, vary, channel = channel, volume_preference = volume_preference)

/datum/dialogue_sound/proc/play(mob/player, atom/location)
	if(!can_play(player, location))
		return FALSE
	prepare_playback(player)
	emit_sound(player, location)
	mark_cooldown()
	return TRUE

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

/datum/component/dialogue_system/RegisterWithParent()
	if(length(pickup_sounds))
		RegisterSignal(parent, COMSIG_ITEM_PICKUP, PROC_REF(on_pickup))
	if(length(dropped_sounds))
		RegisterSignal(parent, COMSIG_ITEM_DROPPED, PROC_REF(on_dropped))

/datum/component/dialogue_system/UnregisterFromParent()
	UnregisterSignal(parent, list(COMSIG_ITEM_PICKUP, COMSIG_ITEM_DROPPED))

/datum/component/dialogue_system/proc/on_pickup(obj/item/source, mob/taker)
	SIGNAL_HANDLER

	if(length(pickup_sounds))
		var/datum/dialogue_sound/sound = pick(pickup_sounds)
		sound.play(taker, get_turf(taker))

/datum/component/dialogue_system/proc/on_dropped(obj/item/source, mob/user)
	SIGNAL_HANDLER

	if(length(dropped_sounds))
		var/datum/dialogue_sound/sound = pick(dropped_sounds)
		sound.play(user, get_turf(user))

/// Raijin Horizon Gauss Rifle dialogue component.
/datum/component/dialogue_system/contractor_gun
	dupe_mode = COMPONENT_DUPE_UNIQUE
	/// Job-title keyed kidnapped sound pools (e.g. JOB_HEAD_OF_PERSONNEL => list(...)).
	var/list/kidnapped_sounds_by_rank
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

/datum/component/dialogue_system/contractor_gun/apply_dialogue_channel()
	. = ..()
	for(var/list/sounds_for_rank as anything in kidnapped_sounds_by_rank)
		apply_channel_to_sound_list(sounds_for_rank)

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
	if(!length(sounds_for_rank))
		return

	var/datum/dialogue_sound/sound = pick(sounds_for_rank)
	sound.delayed_play(victim, get_turf(victim), 3 SECONDS)
