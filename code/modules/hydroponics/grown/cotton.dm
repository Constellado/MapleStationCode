/obj/item/seeds/cotton
	name = "cotton seed pack"
	desc = "A pack of seeds that'll grow into a cotton plant. Assistants make good free labor if neccesary."
	icon_state = "seed-cotton"
	species = "cotton"
	plantname = "Cotton"
	icon_harvest = "cotton-harvest"
	product = /obj/item/grown/cotton
	lifespan = 35
	endurance = 25
	maturation = 15
	production = 1
	yield = 2
	potency = 50
	instability = 15
	growthstages = 3
	growing_icon = 'icons/obj/service/hydroponics/growing.dmi'
	icon_dead = "cotton-dead"
	mutatelist = list(/obj/item/seeds/cotton/durathread)

/obj/item/grown/cotton
	seed = /obj/item/seeds/cotton
	name = "cotton bundle"
	desc = "A fluffy bundle of cotton."
	icon_state = "cotton"
	force = 0
	throwforce = 0
	w_class = WEIGHT_CLASS_TINY
	throw_speed = 2
	throw_range = 3
	attack_verb_continuous = list("pomfs")
	attack_verb_simple = list("pomf")
	drop_sound = 'maplestation_modules/sound/items/drop/herb.ogg'
	pickup_sound = 'maplestation_modules/sound/items/pickup/herb.ogg'

	var/cotton_type = /obj/item/stack/sheet/cotton
	var/cotton_name = "raw cotton"

/obj/item/grown/cotton/attack_self(mob/user)
	user.show_message(span_notice("You pull some [cotton_name] out of the [name]!"), MSG_VISUAL)
	var/seed_modifier = 0
	if(seed)
		seed_modifier = round(seed.potency / 25)
	var/obj/item/stack/cotton = new cotton_type(user.loc, 1 + seed_modifier)
	var/old_cotton_amount = cotton.amount
	for(var/obj/item/stack/potential_stack in user.loc)
		if(QDELETED(potential_stack))
			continue
		if(potential_stack == cotton)
			continue
		if(!istype(potential_stack, cotton_type))
			continue
		if(potential_stack.amount >= potential_stack.max_amount)
			continue
		potential_stack.attackby(cotton, user)

	if(cotton.amount > old_cotton_amount)
		to_chat(user, span_notice("You add the newly-formed [cotton_name] to the stack. It now contains [cotton.amount] [cotton_name]."))
	qdel(src)

//reinforced mutated variant
/obj/item/seeds/cotton/durathread
	name = "durathread seed pack"
	desc = "A pack of seeds that'll grow into an extremely durable thread that could easily rival plasteel if woven properly."
	icon_state = "seed-durathread"
	species = "durathread"
	plantname = "Durathread"
	icon_harvest = "durathread-harvest"
	product = /obj/item/grown/cotton/durathread
	lifespan = 80
	endurance = 50
	maturation = 15
	production = 1
	yield = 2
	potency = 50
	growthstages = 3
	growing_icon = 'icons/obj/service/hydroponics/growing.dmi'
	icon_dead = "cotton-dead"
	mutatelist = null

/obj/item/grown/cotton/durathread
	seed = /obj/item/seeds/cotton/durathread
	name = "durathread bundle"
	desc = "A tough bundle of durathread, good luck unraveling this."
	icon_state = "durathread"
	force = 5
	throwforce = 5
	w_class = WEIGHT_CLASS_NORMAL
	throw_speed = 2
	throw_range = 3
	attack_verb_continuous = list("bashes", "batters", "bludgeons", "whacks")
	attack_verb_simple = list("bash", "batter", "bludgeon", "whack")
	cotton_type = /obj/item/stack/sheet/cotton/durathread
	cotton_name = "raw durathread"
