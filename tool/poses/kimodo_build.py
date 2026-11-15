"""Comparison page: current photo figure next to Kimodo's movements (2 versions) per exercise."""
import json, re, sys
D, data, km, names = sys.argv[1], json.load(open(sys.argv[2])), json.load(open(sys.argv[3])), json.load(open(sys.argv[4]))
ex = {x['id']: x for x in json.load(open('assets/exercises.json'))}
dart = open('lib/data/database.dart').read()
uni = set(re.findall(r"'([^']+)'", dart[dart.index('const defaultUnilateral'):dart.index('];', dart.index('const defaultUnilateral'))]))
ix = {n: i for i, n in enumerate(names)}
MAP = {'neck': 'Neck1', 'sh_l': 'LeftArm', 'sh_r': 'RightArm', 'el_l': 'LeftForeArm', 'el_r': 'RightForeArm',
       'wr_l': 'LeftHand', 'wr_r': 'RightHand', 'hip_l': 'LeftLeg', 'hip_r': 'RightLeg', 'kn_l': 'LeftShin', 'kn_r': 'RightShin',
       'an_l': 'LeftFoot', 'an_r': 'RightFoot', 'toe_l': 'LeftToeEnd', 'toe_r': 'RightToeEnd'}
def conv(fr):
    P = lambda n: [fr[ix[n]][0], -fr[ix[n]][1], fr[ix[n]][2]]  # Kimodo is Y-up; the figures use Y-down
    o = {k: P(v) for k, v in MAP.items()}
    for s in 'lr':
        a, t = o['an_' + s], o['toe_' + s]
        o['heel_' + s] = [a[0] - .3 * (t[0] - a[0]), t[1], a[2] - .3 * (t[2] - a[2])]
    head, le, re_ = P('Head'), P('LeftEye'), P('RightEye')
    em = [(le[i] + re_[i]) / 2 for i in range(3)]
    o['ear_l'] = [head[i] + (le[i] - re_[i]) * 1.2 for i in range(3)]
    o['ear_r'] = [head[i] - (le[i] - re_[i]) * 1.2 for i in range(3)]
    o['nose'] = [em[i] + (em[i] - head[i]) * .6 for i in range(3)]
    return o
d3, meta, order = {}, {}, []
for i, mv in km['motions'].items():
    m = {'name': ex[i]['name'], 'eq': ex[i].get('equipment') or 'body only', 'mus': ex[i]['primaryMuscles'],
         'sec': ex[i].get('secondaryMuscles', []), 'uni': i in uni, 'track': ex[i].get('tracking')}
    if i in data['d']:
        d3[i] = data['d'][i]; meta[i] = dict(m, name=m['name'] + ' · now'); order.append(i)
    for n, smp in enumerate(mv['samples']):
        seq = [conv(f) for f in smp]
        k = f'{i}__k{n}'; d3[k] = {'j': [seq[0], seq[len(seq) // 2]], 'seq': seq}
        meta[k] = dict(m, name=m['name'] + ' · Kimodo ' + 'AB'[n]); order.append(k)
t = open(D + '/review_tpl.html').read()
for k, v in {'__D3__': json.dumps(d3, separators=(',', ':')), '__D2__': '{}', '__META__': json.dumps(meta, separators=(',', ':')),
             '__ORDER__': '[]', '__ALL__': json.dumps(order), '__FAILED__': '[]', '__COUNT__': str(len(order))}.items():
    t = t.replace(k, v)
open(D + '/kimodo.html', 'w').write(t)
print(len(order), 'tiles')
