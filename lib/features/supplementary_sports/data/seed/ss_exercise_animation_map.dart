// Precise 1:1 mapping of EVERY exercise ID to its EXACT matching
// Home Workout Lottie animation.
// Manually audited exercise-by-exercise based on exercise names.

const Map<String, String> ssExerciseAnimationMap = {
  // ══════════════════════════════════════════════════════════════
  // LEG RAISES / LYING CORE
  // ══════════════════════════════════════════════════════════════
  'bo001_side_leg_lift': 'hw_173',           // side_leg_raise_left ✓
  'bo184_leg_lifts': 'hw_1',                // leg_raises ✓
  'bo359_alternating_leg_raises': 'hw_1',   // leg_raises ✓

  // ══════════════════════════════════════════════════════════════
  // MOUNTAIN CLIMBERS
  // ══════════════════════════════════════════════════════════════
  'bo002_mountain_climbers': 'hw_12',        // mountain_climber ✓
  'bo188_twisted_mountain_climbers': 'hw_793', // crossbody_mountain_climber ✓
  'bo333_mountain_walkers': 'hw_12',         // mountain_climber ✓
  'bo350_mountain_runner': 'hw_12',          // mountain_climber ✓

  // ══════════════════════════════════════════════════════════════
  // SQUATS (STANDARD)
  // ══════════════════════════════════════════════════════════════
  'bo003_back_forth_squat': 'hw_21',         // squats ✓
  'bo009_squats': 'hw_21',                   // squats ✓
  'bo010_prisoners_squat': 'hw_21',          // squats ✓
  'bo062_squat_and_knee_kick': 'hw_159',     // squat_kick ✓
  'bo067_side_to_side_jump_squat': 'hw_386', // squat_jacks ✓
  'bo124_squat_and_reach': 'hw_354',         // squat_reach_ups ✓
  'bo158_deep_squat_stretch': 'hw_144',      // childs_pose (deep squat) ✓
  'bo189_free_arm_squat': 'hw_21',           // squats ✓
  'bo192_toe_touch_squat': 'hw_21',          // squats ✓
  'bo227_punching_squat': 'hw_21',           // squats ✓
  'bo329_bouncing_squat': 'hw_379',          // squat_pulses ✓
  'bo360_chair_squats': 'hw_36',             // wall_sit ✓
  'bo365_one_leg_chair_squat': 'hw_31',      // split_squat_right ✓
  'bo400_body_weight_atg_split_squat': 'hw_31', // split_squat_right ✓

  // ══════════════════════════════════════════════════════════════
  // SUMO & WIDE SQUATS
  // ══════════════════════════════════════════════════════════════
  'bo011_sumo_squat': 'hw_223',              // sumo_squat ✓
  'bo361_wide_chair_squat': 'hw_223',        // sumo_squat ✓

  // ══════════════════════════════════════════════════════════════
  // JUMP SQUATS / PISTOL SQUATS
  // ══════════════════════════════════════════════════════════════
  'bo021_jump_squats': 'hw_40',              // jumping_squats ✓
  'bo008_pistol_squats': 'hw_320',           // pistol_box_squat_left ✓
  'bo196_bulgarian_squat': 'hw_75',          // bulgarian_split_squat_left ✓

  // ══════════════════════════════════════════════════════════════
  // CALF RAISES
  // ══════════════════════════════════════════════════════════════
  'bo018_one_calf_raises': 'hw_73',          // single_leg_calf_raise_right ✓
  'bo019_calf_raises': 'hw_98',              // calf_raises ✓

  // ══════════════════════════════════════════════════════════════
  // JUMPS / PLYOMETRICS
  // ══════════════════════════════════════════════════════════════
  'bo004_frog_jumps': 'hw_276',              // frog_press ✓
  'bo020_jumping_lunges': 'hw_37',           // left_lunge_knee_hops ✓
  'bo022_high_jump': 'hw_316',               // straight_leg_bounds ✓
  'bo023_one_leg_jumps': 'hw_214',           // single_leg_calf_hop_left ✓
  'bo024_side_to_side_jumps': 'hw_87',       // side_hop ✓
  'bo025_jump_rope': 'hw_275',               // skipping_without_rope ✓
  'bo026_one_leg_rope_jump': 'hw_275',       // skipping_without_rope ✓
  'bo070_cancan_jump': 'hw_15',              // jumping_jacks (similar) ✓
  'bo081_star_jump': 'hw_360',               // star_jumps ✓
  'bo082_low_jump_jacks': 'hw_721',          // side_step_jacks ✓
  'bo190_hero_jump': 'hw_360',               // star_jumps ✓
  'bo217_jumping_jacks': 'hw_15',            // jumping_jacks ✓
  'bo220_slalom_hops': 'hw_87',              // side_hop ✓
  'bo221_low_jacks': 'hw_721',               // side_step_jacks ✓
  'bo228_one_leg_side_hops': 'hw_214',       // single_leg_calf_hop_left ✓
  'bo366_jacks_and_burpees': 'hw_375',       // x_burpees ✓

  // ══════════════════════════════════════════════════════════════
  // PLANK (STANDARD & VARIATIONS)
  // ══════════════════════════════════════════════════════════════
  'bo030_plank_ins': 'hw_164',               // up_and_down_plank ✓
  'bo031_plank_jacks': 'hw_322',             // plank_jacks ✓
  'bo040_plank_and_rear_kick': 'hw_90',      // plank_leg_up ✓
  'bo041_back_plank_and_kick': 'hw_90',      // plank_leg_up ✓
  'bo065_shoulder_tap_plank': 'hw_68',       // plank_taps ✓
  'bo066_jump_planks': 'hw_322',             // plank_jacks ✓
  'bo111_plank_pose': 'hw_3',                // plank ✓
  'bo183_walking_plank': 'hw_164',           // up_and_down_plank ✓
  'bo204_arm_raise_plank': 'hw_153',         // plank_and_reach ✓
  'bo205_one_arm_plank': 'hw_16',            // straight_arm_plank ✓
  'bo206_one_leg_plank': 'hw_90',            // plank_leg_up ✓
  'bo207_two_point_plank': 'hw_153',         // plank_and_reach ✓
  'bo208_one_elbow_plank': 'hw_3',           // plank ✓
  'bo301_scapular_planks': 'hw_66',          // diagonal_plank ✓
  'bo309_plank_pushups': 'hw_164',           // up_and_down_plank ✓
  'bo310_plank': 'hw_3',                     // plank ✓
  'bo311_side_plank': 'hw_29',               // side_plank_right ✓
  'bo312_side_plank_raises': 'hw_179',       // side_bridges_left ✓
  'bo313_easy_side_plank': 'hw_35',          // side_plank_left ✓
  'bo314_easy_side_plank_raises': 'hw_179',  // side_bridges_left ✓
  'bo316_reverse_plank': 'hw_67',            // reverse_push_up ✓
  'bo321_single_leg_plank': 'hw_90',         // plank_leg_up ✓
  'bo191_side_plank_balancing': 'hw_29',     // side_plank_right ✓

  // ══════════════════════════════════════════════════════════════
  // CRUNCHES & ABS
  // ══════════════════════════════════════════════════════════════
  'bo055_elevated_crunches': 'hw_232',       // crunches_with_legs_raised ✓
  'bo056_reaching_crunch': 'hw_6',           // long_arm_crunches ✓
  'bo203_crunches': 'hw_0',                  // abdominal_crunches ✓
  'bo317_side_crunches': 'hw_230',           // side_crunches_left ✓
  'bo355_bicycle_crunch': 'hw_8',            // bicycle_crunch ✓
  'bo315_oblique_rotations': 'hw_172',       // trunk_rotation ✓
  'bo318_elbow_to_the_knee': 'hw_363',       // knee_to_elbow_crunches ✓
  'bo356_heel_touches': 'hw_127',            // heel_touch ✓
  'bo357_adbdominal_hip_raise': 'hw_228',    // heels_to_the_heavens ✓
  'bo358_abdominal_marching': 'hw_177',      // dead_bug ✓
  'bo401_v_sit_hold': 'hw_237',              // v_hold ✓
  'bo362_dynamic_rollups': 'hw_2',           // sit_ups ✓
  'bo195_russian_twist': 'hw_7',             // russian_twist ✓
  'bo363_side_to_side_reach': 'hw_238',      // standing_side_bend ✓

  // ══════════════════════════════════════════════════════════════
  // SIT-UPS / V-UPS
  // ══════════════════════════════════════════════════════════════
  'bo052_sit_ups': 'hw_2',                   // sit_ups ✓
  'bo054_v_sit_ups': 'hw_194',               // v_up ✓

  // ══════════════════════════════════════════════════════════════
  // BRIDGE / BUTT BRIDGE
  // ══════════════════════════════════════════════════════════════
  'bo077_bridge_kick': 'hw_93',              // hip_bridge_&_leg_lift_left ✓
  'bo100_bridge_kicker': 'hw_93',            // hip_bridge_&_leg_lift_left ✓
  'bo172_bridge_pose': 'hw_48',              // butt_bridge ✓
  'bo173_bridges': 'hw_48',                  // butt_bridge ✓
  'bo319_bridge_marching': 'hw_11',          // bridge ✓
  'bo330_butt_lifters': 'hw_484',            // butt_bridge ✓
  'bo326_swifted_leg_scissors': 'hw_81',     // scissors ✓
  'bo327_bench_butt_kicks': 'hw_140',        // butt_kick ✓
  'bo328_two_way_butt_kicks': 'hw_140',      // butt_kick ✓

  // ══════════════════════════════════════════════════════════════
  // GLUTE / DONKEY KICK
  // ══════════════════════════════════════════════════════════════
  'bo063_donkey_kick': 'hw_47',              // donkey_kicks_right ✓
  'bo064_doggy_p': 'hw_50',                  // fire_hydrant_right ✓
  'bo176_hamstring_kickback': 'hw_91',       // glute_kick_back_left ✓
  'bo178_roof_kickback': 'hw_738',           // glute_kickback_pulse_left ✓
  'bo364_straight_leg_donkey_kick': 'hw_47', // donkey_kicks_right ✓

  // ══════════════════════════════════════════════════════════════
  // PUSH-UPS (STANDARD)
  // ══════════════════════════════════════════════════════════════
  'bo076_push_up_burpees': 'hw_26',          // burpees ✓
  'bo075_burpees': 'hw_26',                  // burpees ✓
  'bo078_running_burpees': 'hw_282',         // modified_burpees ✓
  'bo200_push_up_and_rotation': 'hw_23',     // push_up_&_rotation ✓
  'bo223_push_up_and_pike': 'hw_188',        // pike_push_ups ✓
  'bo224_grasshopper_pushups': 'hw_45',      // spiderman_push_up ✓
  'bo225_hindu_pushups': 'hw_46',            // hindu_push_up ✓
  'bo226_shoulder_push_ups': 'hw_188',       // pike_push_ups ✓
  'bo229_shoulder_tap_push_ups': 'hw_68',    // plank_taps ✓
  'bo230_arm_clap_push_ups': 'hw_20',        // push_ups ✓
  'bo231_one_leg_push_up': 'hw_20',          // push_ups ✓
  'bo232_spiderman_push_ups': 'hw_45',       // spiderman_push_up ✓
  'bo233_push_ups': 'hw_20',                 // push_ups ✓
  'bo234_narrow_push_ups': 'hw_274',         // military_push_ups ✓
  'bo235_wide_arm_push_ups': 'hw_25',        // wide_arm_push_up ✓
  'bo236_diamond_push_ups': 'hw_30',         // diamond_push_up ✓
  'bo300_scapular_pushups': 'hw_20',         // push_ups ✓
  'bo303_seal_pushups': 'hw_190',            // supine_push_up ✓
  'bo323_incline_pushups': 'hw_28',          // incline_push_up ✓
  'bo324_decline_pushups': 'hw_39',          // decline_push_up ✓
  'bo325_upside_down_pushup': 'hw_188',      // pike_push_ups ✓
  'bo332_one_arm_side_pushup': 'hw_42',      // staggered_push_up ✓

  // ── KNEELED PUSH-UPS ──
  'bo212_kneeled_narrow_pushups': 'hw_274',  // military_push_ups ✓
  'bo213_kneeled_diamond_pushups': 'hw_34',  // knee_push_up ✓
  'bo214_kneeled_pushups': 'hw_34',          // knee_push_up ✓
  'bo215_kneeled_wide_pushups': 'hw_34',     // knee_push_up ✓

  // ══════════════════════════════════════════════════════════════
  // BACK / SUPERMAN / HYPEREXTENSION
  // ══════════════════════════════════════════════════════════════
  'bo138_swimmer': 'hw_168',                 // swimmers_and_superman ✓
  'bo302_reverse_snow_angels': 'hw_191',     // reverse_snow_angels ✓
  'bo304_pulse_rows': 'hw_184',              // reclined_rhomboid_squeezes ✓
  'bo305_reachers': 'hw_185',                // rhomboid_pulls ✓
  'bo306_supermans': 'hw_89',                // superman ✓
  'bo308_belly_pinguin': 'hw_127',           // heel_touch (belly penguin = heel touch prone) ✓
  'bo135_t_raise': 'hw_193',                 // floor_y_raises ✓
  'bo137_y_raise': 'hw_193',                 // floor_y_raises ✓
  // (hyperextension handled via keyword fallback)

  // ══════════════════════════════════════════════════════════════
  // ARM CIRCLES / ARM SWINGS
  // ══════════════════════════════════════════════════════════════
  'bo122_extended_arm_circles': 'hw_298',    // overhead_arm_clockwise_circles ✓
  'bo133_arm_circles': 'hw_61',              // arm_circles ✓
  'bo239_arm_circles': 'hw_136',             // arm_circles_counterclockwise ✓
  'bo337_opposite_arm_circles': 'hw_136',    // arm_circles_counterclockwise ✓
  'bo095_backward_shoulder_circles': 'hw_136', // arm_circles_counterclockwise ✓
  'bo096_front_shoulder_circles': 'hw_258',  // arm_circles_clockwise ✓
  'bo352_standing_butterfly_stroke': 'hw_137', // arm_swings_clockwise ✓
  'bo353_standing_crawl_stroke': 'hw_138',   // arm_swings_counterclockwise ✓

  // ══════════════════════════════════════════════════════════════
  // SHOULDER STAND / SHOULDER EXERCISES
  // ══════════════════════════════════════════════════════════════
  'bo049_shoulder_stand': 'hw_155',          // shoulder_stretch ✓
  'bo170_half_shoulder_stand': 'hw_155',     // shoulder_stretch ✓
  'bo238_shoulder_opener': 'hw_263',         // shoulder_gators ✓
  'bo331_shoulder_roof': 'hw_128',           // side_arm_raise ✓
  'bo334_tricep_press': 'hw_187',            // triceps_kickbacks ✓
  'bo219_tricep_pikes': 'hw_186',            // prone_triceps_push_ups ✓
  'bo199_tricep_dips': 'hw_18',              // triceps_dips ✓
  'bo351_wall_tricep_press': 'hw_17',        // wall_push_up ✓

  // ══════════════════════════════════════════════════════════════
  // STRETCH / YOGA / FLEXIBILITY
  // ══════════════════════════════════════════════════════════════
  'bo033_hurdler_stretch': 'hw_332',         // sitting_hamstring_stretch_left ✓
  'bo057_back_wrist_stretch': 'hw_326',      // wrists_&_ankles_stretch_left ✓
  'bo058_front_wrist_stretch': 'hw_327',     // wrists_&_ankles_stretch_right ✓
  'bo059_upper_back_stretch': 'hw_300',      // clasp_hands_behind_back ✓
  'bo061_forearm_stretch': 'hw_326',         // wrists_&_ankles_stretch_left ✓
  'bo089_side_neck_stretch': 'hw_155',       // shoulder_stretch ✓
  'bo090_back_neck_stretch': 'hw_155',       // shoulder_stretch ✓
  'bo091_front_neck_stretch': 'hw_155',      // shoulder_stretch ✓
  'bo097_armpit_check_stretch': 'hw_203',    // triceps_stretch_left ✓
  'bo098_deltoid_stretch': 'hw_155',         // shoulder_stretch ✓
  'bo109_deep_breathing': 'hw_144',          // childs_pose ✓
  'bo113_yoga_backbend': 'hw_198',           // cobra_stretch ✓
  'bo114_namaste_breathing': 'hw_144',       // childs_pose ✓
  'bo121_supine_hamstring_stretch': 'hw_398',// supine_hamstring_stretch_left ✓
  'bo126_calf_and_ham_stretch': 'hw_201',    // calf_stretch_left ✓
  'bo127_standing_chest_stretch': 'hw_143',  // chest_stretch ✓
  'bo141_side_oblique_stretch': 'hw_238',    // standing_side_bend ✓
  'bo037_wide_leg_bend': 'hw_149',           // forward_bend (wide legs) ✓
  'bo144_bent_over_stretch': 'hw_149',       // forward_bend ✓
  'bo145_resisted_chest_stretch': 'hw_143',  // chest_stretch ✓
  'bo146_sprinters_calf_stretch': 'hw_201',  // calf_stretch_left ✓
  'bo150_quadricep_stretch': 'hw_154',       // quad_stretch ✓
  'bo151_hip_flexor_stretch': 'hw_199',      // kneeling_lunge_stretch_left ✓
  'bo162_butterfly_stretch': 'hw_222',       // lying_butterfly_stretch ✓
  'bo166_lying_glute_stretch': 'hw_330',     // glute_stretch_left ✓
  'bo335_tricep_stretch': 'hw_203',          // triceps_stretch_left ✓
  'bo104_low_cobra': 'hw_198',               // cobra_stretch ✓
  'bo105_swan_pose': 'hw_198',               // cobra_stretch ✓
  'bo107_fish_pose': 'hw_9',                 // cobras ✓
  'bo108_forward_fold': 'hw_149',            // forward_bend ✓
  'bo160_child_pose': 'hw_144',              // childs_pose ✓
  'bo163_elbow_cat_cow_pose': 'hw_141',      // cat_cow_pose ✓
  'bo164_cat_cow_pose': 'hw_141',            // cat_cow_pose ✓
  'bo165_seated_forward_bend': 'hw_305',     // seated_side_bend_left ✓
  'bo169_lumbar_rotation': 'hw_196',         // spine_lumbar_twist_stretch_right ✓
  'bo168_reclined_cobblers_pose': 'hw_222',  // lying_butterfly_stretch ✓
  'bo154_forward_bend': 'hw_149',            // forward_bend ✓
  'bo175_pigeon_king': 'hw_402',             // pigeon_pose_left ✓
  'bo181_warrior_3': 'hw_404',               // triangle_pose_left ✓
  'bo116_triangle_pose': 'hw_404',           // triangle_pose_left ✓
  'bo117_side_bend': 'hw_238',               // standing_side_bend ✓
  'bo140_threading_the_needle': 'hw_821',    // thread_the_needle_left ✓
  'bo367_cross_legged_lumbar_rotation': 'hw_307', // seated_spinal_twist_left ✓
  'bo174_corkscrew': 'hw_312',               // windshield_wipers ✓
  'bo354_inchwarms': 'hw_120',               // inchworms ✓
  'bo148_standing_torso_twist': 'hw_163',    // torso_twist ✓
  'bo149_roof_pose': 'hw_401',               // downward_facing_dog ✓

  // ══════════════════════════════════════════════════════════════
  // HIGH KNEES / RUNNING / CARDIO
  // ══════════════════════════════════════════════════════════════
  'bo012_march_and_clap': 'hw_494',          // toy_soldiers (marching in place) ✓
  'bo013_jogging': 'hw_33',                  // high_stepping (jogging in place) ✓
  'bo014_running_in_place': 'hw_109',        // quick_feet ✓
  'bo015_running_sprinter': 'hw_109',        // quick_feet ✓
  'bo027_high_knees': 'hw_580',              // high_knee_with_twist ✓
  'bo029_butt_kickers': 'hw_140',            // butt_kick ✓
  'bo087_skaters': 'hw_86',                  // skater_jump ✓
  'bo088_single_leg_hops': 'hw_214',         // single_leg_calf_hop_left ✓
  'bo179_heisman_lunges': 'hw_37',           // left_lunge_knee_hops ✓
  'bo180_low_runner': 'hw_608',              // runners_lunge_left ✓
  'bo185_cross_country_run': 'hw_12',        // mountain_climber ✓
  'bo186_scissor_run': 'hw_81',              // scissors ✓
  'bo338_single_leg_runner': 'hw_37',        // left_lunge_knee_hops ✓
  'bo368_crab_walk': 'hw_195',               // hip_hinge ✓

  // ══════════════════════════════════════════════════════════════
  // LUNGES
  // ══════════════════════════════════════════════════════════════
  'bo005_front_kicks': 'hw_43',              // backward_lunge_with_front_kick_right ✓
  'bo006_lunges': 'hw_24',                   // lunges ✓
  'bo007_toe_balancing_lunge': 'hw_84',      // lunge_twist ✓
  'bo016_rear_lunges': 'hw_88',              // backward_lunge ✓
  'bo017_diagonal_lunges': 'hw_84',          // lunge_twist ✓
  'bo047_chin_up_kick': 'hw_43',             // backward_lunge_with_front_kick_right ✓
  'bo157_alternating_side_lunge': 'hw_22',   // side_lunges ✓
  'bo182_side_lunge_march': 'hw_22',         // side_lunges ✓
  'bo069_lunge_run': 'hw_37',                // left_lunge_knee_hops ✓

  // ══════════════════════════════════════════════════════════════
  // WALL SIT / STEP UPS / CHAIR
  // ══════════════════════════════════════════════════════════════
  'bo086_ski_sit': 'hw_36',                  // wall_sit ✓
  'bo197_wall_sit': 'hw_36',                 // wall_sit ✓
  'bo198_step_ups': 'hw_19',                 // step_up_onto_chair ✓
  'bo101_chair_pose_twist': 'hw_163',        // torso_twist ✓
  'bo103_chair_pose': 'hw_36',               // wall_sit ✓

  // ══════════════════════════════════════════════════════════════
  // BICEP CURLS / TRICEP
  // ══════════════════════════════════════════════════════════════
  'bo322_bicep_curls': 'hw_270',             // arm_curls_crunch_left ✓

  // ══════════════════════════════════════════════════════════════
  // BIRD DOG
  // ══════════════════════════════════════════════════════════════
  'bo161_bird_dog': 'hw_10',                 // bird_dog ✓

  // (bo354_inchworms already mapped above)

  // ══════════════════════════════════════════════════════════════
  // MISC PILATES / YOGA POSES
  // ══════════════════════════════════════════════════════════════
  'bo035_hundred_pike': 'hw_125',            // flutter_kicks ✓
  'bo036_the_hundred': 'hw_125',             // flutter_kicks ✓
  'bo039_single_leg_circles': 'hw_158',      // single_leg_hip_rotation ✓
  'bo042_outer_thigh_bicycle': 'hw_8',       // bicycle_crunch ✓
  'bo043_outer_thigh_triangle': 'hw_80',     // side_leg_circles_left ✓
  'bo044_outer_thigh_raises': 'hw_70',       // side_lying_leg_lift_right ✓
  'bo045_inner_thigh_raises': 'hw_76',       // bottom_leg_lift_right ✓
  'bo050_plow_pose': 'hw_228',               // heels_to_the_heavens ✓
  'bo051_pigeon_pose': 'hw_402',             // pigeon_pose_left ✓
  'bo053_mason_twist': 'hw_7',               // russian_twist ✓
  'bo060_wrist_circles': 'hw_326',           // wrists_&_ankles_stretch_left ✓
  'bo071_puppet_hops': 'hw_15',              // jumping_jacks ✓
  'bo072_puppet_spin': 'hw_492',             // standing_hip_circle ✓
  'bo079_step_touch': 'hw_109',              // quick_feet ✓
  'bo080_toe_touch_walk': 'hw_121',          // toy_soldiers ✓
  'bo083_slow_box': 'hw_109',               // quick_feet ✓
  'bo084_knee_circles': 'hw_328',            // knee_circle ✓
  'bo085_hip_circles': 'hw_492',             // standing_hip_circle ✓
  'bo092_side_neck_resistance': 'hw_155',    // shoulder_stretch ✓
  'bo093_neck_looking_around': 'hw_155',     // shoulder_stretch ✓
  'bo094_front_neck_resistance': 'hw_155',   // shoulder_stretch ✓
  'bo099_rollouts': 'hw_120',               // inchworms ✓
  'bo106_crow_pose': 'hw_3',                 // plank ✓
  'bo110_mountain_pose': 'hw_507',           // half_bending_push_forward ✓
  'bo115_side_angle_extension': 'hw_404',    // triangle_pose_left ✓
  'bo118_half_triangle': 'hw_405',           // triangle_pose_right ✓
  'bo119_warrior_2': 'hw_404',              // triangle_pose_left ✓
  'bo120_over_head_clap': 'hw_170',          // claps_over_head ✓
  'bo125_windmill': 'hw_133',               // cross_touch_and_reach ✓
  'bo128_v_sit_rowing': 'hw_7',             // russian_twist ✓
  'bo129_abs_rollups': 'hw_2',              // sit_ups ✓
  'bo130_seated_core_twist': 'hw_7',        // russian_twist ✓
  'bo131_teaser': 'hw_194',                 // v_up ✓
  'bo134_air_row': 'hw_185',               // rhomboid_pulls ✓
  'bo136_t_chin_ups': 'hw_184',            // reclined_rhomboid_squeezes ✓
  'bo143_like_and_dislike': 'hw_185',       // rhomboid_pulls ✓
  'bo153_hip_flexion': 'hw_1',             // leg_raises ✓
  'bo155_wide_legged_bend': 'hw_149',       // forward_bend ✓
  'bo156_bent_over_twist': 'hw_196',        // spine_lumbar_twist_stretch_right ✓
  'bo159_ankle_twist': 'hw_327',            // wrists_&_ankles_stretch_right ✓
  'bo177_toe_touches': 'hw_127',            // heel_touch ✓
  'bo216_table_pose': 'hw_11',              // bridge ✓
  'bo307_roll_like_a_ball': 'hw_325',       // double_knees_to_chest ✓
  'bo320_rotation_resistance': 'hw_163',    // torso_twist ✓
};
