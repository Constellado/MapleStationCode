/mob/living/carbon/Initialize(mapload)
	. = ..()
	create_carbon_reagents()
	update_body_parts() //to update the carbon's new bodyparts appearance
	register_context()

	GLOB.carbon_list += src
	ADD_TRAIT(src, TRAIT_CAN_HOLD_ITEMS, INNATE_TRAIT) // Carbons are assumed to be innately capable of having arms, we check their arms count instead

/mob/living/carbon/Destroy()
	//This must be done first, so the mob ghosts correctly before DNA etc is nulled
	. = ..()

	QDEL_LIST(hand_bodyparts)
	QDEL_LIST(organs)
	QDEL_LIST(bodyparts)
	QDEL_LIST(implants)
	for(var/wound in all_wounds) // these LAZYREMOVE themselves when deleted so no need to remove the list here
		qdel(wound)
	for(var/scar in all_scars)
		qdel(scar)
	remove_from_all_data_huds()
	QDEL_NULL(dna)
	GLOB.carbon_list -= src

/mob/living/carbon/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	. = ..()
	if(. & ITEM_INTERACT_ANY_BLOCKER)
		return .
	// Needs to happen after parent call otherwise wounds are prioritized over surgery
	for(var/datum/wound/wound as anything in shuffle(all_wounds))
		if(wound.try_treating(tool, user))
			return ITEM_INTERACT_SUCCESS
	return .

/mob/living/carbon/click_ctrl_shift(mob/user)
	if(iscarbon(user))
		var/mob/living/carbon/carbon_user = user
		carbon_user.give(src)

