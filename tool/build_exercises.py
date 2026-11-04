#!/usr/bin/env python3
"""Builds assets/exercises.json from free-exercise-db (Unlicense).

- Cleans up names of popular exercises (e.g. "Barbell Bench Press - Medium Grip"
  -> "Barbell Bench Press") and applies a few generic clean-ups.
- Adds common exercises that are missing (ids start with "hz_").
- Assigns a popularity rank (lower = more popular) used to show the 5 most
  popular exercises of a muscle group first.
- Sets the tracking type for holds/cardio ("duration").

Usage: python3 tool/build_exercises.py [path-or-url-to-free-exercise-db/dist/exercises.json]
After changing the output, bump `exerciseSeedVersion` in lib/data/exercise_repository.dart.
"""
import json
import re
import sys
import urllib.request

SOURCE = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/dist/exercises.json'

# Most popular first, per primary muscle. (id, clean name or None to keep)
POPULAR = {
    'chest': [
        ('Barbell_Bench_Press_-_Medium_Grip', 'Barbell Bench Press'),
        ('Incline_Dumbbell_Press', 'Incline Dumbbell Press'),
        ('Dumbbell_Bench_Press', 'Dumbbell Bench Press'),
        ('Barbell_Incline_Bench_Press_-_Medium_Grip', 'Incline Barbell Bench Press'),
        ('Cable_Crossover', 'Cable Crossover'),
        ('Pushups', 'Push-Up'),
        ('Butterfly', 'Pec Deck (Machine Fly)'),
        ('Leverage_Chest_Press', 'Machine Chest Press'),
        ('Dips_-_Chest_Version', 'Chest Dip'),
        ('Dumbbell_Flyes', 'Dumbbell Fly'),
        ('Decline_Barbell_Bench_Press', 'Decline Barbell Bench Press'),
        ('Smith_Machine_Bench_Press', 'Smith Machine Bench Press'),
        ('Incline_Dumbbell_Flyes', 'Incline Dumbbell Fly'),
        ('Smith_Machine_Incline_Bench_Press', 'Smith Machine Incline Bench Press'),
    ],
    'quadriceps': [
        ('Barbell_Squat', 'Barbell Squat'),
        ('Leg_Press', 'Leg Press'),
        ('Leg_Extensions', 'Leg Extension'),
        ('hz_bulgarian_split_squat', 'Bulgarian Split Squat'),
        ('Front_Barbell_Squat', 'Barbell Front Squat'),
        ('Hack_Squat', 'Hack Squat'),
        ('Goblet_Squat', 'Goblet Squat'),
        ('Dumbbell_Lunges', 'Dumbbell Lunge'),
        ('Barbell_Walking_Lunge', 'Barbell Walking Lunge'),
        ('Dumbbell_Step_Ups', 'Dumbbell Step-Up'),
        ('Smith_Machine_Squat', 'Smith Machine Squat'),
        ('Bodyweight_Squat', 'Bodyweight Squat'),
        ('hz_wall_sit', 'Wall Sit'),
    ],
    'lower back': [
        ('Barbell_Deadlift', 'Barbell Deadlift'),
        ('Hyperextensions_Back_Extensions', 'Back Extension'),
        ('Deficit_Deadlift', 'Deficit Deadlift'),
    ],
    'lats': [
        ('Pullups', 'Pull-Up'),
        ('Wide-Grip_Lat_Pulldown', 'Lat Pulldown'),
        ('Chin-Up', 'Chin-Up'),
        ('Close-Grip_Front_Lat_Pulldown', 'Lat Pulldown (Close Grip)'),
        ('Straight-Arm_Pulldown', 'Straight-Arm Pulldown'),
        ('hz_assisted_pull_up', 'Assisted Pull-Up (Machine)'),
        ('V-Bar_Pulldown', 'Lat Pulldown (V-Bar)'),
        ('One_Arm_Lat_Pulldown', 'Single-Arm Lat Pulldown'),
    ],
    'shoulders': [
        ('Standing_Military_Press', 'Barbell Overhead Press'),
        ('Dumbbell_Shoulder_Press', 'Dumbbell Shoulder Press'),
        ('Side_Lateral_Raise', 'Dumbbell Lateral Raise'),
        ('Face_Pull', 'Face Pull'),
        ('hz_cable_lateral_raise', 'Cable Lateral Raise'),
        ('Machine_Shoulder_Military_Press', 'Machine Shoulder Press'),
        ('Reverse_Machine_Flyes', 'Rear Delt Machine Fly'),
        ('Arnold_Dumbbell_Press', 'Arnold Press'),
        ('Reverse_Flyes', 'Dumbbell Rear Delt Fly'),
        ('Front_Dumbbell_Raise', 'Dumbbell Front Raise'),
        ('Seated_Barbell_Military_Press', 'Seated Barbell Overhead Press'),
        ('Upright_Barbell_Row', 'Barbell Upright Row'),
        ('Cable_Rear_Delt_Fly', 'Cable Rear Delt Fly'),
    ],
    'middle back': [
        ('Bent_Over_Barbell_Row', 'Barbell Row'),
        ('Seated_Cable_Rows', 'Seated Cable Row'),
        ('One-Arm_Dumbbell_Row', 'Dumbbell Row'),
        ('T-Bar_Row_with_Handle', 'T-Bar Row'),
        ('hz_seated_machine_row', 'Seated Machine Row'),
        ('Inverted_Row', 'Inverted Row'),
        ('Dumbbell_Incline_Row', 'Chest-Supported Dumbbell Row'),
        ('Bent_Over_Two-Dumbbell_Row', 'Dumbbell Bent-Over Row'),
        ('Reverse_Grip_Bent-Over_Rows', 'Barbell Row (Underhand)'),
    ],
    'hamstrings': [
        ('Romanian_Deadlift', 'Barbell Romanian Deadlift'),
        ('Lying_Leg_Curls', 'Lying Leg Curl'),
        ('Seated_Leg_Curl', 'Seated Leg Curl'),
        ('hz_dumbbell_rdl', 'Dumbbell Romanian Deadlift'),
        ('Good_Morning', 'Barbell Good Morning'),
        ('Sumo_Deadlift', 'Sumo Deadlift'),
        ('hz_kettlebell_swing', 'Kettlebell Swing'),
        ('Glute_Ham_Raise', 'Glute Ham Raise'),
        ('Stiff-Legged_Barbell_Deadlift', 'Barbell Stiff-Leg Deadlift'),
    ],
    'biceps': [
        ('Barbell_Curl', 'Barbell Curl'),
        ('Dumbbell_Bicep_Curl', 'Dumbbell Curl'),
        ('Hammer_Curls', 'Dumbbell Hammer Curl'),
        ('Preacher_Curl', 'Barbell Preacher Curl'),
        ('Standing_Biceps_Cable_Curl', 'Cable Curl'),
        ('Incline_Dumbbell_Curl', 'Incline Dumbbell Curl'),
        ('EZ-Bar_Curl', 'EZ-Bar Curl'),
        ('Concentration_Curls', 'Concentration Curl'),
        ('Machine_Bicep_Curl', 'Machine Curl'),
        ('Cable_Hammer_Curls_-_Rope_Attachment', 'Cable Hammer Curl (Rope)'),
    ],
    'triceps': [
        ('Triceps_Pushdown', 'Triceps Pushdown'),
        ('Triceps_Pushdown_-_Rope_Attachment', 'Triceps Rope Pushdown'),
        ('Cable_Rope_Overhead_Triceps_Extension', 'Overhead Cable Triceps Extension'),
        ('EZ-Bar_Skullcrusher', 'Skull Crusher'),
        ('Close-Grip_Barbell_Bench_Press', 'Close-Grip Bench Press'),
        ('Dips_-_Triceps_Version', 'Triceps Dip'),
        ('Standing_Dumbbell_Triceps_Extension', 'Dumbbell Overhead Triceps Extension'),
        ('Tricep_Dumbbell_Kickback', 'Dumbbell Triceps Kickback'),
        ('Bench_Dips', 'Bench Dip'),
        ('Lying_Dumbbell_Tricep_Extension', 'Dumbbell Skull Crusher'),
    ],
    'glutes': [
        ('Barbell_Hip_Thrust', 'Barbell Hip Thrust'),
        ('Barbell_Glute_Bridge', 'Barbell Glute Bridge'),
        ('hz_cable_kickback', 'Cable Glute Kickback'),
        ('hz_glute_bridge', 'Glute Bridge'),
        ('Glute_Kickback', 'Glute Kickback (Bodyweight)'),
        ('Single_Leg_Glute_Bridge', 'Single-Leg Glute Bridge'),
    ],
    'abdominals': [
        ('Plank', 'Plank'),
        ('Crunches', 'Crunch'),
        ('Hanging_Leg_Raise', 'Hanging Leg Raise'),
        ('Cable_Crunch', 'Cable Crunch'),
        ('Ab_Roller', 'Ab Wheel Rollout'),
        ('Russian_Twist', 'Russian Twist'),
        ('hz_side_plank', 'Side Plank'),
        ('Flat_Bench_Lying_Leg_Raise', 'Lying Leg Raise'),
        ('Sit-Up', 'Sit-Up'),
        ('hz_bicycle_crunch', 'Bicycle Crunch'),
        ('Dead_Bug', 'Dead Bug'),
        ('Ab_Crunch_Machine', 'Machine Crunch'),
    ],
    'calves': [
        ('Standing_Calf_Raises', 'Standing Calf Raise'),
        ('Seated_Calf_Raise', 'Seated Calf Raise'),
        ('Calf_Press_On_The_Leg_Press_Machine', 'Leg Press Calf Raise'),
        ('Standing_Dumbbell_Calf_Raise', 'Dumbbell Calf Raise'),
        ('Smith_Machine_Calf_Raise', 'Smith Machine Calf Raise'),
        ('Standing_Barbell_Calf_Raise', 'Barbell Calf Raise'),
    ],
    'traps': [
        ('Dumbbell_Shrug', 'Dumbbell Shrug'),
        ('Barbell_Shrug', 'Barbell Shrug'),
        ('Cable_Shrugs', 'Cable Shrug'),
        ('Leverage_Shrug', 'Machine Shrug'),
        ('Upright_Cable_Row', 'Cable Upright Row'),
        ('Standing_Dumbbell_Upright_Row', 'Dumbbell Upright Row'),
    ],
    'forearms': [
        ('Farmers_Walk', "Farmer's Walk"),
        ('hz_dead_hang', 'Dead Hang'),
        ('Palms-Up_Barbell_Wrist_Curl_Over_A_Bench', 'Barbell Wrist Curl'),
        ('Palms-Down_Wrist_Curl_Over_A_Bench', 'Barbell Reverse Wrist Curl'),
        ('Seated_Dumbbell_Palms-Up_Wrist_Curl', 'Dumbbell Wrist Curl'),
        ('Wrist_Roller', 'Wrist Roller'),
    ],
    'adductors': [('Thigh_Adductor', 'Hip Adduction (Machine)')],
    'abductors': [
        ('Thigh_Abductor', 'Hip Abduction (Machine)'),
        ('hz_banded_lateral_walk', 'Banded Lateral Walk'),
    ],
}
# Muscle order for the "no filter" top list (bench, squat, deadlift, pull-up, OHP, ...).
MUSCLE_PRIORITY = ['chest', 'quadriceps', 'lower back', 'lats', 'shoulders', 'middle back', 'hamstrings', 'biceps',
                   'triceps', 'glutes', 'abdominals', 'calves', 'traps', 'forearms', 'adductors', 'abductors']

