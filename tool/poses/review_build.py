import json, sys
D, data = sys.argv[1], json.load(open(sys.argv[2]))
ex = {x['id']: x for x in json.load(open('assets/exercises.json'))}
d3 = {k: v for k, v in data['d'].items() if k in ex}
failed = [k for k in data['failed'] if k in ex]
order = sorted(d3, key=lambda i: (not ex[i].get('popularity'), ex[i].get('popularity') or 0, ex[i]['name']))
meta = {i: {'name': ex[i]['name'], 'eq': ex[i].get('equipment') or 'body only', 'mus': ex[i]['primaryMuscles'],
            'sec': ex[i].get('secondaryMuscles', [])} for i in list(d3) + failed}
t = open(D + '/review_tpl.html').read()
for k, v in {'__D3__': json.dumps(d3, separators=(',', ':')), '__D2__': '{}', '__META__': json.dumps(meta, separators=(',', ':')),
             '__ORDER__': '[]', '__ALL__': json.dumps(order), '__FAILED__': json.dumps(failed), '__COUNT__': str(len(order))}.items():
    t = t.replace(k, v)
open(D + '/review.html', 'w').write(t)
print(len(order), 'figures,', len(failed), 'without')
