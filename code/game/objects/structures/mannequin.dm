#define MANNEQUIN_WOOD "wood"
#define MANNEQUIN_PLASTIC "plastic"
#define MANNEQUIN_SKELETON "skeleton"

/// A mannequin! A structure that can display clothing on itself.
/obj/structure/mannequin
	name = "mannequin"
	desc = "Oh, so this is a dress-up game now."
	icon = 'icons/mob/human/mannequin.dmi'
	icon_state = "mannequin_wood_male"
	density = TRUE
	resistance_flags = FLAMMABLE
	appearance_flags = KEEP_TOGETHER|TILE_BOUND|PIXEL_SCALE|LONG_GLIDE
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	pixel_y = 3
	base_pixel_y = 3
	layer = ABOVE_MOB_LAYER
	plane = ABOVE_GAME_PLANE
	/// Which body type we use, male or female?
	var/body_type
	/// Material we're used of, wood or plastic?
	var/material
	/// String for the underwear we use.
	var/underwear_name
	/// String for the undershirt we use.
	var/undershirt_name
	/// String for the socks we use.
	var/socks_name
	/// Static list of slot flags we have clothing slots for.
	var/static/list/slot_flags = list(
		ITEM_SLOT_HEAD,
		ITEM_SLOT_EYES,
		ITEM_SLOT_EARS,
		ITEM_SLOT_MASK,
		ITEM_SLOT_NECK,
		ITEM_SLOT_BACK,
		ITEM_SLOT_BELT,
		ITEM_SLOT_ID,
		ITEM_SLOT_ICLOTHING,
		ITEM_SLOT_OCLOTHING,
		ITEM_SLOT_GLOVES,
		ITEM_SLOT_FEET,
	)
	/// Assoc list of all item slots (turned to strings) to the items they hold.
	var/list/worn_items = list()
	///List of all clothing items the mannequin should be spawning in with on Initialize.
	var/list/obj/item/clothing/starting_items = list()

/obj/structure/mannequin/Initialize(mapload)
	. = ..()
	for(var/slot_flag in slot_flags)
		worn_items["[slot_flag]"] = null
		for(var/obj/item/clothing/items as anything in starting_items)
			if(initial(items.slot_flags) & slot_flag)
				worn_items["[slot_flag]"] = new items(src)
				starting_items -= items
				break
	if(starting_items.len)
		CRASH("[src] had [starting_items.len] starting items fail to equip.")
	if(!body_type)
		body_type = pick(MALE, FEMALE)
	if(!material)
		material = pick(MANNEQUIN_WOOD, MANNEQUIN_PLASTIC)
	icon_state = "mannequin_[material]_[body_type == FEMALE ? "female" : "male"]"
	AddElement(/datum/element/strippable, GLOB.strippable_mannequin_items)
	AddComponent(/datum/component/simple_rotation, ROTATION_IGNORE_ANCHORED)
	AddComponent(/datum/component/marionette)
	update_appearance()

/obj/structure/mannequin/Destroy()
	QDEL_LIST_ASSOC_VAL(worn_items)
	return ..()

/obj/structure/mannequin/atom_destruction(damage_flag)
	for(var/slot_flag in worn_items)
		var/obj/item/worn_item = worn_items[slot_flag]
		if(worn_item)
			worn_item.forceMove(drop_location())
	return ..()

/obj/structure/mannequin/Exited(atom/movable/gone, direction)
	. = ..()
	for(var/slot_flag in worn_items)
		if(worn_items[slot_flag] == gone)
			worn_items[slot_flag] = null
	update_appearance()

/obj/structure/mannequin/wrench_act(mob/living/user, obj/item/tool)
	. = ..()
	default_unfasten_wrench(user, tool)
	return ITEM_INTERACT_SUCCESS