/mob/living/carbon/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	. = ..()
	var/hurt = TRUE
	var/extra_speed = 0
	var/oof_noise = FALSE //We smacked something with denisty, so play a noise
	var/mob/thrower = throwingdatum?.get_thrower()
	if(thrower != src)
		extra_speed = min(max(0, throwingdatum.speed - initial(throw_speed)), CARBON_MAX_IMPACT_SPEED_BONUS)

	if(istype(throwingdatum))
		hurt = !throwingdatum.gentle
	if(hurt && hit_atom.density)
		if(isturf(hit_atom))
			Paralyze(2 SECONDS)
			damage_random_bodypart(10 + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
		else if(isstructure(hit_atom) && extra_speed)
			Paralyze(1 SECONDS)
			damage_random_bodypart(5 + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
		else if(!iscarbon(hit_atom) && extra_speed)
			damage_random_bodypart(5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
		visible_message(
			span_danger("[src] crashes into [hit_atom][extra_speed ? " really hard" : ""]!!"),
			span_userdanger("You[extra_speed ? " violently" : ""] crash into [hit_atom][extra_speed ? " extra hard" : ""]!"),
		)
		log_combat(hit_atom, src, "crashes ")
		oof_noise = TRUE

	if(iscarbon(hit_atom) && hit_atom != src)
		var/mob/living/carbon/victim = hit_atom
		var/blocked = FALSE
		if(victim.movement_type & FLYING)
			return
		if(!hurt)
			return

		if(victim.check_block(src, 0, "[name]", LEAP_ATTACK))
			blocked = TRUE

		damage_random_bodypart(10 + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
		Paralyze(2 SECONDS)
		oof_noise = TRUE

		if(blocked)
			visible_message(span_danger("[src] crashes into [victim][extra_speed ? " really hard" : ""], but [victim] blocked the worst of it!"),\
				span_userdanger("You violently crash into [victim][extra_speed ? " extra hard" : ""], but [victim] managed to block the worst of it!"))
			log_combat(src, victim, "crashed into and was blocked by")
			return
		else
			victim.Paralyze(2 SECONDS)
			victim.damage_random_bodypart(10 + 5 * extra_speed, check_armor = TRUE, wound_bonus = extra_speed * 5)
			visible_message(span_danger("[src] crashes into [victim][extra_speed ? " really hard" : ""], knocking them both over!"),\
				span_userdanger("You violently crash into [victim][extra_speed ? " extra hard" : ""]!"))
			log_combat(src, victim, "crashed into")

	if(oof_noise)
		playsound(src,'sound/weapons/punch1.ogg',50,TRUE)

//Throwing stuff
/mob/living/carbon/proc/toggle_throw_mode()
	if(incapacitated())
		return
	if(throw_mode)
		throw_mode_off(THROW_MODE_TOGGLE)
	else
		throw_mode_on(THROW_MODE_TOGGLE)


/mob/living/carbon/proc/throw_mode_off(method)
	if(throw_mode > method) //A toggle doesnt affect a hold
		return
	throw_mode = THROW_MODE_DISABLED
	if(hud_used)
		hud_used.throw_icon.icon_state = "act_throw_off"


/mob/living/carbon/proc/throw_mode_on(mode = THROW_MODE_TOGGLE)
	if(incapacitated())
		return
	throw_mode = mode
	if(hud_used)
		hud_used.throw_icon.icon_state = "act_throw_on"

/mob/proc/throw_item(atom/target)
	SEND_SIGNAL(src, COMSIG_MOB_THROW, target)
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_CARBON_THROW_THING, src, target)
	return TRUE

/mob/living/carbon/throw_item(atom/target)
	. = ..()
	throw_mode_off(THROW_MODE_TOGGLE)
	if(!target || !isturf(loc))
		return FALSE
	if(istype(target, /atom/movable/screen))
		return FALSE
	var/atom/movable/thrown_thing
	var/obj/item/held_item = get_active_held_item()
	var/verb_text = pick("throw", "toss", "hurl", "chuck", "fling")
	if(prob(0.5))
		verb_text = "yeet"
	var/neckgrab_throw = FALSE // we can't check for if it's a neckgrab throw when totaling up power_throw since we've already stopped pulling them by then, so get it early
	var/frequency_number = 1 //We assign a default frequency number for the sound of the throw.
	if(held_item)
		thrown_thing = held_item.on_thrown(src, target)
	else if(isliving(pulling))
		thrown_thing = pulling
	else if(length(buckled_mobs) == 1 && isliving(buckled_mobs[1]) && buckle_lying != 0)
		thrown_thing = buckled_mobs[1]

	if(isliving(thrown_thing))
		var/mob/living/throwable_mob = thrown_thing
		if(throwable_mob.buckled == src)
			pass() // we're yeeting a fireman carry guy
		else
			if(grab_state < GRAB_AGGRESSIVE)
				return FALSE
			if(throwable_mob.buckled)
				return FALSE
		if(HAS_TRAIT(src, TRAIT_PACIFISM))
			to_chat(src, span_warning("You don't want to risk hurting [throwable_mob]!"))
			return FALSE
		if(grab_state >= GRAB_NECK)
			neckgrab_throw = TRUE
		if(throwable_mob.buckled == src)
			unbuckle_mob(thrown_thing)
		if(throwable_mob == pulling)
			stop_pulling()

	if(!thrown_thing)
		return FALSE
	if(isliving(thrown_thing))
		var/turf/start_T = get_turf(loc) //Get the start and target tile for the descriptors
		var/turf/end_T = get_turf(target)
		if(start_T && end_T)
			log_combat(src, thrown_thing, "thrown", addition="grab from tile in [AREACOORD(start_T)] towards tile at [AREACOORD(end_T)]")
	var/power_throw = 0
	if(HAS_TRAIT(src, TRAIT_HULK))
		power_throw++
	if(HAS_TRAIT(src, TRAIT_DWARF))
		power_throw--
	if(HAS_TRAIT(thrown_thing, TRAIT_DWARF))
		power_throw++
	if(neckgrab_throw)
		power_throw++
	if(HAS_TRAIT(src, TRAIT_TOSS_GUN_HARD) && isgun(thrown_thing))
		power_throw++
	if(isitem(thrown_thing))
		var/obj/item/thrown_item = thrown_thing
		frequency_number = 1-(thrown_item.w_class-3)/8 //At normal weight, the frequency is at 1. For tiny, it is 1.25. For huge, it is 0.75.
		if(thrown_item.throw_verb)
			verb_text = thrown_item.throw_verb
	do_attack_animation(target, no_effect = 1)
	var/sound/throwsound = 'sound/weapons/throw.ogg'
	var/power_throw_text = "."
	if(power_throw > 0) //If we have anything that boosts our throw power like hulk, we use the rougher heavier variant.
		throwsound = 'sound/weapons/throwhard.ogg'
		power_throw_text = " really hard!"
	if(power_throw < 0) //if we have anything that weakens our throw power like dward, we use a slower variant.
		throwsound = 'sound/weapons/throwsoft.ogg'
		power_throw_text = " flimsily."
	frequency_number = frequency_number + (rand(-5,5)/100); //Adds a bit of randomness in the frequency to not sound exactly the same.
	//The volume of the sound takes the minimum between the distance thrown or the max range an item, but no more than 50. Short throws are quieter. A fast throwing speed also makes the noise sharper.
	playsound(src, throwsound, min(8*min(get_dist(loc,target),thrown_thing.throw_range), 50), vary = TRUE, extrarange = -1, frequency = frequency_number)
	visible_message(span_danger("[src] [verb_text][plural_s(verb_text)] [thrown_thing][power_throw_text]"), \
					span_danger("You [verb_text] [thrown_thing][power_throw_text]"))
	log_message("has thrown [thrown_thing] [power_throw_text]", LOG_ATTACK)
	var/extra_throw_range = HAS_TRAIT(src, TRAIT_THROWINGARM) ? 2 : 0
	newtonian_move(get_dir(target, src))
	thrown_thing.safe_throw_at(target, thrown_thing.throw_range + extra_throw_range, max(1,thrown_thing.throw_speed + power_throw), src, null, null, null, move_force)

/mob/living/carbon/proc/canBeHandcuffed()
	return FALSE

/mob/living/carbon/proc/create_carbon_reagents()
	if (!isnull(reagents))
		return

	create_reagents(1000, REAGENT_HOLDER_ALIVE)

/mob/living/carbon/Topic(href, href_list)
	..()
	if(href_list["embedded_object"])
		var/obj/item/bodypart/L = locate(href_list["embedded_limb"]) in bodyparts
		if(!L)
			return
		var/obj/item/I = locate(href_list["embedded_object"]) in L.embedded_objects
		if(!I || I.loc != src) //no item, no limb, or item is not in limb or in the person anymore
			return
		SEND_SIGNAL(src, COMSIG_CARBON_EMBED_RIP, I, L)
		return

	if(href_list["gauze_limb"])
		var/obj/item/bodypart/gauzed = locate(href_list["gauze_limb"]) in bodyparts
		if(isnull(gauzed?.current_gauze))
			return
		// rest of the sanity is handled in the proc itself
		gauzed.help_remove_gauze(usr)
		return

	if(href_list["show_paper_note"])
		var/obj/item/paper/paper_note = locate(href_list["show_paper_note"])
		if(!paper_note)
			return

		paper_note.show_through_camera(usr)

/mob/living/carbon/on_fall()
	. = ..()
	loc.handle_fall(src)//it's loc so it doesn't call the mob's handle_fall which does nothing

/mob/living/carbon/is_muzzled()
	for (var/obj/item/clothing/clothing in get_equipped_items())
		if(clothing.clothing_flags & BLOCKS_SPEECH)
			return TRUE
	return FALSE


/mob/living/carbon/resist_buckle()
	if(!HAS_TRAIT(src, TRAIT_RESTRAINED))
		buckled.user_unbuckle_mob(src, src)
		return

	changeNext_move(CLICK_CD_BREAKOUT)
	last_special = world.time + CLICK_CD_BREAKOUT
	var/buckle_cd = 1 MINUTES

	if(handcuffed)
		var/obj/item/restraints/cuffs = src.get_item_by_slot(ITEM_SLOT_HANDCUFFED)
		buckle_cd = cuffs.breakouttime

	visible_message(span_warning("[src] attempts to unbuckle [p_them()]self!"),
				span_notice("You attempt to unbuckle yourself... \
				(This will take around [DisplayTimeText(buckle_cd)] and you must stay still.)"))

	if(!do_after(src, buckle_cd, target = src, timed_action_flags = IGNORE_HELD_ITEM, hidden = TRUE))
		if(buckled)
			to_chat(src, span_warning("You fail to unbuckle yourself!"))
		return

	if(QDELETED(src) || isnull(buckled))
		return

	buckled.user_unbuckle_mob(src, src)


/mob/living/carbon/resist_fire()
	return !!apply_status_effect(/datum/status_effect/stop_drop_roll)

/mob/living/carbon/resist_restraints()
	var/obj/item/I = null
	var/type = 0
	if(handcuffed)
		I = handcuffed
		type = 1
	else if(legcuffed)
		I = legcuffed
		type = 2
	if(I)
		if(type == 1)
			changeNext_move(CLICK_CD_BREAKOUT)
			last_special = world.time + CLICK_CD_BREAKOUT
		if(type == 2)
			changeNext_move(CLICK_CD_RANGE)
			last_special = world.time + CLICK_CD_RANGE
		cuff_resist(I)


/**
 * Helper to break the cuffs from hands
 * @param {obj/item} cuffs - The cuffs to break
 * @param {number} breakouttime - The time it takes to break the cuffs. Use SECONDS/MINUTES defines
 * @param {number} cuff_break - Speed multiplier, 0 is default, see _DEFINES\combat.dm
 */
/mob/living/carbon/proc/cuff_resist(obj/item/cuffs, breakouttime = 1 MINUTES, cuff_break = 0)
	if((cuff_break != INSTANT_CUFFBREAK) && (SEND_SIGNAL(src, COMSIG_MOB_REMOVING_CUFFS, cuffs) & COMSIG_MOB_BLOCK_CUFF_REMOVAL))
		return //The blocking object should sent a fluff-appropriate to_chat about cuff removal being blocked
	if(cuffs.item_flags & BEING_REMOVED)
		to_chat(src, span_warning("You're already attempting to remove [cuffs]!"))
		return
	cuffs.item_flags |= BEING_REMOVED
	breakouttime = cuffs.breakouttime
	if(!cuff_break)
		visible_message(span_warning("[src] attempts to remove [cuffs]!"))
		to_chat(src, span_notice("You attempt to remove [cuffs]... (This will take around [DisplayTimeText(breakouttime)] and you need to stand still.)"))
		if(do_after(src, breakouttime, target = src, timed_action_flags = IGNORE_HELD_ITEM, hidden = TRUE))
			. = clear_cuffs(cuffs, cuff_break)
		else
			to_chat(src, span_warning("You fail to remove [cuffs]!"))

	else if(cuff_break == FAST_CUFFBREAK)
		breakouttime = 5 SECONDS
		visible_message(span_warning("[src] is trying to break [cuffs]!"))
		to_chat(src, span_notice("You attempt to break [cuffs]... (This will take around 5 seconds and you need to stand still.)"))
		if(do_after(src, breakouttime, target = src, timed_action_flags = IGNORE_HELD_ITEM))
			. = clear_cuffs(cuffs, cuff_break)
		else
			to_chat(src, span_warning("You fail to break [cuffs]!"))

	else if(cuff_break == INSTANT_CUFFBREAK)
		. = clear_cuffs(cuffs, cuff_break)
	cuffs.item_flags &= ~BEING_REMOVED

/mob/living/carbon/proc/uncuff()
	if (handcuffed)
		var/obj/item/W = handcuffed
		set_handcuffed(null)
		if (buckled?.buckle_requires_restraints)
			buckled.unbuckle_mob(src)
		update_handcuffed()
		if (client)
			client.screen -= W
		if (W)
			W.forceMove(drop_location())
			W.dropped(src)
			if (W)
				W.layer = initial(W.layer)
				SET_PLANE_EXPLICIT(W, initial(W.plane), src)
		changeNext_move(0)
	if (legcuffed)
		var/obj/item/W = legcuffed
		legcuffed = null
		update_worn_legcuffs()
		if (client)
			client.screen -= W
		if (W)
			W.forceMove(drop_location())
			W.dropped(src)
			if (W)
				W.layer = initial(W.layer)
				SET_PLANE_EXPLICIT(W, initial(W.plane), src)
		changeNext_move(0)
	update_equipment_speed_mods() // In case cuffs ever change speed

/mob/living/carbon/proc/clear_cuffs(obj/item/I, cuff_break)
	if(!I.loc || buckled)
		return FALSE
	if(I != handcuffed && I != legcuffed)
		return FALSE
	visible_message(span_danger("[src] manages to [cuff_break ? "break" : "remove"] [I]!"))
	to_chat(src, span_notice("You successfully [cuff_break ? "break" : "remove"] [I]."))

	if(cuff_break)
		. = !((I == handcuffed) || (I == legcuffed))
		qdel(I)
		return TRUE

	else
		if(I == handcuffed)
			handcuffed.forceMove(drop_location())
			set_handcuffed(null)
			I.dropped(src)
			if(buckled?.buckle_requires_restraints)
				buckled.unbuckle_mob(src)
			update_handcuffed()
			return TRUE
		if(I == legcuffed)
			legcuffed.forceMove(drop_location())
			legcuffed = null
			I.dropped(src)
			update_worn_legcuffs()
			return TRUE

/mob/living/carbon/proc/accident(obj/item/I)
	if(!I || (I.item_flags & ABSTRACT) || HAS_TRAIT(I, TRAIT_NODROP))
		return

	dropItemToGround(I)

	var/modifier = 0
	if(HAS_TRAIT(src, TRAIT_CLUMSY))
		modifier -= 40 //Clumsy people are more likely to hit themselves -Honk!

	switch(rand(1,100)+modifier) //91-100=Nothing special happens
		if(-INFINITY to 0) //attack yourself
			INVOKE_ASYNC(I, TYPE_PROC_REF(/obj/item, attack), src, src)
		if(1 to 30) //throw it at yourself
			I.throw_impact(src)
		if(31 to 60) //Throw object in facing direction
			var/turf/target = get_turf(loc)
			var/range = rand(2,I.throw_range)
			for(var/i in 1 to range-1)
				var/turf/new_turf = get_step(target, dir)
				target = new_turf
				if(new_turf.density)
					break
			I.throw_at(target,I.throw_range,I.throw_speed,src)
		if(61 to 90) //throw it down to the floor
			var/turf/target = get_turf(loc)
			I.safe_throw_at(target,I.throw_range,I.throw_speed,src, force = move_force)

/mob/living/carbon/attack_ui(slot, params)
	if(!has_hand_for_held_index(active_hand_index))
		return 0
	return ..()

/// Proc that compels the mob to throw up. Returns TRUE if the mob actually threw up.
/mob/living/carbon/proc/vomit(vomit_flags = VOMIT_CATEGORY_DEFAULT, vomit_type = /obj/effect/decal/cleanable/vomit/toxic, lost_nutrition = 10, distance = 1, purge_ratio = 0.1)
	var/force = (vomit_flags & MOB_VOMIT_FORCE)
	if((HAS_TRAIT(src, TRAIT_NOHUNGER) || HAS_TRAIT(src, TRAIT_TOXINLOVER)) && !force)
		return TRUE

	if(!force && HAS_TRAIT(src, TRAIT_STRONG_STOMACH))
		lost_nutrition *= 0.5

	SEND_SIGNAL(src, COMSIG_CARBON_VOMITED, distance, force)

	// cache some stuff that we'll need later (at least multiple times)
	var/starting_dir = dir
	var/message = (vomit_flags & MOB_VOMIT_MESSAGE)
	var/stun = (vomit_flags & MOB_VOMIT_STUN)
	var/knockdown = (vomit_flags & MOB_VOMIT_KNOCKDOWN)
	var/blood = (vomit_flags & MOB_VOMIT_BLOOD)

	if(!force && !blood && (nutrition < 100))
		if(message)
			visible_message(
				span_warning("[src] dry heaves!"),
				span_userdanger("You try to throw up, but there's nothing in your stomach!"),
			)
		if(stun)
			var/stun_time = 20 SECONDS
			if(HAS_TRAIT(src, TRAIT_STRONG_STOMACH))
				stun_time *= 0.5
			Stun(stun_time)
		if(knockdown)
			Knockdown(20 SECONDS)
		return TRUE

	if(is_mouth_covered()) //make this add a blood/vomit overlay later it'll be hilarious
		if(message)
			visible_message(
				span_danger("[src] throws up all over [p_them()]self!"),
				span_userdanger("You throw up all over yourself!"),
			)
			add_mood_event("vomit", /datum/mood_event/vomitself)
		distance = 0
	else
		if(message)
			visible_message(
				span_danger("[src] throws up!"),
				span_userdanger("You throw up!"),
			)
			if(!isflyperson(src))
				add_mood_event("vomit", /datum/mood_event/vomit)

	if(stun)
		var/stun_time = 8 SECONDS
		if(!blood && HAS_TRAIT(src, TRAIT_STRONG_STOMACH))
			stun_time *= 0.5
		Stun(stun_time)
	if(knockdown)
		Knockdown(8 SECONDS)

	playsound(src, 'sound/effects/splat.ogg', 50, TRUE)

	var/need_mob_update = FALSE
	var/turf/location = get_turf(src)
	if(!blood)
		adjust_nutrition(-lost_nutrition)
		need_mob_update += adjustToxLoss(-3, updating_health = FALSE)

	for(var/i = 0 to distance)
		if(blood)
			if(location)
				add_splatter_floor(location)
			if(vomit_flags & MOB_VOMIT_HARM)
				need_mob_update += adjustBruteLoss(3, updating_health = FALSE)
		else
			if(location)
				location.add_vomit_floor(src, vomit_type, vomit_flags, purge_ratio) // call purge when doing detoxicfication to pump more chems out of the stomach.

		location = get_step(location, starting_dir)
		if (location?.is_blocked_turf())
			break
	if(need_mob_update) // so we only have to call updatehealth() once as opposed to n times
		updatehealth()

	return TRUE

/**
 * Expel the reagents you just tried to ingest
 *
 * When you try to ingest reagents but you do not have a stomach
 * you will spew the reagents on the floor.
 *
 * Vars:
 * * bite: /atom the reagents to expel
 * * amount: int The amount of reagent
 */
/mob/living/carbon/proc/expel_ingested(atom/bite, amount)
	visible_message(span_danger("[src] throws up all over [p_them()]self!"), \
					span_userdanger("You are unable to keep the [bite] down without a stomach!"))

	var/turf/floor = get_turf(src)
	var/obj/effect/decal/cleanable/vomit/spew = new(floor, get_static_viruses())
	bite.reagents.trans_to(spew, amount, transferred_by = src)

/mob/living/carbon/proc/spew_organ(power = 5, amt = 1)
	for(var/i in 1 to amt)
		if(!organs.len)
			break //Guess we're out of organs!
		var/obj/item/organ/guts = pick(organs)
		var/turf/T = get_turf(src)
		guts.Remove(src)
		guts.forceMove(T)
		var/atom/throw_target = get_edge_target_turf(guts, dir)
		guts.throw_at(throw_target, power, 4, src)


/mob/living/carbon/fully_replace_character_name(oldname,newname)
	. = ..()
	if(dna)
		dna.real_name = real_name
	var/obj/item/bodypart/head/my_head = get_bodypart(BODY_ZONE_HEAD)
	if(my_head)
		my_head.real_name = real_name


/mob/living/carbon/set_body_position(new_value)
	. = ..()
	if(isnull(.))
		return
	if(new_value == LYING_DOWN)
		add_movespeed_modifier(/datum/movespeed_modifier/carbon_crawling)
	else
		remove_movespeed_modifier(/datum/movespeed_modifier/carbon_crawling)


//Updates the mob's health from bodyparts and mob damage variables
/mob/living/carbon/updatehealth()
	if(status_flags & GODMODE)
		return

	var/total_brute = getBruteLoss()
	var/total_burn = getFireLoss()
	var/total_oxy = getOxyLoss()
	var/total_tox = getToxLoss()

	var/oldhp = health
	set_health(round(maxHealth - total_oxy - total_tox - total_burn - total_brute, DAMAGE_PRECISION))

	var/brutecon = round(-0.01 * (total_brute ** 1.5), 0.01)
	var/firecon =  round(-0.01 * (total_burn ** 1.5), 0.01)
	var/oxycon = HAS_TRAIT(src, TRAIT_NOBREATH) ? 0 : round(-1 * min(total_oxy * (total_oxy >= 100 ? 0.5 : 0.33), 100), 0.01)
	var/toxcon = HAS_TRAIT(src, TRAIT_TOXIMMUNE) ? 0 : round(-2 * (total_tox ** 0.75), 0.01)
	// To prevent nobreath/noblood species from being incredibly tanky, due to ignoring major sources of con damage,
	// we up their damage taken from brute and fire by 2x to compensate.
	if(HAS_TRAIT(src, TRAIT_NOBLOOD) || HAS_TRAIT(src, TRAIT_NOBREATH) || isnull(pain_controller))
		brutecon *= 2
		firecon *= 2
	// Ignores the helpers because we can handle them in bulk
	LAZYSET(consciousness_modifiers, BLUNT_DAMAGE, brutecon)
	LAZYSET(consciousness_modifiers, BURN_DAMAGE, firecon)
	LAZYSET(consciousness_modifiers, OXY_DAMAGE, oxycon)
	LAZYSET(consciousness_modifiers, TOX_DAMAGE, toxcon)

	var/oldcon = consciousness
	update_conscisouness()
	if(QDELETED(src))
		return

	var/to_update = NONE
	if(health != oldhp)
		to_update |= UPDATE_SELF_HEALTH|UPDATE_SELF_DAMAGE|UPDATE_MEDHUD_HEALTH
	if(consciousness != oldcon)
		to_update |= UPDATE_SELF_DAMAGE
	if(to_update)
		SShealth_updates.queue_update(src, to_update)

	if(total_burn > maxHealth * 4 && stat == DEAD && !HAS_TRAIT(src, TRAIT_UNHUSKABLE) && !HAS_TRAIT(src, TRAIT_HUSK))
		var/num_seared_parts = 0
		for(var/obj/item/bodypart/part as anything in bodyparts)
			if(IS_ROBOTIC_LIMB(part) || part.burn_dam <= (LIMB_MAX_HP_DEFAULT / 3))
				continue
			num_seared_parts++

		if(num_seared_parts >= 3)
			become_husk(BURN)

#ifdef HEALTH_DEBUG
	if(client && hud_used)
		hud_used.healthdoll.maptext_x = -50
		hud_used.healthdoll.maptext_height = 200
		hud_used.healthdoll.maptext_width = 75
		hud_used.healthdoll.maptext = MAPTEXT("Th: [health]\
			<br>Br: [total_brute]\
			<br>Bu: [total_burn]\
			<br>O: [total_oxy]\
			<br>T: [total_tox]\
			<br>Con: [consciousness]\
			<br>Pain: [pain_controller.get_total_pain()]\
			<br>Shock: [pain_controller.traumatic_shock]\
		")
#endif

	SEND_SIGNAL(src, COMSIG_LIVING_HEALTH_UPDATE)

/datum/movespeed_modifier/carbon_consciousness
	variable = TRUE
	flags = IGNORE_NOSLOW

/datum/actionspeed_modifier/carbon_consciousness
	variable = TRUE

/mob/living/proc/update_conscisouness()
	return

/mob/living/carbon/update_conscisouness()

	consciousness = CONSCIOUSNESS_MAX
	var/max_consciousness = UPPER_CONSCIOUSNESS_MAX

	for(var/mod in consciousness_modifiers)
		consciousness += consciousness_modifiers[mod]
	for(var/mult in consciousness_multipliers)
		consciousness *= consciousness_multipliers[mult]
	for(var/max_mod in max_consciousness_values)
		max_consciousness = min(max_consciousness_values[max_mod], max_consciousness)

	consciousness = min(round(consciousness, 0.01), max(max_consciousness, 10))

	update_stat() // may result in death
	if(QDELETED(src))
		return

	if(CONFIG_GET(flag/near_death_experience))
		if(consciousness >= 10)
			REMOVE_TRAIT(src, TRAIT_SIXTHSENSE, "near-death")
			clear_mood_event("near-death")
			unset_pain_mod(PAIN_MOD_NEAR_DEATH)
		else if(!HAS_TRAIT(src, TRAIT_NODEATH))
			ADD_TRAIT(src, TRAIT_SIXTHSENSE, "near-death")
			add_mood_event("near-death", /datum/mood_event/deaths_door)
			set_pain_mod(PAIN_MOD_NEAR_DEATH, 0.1)

	paincrit_check()

	if(consciousness <= 90)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/carbon_consciousness, multiplicative_slowdown = (HARD_CRIT_THRESHOLD / max(consciousness, 1)))
		add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/carbon_consciousness, multiplicative_slowdown = (HARD_CRIT_THRESHOLD / max(consciousness, 1)))
	else if(LAZYACCESS(movespeed_modification, "[/datum/movespeed_modifier/carbon_consciousness]"))
		remove_movespeed_modifier(/datum/movespeed_modifier/carbon_consciousness)
		remove_actionspeed_modifier(/datum/actionspeed_modifier/carbon_consciousness)

	SShealth_updates.queue_update(src, UPDATE_SELF|UPDATE_MEDHUD_HEALTH)

/mob/living/carbon/proc/paincrit_check()
	if(crit_percent() < 100 || HAS_TRAIT(src, TRAIT_NOSOFTCRIT)) // melbert todo
		if(HAS_TRAIT_FROM(src, TRAIT_SOFT_CRIT, PAINCRIT))
			Paralyze(2 SECONDS)
			remove_traits(list(TRAIT_SOFT_CRIT, TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), PAINCRIT)
		return

	if(HAS_TRAIT_FROM(src, TRAIT_SOFT_CRIT, PAINCRIT))
		return
	var/is_standing = body_position == STANDING_UP
	add_traits(list(TRAIT_SOFT_CRIT, TRAIT_INCAPACITATED, TRAIT_IMMOBILIZED, TRAIT_FLOORED, TRAIT_HANDS_BLOCKED), PAINCRIT)
	if(stat == DEAD)
		return
	if(buckled)
		visible_message(
			span_warning("[src] slumps against [buckled]!"),
			span_userdanger("You go limp, unable to move!"),
			visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
		)

	else if(is_standing && body_position != STANDING_UP)
		visible_message(
			span_warning("[src] collapses!"),
			span_userdanger("You collapse, unable to stand!"),
			visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
		)
	else if(body_position == LYING_DOWN)
		visible_message(
			span_warning("[src] slumps against the ground!"),
			span_userdanger("You go limp, unable to get up!"),
			visible_message_flags = ALWAYS_SHOW_SELF_MESSAGE,
		)
	else
		to_chat(src, span_userdanger("You can't will yourself to move!"))

/mob/living/carbon/update_sight()
	if(!client)
		return
	if(stat == DEAD)
		if(SSmapping.level_trait(z, ZTRAIT_NOXRAY))
			set_sight(null)
		else if(is_secret_level(z))
			set_sight(initial(sight))
		else
			set_sight(SEE_TURFS|SEE_MOBS|SEE_OBJS)
		set_invis_see(SEE_INVISIBLE_OBSERVER)
		return

	var/new_sight = initial(sight)
	lighting_cutoff = initial(lighting_cutoff)
	lighting_color_cutoffs = list(lighting_cutoff_red, lighting_cutoff_green, lighting_cutoff_blue)

	var/obj/item/organ/internal/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
	if(eyes)
		set_invis_see(eyes.see_invisible)
		new_sight |= eyes.sight_flags
		if(!isnull(eyes.lighting_cutoff))
			lighting_cutoff = eyes.lighting_cutoff
		if(!isnull(eyes.color_cutoffs))
			lighting_color_cutoffs = blend_cutoff_colors(lighting_color_cutoffs, eyes.color_cutoffs)

	if(client.eye && client.eye != src)
		var/atom/A = client.eye
		if(A.update_remote_sight(src)) //returns 1 if we override all other sight updates.
			return

	if(glasses)
		new_sight |= glasses.vision_flags
		if(glasses.invis_override)
			set_invis_see(glasses.invis_override)
		else
			set_invis_see(min(glasses.invis_view, see_invisible))
		if(!isnull(glasses.lighting_cutoff))
			lighting_cutoff = max(lighting_cutoff, glasses.lighting_cutoff)
		if(length(glasses.color_cutoffs))
			lighting_color_cutoffs = blend_cutoff_colors(lighting_color_cutoffs, glasses.color_cutoffs)

	if(HAS_TRAIT(src, TRAIT_TRUE_NIGHT_VISION))
		lighting_cutoff = max(lighting_cutoff, LIGHTING_CUTOFF_HIGH)

	if(HAS_TRAIT(src, TRAIT_MESON_VISION))
		new_sight |= SEE_TURFS
		lighting_cutoff = max(lighting_cutoff, LIGHTING_CUTOFF_MEDIUM)

	if(HAS_TRAIT(src, TRAIT_THERMAL_VISION))
		new_sight |= SEE_MOBS
		lighting_cutoff = max(lighting_cutoff, LIGHTING_CUTOFF_MEDIUM)

	if(HAS_TRAIT(src, TRAIT_XRAY_VISION))
		new_sight |= SEE_TURFS|SEE_MOBS|SEE_OBJS

	if(SSmapping.level_trait(z, ZTRAIT_NOXRAY))
		new_sight = NONE

	set_sight(new_sight)
	return ..()

/**
 * Calculates how visually impaired the mob is by their equipment and other factors
 *
 * This is where clothing adds its various vision limiting effects, such as welding helmets
 */
/mob/living/carbon/proc/update_tint()
	var/tint = 0
	if(isclothing(head))
		tint += head.tint
	if(isclothing(wear_mask))
		tint += wear_mask.tint
	if(isclothing(glasses))
		tint += glasses.tint

	var/obj/item/organ/internal/eyes/eyes = get_organ_slot(ORGAN_SLOT_EYES)
	if(eyes)
		tint += eyes.tint

	if(tint >= TINT_BLIND)
		become_blind(EYES_COVERED)

	else if(tint >= TINT_DARKENED)
		cure_blind(EYES_COVERED)
		overlay_fullscreen("tint", /atom/movable/screen/fullscreen/impaired, 2)

	else
		cure_blind(EYES_COVERED)
		clear_fullscreen("tint", 0 SECONDS)

/// Applies damage hud according to how conscious the mob is
/mob/living/carbon/proc/apply_crit_screen_overlay()
	if(HAS_TRAIT(src, TRAIT_NOCRITOVERLAY))
		clear_fullscreen("crit")
		return

	var/severity = clamp(round(crit_percent() / 15, 1), 0, 10)
	if(severity > 0)
		overlay_fullscreen("crit", /atom/movable/screen/fullscreen/crit, severity)
	else
		clear_fullscreen("crit")

/// Applies damage hud according to how much oxygen damage the mob has taken
/mob/living/carbon/proc/apply_oxy_screen_overlay()
	var/current_oxyloss = getOxyLoss()
	if(current_oxyloss <= 10)
		clear_fullscreen("oxy")
		return

	var/severity = clamp(round((current_oxyloss - 10) / 5 + 1, 1), 1, 7)
	overlay_fullscreen("oxy", /atom/movable/screen/fullscreen/oxy, severity)

/// Applies damage hud according to how much raw damage the mob has taken
/mob/living/carbon/proc/apply_damage_screen_overlay()
	var/hurtdamage = (pain_controller ? (pain_controller.get_total_pain() / 3) : (getBruteLoss() + getFireLoss())) + damageoverlaytemp
	if(hurtdamage <= 5)
		clear_fullscreen("brute")
		return

	var/severity = clamp(round((hurtdamage - 5) / 15, 1), 1, 6)
	overlay_fullscreen("brute", /atom/movable/screen/fullscreen/brute, severity)

/mob/living/carbon/update_damage_hud()
	if(!client)
		return

	apply_crit_screen_overlay()
	apply_oxy_screen_overlay()
	apply_damage_screen_overlay()

/// Determines how close we are to being in pain crit (Fully immobile)
/// Returns a number between -INFINITY to INFINITY, where 100 = in crit, >100 = probably about to die, <0 = super healthy
/mob/living/carbon/proc/crit_percent()
	var/con_percent = (CONSCIOUSNESS_MAX - consciousness) / (CONSCIOUSNESS_MAX - CONSCIOUSNESS_CRIT_THRESHOLD)
	var/shock_percent = (pain_controller?.traumatic_shock || 0) / SHOCK_CRIT_THRESHOLD
	var/pain_percent = (pain_controller?.get_total_pain() || 0) / PAIN_CRIT_THRESOLD
	var/softcrit_percent = (stat == SOFT_CRIT) ? 0.5 : 0
	return round(max(con_percent, shock_percent, pain_percent, softcrit_percent), 0.01) * 100

/mob/living/carbon/update_health_hud()
	if(!client || !hud_used?.healths)
		return

	if(stat == DEAD)
		hud_used.healths.icon_state = "health7"
		return

	if(SEND_SIGNAL(src, COMSIG_CARBON_UPDATING_HEALTH_HUD) & COMPONENT_OVERRIDE_HEALTH_HUD)
		return

	if(stat >= SOFT_CRIT)
		hud_used.healths.icon_state = "health6"
		return

	switch(100 - crit_percent())
		if(95 to INFINITY)
			hud_used.healths.icon_state = "health0"
		if(80 to 95)
			hud_used.healths.icon_state = "health1"
		if(60 to 80)
			hud_used.healths.icon_state = "health2"
		if(40 to 60)
			hud_used.healths.icon_state = "health3"
		if(20 to 40)
			hud_used.healths.icon_state = "health4"
		else
			hud_used.healths.icon_state = "health5"

/// Upsed specifically to update the spacesuit hud element
/mob/living/carbon/proc/update_spacesuit_hud_icon(cell_state = "empty")
	hud_used?.spacesuit?.icon_state = "spacesuit_[cell_state]"

/**
 * Adds a conscious modifier to the mob
 *
 * Only on living because I am lazy
 */
/mob/living/proc/add_consciousness_modifier(modifier, value)
	return

/mob/living/carbon/add_consciousness_modifier(modifier, value)
	if(LAZYACCESS(consciousness_modifiers, modifier) != value)
		LAZYSET(consciousness_modifiers, modifier, value)
		SShealth_updates.queue_update(src, UPDATE_CON)

/**
 * Removes a conscious modifier from the mob
 */
/mob/living/proc/remove_consciousness_modifier(modifier)
	return

/mob/living/carbon/remove_consciousness_modifier(modifier)
	if(LAZYACCESS(consciousness_modifiers, modifier))
		LAZYREMOVE(consciousness_modifiers, modifier)
		SShealth_updates.queue_update(src, UPDATE_CON)

/**
 * Adds a conscious multiplier to the mob
 *
 * Only on living because I am lazy
 */
/mob/living/proc/add_consciousness_multiplier(multiplier, value)
	return

/mob/living/carbon/add_consciousness_multiplier(multiplier, value)
	if(LAZYACCESS(consciousness_multipliers, multiplier) != value)
		LAZYSET(consciousness_multipliers, multiplier, value)
		SShealth_updates.queue_update(src, UPDATE_CON)

/**
 * Removes a conscious multiplier from the mob
 */
/mob/living/proc/remove_consciousness_multiplier(multiplier)
	return

/mob/living/carbon/remove_consciousness_multiplier(multiplier)
	if(LAZYACCESS(consciousness_multipliers, multiplier))
		LAZYREMOVE(consciousness_multipliers, multiplier)
		SShealth_updates.queue_update(src, UPDATE_CON)

/**
 * Adds a max consciousness value to the mob
 *
 * Only on living because I am lazy
 */
/mob/living/proc/add_max_consciousness_value(value, max_value)
	return

/mob/living/carbon/add_max_consciousness_value(value, max_value)
	if(LAZYACCESS(max_consciousness_values, value) != max_value)
		LAZYSET(max_consciousness_values, value, max_value)
		SShealth_updates.queue_update(src, UPDATE_CON)

/**
 * Removes a max consciousness value from the mob
 */
/mob/living/proc/remove_max_consciousness_value(value)
	return

/mob/living/carbon/remove_max_consciousness_value(value)
	if(LAZYACCESS(max_consciousness_values, value))
		LAZYREMOVE(max_consciousness_values, value)
		SShealth_updates.queue_update(src, UPDATE_CON)

/mob/living/carbon/update_stat()
	if(status_flags & GODMODE)
		if(stat != CONSCIOUS)
			set_stat(CONSCIOUS)
		return

	if(stat == DEAD) // You must manually set stat back to a non-death stat for revival
		return

	if(consciousness <= 0 && !HAS_TRAIT(src, TRAIT_NODEATH))
		if(stat != DEAD)
			death()
		return

	if(consciousness <= 30 && !HAS_TRAIT(src, TRAIT_NOHARDCRIT))
		if(stat != HARD_CRIT)
			set_stat(HARD_CRIT)
		return

	if(HAS_TRAIT(src, TRAIT_SOFT_CRIT) && !HAS_TRAIT(src, TRAIT_NOSOFTCRIT))
		if(stat != SOFT_CRIT)
			set_stat(SOFT_CRIT)
		return

	if(stat != CONSCIOUS)
		set_stat(CONSCIOUS)
		return

//called when we get cuffed/uncuffed
/mob/living/carbon/proc/update_handcuffed()
	if(handcuffed)
		drop_all_held_items()
		stop_pulling()
		throw_alert(ALERT_HANDCUFFED, /atom/movable/screen/alert/restrained/handcuffed, new_master = src.handcuffed)
		add_mood_event("handcuffed", /datum/mood_event/handcuffed)
	else
		clear_alert(ALERT_HANDCUFFED)
		clear_mood_event("handcuffed")
	update_mob_action_buttons() //some of our action buttons might be unusable when we're handcuffed.
	update_worn_handcuffs()
	update_hud_handcuffed()

/mob/living/carbon/revive(full_heal_flags = NONE, excess_healing = 0, force_grab_ghost = FALSE)
	if(excess_healing)
		if(dna && !HAS_TRAIT(src, TRAIT_NOBLOOD))
			blood_volume += (excess_healing * 2) //1 excess = 10 blood

		for(var/obj/item/organ/target_organ as anything in organs)
			if(!target_organ.damage)
				continue

			target_organ.apply_organ_damage(excess_healing * -1, required_organ_flag = ORGAN_ORGANIC) //1 excess = 5 organ damage healed

	. = ..()
	update_bodypart_bleed_overlays()

/mob/living/carbon/heal_and_revive(heal_to = 75, revive_message)
	// We can't heal them if they're missing a heart
	if(needs_heart() && !get_organ_slot(ORGAN_SLOT_HEART))
		return FALSE

	// We can't heal them if they're missing their lungs
	if(!HAS_TRAIT(src, TRAIT_NOBREATH) && !isnull(dna?.species.mutantlungs) && !get_organ_slot(ORGAN_SLOT_LUNGS))
		return FALSE

	// And we can't heal them if they're missing their liver
	if(!HAS_TRAIT(src, TRAIT_LIVERLESS_METABOLISM) && !isnull(dna?.species.mutantliver) && !get_organ_slot(ORGAN_SLOT_LIVER))
		return FALSE

	. = ..()
	if(.) // if revived successfully
		set_heartattack(FALSE)

	return .

/mob/living/carbon/fully_heal(heal_flags = HEAL_ALL)

	// Should be handled via signal on embedded, or via heal on bodypart
	// Otherwise I don't care to give it a separate flag
	remove_all_embedded_objects()

	if(heal_flags & HEAL_NEGATIVE_DISEASES)
		for(var/datum/disease/disease as anything in diseases)
			if(disease.severity != DISEASE_SEVERITY_POSITIVE)
				disease.cure(FALSE)

	if(heal_flags & HEAL_WOUNDS)
		for(var/datum/wound/wound as anything in all_wounds)
			wound.remove_wound()

	if(heal_flags & HEAL_LIMBS)
		regenerate_limbs()

	if(heal_flags & (HEAL_REFRESH_ORGANS|HEAL_ORGANS))
		regenerate_organs(regenerate_existing = (heal_flags & HEAL_REFRESH_ORGANS))

	if(heal_flags & HEAL_TRAUMAS)
		cure_all_traumas(TRAUMA_RESILIENCE_MAGIC)
		// Addictions are like traumas
		if(mind)
			for(var/addiction_type in subtypesof(/datum/addiction))
				mind.remove_addiction_points(addiction_type, MAX_ADDICTION_POINTS) //Remove the addiction!

	if(heal_flags & HEAL_RESTRAINTS)
		QDEL_NULL(handcuffed)
		QDEL_NULL(legcuffed)
		set_handcuffed(null)
		update_handcuffed()

	return ..()

/mob/living/carbon/do_strange_reagent_revival(healing_amount)
	set_heartattack(FALSE)
	return ..()

/mob/living/carbon/can_be_revived()
	if(HAS_TRAIT(src, TRAIT_HUSK))
		return FALSE
	if(!get_organ_by_type(/obj/item/organ/internal/brain) && (!IS_CHANGELING(src)))
		return FALSE
	return TRUE

/mob/living/carbon/proc/can_defib()
	if (HAS_TRAIT(src, TRAIT_SUICIDED))
		return DEFIB_FAIL_SUICIDE

	if (HAS_TRAIT(src, TRAIT_HUSK))
		return DEFIB_FAIL_HUSK

	if (HAS_TRAIT(src, TRAIT_DEFIB_BLACKLISTED))
		return DEFIB_FAIL_BLACKLISTED

	if(consciousness + /datum/status_effect/recent_defib::base_con < 0)
		return DEFIB_FAIL_CON

	// Only check for a heart if they actually need a heart. Who would've thunk
	if (needs_heart())
		var/obj/item/organ/internal/heart = get_organ_by_type(/obj/item/organ/internal/heart)

		if (!heart)
			return DEFIB_FAIL_NO_HEART

		if (heart.organ_flags & ORGAN_FAILING)
			return DEFIB_FAIL_FAILING_HEART

	var/obj/item/organ/internal/brain/current_brain = get_organ_by_type(/obj/item/organ/internal/brain)

	if (QDELETED(current_brain))
		return DEFIB_FAIL_NO_BRAIN

	if (current_brain.organ_flags & ORGAN_FAILING)
		return DEFIB_FAIL_FAILING_BRAIN

	if (current_brain.suicided || (current_brain.brainmob && HAS_TRAIT(current_brain.brainmob, TRAIT_SUICIDED)))
		return DEFIB_FAIL_NO_INTELLIGENCE

	if(key && key[1] == "@") // Adminghosts
		return DEFIB_NOGRAB_AGHOST

	return DEFIB_POSSIBLE

/mob/living/carbon/proc/can_defib_client()
	return (client || get_ghost(FALSE, TRUE)) && (can_defib() & DEFIB_REVIVABLE_STATES)

/mob/living/carbon/harvest(mob/living/user)
	if(QDELETED(src))
		return
	var/organs_amt = 0
	for(var/obj/item/organ/organ as anything in organs)
		if(prob(50))
			organs_amt++
			organ.Remove(src)
			organ.forceMove(drop_location())
	if(organs_amt)
		to_chat(user, span_notice("You retrieve some of [src]\'s internal organs!"))
	remove_all_embedded_objects()

/// Creates body parts for this carbon completely from scratch.
/// Optionally takes a map of body zones to what type to instantiate instead of them.
/mob/living/carbon/proc/create_bodyparts(list/overrides)
	var/list/bodyparts_paths = bodyparts.Copy()
	bodyparts = list()
	for(var/obj/item/bodypart/bodypart_path as anything in bodyparts_paths)
		var/real_body_part_path = overrides?[initial(bodypart_path.body_zone)] || bodypart_path
		var/obj/item/bodypart/bodypart_instance = new real_body_part_path()
		add_bodypart(bodypart_instance)

/// Called when a new hand is added
/mob/living/carbon/proc/on_added_hand(obj/item/bodypart/arm/new_hand, hand_index)
	if(hand_index > hand_bodyparts.len)
		hand_bodyparts.len = hand_index
	hand_bodyparts[hand_index] = new_hand

/// Cleans up references to a hand when it is dismembered or deleted
/mob/living/carbon/proc/on_lost_hand(obj/item/bodypart/arm/lost_hand)
	hand_bodyparts[lost_hand.held_index] = null

///Proc to hook behavior on bodypart additions. Do not directly call. You're looking for [/obj/item/bodypart/proc/try_attach_limb()].
/mob/living/carbon/proc/add_bodypart(obj/item/bodypart/new_bodypart)
	SHOULD_NOT_OVERRIDE(TRUE)

	new_bodypart.on_adding(src)
	bodyparts += new_bodypart
	new_bodypart.update_owner(src)

	for(var/obj/item/organ/organ in new_bodypart)
		organ.mob_insert(src)

	switch(new_bodypart.body_part)
		if(LEG_LEFT, LEG_RIGHT)
			set_num_legs(num_legs + 1)
			if(!new_bodypart.bodypart_disabled)
				set_usable_legs(usable_legs + 1)
		if(ARM_LEFT, ARM_RIGHT)
			set_num_hands(num_hands + 1)
			if(!new_bodypart.bodypart_disabled)
				set_usable_hands(usable_hands + 1)

	synchronize_bodytypes()

///Proc to hook behavior on bodypart removals.  Do not directly call. You're looking for [/obj/item/bodypart/proc/drop_limb()].
/mob/living/carbon/proc/remove_bodypart(obj/item/bodypart/old_bodypart, special)
	SHOULD_NOT_OVERRIDE(TRUE)

	if(special)
		for(var/obj/item/organ/organ in old_bodypart)
			organ.bodypart_remove(limb_owner = src, movement_flags = NO_ID_TRANSFER)
	else
		for(var/obj/item/organ/organ in old_bodypart)
			organ.mob_remove(src, special)

	old_bodypart.on_removal(src)
	bodyparts -= old_bodypart

	switch(old_bodypart.body_part)
		if(LEG_LEFT, LEG_RIGHT)
			set_num_legs(num_legs - 1)
			if(!old_bodypart.bodypart_disabled)
				set_usable_legs(usable_legs - 1)
		if(ARM_LEFT, ARM_RIGHT)
			set_num_hands(num_hands - 1)
			if(!old_bodypart.bodypart_disabled)
				set_usable_hands(usable_hands - 1)

	synchronize_bodytypes()

///Updates the bodypart speed modifier based on our bodyparts.
/mob/living/carbon/proc/update_bodypart_speed_modifier()
	var/final_modification = 0
	for(var/obj/item/bodypart/bodypart as anything in bodyparts)
		final_modification += bodypart.speed_modifier
	add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/bodypart, update = TRUE, multiplicative_slowdown = final_modification)

