/obj/effect/projectile/tracer
	name = "beam"
	icon = 'icons/obj/weapons/guns/projectiles_tracer.dmi'
	/// If TRUE, apply PIXEL_SCALE to this tracer's spawned segment effects.
	var/use_pixel_scale = FALSE

/obj/effect/projectile/tracer/laser
	name = "laser"
	icon_state = "beam"

/obj/effect/projectile/tracer/laser/blue
	icon_state = "beam_blue"

/obj/effect/projectile/tracer/disabler
	name = "disabler"
	icon_state = "beam_omni"

/obj/effect/projectile/tracer/xray
	name = "\improper X-ray laser"
	icon_state = "xray"

/obj/effect/projectile/tracer/pulse
	name = "pulse laser"
	icon_state = "u_laser"

/obj/effect/projectile/tracer/plasma_cutter
	name = "plasma blast"
	icon_state = "plasmacutter"

/obj/effect/projectile/tracer/stun
	name = "stun beam"
	icon_state = "stun"

/obj/effect/projectile/tracer/heavy_laser
	name = "heavy laser"
	icon_state = "beam_heavy"

/obj/effect/projectile/tracer/solar
	name = "solar beam"
	icon_state = "solar"

/obj/effect/projectile/tracer/solar/thin
	icon_state = "solar_thin"

/obj/effect/projectile/tracer/solar/thinnest
	icon_state = "solar_thinnest"

/// A tracer that renders separate start/end caps plus tiled middle segments.
/obj/effect/projectile/tracer/segmented
	/// Icon state used by the tiled middle segments.
	var/mid_icon_state
	/// Icon state used by the starting cap.
	var/start_icon_state
	/// Icon state used by the ending cap.
	var/end_icon_state
	/// Number of tile-lengths reserved for caps (one at each end by default).
	var/cap_padding_tiles = 2
	/// Start and end cap tracers spawned in apply_vars, co-deleted with this tracer.
	var/list/beam_cap_effects

/obj/effect/projectile/tracer/segmented/apply_vars(angle_override, p_x = 0, p_y = 0, color_override, scaling = 1, increment = 0)
	pixel_x = p_x
	pixel_y = p_y
	if(color_override)
		color = color_override
	// This object acts as a manager; visible segments are spawned below.
	alpha = 0

	QDEL_LIST(beam_cap_effects)
	beam_cap_effects = list()

	// Pixel distance from beam midpoint to each cap centre: half-beam minus half-tile.
	var/cap_dist = max((scaling * ICON_SIZE_ALL / 2) - (ICON_SIZE_ALL / 2), 0)
	var/sin_angle = sin(angle_override)
	var/cos_angle = cos(angle_override)
	var/mid_tiles = max(scaling - cap_padding_tiles, 0)
	var/mid_count = floor(mid_tiles)
	var/mid_remainder = mid_tiles - mid_count
	var/cap_dx = round(sin(angle_override) * cap_dist, 1)
	var/cap_dy = round(cos(angle_override) * cap_dist, 1)

	var/obj/effect/projectile/tracer/cap_start = new /obj/effect/projectile/tracer(loc)
	cap_start.icon = icon
	cap_start.icon_state = start_icon_state
	if(use_pixel_scale)
		cap_start.appearance_flags |= PIXEL_SCALE
	else
		cap_start.appearance_flags &= ~PIXEL_SCALE
	cap_start.apply_vars(angle_override = angle_override, p_x = p_x - cap_dx, p_y = p_y - cap_dy, color_override = color_override)

	var/obj/effect/projectile/tracer/cap_end = new /obj/effect/projectile/tracer(loc)
	cap_end.icon = icon
	cap_end.icon_state = end_icon_state
	if(use_pixel_scale)
		cap_end.appearance_flags |= PIXEL_SCALE
	else
		cap_end.appearance_flags &= ~PIXEL_SCALE
	cap_end.apply_vars(angle_override = angle_override, p_x = p_x + cap_dx, p_y = p_y + cap_dy, color_override = color_override)

	beam_cap_effects += cap_start
	for(var/i in 1 to mid_count)
		var/mid_dist = -cap_dist + i * ICON_SIZE_ALL
		var/mid_dx = round(sin_angle * mid_dist, 1)
		var/mid_dy = round(cos_angle * mid_dist, 1)
		var/obj/effect/projectile/tracer/mid_segment = new /obj/effect/projectile/tracer(loc)
		mid_segment.icon = icon
		mid_segment.icon_state = mid_icon_state
		if(use_pixel_scale)
			mid_segment.appearance_flags |= PIXEL_SCALE
		else
			mid_segment.appearance_flags &= ~PIXEL_SCALE
		mid_segment.apply_vars(angle_override = angle_override, p_x = p_x + mid_dx, p_y = p_y + mid_dy, color_override = color_override)
		beam_cap_effects += mid_segment
	if(mid_remainder > 0.01)
		// Place a shortened final mid segment so it touches both the last full mid and the end cap.
		var/partial_mid_dist = cap_dist - (ICON_SIZE_ALL / 2) - ((ICON_SIZE_ALL * mid_remainder) / 2)
		var/partial_mid_dx = round(sin_angle * partial_mid_dist, 1)
		var/partial_mid_dy = round(cos_angle * partial_mid_dist, 1)
		var/obj/effect/projectile/tracer/partial_mid_segment = new /obj/effect/projectile/tracer(loc)
		partial_mid_segment.icon = icon
		partial_mid_segment.icon_state = mid_icon_state
		if(use_pixel_scale)
			partial_mid_segment.appearance_flags |= PIXEL_SCALE
		else
			partial_mid_segment.appearance_flags &= ~PIXEL_SCALE
		partial_mid_segment.apply_vars(angle_override = angle_override, p_x = p_x + partial_mid_dx, p_y = p_y + partial_mid_dy, color_override = color_override, scaling = mid_remainder)
		beam_cap_effects += partial_mid_segment
	beam_cap_effects += cap_end

