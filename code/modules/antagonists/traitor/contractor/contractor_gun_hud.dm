/atom/movable/screen/gauss_ammo_display
	name = "gauss ammo display"
	icon_state = "gunhud"
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

/atom/movable/screen/gauss_ammo_display/proc/on_gun_ammo_changed(obj/item/gun/energy/gauss_rifle/source, shots_left, max_shots)
	SIGNAL_HANDLER
	refresh_display(shots_left)

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

/atom/movable/screen/gauss_ammo_display/proc/refresh_display(shots_left)
	if(shots_overlay)
		cut_overlay(shots_overlay)
		shots_overlay = null

	if(shots_left <= 0)
		return

	shots_overlay = mutable_appearance('code/modules/antagonists/traitor/contractor/icons/contractor_hud_numbers.dmi', "[shots_left]")
	add_overlay(shots_overlay)