/mob/living/carbon/proc/create_internal_organs()
	for(var/obj/item/organ/internal/internal_organ in organs)
		internal_organ.Insert(src)

/proc/cmp_organ_slot_asc(slot_a, slot_b)
	return GLOB.organ_process_order.Find(slot_a) - GLOB.organ_process_order.Find(slot_b)

/mob/living/carbon/vv_get_dropdown()
	. = ..()
	VV_DROPDOWN_OPTION("", "---------")
	VV_DROPDOWN_OPTION(VV_HK_MODIFY_BODYPART, "Modify bodypart")
	VV_DROPDOWN_OPTION(VV_HK_MODIFY_ORGANS, "Modify organs")
	VV_DROPDOWN_OPTION(VV_HK_MARTIAL_ART, "Give Martial Arts")
	VV_DROPDOWN_OPTION(VV_HK_GIVE_TRAUMA, "Give Brain Trauma")
	VV_DROPDOWN_OPTION(VV_HK_CURE_TRAUMA, "Cure Brain Traumas")

/mob/living/carbon/vv_do_topic(list/href_list)
	. = ..()

	if(!.)
		return

	if(href_list[VV_HK_MODIFY_BODYPART])
		if(!check_rights(R_SPAWN))
			return
		var/edit_action = input(usr, "What would you like to do?","Modify Body Part") as null|anything in list("replace","remove")
		if(!edit_action)
			return
		var/list/limb_list = list()
		if(edit_action == "remove")
			for(var/obj/item/bodypart/B as anything in bodyparts)
				limb_list += B.body_zone
				limb_list -= BODY_ZONE_CHEST
		else
			limb_list = list(BODY_ZONE_HEAD, BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_CHEST)
		var/result = input(usr, "Please choose which bodypart to [edit_action]","[capitalize(edit_action)] Bodypart") as null|anything in sort_list(limb_list)
		if(result)
			var/obj/item/bodypart/BP = get_bodypart(result)
			var/list/limbtypes = list()
			switch(result)
				if(BODY_ZONE_CHEST)
					limbtypes = typesof(/obj/item/bodypart/chest)
				if(BODY_ZONE_R_ARM)
					limbtypes = typesof(/obj/item/bodypart/arm/right)
				if(BODY_ZONE_L_ARM)
					limbtypes = typesof(/obj/item/bodypart/arm/left)
				if(BODY_ZONE_HEAD)
					limbtypes = typesof(/obj/item/bodypart/head)
				if(BODY_ZONE_L_LEG)
					limbtypes = typesof(/obj/item/bodypart/leg/left)
				if(BODY_ZONE_R_LEG)
					limbtypes = typesof(/obj/item/bodypart/leg/right)
			switch(edit_action)
				if("remove")
					if(BP)
						BP.drop_limb()
						admin_ticket_log("[key_name_admin(usr)] has removed [src]'s [parse_zone(BP.body_zone)]")
					else
						to_chat(usr, span_boldwarning("[src] doesn't have such bodypart."))
						admin_ticket_log("[key_name_admin(usr)] has attempted to modify the bodyparts of [src]")
				if("replace")
					var/limb2add = input(usr, "Select a bodypart type to add", "Add/Replace Bodypart") as null|anything in sort_list(limbtypes)
					var/obj/item/bodypart/new_bp = new limb2add()
					if(new_bp.replace_limb(src, special = TRUE))
						admin_ticket_log("key_name_admin(usr)] has replaced [src]'s [BP.type] with [new_bp.type]")
						qdel(BP)
					else
						to_chat(usr, "Failed to replace bodypart! They might be incompatible.")
						admin_ticket_log("[key_name_admin(usr)] has attempted to modify the bodyparts of [src]")

	if(href_list[VV_HK_MODIFY_ORGANS])
		return SSadmin_verbs.dynamic_invoke_verb(usr, /datum/admin_verb/manipulate_organs, src)

	if(href_list[VV_HK_MARTIAL_ART])
		if(!check_rights(NONE))
			return
		var/list/artpaths = subtypesof(/datum/martial_art)
		var/list/artnames = list()
		for(var/i in artpaths)
			var/datum/martial_art/M = i
			artnames[initial(M.name)] = M
		var/result = input(usr, "Choose the martial art to teach","JUDO CHOP") as null|anything in sort_list(artnames, GLOBAL_PROC_REF(cmp_typepaths_asc))
		if(!usr)
			return
		if(QDELETED(src))
			to_chat(usr, span_boldwarning("Mob doesn't exist anymore."))
			return
		if(result)
			var/chosenart = artnames[result]
			var/datum/martial_art/MA = new chosenart
			MA.teach(src)
			log_admin("[key_name(usr)] has taught [MA] to [key_name(src)].")
			message_admins(span_notice("[key_name_admin(usr)] has taught [MA] to [key_name_admin(src)]."))

	if(href_list[VV_HK_GIVE_TRAUMA])
		if(!check_rights(NONE))
			return
		var/list/traumas = subtypesof(/datum/brain_trauma)
		var/result = input(usr, "Choose the brain trauma to apply","Traumatize") as null|anything in sort_list(traumas, GLOBAL_PROC_REF(cmp_typepaths_asc))
		if(!usr)
			return
		if(QDELETED(src))
			to_chat(usr, "Mob doesn't exist anymore")
			return
		if(!result)
			return
		var/datum/brain_trauma/BT = gain_trauma(result)
		if(BT)
			log_admin("[key_name(usr)] has traumatized [key_name(src)] with [BT.name]")
			message_admins(span_notice("[key_name_admin(usr)] has traumatized [key_name_admin(src)] with [BT.name]."))

	if(href_list[VV_HK_CURE_TRAUMA])
		if(!check_rights(NONE))
			return
		cure_all_traumas(TRAUMA_RESILIENCE_ABSOLUTE)
		log_admin("[key_name(usr)] has cured all traumas from [key_name(src)].")
		message_admins(span_notice("[key_name_admin(usr)] has cured all traumas from [key_name_admin(src)]."))