/obj/structure/mannequin/update_overlays()
	. = ..()
	var/mutable_appearance/pedestal = mutable_appearance(icon, "pedestal_[material]")
	pedestal.pixel_z = -3
	. += pedestal
	var/datum/sprite_accessory/underwear/underwear = GLOB.underwear_list[underwear_name]
	if(underwear)
		if(body_type == FEMALE && underwear.gender == MALE)
			. += mutable_appearance(wear_female_version(underwear.icon_state, underwear.icon, FEMALE_UNIFORM_FULL), layer = -BODY_LAYER)
		else
			. += mutable_appearance(underwear.icon, underwear.icon_state, layer = -BODY_LAYER)
	var/datum/sprite_accessory/undershirt/undershirt = GLOB.undershirt_list[undershirt_name]
	if(undershirt)
		if(body_type == FEMALE)
			. += mutable_appearance(wear_female_version(undershirt.icon_state, undershirt.icon), layer = -BODY_LAYER)
		else
			. += mutable_appearance(undershirt.icon, undershirt.icon_state, layer = -BODY_LAYER)
	var/datum/sprite_accessory/socks/socks = GLOB.socks_list[socks_name]
	if(socks)
		. += mutable_appearance(socks.icon, socks.icon_state, -BODY_LAYER)
	for(var/slot_flag in worn_items)
		var/obj/item/worn_item = worn_items[slot_flag]
		if(!worn_item)
			continue
		var/default_layer = 0
		var/default_icon = null
		var/female_icon = NO_FEMALE_UNIFORM
		switch(text2num(slot_flag)) //this kinda sucks because build worn icon kinda sucks
			if(ITEM_SLOT_HEAD)
				default_layer = HEAD_LAYER
				default_icon = 'icons/mob/clothing/head/default.dmi'
			if(ITEM_SLOT_EYES)
				default_layer = GLASSES_LAYER
				default_icon = 'icons/mob/clothing/eyes.dmi'
			if(ITEM_SLOT_EARS)
				default_layer = EARS_LAYER
				default_icon = 'icons/mob/clothing/ears.dmi'
			if(ITEM_SLOT_MASK)
				default_layer = FACEMASK_LAYER
				default_icon = 'icons/mob/clothing/mask.dmi'
			if(ITEM_SLOT_NECK)
				default_layer = NECK_LAYER
				default_icon = 'icons/mob/clothing/neck.dmi'
			if(ITEM_SLOT_BACK)
				default_layer = BACK_LAYER
				default_icon = 'icons/mob/clothing/back.dmi'
			if(ITEM_SLOT_BELT)
				default_layer = BELT_LAYER
				default_icon = 'icons/mob/clothing/belt.dmi'
			if(ITEM_SLOT_ID)
				default_layer = ID_LAYER
				default_icon = 'icons/mob/clothing/id.dmi'
			if(ITEM_SLOT_ICLOTHING)
				default_layer = UNIFORM_LAYER
				default_icon = DEFAULT_UNIFORM_FILE
				if(body_type == FEMALE && istype(worn_item, /obj/item/clothing/under))
					var/obj/item/clothing/under/worn_jumpsuit = worn_item
					female_icon = worn_jumpsuit.female_sprite_flags
			if(ITEM_SLOT_OCLOTHING)
				default_layer = SUIT_LAYER
				default_icon = DEFAULT_SUIT_FILE
			if(ITEM_SLOT_GLOVES)
				default_layer = GLOVES_LAYER
				default_icon = 'icons/mob/clothing/hands.dmi'
			if(ITEM_SLOT_FEET)
				default_layer = SHOES_LAYER
				default_icon = DEFAULT_SHOES_FILE
		. += worn_item.build_worn_icon(default_layer, default_icon, female_uniform = female_icon)

/obj/structure/mannequin/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	var/choice = tgui_input_list(user, "Underwear, Undershirt, or Socks?", "Changing", list("Underwear","Undershirt","Socks"))
	if(!Adjacent(user))
		return
	switch(choice)
		if("Underwear")
			var/new_undies = tgui_input_list(user, "Select the mannequin's underwear", "Changing", GLOB.underwear_list)
			if(new_undies)
				underwear_name = new_undies
		if("Undershirt")
			var/new_undershirt = tgui_input_list(user, "Select the mannequin's undershirt", "Changing", GLOB.undershirt_list)
			if(new_undershirt)
				undershirt_name = new_undershirt
		if("Socks")
			var/new_socks = tgui_input_list(user, "Select the mannequin's socks", "Changing", GLOB.socks_list)
			if(new_socks)
				socks_name = new_socks
	update_appearance()

/obj/structure/mannequin/wood
	material = MANNEQUIN_WOOD

/obj/structure/mannequin/plastic
	material = MANNEQUIN_PLASTIC

/obj/structure/mannequin/skeleton
	name = "skeleton model"
	desc = "Not to knock over."
	material = MANNEQUIN_SKELETON
	obj_flags = UNIQUE_RENAME
	starting_items = list(
		/obj/item/clothing/glasses/eyepatch,
		/obj/item/clothing/suit/costume/hawaiian,
	)

