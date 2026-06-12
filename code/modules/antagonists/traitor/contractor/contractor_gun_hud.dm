/atom/movable/screen/gauss_ammo_display
	name = "gauss ammo display"
	icon_state = "normal_hud"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_hud.dmi'
	screen_loc = ui_contractor_gun_hud
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_HUD_PLANE
	/// Current mob this display is shown for.
	var/mob/current_owner
	/// Cached number overlay so it can be replaced cleanly.
	var/mutable_appearance/shots_overlay

/atom/movable/screen/gauss_ammo_display/Destroy()
	hide_from_owner()
	return ..()

/atom/movable/screen/gauss_ammo_display/proc/on_gun_ammo_changed(obj/item/gun/energy/gauss_rifle/source, shots_left, max_shots, mode_prefix)
	SIGNAL_HANDLER
	refresh_display(shots_left, max_shots, mode_prefix)

/atom/movable/screen/gauss_ammo_display/proc/show_for(mob/new_owner)
	if(!new_owner?.client)
		return

	if(new_owner == current_owner)
		if(!(src in new_owner.client.screen))
			new_owner.client.screen += src
		return

	hide_from_owner()
	current_owner = new_owner
	current_owner.client.screen += src

/atom/movable/screen/gauss_ammo_display/proc/hide_from_owner()
	if(current_owner)
		current_owner.client?.screen -= src
	current_owner = null

/atom/movable/screen/gauss_ammo_display/proc/refresh_display(shots_left, max_shots, mode_prefix = "normal")
	icon_state = get_hud_icon_state(mode_prefix)

	if(shots_overlay)
		cut_overlay(shots_overlay)
		shots_overlay = null

	if(shots_left <= 0)
		return

	var/prefix = get_number_prefix(mode_prefix)
	var/number_state = "[prefix]_[shots_left]"
	if(!icon_exists(icon, number_state))
		var/fallback_max = max(shots_left, max_shots, 1)
		for(var/i in fallback_max to 1 step -1)
			if(icon_exists(icon, "[prefix]_[i]"))
				number_state = "[prefix]_[i]"
				break

	shots_overlay = mutable_appearance(icon, number_state)
	add_overlay(shots_overlay)

/atom/movable/screen/gauss_ammo_display/proc/get_hud_icon_state(mode_prefix)
	var/state = "[mode_prefix]_hud"
	if(icon_exists(icon, state))
		return state
	return "normal_hud"

/atom/movable/screen/gauss_ammo_display/proc/get_number_prefix(mode_prefix)
	if(icon_exists(icon, "[mode_prefix]_1"))
		return mode_prefix
	return "normal"

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss
	// Use OPAQUE mouse opacity so the catcher captures mouse events across its entire
	// bounding box. Visuals are attached via vis_contents so they don't interfere with
	// mouse hit-testing (which would cause ICON_X/ICON_Y in mouse params to be reported
	// relative to whichever visual the cursor is hovering, making the scope spaz out).
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	// Hide the catcher's own icon. MOUSE_OPACITY_OPAQUE uses the bounding box, not the
	// rendered alpha, so clicks still work. Visuals override this via RESET_ALPHA so they
	// remain visible despite the parent being alpha 0.
	alpha = 0
	/// Duration of the fade-out animation when the scope is closed.
	var/visual_fade_time = 1 SECONDS
	var/obj/item/gun/energy/gauss_rifle/source_gun
	/// Scope reticle/frame visual, shown above mobs.
	var/atom/movable/screen/gauss_scope_visual/scope_visual
	/// Background visual, shown below mobs so they render on top.
	var/atom/movable/screen/gauss_scope_visual/background/background_visual

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/assign_to_mob(mob/new_owner, range_modifier, obj/item/source_item)
	. = ..()
	source_gun = source_item
	update_scope_visuals()
	if(isliving(new_owner))
		RegisterSignal(new_owner, SIGNAL_REMOVETRAIT(TRAIT_USER_SCOPED), PROC_REF(on_scope_removed))
	if(source_gun)
		RegisterSignal(source_gun, COMSIG_GAUSS_RIFLE_MODE_CHANGED, PROC_REF(on_gun_mode_changed))

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/Destroy()
	if(owner)
		UnregisterSignal(owner, SIGNAL_REMOVETRAIT(TRAIT_USER_SCOPED))
	if(source_gun)
		UnregisterSignal(source_gun, COMSIG_GAUSS_RIFLE_MODE_CHANGED)
	clear_visuals(immediate = TRUE)
	source_gun = null
	return ..()

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/on_scope_removed(datum/source)
	SIGNAL_HANDLER
	clear_visuals(immediate = FALSE)

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/on_gun_mode_changed(datum/source)
	SIGNAL_HANDLER
	update_scope_visuals()

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/clear_visuals(immediate = FALSE)
	if(immediate || !visual_fade_time)
		if(scope_visual)
			vis_contents -= scope_visual
			QDEL_NULL(scope_visual)
		if(background_visual)
			vis_contents -= background_visual
			QDEL_NULL(background_visual)
		return

	// Fade out, then qdel after the animation finishes.
	if(scope_visual)
		animate(scope_visual, alpha = 0, time = visual_fade_time)
		QDEL_IN(scope_visual, visual_fade_time)
		scope_visual = null
	if(background_visual)
		animate(background_visual, alpha = 0, time = visual_fade_time)
		QDEL_IN(background_visual, visual_fade_time)
		background_visual = null