/mob/living/carbon/can_resist()
	return bodyparts.len > 2 && ..()

/mob/living/carbon/proc/hypnosis_vulnerable()
	if(HAS_TRAIT(src, TRAIT_MINDSHIELD))
		return FALSE
	if(has_status_effect(/datum/status_effect/hallucination) || has_status_effect(/datum/status_effect/drugginess))
		return TRUE
	if(IsSleeping() || IsUnconscious())
		return TRUE
	if(HAS_TRAIT(src, TRAIT_DUMB))
		return TRUE
	if(mob_mood.sanity < SANITY_UNSTABLE)
		return TRUE

/mob/living/carbon/wash(clean_types)
	. = ..()

	// Wash equipped stuff that cannot be covered
	for(var/obj/item/held_thing in held_items)
		if(held_thing.wash(clean_types))
			. = TRUE

	if(back?.wash(clean_types))
		update_worn_back(0)
		. = TRUE

	if(head?.wash(clean_types))
		update_worn_head()
		. = TRUE

	// Check and wash stuff that can be covered
	var/obscured = check_obscured_slots()

	// If the eyes are covered by anything but glasses, that thing will be covering any potential glasses as well.
	if(glasses && is_eyes_covered(ITEM_SLOT_MASK|ITEM_SLOT_HEAD) && glasses.wash(clean_types))
		update_worn_glasses()
		. = TRUE

	if(wear_mask && !(obscured & ITEM_SLOT_MASK) && wear_mask.wash(clean_types))
		update_worn_mask()
		. = TRUE

	if(ears && !(obscured & ITEM_SLOT_EARS) && ears.wash(clean_types))
		update_inv_ears()
		. = TRUE

	if(wear_neck && !(obscured & ITEM_SLOT_NECK) && wear_neck.wash(clean_types))
		update_worn_neck()
		. = TRUE

	if(shoes && !(obscured & ITEM_SLOT_FEET) && shoes.wash(clean_types))
		update_worn_shoes()
		. = TRUE

	if(gloves && !(obscured & ITEM_SLOT_GLOVES) && gloves.wash(clean_types))
		update_worn_gloves()
		. = TRUE

