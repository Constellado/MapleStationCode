/mob/living
	see_invisible = SEE_INVISIBLE_LIVING
	hud_possible = list(HEALTH_HUD,STATUS_HUD,ANTAG_HUD)
	pressure_resistance = 10
	hud_type = /datum/hud/living
	interaction_flags_click = ALLOW_RESTING
	interaction_flags_mouse_drop = ALLOW_RESTING

	///Tracks the current size of the mob in relation to its original size. Use update_transform(resize) to change it.
	var/current_size = RESIZE_DEFAULT_SIZE
	var/lastattacker = null
	var/lastattackerckey = null

	//Health and life related vars
	/// Maximum health that should be possible.
	var/maxHealth = MAX_LIVING_HEALTH
	/// The mob's current health.
	var/health = MAX_LIVING_HEALTH

	/// The max amount of stamina damage we can have at once
	var/max_stamina = 120
	/// Basically, amount of fatigue
	/// Having a lot of it slows down your movement speed
	/// Also often used for "fake damage"
	var/staminaloss = 0

	/**
	 * How conscious is the mob?
	 *
	 * This is, effectively, the mob's REAL health.
	 * It is a cumulative value of many factors, including health, wounds, diseases, and so on.
	 *
	 * 0 is death. 100 is default. 150 is the maximum.
	 */
	var/consciousness = CONSCIOUSNESS_MAX
	/// Assoc Lazylist of flat modifiers to consciousness.
	var/list/consciousness_modifiers
	/// Assoc Lazylist of multipliers to consciousness. Applied after modifiers.
	var/list/consciousness_multipliers
	/// Assoc Lazylist of max consciousness values. Smallest one is used, but not beyond 10.
	/// Don't increase max consciousness (over 150), that makes no sense.
	var/list/max_consciousness_values

	/// Modified applied to attacks with items or fists
	var/outgoing_damage_mod = 1

	//Damage related vars, NOTE: THESE SHOULD ONLY BE MODIFIED BY PROCS
	///Brutal damage caused by brute force (punching, being clubbed by a toolbox ect... this also accounts for pressure damage)
	var/bruteloss = 0
	///Oxygen depravation damage (no air in lungs)
	var/oxyloss = 0
	///Toxic damage caused by being poisoned or radiated
	var/toxloss = 0
	///Burn damage caused by being way too hot, too cold or burnt.
	var/fireloss = 0

	/// The movement intent of the mob (run/wal)
	var/move_intent = MOVE_INTENT_RUN

	/// Rate at which fire stacks should decay from this mob
	var/fire_stack_decay_rate = -0.05

	//Damage dealing vars! These are meaningless outside of specific instances where it's checked and defined.
	/// Lower bound of damage done by unarmed melee attacks. Mob code is a mess, only works where this is checked for.
	var/melee_damage_lower = 0
	/// Upper bound of damage done by unarmed melee attacks. Please ensure you check the xyz_defenses.dm for the mobs in question to see if it uses this or hardcoded values.
	var/melee_damage_upper = 0

	/// Generic bitflags for boolean conditions at the [/mob/living] level. Keep this for inherent traits of living types, instead of runtime-changeable ones.
	var/living_flags = NONE

	/// Flags that determine the potential of a mob to perform certain actions. Do not change this directly.
	var/mobility_flags = MOBILITY_FLAGS_DEFAULT

	var/resting = FALSE

	/// Variable to track the body position of a mob, regardgless of the actual angle of rotation (usually matching it, but not necessarily).
	var/body_position = STANDING_UP
	/// Number of degrees of rotation of a mob. 0 means no rotation, up-side facing NORTH. 90 means up-side rotated to face EAST, and so on.
	VAR_PROTECTED/lying_angle = 0
	/// Value of lying lying_angle before last change. TODO: Remove the need for this.
	var/lying_prev = 0
	/// Does the mob rotate when lying
	var/rotate_on_lying = FALSE
	///Used by the resist verb, likely used to prevent players from bypassing next_move by logging in/out.
	var/last_special = 0

	///A message sent when the mob dies, with the *deathgasp emote
	var/death_message = ""
	///A sound sent when the mob dies, with the *deathgasp emote
	var/death_sound

	/// Helper vars for quick access to firestacks, these should be updated every time firestacks are adjusted
	var/on_fire = FALSE
	var/fire_stacks = 0

	/**
	  * Allows mobs to move through dense areas without restriction. For instance, in space or out of holder objects.
	  *
	  * FALSE is off, [INCORPOREAL_MOVE_BASIC] is normal, [INCORPOREAL_MOVE_SHADOW] is for ninjas
	  * and [INCORPOREAL_MOVE_JAUNT] is blocked by holy water/salt
	  */
	var/incorporeal_move = FALSE

	var/list/quirks
	///a list of surgery datums. generally empty, they're added when the player wants them.
	var/list/surgeries = list()
	/// Lazylist of surgery speed modifiers
	var/list/mob_surgery_speed_mods

	/// Used by [living/Bump()][/mob/living/proc/Bump] and [living/PushAM()][/mob/living/proc/PushAM] to prevent potential infinite loop.
	var/now_pushing = null

	///The mob's latest time-of-death
	var/timeofdeath = 0
	///The mob's latest time-of-death, as a station timestamp instead of world.time
	var/station_timestamp_timeofdeath

	/// Sets AI behavior that allows mobs to target and dismember limbs with their basic attack.
	var/limb_destroyer = 0

	var/mob_size = MOB_SIZE_HUMAN
	/// List of biotypes the mob belongs to. Used by diseases and reagents mainly.
	var/mob_biotypes = MOB_ORGANIC
	/// The type of respiration the mob is capable of doing. Used by adjustOxyLoss.
	var/mob_respiration_type = RESPIRATION_OXYGEN
	/// How efficient are we at metabolizing reagents and regulating body temperature?
	/// Note: Do not set this for mobs with stomach organs, as the stomach overrides this value entirely.
	var/metabolism_efficiency = 1
	///does the mob have distinct limbs?(arms,legs, chest,head)
	var/has_limbs = FALSE

	///How many legs does this mob have by default. This shouldn't change at runtime.
	var/default_num_legs = 2
	///How many legs does this mob currently have. Should only be changed through set_num_legs()
	var/num_legs = 2
	///How many usable legs this mob currently has. Should only be changed through set_usable_legs()
	var/usable_legs = 2

	///How many hands does this mob have by default. This shouldn't change at runtime.
	var/default_num_hands = 2
	///How many hands hands does this mob currently have. Should only be changed through set_num_hands()
	var/num_hands = 2
	///How many usable hands does this mob currently have. Should only be changed through set_usable_hands()
	var/usable_hands = 2

	var/list/pipes_shown = list()
	var/last_played_vent = 0
	/// The last direction we moved in a vent. Used to make holding two directions feel nice
	var/last_vent_dir = 0
	/// Cell tracker datum we use to manage the pipes around us, for faster ventcrawling
	/// Should only exist if you're in a pipe
	var/datum/cell_tracker/pipetracker

	var/smoke_delay = 0 ///used to prevent spam with smoke reagent reaction on mob.

	///what icon the mob uses for speechbubbles
	var/bubble_icon = "default"
	///if this exists AND the normal sprite is bigger than 32x32, this is the replacement icon state (because health doll size limitations). the icon will always be screen_gen.dmi
	var/health_doll_icon

	var/last_bumped = 0
	///if a mob's name should be appended with an id when created e.g. Mob (666)
	var/unique_name = FALSE
	///the id a mob gets when it's created
	var/numba = 0

	///these will be yielded from butchering with a probability chance equal to the butcher item's effectiveness
	var/list/butcher_results = null
	///these will always be yielded from butchering
	var/list/guaranteed_butcher_results = null
	///effectiveness prob. is modified negatively by this amount; positive numbers make it more difficult, negative ones make it easier
	var/butcher_difficulty = 0

	///how much blood the mob has
	var/blood_volume = 0

	///a list of all status effects the mob has
	var/list/status_effects
	var/list/implants = null

	///used for database logging
	var/last_words

	///whether this can be picked up and held.
	var/can_be_held = FALSE
	/// The w_class of the holder when held.
	var/held_w_class = WEIGHT_CLASS_NORMAL
	///if it can be held, can it be equipped to any slots? (think pAI's on head)
	var/worn_slot_flags = NONE

	var/ventcrawl_layer = PIPING_LAYER_DEFAULT
	var/losebreath = 0

	//List of active diseases
	/// list of all diseases in a mob
	var/list/diseases
	var/list/disease_resistances

	///Whether the mob is slowed down when dragging another prone mob
	var/slowed_by_drag = TRUE

	//this stuff is here to make it simple for admins to mess with custom held sprites
	///left hand icon for holding mobs
	var/icon/held_lh = 'icons/mob/inhands/pets_held_lh.dmi'
	///right hand icon for holding mobs
	var/icon/held_rh = 'icons/mob/inhands/pets_held_rh.dmi'
	///what it looks like when the mob is held on your head
	var/icon/head_icon = 'icons/mob/clothing/head/pets_head.dmi'
	/// icon_state for holding mobs.
	var/held_state = ""

	///If combat mode is on or not
	var/combat_mode = FALSE

	/// Is this mob allowed to be buckled/unbuckled to/from things?
	var/can_buckle_to = TRUE

	///The height offset of a mob's maptext due to their current size.
	var/body_maptext_height_offset = 0

	/// FOV view that is applied from either nativeness or traits
	var/fov_view
	/// Lazy list of FOV traits that will apply a FOV view when handled.
	var/list/fov_traits
	///what multiplicative slowdown we get from turfs currently.
	var/current_turf_slowdown = 0

	/// Living mob's mood datum
	var/datum/mood/mob_mood

	// Multiple imaginary friends!
	/// Contains the owner and all imaginary friend mobs if they exist, otherwise null
	var/list/imaginary_group = null

	/// What our current gravity state is. Used to avoid duplicate animates and such
	var/gravity_state = null

	/// Body temp we homeostasize to
	var/standard_body_temperature = BODYTEMP_NORMAL
	/// Temperature of our insides
	var/body_temperature = BODYTEMP_NORMAL
	/// Lazylist of targets we homeostasize to
	/// This allows multiple effects to add a different target to the list, which is averaged
	/// (So you can have both a fever and a cold at the same time)
	/// If empty just defaults to standard_body_temperature
	var/list/homeostasis_targets

	/// How cold to start sustaining cold damage
	var/bodytemp_cold_damage_limit = -1 // -1 = no cold damage ever
	/// How hot to start sustaining heat damage
	var/bodytemp_heat_damage_limit = INFINITY // INFINITY = no heat damage ever

	/// How fast the mob's temperature normalizes to their environment
	var/temperature_normalization_speed = 0.1
	/// How fast the mob's temperature normalizes to their homeostasis
	/// Also gets multiplied by metabolism_efficiency.
	/// Note that more of this = more nutrition is consumed every life tick.
	var/temperature_homeostasis_speed = 0.5
	/// Protection (insulation) from temperature changes, max 1
	var/temperature_insulation = 0

	/// Whether we currently have temp alerts, minor optimization
	VAR_PRIVATE/temp_alerts = FALSE

	/// Lazylists of pixel offsets this mob is currently using
	/// Modify this via add_offsets and remove_offsets,
	/// NOT directly (and definitely avoid modifying offsets directly)
	VAR_PRIVATE/list/offsets
