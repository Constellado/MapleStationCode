///Called from /datum/species/proc/help : (mob/living/carbon/human/helper, datum/martial_art/helper_style)
#define COMSIG_CARBON_PRE_HELP "carbon_pre_help"
	/// Stops the rest of the help
	#define COMPONENT_BLOCK_HELP_ACT (1<<0)

///Called from /mob/living/carbon/help_shake_act, before any hugs have ocurred. (mob/living/helper)
#define COMSIG_CARBON_PRE_MISC_HELP "carbon_pre_misc_help"
	/// Stops the rest of help act (hugging, etc) from occuring
	#define COMPONENT_BLOCK_MISC_HELP (1<<0)

///Called from /mob/living/carbon/help_shake_act on the person being helped, after any hugs have ocurred. (mob/living/helper)
#define COMSIG_CARBON_HELP_ACT "carbon_help"
///Called from /mob/living/carbon/help_shake_act on the helper, after any hugs have ocurred. (mob/living/helped)
#define COMSIG_CARBON_HELPED "carbon_helped_someone"

///When a carbon slips. Called on /turf/open/handle_slip()
#define COMSIG_ON_CARBON_SLIP "carbon_slip"
// /mob/living/carbon physiology signals
#define COMSIG_CARBON_GAIN_WOUND "carbon_gain_wound" //from /datum/wound/proc/apply_wound() (/mob/living/carbon/C, /datum/wound/W, /obj/item/bodypart/L)
#define COMSIG_CARBON_LOSE_WOUND "carbon_lose_wound" //from /datum/wound/proc/remove_wound() (/mob/living/carbon/C, /datum/wound/W, /obj/item/bodypart/L)
/// Called after limb AND victim has been unset
#define COMSIG_CARBON_POST_LOSE_WOUND "carbon_post_lose_wound" //from /datum/wound/proc/remove_wound() (/datum/wound/lost_wound, /obj/item/bodypart/part, ignore_limb, replaced)
///from base of /obj/item/bodypart/proc/can_attach_limb(): (new_limb, special) allows you to fail limb attachment
#define COMSIG_ATTEMPT_CARBON_ATTACH_LIMB "attempt_carbon_attach_limb"
	#define COMPONENT_NO_ATTACH (1<<0)
///from base of /obj/item/bodypart/proc/try_attach_limb(): (new_limb, special)
#define COMSIG_CARBON_ATTACH_LIMB "carbon_attach_limb"
/// Called from bodypart being attached /obj/item/bodypart/proc/try_attach_limb(mob/living/carbon/new_owner, special)
#define COMSIG_BODYPART_ATTACHED "bodypart_attached"
///from base of /obj/item/bodypart/proc/try_attach_limb(): (new_limb, special)
#define COMSIG_CARBON_POST_ATTACH_LIMB "carbon_post_attach_limb"
///from /obj/item/bodypart/proc/receive_damage, sent from the limb owner (limb, brute, burn)
#define COMSIG_CARBON_LIMB_DAMAGED "carbon_limb_damaged"
	#define COMPONENT_PREVENT_LIMB_DAMAGE (1 << 0)
/// from /obj/item/bodypart/proc/apply_gauze(/obj/item/stack/gauze): (/obj/item/stack/medical/gauze/applied_gauze, /obj/item/stack/medical/gauze/stack_used)
#define COMSIG_BODYPART_GAUZED "bodypart_gauzed"
/// from /obj/item/stack/medical/gauze/Destroy(): (/obj/item/stack/medical/gauze/removed_gauze)
#define COMSIG_BODYPART_UNGAUZED "bodypart_ungauzed"

/// Called from bodypart changing owner, which could be on attach or detachment. Either argument can be null. (mob/living/carbon/new_owner, mob/living/carbon/old_owner)
#define COMSIG_BODYPART_CHANGED_OWNER "bodypart_changed_owner"

/// Called from update_health_hud, whenever a bodypart is being updated on the health doll
#define COMSIG_BODYPART_UPDATING_HEALTH_HUD "bodypart_updating_health_hud"
	/// Return to override that bodypart's health hud with whatever is returned by the list
	#define OVERRIDE_BODYPART_HEALTH_HUD (1<<0)