/// if any of our bodyparts are bleeding
/mob/living/carbon/proc/is_bleeding()
	if(HAS_TRAIT(src, TRAIT_NOBLOOD))
		return FALSE
	for(var/obj/item/bodypart/part as anything in bodyparts)
		if(part.get_modified_bleed_rate())
			return TRUE
	return FALSE

/// get our total bleedrate
/mob/living/carbon/proc/get_total_bleed_rate()
	if(HAS_TRAIT(src, TRAIT_NOBLOOD))
		return 0

	var/total_bleed_rate = 0
	for(var/obj/item/bodypart/part as anything in bodyparts)
		total_bleed_rate += part.get_modified_bleed_rate()

	return total_bleed_rate

/**
 * generate_fake_scars()- for when you want to scar someone, but you don't want to hurt them first. These scars don't count for temporal scarring (hence, fake)
 *
 * If you want a specific wound scar, pass that wound type as the second arg, otherwise you can pass a list like WOUND_LIST_SLASH to generate a random cut scar.
 *
 * Arguments:
 * * num_scars- A number for how many scars you want to add
 * * forced_type- Which wound or category of wounds you want to choose from, WOUND_LIST_BLUNT, WOUND_LIST_SLASH, or WOUND_LIST_BURN (or some combination). If passed a list, picks randomly from the listed wounds. Defaults to all 3 types
 */
