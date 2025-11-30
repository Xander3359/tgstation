/obj/item/clothing/suit/net
	icon_state = "net"
	icon = 'code/nets.dmi'

/obj/item/clothing/suit/net/update_overlays()
	. = ..()
	. += emissive_appearance('code/nets.dmi', "net_emissive", src)

/obj/item/clothing/suit/net/spicy
	icon_state = "spicy_net"
	icon = 'code/nets.dmi'
	
	icon_state = "spicy_net"

/obj/item/net_ammo
	icon_state = "net_ammo"
	icon = 'code/nets.dmi'

/obj/item/net_projectile
	icon_state = "net_projectile"
	icon = 'code/nets.dmi'