/// Called from /obj/item/bodypart/check_for_injuries (mob/living/carbon/examiner, list/check_list)
#define COMSIG_BODYPART_CHECKED_FOR_INJURY "bodypart_injury_checked"
/// Called from /obj/item/bodypart/check_for_injuries (obj/item/bodypart/examined, list/check_list)
#define COMSIG_CARBON_CHECKING_BODYPART "carbon_checking_injury"

/// Called from carbon losing a limb /obj/item/bodypart/proc/drop_limb(obj/item/bodypart/lost_limb, special, dismembered)
#define COMSIG_CARBON_REMOVE_LIMB "carbon_remove_limb"
/// Called from carbon losing a limb /obj/item/bodypart/proc/drop_limb(obj/item/bodypart/lost_limb, special, dismembered)
#define COMSIG_CARBON_POST_REMOVE_LIMB "carbon_post_remove_limb"
/// Called from bodypart being removed /obj/item/bodypart/proc/drop_limb(mob/living/carbon/old_owner, special, dismembered)
#define COMSIG_BODYPART_REMOVED "bodypart_removed"

/// From /obj/item/bodypart/proc/update_limb(): (dropping_limb, is_creating)
#define COMSIG_BODYPART_UPDATED "bodypart_updated"

///from base of mob/living/carbon/soundbang_act(): (list(intensity))
#define COMSIG_CARBON_SOUNDBANG "carbon_soundbang"
///from /item/organ/proc/Insert() (/obj/item/organ/)
#define COMSIG_CARBON_GAIN_ORGAN "carbon_gain_organ"
///from /item/organ/proc/Remove() (/obj/item/organ/)
#define COMSIG_CARBON_LOSE_ORGAN "carbon_lose_organ"
///from /mob/living/carbon/doUnEquip(obj/item/I, force, newloc, no_move, invdrop, silent)
#define COMSIG_CARBON_EQUIP_HAT "carbon_equip_hat"
///from /mob/living/carbon/doUnEquip(obj/item/I, force, newloc, no_move, invdrop, silent)
#define COMSIG_CARBON_UNEQUIP_HAT "carbon_unequip_hat"
///from /mob/living/carbon/doUnEquip(obj/item/I, force, newloc, no_move, invdrop, silent)
#define COMSIG_CARBON_UNEQUIP_SHOECOVER "carbon_unequip_shoecover"
#define COMSIG_CARBON_EQUIP_SHOECOVER "carbon_equip_shoecover"
///defined twice, in carbon and human's topics, fired when interacting with a valid embedded_object to pull it out (mob/living/carbon/target, /obj/item, /obj/item/bodypart/L)
#define COMSIG_CARBON_EMBED_RIP "item_embed_start_rip"
///called when removing a given item from a mob, from mob/living/carbon/remove_embedded_object(mob/living/carbon/target, /obj/item)
#define COMSIG_CARBON_EMBED_REMOVAL "item_embed_remove_safe"
///Called when someone attempts to cuff a carbon
#define COMSIG_CARBON_CUFF_ATTEMPTED "carbon_attempt_cuff"
	#define COMSIG_CARBON_CUFF_PREVENT (1<<0)
///Called when a carbon mutates (source = dna, mutation = mutation added)
#define COMSIG_CARBON_GAIN_MUTATION "carbon_gain_mutation"
///Called when a carbon loses a mutation (source = dna, mutation = mutation lose)
#define COMSIG_CARBON_LOSE_MUTATION "carbon_lose_mutation"
///Called when a carbon becomes addicted (source = what addiction datum, addicted_mind = mind of the addicted carbon)
#define COMSIG_CARBON_GAIN_ADDICTION "carbon_gain_addiction"
///Called when a carbon is no longer addicted (source = what addiction datum was lost, addicted_mind = mind of the freed carbon)
#define COMSIG_CARBON_LOSE_ADDICTION "carbon_lose_addiction"
///Called when a carbon gets a brain trauma (source = carbon, trauma = what trauma was added) - this is before on_gain()
#define COMSIG_CARBON_GAIN_TRAUMA "carbon_gain_trauma"
///Called when a carbon loses a brain trauma (source = carbon, trauma = what trauma was removed)
#define COMSIG_CARBON_LOSE_TRAUMA "carbon_lose_trauma"
///Called when a carbon's health hud is updated. (source = carbon, shown_health_amount)
#define COMSIG_CARBON_UPDATING_HEALTH_HUD "carbon_health_hud_update"
	/// Return if you override the carbon's health hud with something else
	#define COMPONENT_OVERRIDE_HEALTH_HUD (1<<0)