/mob/living/carbon/proc/generate_fake_scars(num_scars, forced_type)
	for(var/i in 1 to num_scars)
		var/datum/scar/scaries = new
		var/obj/item/bodypart/scar_part = pick(bodyparts)

		var/wound_type
		if(forced_type)
			if(islist(forced_type))
				wound_type = pick(forced_type)
			else
				wound_type = forced_type
		else
			for (var/datum/wound/path as anything in shuffle(GLOB.all_wound_pregen_data))
				var/datum/wound_pregen_data/pregen_data = GLOB.all_wound_pregen_data[path]
				if (pregen_data.can_be_applied_to(scar_part, random_roll = TRUE))
					wound_type = path
					break

		if (wound_type) // can feasibly happen, if its an inorganic limb/cant be wounded/scarred
			var/datum/wound/phantom_wound = new wound_type
			scaries.generate(scar_part, phantom_wound)
			scaries.fake = TRUE
			QDEL_NULL(phantom_wound)

/mob/living/carbon/is_face_visible()
	return !(wear_mask?.flags_inv & HIDEFACE) && !(head?.flags_inv & HIDEFACE)

/// Returns whether or not the carbon should be able to be shocked
/mob/living/carbon/proc/should_electrocute(power_source)
	if (ismecha(loc))
		return FALSE

	if (wearing_shock_proof_gloves())
		return FALSE

	if(!get_powernet_info_from_source(power_source))
		return FALSE

	if (HAS_TRAIT(src, TRAIT_SHOCKIMMUNE))
		return FALSE

	return TRUE

