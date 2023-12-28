# OpenSCAD Benchmarking

This repo contains scripts for benchmarking select OpenSCAD features.
Each benchmark feature currently has its own small top-level script, which generally calls into the main benchmarking tools.

## Common scripts

TODO:
* analyze_results.py
* gen_param_sets


## Geometry evaluation

This compares performance of the CGAL, fast-csg and Manifold geometry backends.

### Running the benchmarks yourself on your own files

```bash
export OPENSCAD=$PWD/OpenSCAD.app/Contents/MacOS/OpenSCAD
# export OPENSCAD=$PWD/openscad

git clone https://gist.github.com/ochafik/70a6b15e982b7ccd5a79ff9afd99dbcf openscad-manifold-benchmarks
cd openscad-manifold-benchmarks
./get_libs # Will fetch lots of common libs

RUNS=5 ./bench_geom.sh data/geom-tests/bolts.scad
# ./bench-geom.sh *.scad 
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

These will be picked up automatically by `./bench_geom.sh scalemail.scad`

### Results

| File | Speed-up | CPU utilization | manifold | fast-csg | nef |
|:-----|---------:|----------------:|---------:|---------:|----:|
| condensed-matter.scad | 8.3x | 2.6 cores | 0.99 seconds | 8.25 seconds |  |
| condensed-matter.scad:$fn=100 | 19.9x | 3.2 cores | 27.16 seconds | 8 minutes and 59.73 seconds |  |
| examples/Parametric/candleStand.scad:small | 32.3x | 2.4 cores | 0.25 seconds | **49.16 seconds** | 8.05 seconds |
| bolts.scad | 8.9x | 1.3 cores | 4.59 seconds | 40.82 seconds |  |
| box-with-filleted-holes.scad | 9.6x | 2.9 cores | 10.61 seconds | 1 minute and 42.3 seconds | 18 minutes and 52.35 seconds |
| libs/github.com/rcolyer/threads-scad/threads.scad | 13.1x | 1.5 cores | 1.39 seconds | 18.27 seconds | 1 minute and 9.41 seconds |
| maze.scad: | 27.7x | 2.6 cores | 3.35 seconds | **5 minutes and 32.25 seconds** | 1 minute and 32.68 seconds |
| menger.scad | 36.7x | 3.9 cores | 5.08 seconds | 3 minutes and 6.14 seconds | 4 minutes and 53.86 seconds |
| minkowski-of-minkowski-difference.scad | 1.0 | 1.8 cores | 42.85 seconds | 43.59 seconds | 3 minutes and 34.84 seconds |
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

### Interpretation

*   🎉 OpenSCAD+Manifold is 5-30x faster than OpenSCAD+fast-csg (CGAL corefinement w/ a Nef fallback). The reasons for that are many:
    *   it doesn't use exact rationals (mere single-precision floats), which are slow *and* (in their lazy CGAL::Epeck wrappers) have suprising performance characteristics (which I tried to work around with all the exact-forcing options)
    *   it's multithreaded (even though I didn't build w/ CUDA support, just w/ CPU multithreading using TBB), 
    *   it does not fall back to Nef CSG operations. Well, ok, it does use Nefs to perform convex parts decomposition, and in case of exception it will fall back to Nef minkowski, but normal CSG ops are 100% handled by Manifold.
*   ❌ One model is surprisingly not improving (minkowski-of-minkowski-difference.scad), needs investigation! Lemme know if you find more like this!
*   ⚠️ More testing (esp. re/ output quality) is needed! Besides normal bugs, there might be cases where the single precision bites, say, with lots of nested up/down scalings. I have plans to flatten the tree in https://github.com/openscad/openscad/pull/4561 to help deal with that.
*   ⚠️ Manifold might be more picky with input meshes, rejecting more eagerly invalid geometry. Mostly a backwards compatibility issue, but maybe we could fix some meshes if that's too widespread an issue.
*   🎉 Manifold is the way to go. It's fast (and will only get better, its code base seems to have room for more parallelism), allows for safe parallel algorithms (like the minkowski variant I've thrown in, which itself has room for more parallelism), and it seems to have more predictible performance than CGAL's corefinement (numbers above are single runs, but if you run with `RUNS=10 ./bench-geom.sh ...` you'll see the variance of fast-csg is much higher for some reason!).
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

## VBO Rendering (single frame)

This compares performance of the the various VBO rendering experimental features vs. the default (non-VBO) rendering.
The test itself measures the full OpenSCAD time for generating a single PNG frame.

The purpose of the test is to benchmark time to render the first preview frame, and to catch regressions in frame setup time.

TODO:
* Go through tests and eliminate tests with very similar performance
* Measure both preview, throwntogether and render(Manifold)
* Linux vs. macOS

**Running**

```
OPENSCAD=path/to/openscad RUNS=2 ./bench_vbo.sh data/vbo-tests/*.scad
```

**Results**

Columns:
* **none:** Default rendering (no VBOs)
* **vbo-indexed:** vbo-new, but with indexed VBOs
* **vbo-old:** --enable=vertex-object-renderers
* **vbo-new:** --enable=vertex-object-renderers --enable=vertex-object-renderers-direct --enable=vertex-object-renderers-prealloc


For these results, we're mostly interested in validating that **vbo-new** is comparable to or better than **none**.

| File | none | vbo-indexed | vbo-new | vbo-old |
|:-----|----:|----:|----:|----:|
| data/vbo-tests/colorful-spheres.scad | 0.07 seconds | 0.06 seconds | 0.06 seconds | 0.06 seconds |
| data/vbo-tests/colorful-spheres.scad:step=10 | 0.27 seconds | 0.46 seconds | 0.38 seconds | 0.46 seconds |
| data/vbo-tests/colorful-spheres.scad:step=20 | 0.08 seconds | 0.10 seconds | 0.09 seconds | 0.10 seconds |
| data/vbo-tests/colorful-spheres.scad:step=5 | 1.61 seconds | 1.60 seconds | 1.60 seconds | 1.61 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad | 0.15 seconds | 0.23 seconds | 0.15 seconds | 0.23 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=10 | 0.48 seconds | 0.77 seconds | 0.40 seconds | 0.77 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=20 | 1.73 seconds | 2.91 seconds | 1.42 seconds | 2.91 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=50 | 11.86 seconds | 21.30 seconds | 8.85 seconds | 21.33 seconds |
| data/vbo-tests/large-sphere.scad | 0.04 seconds | 0.04 seconds | 0.04 seconds | 0.04 seconds |
| data/vbo-tests/large-sphere.scad:$fn=1000 | 0.27 seconds | 1.00 seconds | 0.64 seconds | 1.00 seconds |
| data/vbo-tests/large-sphere.scad:$fn=200 | 0.05 seconds | 0.08 seconds | 0.07 seconds | 0.08 seconds |
| data/vbo-tests/large-sphere.scad:$fn=2000 | 1.26 seconds | 4.59 seconds | 3.16 seconds | 4.58 seconds |
| data/vbo-tests/many-cubes.scad | 0.06 seconds | 0.07 seconds | 0.06 seconds | 0.07 seconds |
| data/vbo-tests/many-cubes.scad:NUM=100 | 8.45 seconds | 8.45 seconds | 8.47 seconds | 8.44 seconds |
| data/vbo-tests/many-cubes.scad:NUM=20 | 0.13 seconds | 0.21 seconds | 0.18 seconds | 0.21 seconds |
| data/vbo-tests/many-cubes.scad:NUM=50 | 1.10 seconds | 1.10 seconds | 1.09 seconds | 1.10 seconds |
| data/vbo-tests/many-spheres.scad | 0.14 seconds | 1.23 seconds | 0.55 seconds | 1.23 seconds |
| data/vbo-tests/many-spheres.scad:NUM=1000 | 0.86 seconds | 11.90 seconds | 5.04 seconds | 11.89 seconds |
| data/vbo-tests/many-spheres.scad:NUM=200 | 0.22 seconds | 2.39 seconds | 1.03 seconds | 2.40 seconds |
| data/vbo-tests/many-spheres.scad:NUM=500 | 0.46 seconds | 6.24 seconds | 2.49 seconds | 5.99 seconds |

## VBO Rendering (multiple frames)

This test renders multiple frames after a single frame setup. The time includes full OpenSCAD processing time as well; it's very similar to the "single frame" variant, except it just calls `GLView::render()`` a number of times in succession. 

TODO:
* Go through tests and eliminate tests with very similar performance
* Test preview vs. throwntogether vs. render(Manifold)
* Linux vs. macOS

**Running**

```
OPENSCAD=path/to/openscad RUNS=2 bench_vbo_num_frames.sh data/numframes-tests/*.scad
```

**Results**

| File | none | vbo-indexed | vbo-new | vbo-old |
|:-----|----:|----:|----:|----:|
| data/numframes-tests/colorful-spheres.scad | 0.11 seconds | 0.09 seconds | 0.08 seconds | 0.08 seconds |
| data/numframes-tests/colorful-spheres.scad:step=10 | 0.88 seconds | 0.78 seconds | 0.74 seconds | 0.82 seconds |
| data/numframes-tests/colorful-spheres.scad:step=20 | 0.15 seconds | 0.14 seconds | 0.14 seconds | 0.14 seconds |
| data/numframes-tests/colorful-spheres.scad:step=5 | 1.71 seconds | 1.61 seconds | 1.61 seconds | 1.61 seconds |
| data/numframes-tests/cube-with-half-spheres-dents.scad | 5.34 seconds | 0.28 seconds | 0.24 seconds | 0.31 seconds |
| data/numframes-tests/cube-with-half-spheres-dents.scad:N=10 | 24.12 seconds | 0.92 seconds | 0.71 seconds | 0.93 seconds |
| data/numframes-tests/cube-with-half-spheres-dents.scad:N=20 | 1.0 minutes, 39.16 seconds | 3.61 seconds | 2.75 seconds | 3.61 seconds |
| data/numframes-tests/large-sphere.scad | 0.07 seconds | 0.04 seconds | 0.05 seconds | 0.04 seconds |
| data/numframes-tests/large-sphere.scad:$fn=1000 | 2.55 seconds | 0.87 seconds | 0.67 seconds | 0.88 seconds |
| data/numframes-tests/large-sphere.scad:$fn=200 | 0.15 seconds | 0.08 seconds | 0.07 seconds | 0.08 seconds |
| data/numframes-tests/large-sphere.scad:$fn=2000 | 10.56 seconds | 4.26 seconds | 3.26 seconds | 4.12 seconds |
| data/numframes-tests/many-cubes.scad | 0.11 seconds | 0.09 seconds | 0.09 seconds | 0.09 seconds |
| data/numframes-tests/many-cubes.scad:NUM=100 | 8.59 seconds | 8.55 seconds | 8.49 seconds | 8.45 seconds |
| data/numframes-tests/many-cubes.scad:NUM=20 | 0.40 seconds | 0.35 seconds | 0.33 seconds | 0.34 seconds |
| data/numframes-tests/many-cubes.scad:NUM=50 | 1.10 seconds | 1.10 seconds | 1.10 seconds | 1.17 seconds |
| data/numframes-tests/many-spheres.scad | 3.99 seconds | 1.03 seconds | 0.62 seconds | 1.04 seconds |
| data/numframes-tests/many-spheres.scad:NUM=1000 | 39.44 seconds | 9.95 seconds | 5.75 seconds | 10.32 seconds |
| data/numframes-tests/many-spheres.scad:NUM=200 | 8.01 seconds | 2.00 seconds | 1.16 seconds | 2.00 seconds |
| data/numframes-tests/many-spheres.scad:NUM=500 | 19.65 seconds | 5.14 seconds | 2.80 seconds | 5.17