///Called when a carbon updates their sanity (source = carbon)
#define COMSIG_CARBON_SANITY_UPDATE "carbon_sanity_update"
///Called when a carbon attempts to breath, before the breath has actually occured
#define COMSIG_CARBON_ATTEMPT_BREATHE "carbon_attempt_breathe"
	/// Prevents the breath entirely, which means they will neither suffocate nor regain oxyloss nor decay losebreath stacks
	#define BREATHE_BLOCK_BREATH (1<<0)
	/// Allow the breath but prevent inake, think losebreath
	#define BREATHE_SKIP_BREATH (1<<1)
/// Called when a carbon breathes out (breath (the exhale))
#define COMSIG_CARBON_BREATH_EXHALE "carbon_breath_exhale"
	/// Return if the exhale was handled, or I guess to send the exhale into the void
	#define BREATHE_EXHALE_HANDLED (1<<0)
///Called when a carbon updates their mood
#define COMSIG_CARBON_MOOD_UPDATE "carbon_mood_update"
///Called when a carbon attempts to eat (eating)
#define COMSIG_CARBON_ATTEMPT_EAT "carbon_attempt_eat"
	// Prevents the breath
	#define COMSIG_CARBON_BLOCK_EAT (1 << 0)
///Called when a carbon vomits : (distance, force)
#define COMSIG_CARBON_VOMITED "carbon_vomited"
///Called from apply_overlay(cache_index, overlay)
#define COMSIG_CARBON_APPLY_OVERLAY "carbon_apply_overlay"
///Called from remove_overlay(cache_index, overlay)
#define COMSIG_CARBON_REMOVE_OVERLAY "carbon_remove_overlay"

// /mob/living/carbon/human signals

///Applied preferences to a human
#define COMSIG_HUMAN_PREFS_APPLIED "human_prefs_applied"
///Whenever EquipRanked is called, called after job is set
#define COMSIG_JOB_RECEIVED "job_received"
///from /datum/species/handle_fire. Called when the human is set on fire and burning clothes and stuff
#define COMSIG_HUMAN_BURNING "human_burning"
	/// Return to do no burn damage
	#define BURNING_HANDLED (1<<0)
	/// Return to skip protection check (ie, cause damage even if wearing fireproof clothing)
	#define BURNING_SKIP_PROTECTION (1<<1)
///from /mob/living/carbon/human/proc/force_say(): ()
#define COMSIG_HUMAN_FORCESAY "human_forcesay"

///from /mob/living/carbon/human/get_visible_name(), not sent if the mob has TRAIT_UNKNOWN: (identity)
#define COMSIG_HUMAN_GET_VISIBLE_NAME "human_get_visible_name"
	//Index for the name of the face
	#define VISIBLE_NAME_FACE 1
	//Index for the name of the id
	#define VISIBLE_NAME_ID 2

// Mob transformation signals
///Called when a human turns into a monkey, from /mob/living/carbon/proc/finish_monkeyize()
#define COMSIG_HUMAN_MONKEYIZE "human_monkeyize"
///Called when a monkey turns into a human, from /mob/living/carbon/proc/finish_humanize(species)
#define COMSIG_MONKEY_HUMANIZE "monkey_humanize"

///From mob/living/carbon/human/suicide()
#define COMSIG_HUMAN_SUICIDE_ACT "human_suicide_act"

///from base of /mob/living/carbon/regenerate_limbs(): (excluded_limbs)
#define COMSIG_CARBON_REGENERATE_LIMBS "living_regen_limbs"

///from /atom/movable/screen/alert/give/proc/handle_transfer(): (taker, item)
#define COMSIG_CARBON_ITEM_GIVEN "carbon_item_given"

/// Sent at the very end of human character setup
#define COMSIG_HUMAN_CHARACTER_SETUP "after_human_setup"

/// Carbon is steppin
#define COMSIG_CARBON_STEP "carbon_step"
/// Carbon is steppin on a painful limb
#define COMSIG_CARBON_PAINED_STEP "carbon_pain_step"
	/// Stop the pain from happening
	#define STOP_PAIN (1<<0)
/// from /datum/status_effect/limp/proc/check_step()
#define COMSIG_CARBON_LIMPING "mob_limp_check"
	#define COMPONENT_CANCEL_LIMP (1<<0)