POPULAR_STRETCHES = [
    ('Hamstring_Stretch', 'Standing Hamstring Stretch'),
    ('Kneeling_Hip_Flexor', 'Kneeling Hip Flexor Stretch'),
    ('hz_pigeon_pose', 'Pigeon Pose'),
    ('Childs_Pose', "Child's Pose"),
    ('hz_doorway_chest_stretch', 'Doorway Chest Stretch'),
    ('Quad_Stretch', 'Standing Quad Stretch'),
    ('Calf_Stretch_Hands_Against_Wall', 'Wall Calf Stretch'),
    ('Cat_Stretch', 'Cat-Cow Stretch'),
    ('Ankle_On_The_Knee', 'Figure-Four Glute Stretch'),
    ('Shoulder_Stretch', 'Cross-Body Shoulder Stretch'),
    ('Worlds_Greatest_Stretch', "World's Greatest Stretch"),
    ('hz_cobra_stretch', 'Cobra Stretch'),
    ('hz_butterfly_stretch', 'Butterfly Stretch'),
    ('Triceps_Stretch', 'Triceps Stretch'),
    ('Lying_Crossover', 'Lying Spinal Twist'),
    ('Side_Neck_Stretch', 'Side Neck Stretch'),
]

# Other renames (no popularity rank).
RENAMES = {
    'Barbell_Full_Squat': 'Barbell Full Squat (ATG)',
    'Leverage_Incline_Chest_Press': 'Incline Machine Chest Press',
    'Leverage_Decline_Chest_Press': 'Decline Machine Chest Press',
    'Low_Cable_Crossover': 'Low-to-High Cable Fly',
    'Flat_Bench_Cable_Flyes': 'Flat Bench Cable Fly',
    'Incline_Cable_Flye': 'Incline Cable Fly',
    'Bent-Arm_Dumbbell_Pullover': 'Dumbbell Pullover',
    'Bent-Arm_Barbell_Pullover': 'Barbell Pullover',
    'Split_Squat_with_Dumbbells': 'Dumbbell Split Squat',
    'Dumbbell_Rear_Lunge': 'Dumbbell Reverse Lunge',
    'Bodyweight_Walking_Lunge': 'Walking Lunge (Bodyweight)',
    'Barbell_Step_Ups': 'Barbell Step-Up',
    'Hyperextensions_With_No_Hyperextension_Bench': 'Floor Back Extension',
    'Stiff-Legged_Dumbbell_Deadlift': 'Dumbbell Stiff-Leg Deadlift',
    'Band_Assisted_Pull-Up': 'Assisted Pull-Up (Band)',
    'Underhand_Cable_Pulldowns': 'Lat Pulldown (Underhand)',
    'Wide-Grip_Pulldown_Behind_The_Neck': 'Behind-the-Neck Pulldown',
    'Wide-Grip_Rear_Pull-Up': 'Wide-Grip Pull-Up',
    'V-Bar_Pullup': 'V-Bar Pull-Up',
    'Rope_Straight-Arm_Pulldown': 'Straight-Arm Pulldown (Rope)',
    'Cable_Seated_Lateral_Raise': 'Seated Cable Lateral Raise',
    'Seated_Side_Lateral_Raise': 'Seated Dumbbell Lateral Raise',
    'Smith_Machine_Overhead_Shoulder_Press': 'Smith Machine Shoulder Press',
    'Leverage_Shoulder_Press': 'Plate-Loaded Shoulder Press',
    'Handstand_Push-Ups': 'Handstand Push-Up',
    'Front_Cable_Raise': 'Cable Front Raise',
    'Front_Plate_Raise': 'Plate Front Raise',
    'Leverage_High_Row': 'Machine High Row',
    'Leverage_Iso_Row': 'Machine Iso Row',
    'Lying_T-Bar_Row': 'Chest-Supported T-Bar Row',
    'Smith_Machine_Bent_Over_Row': 'Smith Machine Row',
    'Seated_One-arm_Cable_Pulley_Rows': 'Single-Arm Cable Row',
    'Dumbbell_Alternate_Bicep_Curl': 'Dumbbell Alternating Curl',
    'Machine_Preacher_Curls': 'Machine Preacher Curl',
    'Two-Arm_Dumbbell_Preacher_Curl': 'Dumbbell Preacher Curl',
    'Alternate_Hammer_Curl': 'Alternating Hammer Curl',
    'Incline_Hammer_Curls': 'Incline Hammer Curl',
    'Triceps_Pushdown_-_V-Bar_Attachment': 'Triceps Pushdown (V-Bar)',
    'Reverse_Grip_Triceps_Pushdown': 'Reverse-Grip Triceps Pushdown',
    'Triceps_Overhead_Extension_with_Rope': 'Triceps Overhead Extension (Rope)',
    'Dip_Machine': 'Machine Dip',
    'Push-Ups_-_Close_Triceps_Position': 'Diamond Push-Up',
    'Lying_Triceps_Press': 'EZ-Bar Lying Triceps Extension',
    'Step-up_with_Knee_Raise': 'Step-Up with Knee Raise',
    'Knee_Hip_Raise_On_Parallel_Bars': "Captain's Chair Knee Raise",
    'Donkey_Calf_Raises': 'Donkey Calf Raise',
    'Calf_Press': 'Calf Press (Machine)',
    'Seated_Dumbbell_Palms-Down_Wrist_Curl': 'Dumbbell Reverse Wrist Curl',
    'Smith_Machine_Upright_Row': 'Smith Machine Upright Row',
    'Rope_Jumping': 'Jump Rope',
    'Rowing_Stationary': 'Rowing Machine',
    'Bicycling_Stationary': 'Stationary Bike',
    'Jogging_Treadmill': 'Treadmill Jog',
    'Running_Treadmill': 'Treadmill Run',
    'Front_Box_Jump': 'Box Jump',
    'Mountain_Climbers': 'Mountain Climber',
    'Push-Ups_With_Feet_Elevated': 'Feet-Elevated Push-Up',
    # Stretches
    'Seated_Floor_Hamstring_Stretch': 'Seated Hamstring Stretch',
    'Seated_Hamstring': 'Seated Single-Leg Hamstring Stretch',
    'Lying_Glute': 'Lying Glute Stretch',
    'Lying_Hamstring': 'Lying Hamstring Stretch',
    'Seated_Glute': 'Seated Glute Stretch',
    'Overhead_Lat': 'Overhead Lat Stretch',
    'Seated_Biceps': 'Seated Biceps Stretch',
    'Seated_Front_Deltoid': 'Seated Front Delt Stretch',
    'Lying_Prone_Quadriceps': 'Lying Quad Stretch',
    'Standing_Hip_Flexors': 'Standing Hip Flexor Stretch',
    'The_Straddle': 'Straddle Stretch',
    'Adductor': 'Adductor Stretch',
    'Adductor_Groin': 'Groin Stretch',
    'Hug_Knees_To_Chest': 'Knees-to-Chest Stretch',
    'One_Knee_To_Chest': 'Single Knee-to-Chest Stretch',
    'Knee_Across_The_Body': 'Knee-Across-Body Stretch',
    'Overhead_Triceps': 'Overhead Triceps Stretch',
    'Calf_Stretch_Elbows_Against_Wall': 'Wall Calf Stretch (Elbows)',
    'Iliotibial_Tract-SMR': 'IT Band Foam Roll',
    'Chest_And_Front_Of_Shoulder_Stretch': 'Chest and Shoulder Stretch',
}

