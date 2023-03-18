# OpenSCAD + Manifold = ❤️

Benchmark scripts & results for the upcoming [Manifold](https://github.com/elalish/manifold) rendering engine support in [OpenSCAD](https://github.com/openscad/openscad) (https://github.com/openscad/openscad/pull/4533)

TL;DR: [Jump to results already!](#results)

For reference: [old benchmarks of fast-csg](https://gist.github.com/ochafik/2db96400e3c1f73558fcede990b8a355), which the Manifold backend might well soon replace!

Note that minkowski operations get a specific boost thanks to the introduction of parallelism in the algorithm itself (and then the  union of parts it generates benefits from Manifold's own parallelism)

## Running the benchmarks yourself on your own files

```bash
export OPENSCAD=$PWD/OpenSCAD.app/Contents/MacOS/OpenSCAD
# export OPENSCAD=$PWD/openscad

git clone https://gist.github.com/ochafik/70a6b15e982b7ccd5a79ff9afd99dbcf openscad-manifold-benchmarks
cd openscad-manifold-benchmarks
./get_libs # Will fetch lots of common libs

RUNS=5 ./bench bolts.scad
# ./bench *.scad 
```

Each run outputs a timestamped JSON results file. Multiple files can be merge-analyzed to generate a markdown table and human summary:

```bash
./analyze_results out/results-3-files-5-variants-20230317-1944.json out/threads-20230317-1943.json
```

Also, if `file.scad` file has a companion `file.json` with customizer parameter sets, all the sets will be executed. Specify `file.scad:` to only execute the file with its default values, or specify a single parameter set by name `file.scad:my parameter set name`.

You can generate custom parameter sets with the following helper:

```bash
./gen_param_sets 'N=[2,10]' '$fn=[20,100]' | tee scalemail.json
```

```
{
    "fileFormatVersion": "1",
    "parameterSets": {
        "N=2 $fn=20": {
            "N": "2",
            "$fn": "20"
        },
        "N=2 $fn=100": {
            "N": "2",
            "$fn": "100"
        },
        "N=10 $fn=20": {
            "N": "10",
            "$fn": "20"
        },
        "N=10 $fn=100": {
            "N": "10",
            "$fn": "100"
        }
    }
}
```

These will be picked up automatically by `./bench scalemail.scad`

## Results

| File | Speed-up | CPU utilization | manifold | fast-csg | nef |
|:-----|---------:|----------------:|---------:|---------:|----:|
| examples/Parametric/candleStand.scad:small | 32.3x | 2.4 cores | 0.25 seconds | **49.16 seconds** | 8.05 seconds |
| bolts.scad | 8.9x | 1.3 cores | 4.59 seconds | 40.82 seconds |  |
| box-with-filleted-holes.scad | 9.6x | 2.9 cores | 10.61 seconds | 1 minute and 42.3 seconds | 18 minutes and 52.35 seconds |
| libs/github.com/rcolyer/threads-scad/threads.scad | 13.1x | 1.5 cores | 1.39 seconds | 18.27 seconds | 1 minute and 9.41 seconds |
| maze.scad: | 27.7x | 2.6 cores | 3.35 seconds | **5 minutes and 32.25 seconds** | 1 minute and 32.68 seconds |
| menger.scad | 36.7x | 3.9 cores | 5.08 seconds | 3 minutes and 6.14 seconds | 4 minutes and 53.86 seconds |
| scalemail.scad | 3.6x | 2.4 cores | 0.61 seconds | 2.17 seconds |  |
| scalemail.scad:N=10 $fn=100 | 19.8x | 3.1 cores | 20.29 seconds | 6 minutes and 41.64 seconds |  |
| scalemail.scad:N=10 $fn=20 | 15.1x | 2.7 cores | 2.01 seconds | 30.39 seconds |  |
| scalemail.scad:N=2 $fn=100 | 5.3x | 3.5 cores | 9.25 seconds | 49.12 seconds |  |
| scalemail.scad:N=2 $fn=20 | 3.5x | 2.3 cores | 0.61 seconds | 2.15 seconds |  |
| smoothed-antennas.scad | 20.5x | 6.0 cores | 38.07 seconds | 13 minutes and 1.15 seconds |  |
| smoothed-cup.scad | 6.4x | 2.9 cores | 4.42 seconds | 28.5 seconds | 4 minutes and 20.81 seconds |

Notes:
*   Speed-up is over the fastest of fast-csg and nef (nef = normal rendering used in the stable releases).
*   fast-csg and nef never use more than 1 core
*   fast-csg has all the related options turned on: `fast-csg-remesh` (which keeps the # of faces in check by remeshing solids after each corefinement), `fast-csg-exact` and `fast-csg-exact-callbacks` (which force lazy numbers to exact after - or during - each operation), `fast-csg-trust-corefinement` (which tries corefinement even in edge cases where we know it might not work)
*   All timings are on a Mac M2 Max (w/ a single run). Please let me know if you see significant speedup differences on other platforms.

## Interpretation

*   🎉 OpenSCAD+Manifold is 5-30x faster than OpenSCAD+fast-csg (CGAL corefinement w/ a Nef fallback). The reasons for that are many:
    *   it doesn't use exact rationals (mere single-precision floats), which are slow *and* (in their lazy CGAL::Epeck wrappers) have suprising performance characteristics (which I tried to work around with all the exact-forcing options)
    *   it's multithreaded (even though I didn't build w/ CUDA support, just w/ CPU multithreading using TBB), 
    *   it does not fall back to Nef CSG operations. Well, ok, it does use Nefs to perform convex parts decomposition, and in case of exception it will fall back to Nef minkowski, but normal CSG ops are 100% handled by Manifold.
*   ❌ One model is surprisingly not improving (minkowski-of-minkowski-difference.scad), needs investigation! Lemme know if you find more like this!
*   ⚠️ More testing (esp. re/ output quality) is needed! Besides normal bugs, there might be cases where the single precision bites, say, with lots of nested up/down scalings. I have plans to flatten the tree in https://github.com/openscad/openscad/pull/4561 to help deal with that.
*   ⚠️ Manifold might be more picky with input meshes, rejecting more eagerly invalid geometry. Mostly a backwards compatibility issue, but maybe we could fix some meshes if that's too widespread an issue.
*   🎉 Manifold is the way to go. It's fast (and will only get better, its code base seems to have room for more parallelism), allows for safe parallel algorithms (like the minkowski variant I've thrown in, which itself has room for more parallelism), and it seems to have more predictible performance than CGAL's corefinement (numbers above are single runs, but if you run with `RUNS=10 ./bench ...` you'll see the variance of fast-csg is much higher for some reason!).
*   🎉 Some models are slower w/ fast-csg than nef. This could be because of Nef fallbacks, issues w/ my remeshing, high cost of forcing numbers to exact, etc. But Manifold crunches through these models for breakfast, so who cares?

Some screenshots of the associated models (which source is below):

*   box-with-filleted-holes.scad

<img width="675" alt="image" src="https://user-images.githubusercontent.com/273860/225524855-819b52fb-534a-4e63-ab97-74b21cb9893d.png">

*   smoothed-cup.scad

<img width="542" alt="image" src="https://user-images.githubusercontent.com/273860/225525640-b87aba18-10eb-42fb-8fa1-ad0a46590ea3.png">

*   smoothed-antennas.scad: taken from [BOSL's docs](https://github.com/revarbat/BOSL2/wiki/Tutorial-Attachments#diffremove-keep), with extra minkowski and detail.

<img width="542" alt="image" src="https://user-images.githubusercontent.com/273860/225692892-f7be9f4c-bff6-4032-a021-efc930a3882d.png">

*   minkowski-of-minkowski-difference.scad: This isn't so fast, need to understand why

<img width="520" alt="image" src="https://user-images.githubusercontent.com/273860/225530675-75e1ea6e-bb0d-4c39-897c-89c119b0e12d.png">

