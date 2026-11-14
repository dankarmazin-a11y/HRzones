import json, sys
D, variant = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else '')
d3 = json.load(open(D + '/p3d/mock3d.json')); d2 = json.load(open(D + '/pose/canon.json'))
ex = {x['id']: x for x in json.load(open('assets/exercises.json'))}
order = ['Barbell_Squat','Barbell_Deadlift','Barbell_Curl','Barbell_Hip_Thrust','Dumbbell_Shoulder_Press','Side_Lateral_Raise','Dumbbell_Lunges','Pushups','Pullups','Lying_Leg_Curls']
meta = {i: {'name': ex[i]['name'], 'eq': ex[i].get('equipment') or 'body only', 'mus': ex[i]['primaryMuscles'], 'sec': ex[i].get('secondaryMuscles', [])} for i in order}
t = open(D + '/linefig3_tpl.html').read()
for k, v in {'__D3__': json.dumps(d3, separators=(',', ':')), '__D2__': json.dumps({i: d2[i] for i in order if i in d2}, separators=(',', ':')),
             '__META__': json.dumps(meta), '__ORDER__': json.dumps(order)}.items():
    t = t.replace(k, v)
open(D + '/linefig.html', 'w').write(t)
print({i: (meta[i]['mus'], meta[i]['sec']) for i in order})