# Duplicates: hidden from the list (kept in the database so old workouts that
# used them still show). id -> the exercise to use instead.
HIDDEN = {
    'Squats_-_With_Bands': 'Squat_with_Bands',
    'Calf_Raise_On_A_Dumbbell': 'Standing_Dumbbell_Calf_Raise',
    'Decline_Smith_Press': 'Smith_Machine_Decline_Press',
    'Dumbbell_One-Arm_Triceps_Extension': 'Standing_One-Arm_Dumbbell_Triceps_Extension',
    'Jogging_Treadmill': 'Running_Treadmill',
    'Barbell_Full_Squat': 'Barbell_Squat',
}

# Exercises held for time.
DURATION_IDS = {'Plank', 'hz_side_plank', 'hz_wall_sit', 'hz_dead_hang'}


def new(id, name, muscle, equipment, category='strength', secondary=(), images_from=None, mechanic='compound',
        instructions=()):
    return {'id': id, 'name': name, 'category': category, 'equipment': equipment, 'primaryMuscles': [muscle],
            'secondaryMuscles': list(secondary), 'instructions': list(instructions), 'images': [],
            'mechanic': mechanic, '_images_from': images_from}


ADDITIONS = [
    new('hz_bulgarian_split_squat', 'Bulgarian Split Squat', 'quadriceps', 'dumbbell', secondary=['glutes'],
        images_from='Split_Squat_with_Dumbbells',
        instructions=['Stand a stride in front of a bench and rest the top of your back foot on it.',
                      'Lower until the front thigh is about parallel to the floor, then drive back up.']),
    new('hz_wall_sit', 'Wall Sit', 'quadriceps', 'body only', mechanic='isolation',
        instructions=['Slide down a wall until your knees are at about 90 degrees and hold.']),
    new('hz_assisted_pull_up', 'Assisted Pull-Up (Machine)', 'lats', 'machine', secondary=['biceps'],
        images_from='Band_Assisted_Pull-Up',
        instructions=['Kneel or stand on the platform, grip the handles and pull your chin over the bar.']),
    new('hz_cable_lateral_raise', 'Cable Lateral Raise', 'shoulders', 'cable', mechanic='isolation',
        images_from='Cable_Seated_Lateral_Raise',
        instructions=['Stand side-on to a low pulley and raise the handle out to the side to shoulder height.']),
    new('hz_seated_machine_row', 'Seated Machine Row', 'middle back', 'machine', secondary=['lats', 'biceps'],
        images_from='Leverage_Iso_Row',
        instructions=['Sit chest against the pad and row the handles back, squeezing the shoulder blades.']),
    new('hz_dumbbell_rdl', 'Dumbbell Romanian Deadlift', 'hamstrings', 'dumbbell', secondary=['glutes', 'lower back'],
        images_from='Stiff-Legged_Dumbbell_Deadlift',
        instructions=['Hold dumbbells in front of your thighs, soften the knees and hinge at the hips.',
                      'Lower until you feel the hamstrings stretch, then drive the hips forward.']),
    new('hz_kettlebell_swing', 'Kettlebell Swing', 'hamstrings', 'kettlebells', secondary=['glutes', 'lower back'],
        images_from='One-Arm_Kettlebell_Swings',
        instructions=['Hinge and hike the kettlebell back between your legs, then snap the hips forward to swing it to chest height.']),
    new('hz_cable_kickback', 'Cable Glute Kickback', 'glutes', 'cable', mechanic='isolation', images_from='Glute_Kickback',
        instructions=['Attach an ankle strap to a low pulley and kick the leg straight back.']),
    new('hz_glute_bridge', 'Glute Bridge', 'glutes', 'body only', secondary=['hamstrings'],
        images_from='Single_Leg_Glute_Bridge',
        instructions=['Lie on your back, feet flat, and drive the hips up until the body forms a straight line.']),
    new('hz_side_plank', 'Side Plank', 'abdominals', 'body only', mechanic='isolation',
        instructions=['Lie on your side on one forearm and lift the hips so the body forms a straight line. Hold.']),
    new('hz_bicycle_crunch', 'Bicycle Crunch', 'abdominals', 'body only', mechanic='isolation',
        images_from='Cross-Body_Crunch',
        instructions=['Lie on your back and alternate bringing each elbow toward the opposite knee.']),
    new('hz_dead_hang', 'Dead Hang', 'forearms', 'body only', secondary=['lats'], mechanic='isolation',
        images_from='One_Handed_Hang', instructions=['Hang from a pull-up bar with straight arms. Hold.']),
    new('hz_banded_lateral_walk', 'Banded Lateral Walk', 'abductors', 'bands', secondary=['glutes'],
        mechanic='isolation',
        instructions=['Place a band around your legs, sit into a half squat and step sideways.']),
    new('hz_burpee', 'Burpee', 'quadriceps', 'body only', category='plyometrics', secondary=['chest'],
        instructions=['Squat down, jump the feet back to a plank, return and jump up.']),
    # Container for a stretching session: one card in a workout whose rows are
    # different stretches (each timed). Hidden from the exercise list.
    new('hz_stretching', 'Stretching', 'full body', 'body only', category='stretching', mechanic=None,
        instructions=['A set of stretches, each held for a time (30 s by default).']),
    # Stretches
    new('hz_pigeon_pose', 'Pigeon Pose', 'glutes', 'body only', category='stretching', mechanic=None,
        images_from='Ankle_On_The_Knee',
        instructions=['From hands and knees, bring one knee forward behind the wrist and extend the other leg back.',
                      'Lower the hips and hold. Switch sides.']),
    new('hz_doorway_chest_stretch', 'Doorway Chest Stretch', 'chest', 'body only', category='stretching',
        mechanic=None, images_from='Chest_And_Front_Of_Shoulder_Stretch',
        instructions=['Place your forearms on the door frame and gently lean forward until you feel the chest stretch.']),
    new('hz_cobra_stretch', 'Cobra Stretch', 'abdominals', 'body only', category='stretching', mechanic=None,
        instructions=['Lie face down, hands under the shoulders, and press the chest up keeping the hips down.']),
    new('hz_butterfly_stretch', 'Butterfly Stretch', 'adductors', 'body only', category='stretching', mechanic=None,
        instructions=['Sit with the soles of your feet together and let the knees fall out. Gently press them down.']),
]