/// Returns if the carbon is wearing shock proof gloves
/mob/living/carbon/proc/wearing_shock_proof_gloves()
	return gloves?.siemens_coefficient == 0

/// Modifies max_skillchip_count and updates active skillchips
/mob/living/carbon/proc/adjust_skillchip_complexity_modifier(delta)
	skillchip_complexity_modifier += delta

	var/obj/item/organ/internal/brain/brain = get_organ_slot(ORGAN_SLOT_BRAIN)

	if(!brain)
		return

	brain.update_skillchips()


/// Modifies the handcuffed value if a different value is passed, returning FALSE otherwise. The variable should only be changed through this proc.
/mob/living/carbon/proc/set_handcuffed(new_value)
	if(handcuffed == new_value)
		return FALSE
	. = handcuffed
	handcuffed = new_value
	if(.)
		if(!handcuffed)
			REMOVE_TRAIT(src, TRAIT_RESTRAINED, HANDCUFFED_TRAIT)
	else if(handcuffed)
		ADD_TRAIT(src, TRAIT_RESTRAINED, HANDCUFFED_TRAIT)

/mob/living/carbon/on_standing_up()
	. = ..()
	update_bodypart_bleed_overlays()

/mob/living/carbon/on_lying_down(new_lying_angle)
	. = ..()
	if(!buckled || buckled.buckle_lying != 0)
		lying_angle_on_lying_down(new_lying_angle)
	update_bodypart_bleed_overlays()