/obj/effect/projectile/tracer/segmented/Destroy()
	QDEL_LIST(beam_cap_effects)
	return ..()

// GAUSS ANTIMATTER
/obj/effect/projectile/tracer/gauss_antimatter
	parent_type = /obj/effect/projectile/tracer/segmented
	icon = 'icons/obj/weapons/guns/antimatter_beam.dmi'
	mid_icon_state = "antimatter-mid"
	start_icon_state = "antimatter-start"
	end_icon_state = "antimatter-squashed"

// BEAM RIFLE
/obj/effect/projectile/tracer/tracer/beam_rifle
	icon_state = "tracer_beam"

/obj/effect/projectile/tracer/tracer/aiming
	icon_state = "pixelbeam_greyscale"
	plane = ABOVE_LIGHTING_PLANE

/obj/effect/projectile/tracer/wormhole
	icon_state = "wormhole_g"

/obj/effect/projectile/tracer/laser/emitter
	name = "emitter beam"
	icon_state = "emitter"

/obj/effect/projectile/tracer/laser/emitter/bluelens
	name = "electrodisruptive emitter beam"
	icon_state = "u_laser"

/obj/effect/projectile/tracer/laser/emitter/redlens
	name = "hyperenergetic emitter beam"
	icon_state = "beam_heavy"

/obj/effect/projectile/tracer/laser/emitter/bioregen
	name = "bioregenerative emitter beam"
	icon_state = "solar"

/obj/effect/projectile/tracer/laser/emitter/psy
	name = "psychosiphoning emitter beam"
	icon_state = "tracer_greyscale"
	color = COLOR_PINK

/obj/effect/projectile/tracer/laser/emitter/magnetic
	name = "magnetogenerative emitter beam"
	icon_state = "tracer_greyscale"
	color = COLOR_SILVER

/obj/effect/projectile/tracer/laser/emitter/quake
	name = "seismodisintegrating emitter beam"
	icon_state = "tracer_greyscale"
	color = COLOR_BROWNER_BROWN

/obj/effect/projectile/tracer/laser/emitter/blast
	name = "hyperconcussive emitter beam"
	icon_state = "tracer_greyscale"
	color = COLOR_ORANGE

/obj/effect/projectile/tracer/sniper
	icon_state = "sniper"