def generic_clean(name):
    n = re.sub(r'\s*-\s*With Bands$', ' (Band)', name, flags=re.I)
    n = re.sub(r'\s+with Bands$', ' (Band)', n, flags=re.I)
    n = re.sub(r'\s+with Chains$', ' (Chains)', n, flags=re.I)
    n = re.sub(r'-SMR$', ' Foam Roll', n)
    n = re.sub(r'\bFlyes\b|\bFlye\b', 'Fly', n)
    return n


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else SOURCE
    if src.startswith('http'):
        data = json.load(urllib.request.urlopen(src))
    else:
        data = json.load(open(src))
    by_id = {e['id']: e for e in data}

    for a in ADDITIONS:
        assert a['id'] not in by_id, a['id']
        img_src = a.pop('_images_from')
        if img_src:
            a['images'] = by_id[img_src]['images'][:1]
        by_id[a['id']] = a
        data.append(a)

    out_names = {}
    for e in data:
        e['name'] = generic_clean(e['name'])
    for id, name in RENAMES.items():
        by_id[id]['name'] = name

    for muscle, items in POPULAR.items():
        prio = MUSCLE_PRIORITY.index(muscle)
        for pos, (id, name) in enumerate(items):
            e = by_id[id]
            assert e['primaryMuscles'][0] == muscle, (id, e['primaryMuscles'])
            if name:
                e['name'] = name
            e['popularity'] = pos * 20 + prio
    for pos, (id, name) in enumerate(POPULAR_STRETCHES):
        e = by_id[id]
        assert e['category'] == 'stretching', id
        e['name'] = name
        e['popularity'] = 1000 + pos

    # Training level: our additions are common basics; popular exercises are
    # always shown in the app regardless of level.
    for e in data:
        e.setdefault('level', 'beginner')
    for id in DURATION_IDS:
        by_id[id]['tracking'] = 'duration'
    for id, instead in HIDDEN.items():
        assert instead in by_id and instead not in HIDDEN, id
        by_id[id]['hidden'] = True

    # Names must be unique (case-insensitive) among visible exercises.
    for e in data:
        if e.get('hidden'):
            continue
        key = e['name'].lower()
        assert key not in out_names, f"duplicate name {e['name']}: {e['id']} / {out_names[key]}"
        out_names[key] = e['id']

    keep = ['id', 'name', 'category', 'equipment', 'primaryMuscles', 'secondaryMuscles', 'instructions', 'images',
            'mechanic', 'popularity', 'tracking', 'hidden', 'level']
    out = [{k: e[k] for k in keep if e.get(k) is not None} for e in sorted(data, key=lambda e: e['name'])]
    with open('assets/exercises.json', 'w') as f:
        json.dump(out, f, separators=(',', ':'), ensure_ascii=False)
    ranked = sum(1 for e in out if 'popularity' in e)
    print(f'{len(out)} exercises ({len(ADDITIONS)} added, {ranked} ranked)')


if __name__ == '__main__':
    main()
