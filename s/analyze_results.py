import sys, json
import itertools

results = json.load(sys.stdin)['results']
def get_file(r):
    return r["parameters"]["file"]
def get_mode(r):
    return r["parameters"]["mode"]
def get_result_with_mode(rs, mode):
    return filter(rs, lambda r: get_mode(r) == mode)[0]

def summarize(file, rs):
    manifold = get_result_with_mode(rs, "manifold")["mean"]
    fastcsg = get_result_with_mode(rs, "fastcsg")["mean"]
    return f'{file}: Manifold: {manifold}s ({faster}x faster)\nFastCsg: {fastcsg}s'

print('\n\n'.join([
    summarize(file, rs)
    for file, rs in itertools.groupby(sorted(results, get_file), get_file)
    if len(rs) == 2
]))

# {
#   "results": [
#     {
#       "command": "./render.sh manifold 'minbosl.scad'",
#       "mean": 2.02906278666,
#       "stddev": null,
#       "median": 2.02906278666,
#       "user": 5.29055854,
#       "system": 0.84655516,
#       "min": 2.02906278666,
#       "max": 2.02906278666,
#       "times": [
#         2.02906278666
#       ],
#       "exit_codes": [
#         0
#       ],
#       "parameters": {
#         "mode": "manifold"
#       }
#     }
#   ]
# }