/// Special carbon interaction on lying down, to transform its sprite by a rotation.
/mob/living/carbon/proc/lying_angle_on_lying_down(new_lying_angle)
	if(!new_lying_angle)
		set_lying_angle(pick(LYING_ANGLE_EAST, LYING_ANGLE_WEST))
	else
		set_lying_angle(new_lying_angle)

/mob/living/carbon/vv_edit_var(var_name, var_value)
	switch(var_name)
		if(NAMEOF(src, disgust))
			set_disgust(var_value)
			. = TRUE
		if(NAMEOF(src, handcuffed))
			set_handcuffed(var_value)
			. = TRUE

	if(!isnull(.))
		datum_flags |= DF_VAR_EDITED
		return

	return ..()

/mob/living/carbon/get_attack_type()
	if(has_active_hand())
		var/obj/item/bodypart/arm/active_arm = get_active_hand()
		return active_arm.attack_type
	return ..()

/mob/living/carbon/proc/attach_rot()
	if(flags_1 & HOLOGRAM_1)
		return
	if(!(mob_biotypes & (MOB_ORGANIC|MOB_UNDEAD)))
		return
	AddComponent(/datum/component/rot, 6 MINUTES, 10 MINUTES, 1)

/**
 * This proc is used to determine whether or not the mob can handle touching an acid affected object.
 */
/mob/living/carbon/proc/can_touch_acid(atom/acided_atom, acid_power, acid_volume)
	// So people can take their own clothes off
	if((acided_atom == src) || (acided_atom.loc == src))
		return TRUE
	if((acid_power * acid_volume) < ACID_LEVEL_HANDBURN)
		return TRUE
	if(gloves?.resistance_flags & (UNACIDABLE | ACID_PROOF))
		return TRUE
	return FALSE

/**
 * This proc is used to determine whether or not the mob can handle touching a burning object.
 */
/mob/living/carbon/proc/can_touch_burning(atom/burning_atom, acid_power, acid_volume)
	// So people can take their own clothes off
	if((burning_atom == src) || (burning_atom.loc == src))
		return TRUE
	if(HAS_TRAIT(src, TRAIT_RESISTHEAT) || HAS_TRAIT(src, TRAIT_RESISTHEATHANDS))
		return TRUE
	if(gloves?.max_heat_protection_temperature >= BURNING_ITEM_MINIMUM_TEMPERATURE)
		return TRUE
	return FALSE

/**
 * This proc is a helper for spraying blood for things like slashing/piercing wounds and dismemberment.
 *
 * The strength of the splatter in the second argument determines how much it can dirty and how far it can go
 *
 * Arguments:
 * * splatter_direction: Which direction the blood is flying
 * * splatter_strength: How many tiles it can go, and how many items it can pass over and dirty
 */
/mob/living/carbon/proc/spray_blood(splatter_direction, splatter_strength = 3)
	if(!isturf(loc))
		return
	var/obj/effect/decal/cleanable/blood/hitsplatter/our_splatter = new(loc, get_static_viruses(), splatter_strength)
	our_splatter.add_blood_DNA(GET_ATOM_BLOOD_DNA(src))
	our_splatter.blood_dna_info = get_blood_dna_list()
	var/turf/targ = get_ranged_target_turf(src, splatter_direction, splatter_strength)
	our_splatter.fly_towards(targ, splatter_strength)

/mob/living/carbon/dropItemToGround(obj/item/item, force = FALSE, silent = FALSE, invdrop = TRUE)
	if(item && ((item in organs) || (item in bodyparts))) //let's not do this, aight?
		return FALSE
	return ..()

/// Helper to cleanly trigger tail wagging
/// Accepts an optional timeout after which we remove the tail wagging
/// Returns true if successful, false otherwise
/mob/living/carbon/proc/wag_tail(timeout = INFINITY)
	var/obj/item/organ/external/tail/wagged = get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL)
	if(!wagged)
		return FALSE
	return wagged.start_wag(src, timeout)

/// Helper to cleanly stop all tail wagging
/// Returns true if successful, false otherwise
/mob/living/carbon/proc/unwag_tail() // can't unwag a tail
	var/obj/item/organ/external/tail/unwagged = get_organ_slot(ORGAN_SLOT_EXTERNAL_TAIL)
	if(!unwagged)
		return FALSE
	return unwagged.stop_wag(src)

/mob/living/carbon/ominous_nosebleed()
	var/obj/item/bodypart/head = get_bodypart(BODY_ZONE_HEAD)
	if(isnull(head))
		return ..()
	if(HAS_TRAIT(src, TRAIT_NOBLOOD))
		to_chat(src, span_notice("You get a headache."))
		return
	head.adjustBleedStacks(5)
	visible_message(span_notice("[src] gets a nosebleed."), span_warning("You get a nosebleed."))