GLOBAL_LIST_INIT(strippable_mannequin_items, create_strippable_list(list(
	/datum/strippable_item/mannequin_slot/head,
	/datum/strippable_item/mannequin_slot/eyes,
	/datum/strippable_item/mannequin_slot/ears,
	/datum/strippable_item/mannequin_slot/mask,
	/datum/strippable_item/mannequin_slot/neck,
	/datum/strippable_item/mannequin_slot/back,
	/datum/strippable_item/mannequin_slot/belt,
	/datum/strippable_item/mannequin_slot/id,
	/datum/strippable_item/mannequin_slot/uniform,
	/datum/strippable_item/mannequin_slot/suit,
	/datum/strippable_item/mannequin_slot/gloves,
	/datum/strippable_item/mannequin_slot/feet,
)))

/datum/strippable_item/mannequin_slot
	/// The ITEM_SLOT_* to equip to.
	var/item_slot

/datum/strippable_item/mannequin_slot/get_item(atom/source)
	var/obj/structure/mannequin/mannequin_source = source
	return istype(mannequin_source) ? mannequin_source.worn_items["[item_slot]"] : null

/datum/strippable_item/mannequin_slot/try_equip(atom/source, obj/item/equipping, mob/user)
	. = ..()
	if(!.)
		return FALSE
	if(!(equipping.slot_flags & item_slot))
		to_chat(user, span_warning("[equipping] won't fit!"))
		return FALSE
	return TRUE

/datum/strippable_item/mannequin_slot/finish_equip(atom/source, obj/item/equipping, mob/user)
	var/obj/structure/mannequin/mannequin_source = source
	if(!istype(mannequin_source))
		return
	if(!user.transferItemToLoc(equipping, mannequin_source) || QDELETED(equipping))
		return
	mannequin_source.worn_items["[item_slot]"] = equipping
	mannequin_source.update_appearance()

/datum/strippable_item/mannequin_slot/finish_unequip(atom/source, mob/user)
	var/obj/structure/mannequin/mannequin_source = source
	if(!istype(mannequin_source))
		return
	var/obj/item/unequipped = mannequin_source.worn_items["[item_slot]"]
	user.put_in_hands(unequipped)

/datum/strippable_item/mannequin_slot/head
	key = STRIPPABLE_ITEM_HEAD
	item_slot = ITEM_SLOT_HEAD

/datum/strippable_item/mannequin_slot/eyes
	key = STRIPPABLE_ITEM_EYES
	item_slot = ITEM_SLOT_EYES

/datum/strippable_item/mannequin_slot/ears
	key = STRIPPABLE_ITEM_EARS
	item_slot = ITEM_SLOT_EARS

/datum/strippable_item/mannequin_slot/mask
	key = STRIPPABLE_ITEM_MASK
	item_slot = ITEM_SLOT_MASK

/datum/strippable_item/mannequin_slot/neck
	key = STRIPPABLE_ITEM_NECK
	item_slot = ITEM_SLOT_NECK

/datum/strippable_item/mannequin_slot/back
	key = STRIPPABLE_ITEM_BACK
	item_slot = ITEM_SLOT_BACK

/datum/strippable_item/mannequin_slot/belt
	key = STRIPPABLE_ITEM_BELT
	item_slot = ITEM_SLOT_BELT

/datum/strippable_item/mannequin_slot/id
	key = STRIPPABLE_ITEM_ID
	item_slot = ITEM_SLOT_ID

/datum/strippable_item/mannequin_slot/uniform
	key = STRIPPABLE_ITEM_JUMPSUIT
	item_slot = ITEM_SLOT_ICLOTHING

/datum/strippable_item/mannequin_slot/suit
	key = STRIPPABLE_ITEM_SUIT
	item_slot = ITEM_SLOT_OCLOTHING

/datum/strippable_item/mannequin_slot/gloves
	key = STRIPPABLE_ITEM_GLOVES
	item_slot = ITEM_SLOT_GLOVES

/datum/strippable_item/mannequin_slot/feet
	key = STRIPPABLE_ITEM_FEET
	item_slot = ITEM_SLOT_FEET

#undef MANNEQUIN_WOOD
#undef MANNEQUIN_PLASTIC
#undef MANNEQUIN_SKELETON