/atom/movable/screen/fullscreen/cursor_catcher/scope/gauss/proc/update_scope_visuals()
	if(!owner?.client || !source_gun)
		return

	clear_visuals(immediate = TRUE)

	var/scope_state = source_gun.get_scope_icon_state(source_gun.get_current_mode_prefix())
	var/stretch = source_gun.scope_overlay_stretches

	background_visual = new(null, null, "scope_background", stretch)
	scope_visual = new(null, null, scope_state, stretch)

	// Apply multi-z plane offset based on the owner's turf so the background actually
	// renders on the same game plane as the mobs on that z level (otherwise it lands on
	// z=1's game plane and won't layer correctly with mobs on higher z levels).
	SET_PLANE_EXPLICIT(background_visual, initial(background_visual.plane), owner)
	SET_PLANE_EXPLICIT(scope_visual, initial(scope_visual.plane), owner)

	vis_contents += background_visual
	vis_contents += scope_visual

/atom/movable/screen/gauss_scope_visual
	name = "gauss scope"
	icon = 'code/modules/antagonists/traitor/contractor/icons/contractor_gun_hud.dmi'
	// TRANSPARENT so mouse events fall through to the cursor catcher behind us.
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_HUD_PLANE
	layer = FULLSCREEN_LAYER
	// Opt out of inheriting the catcher's alpha (so we stay visible despite alpha = 0),
	// color matrix (in case one is ever applied), and stretch transform.
	appearance_flags = RESET_ALPHA | RESET_COLOR | RESET_TRANSFORM

/atom/movable/screen/gauss_scope_visual/Initialize(mapload, datum/hud/hud_owner, new_state, stretch_fullscreen = FALSE)
	. = ..()
	if(new_state)
		icon_state = new_state
	if(stretch_fullscreen)
		var/list/view_size = getviewsize(world.view)
		transform = matrix(view_size[1]/FULLSCREEN_OVERLAY_RESOLUTION_X, 0, 0, 0, view_size[2]/FULLSCREEN_OVERLAY_RESOLUTION_Y, 0)
	else
		// Center the sprite within the fullscreen anchor area at native size.
		var/icon/probe = icon(icon, icon_state)
		var/icon_width = probe.Width()
		var/icon_height = probe.Height()
		pixel_x = round((FULLSCREEN_OVERLAY_RESOLUTION_X * ICON_SIZE_X - icon_width) * 0.5)
		pixel_y = round((FULLSCREEN_OVERLAY_RESOLUTION_Y * ICON_SIZE_Y - icon_height) * 0.5)

/atom/movable/screen/gauss_scope_visual/background
	plane = GAME_PLANE
	layer = BELOW_MOB_LAYER
