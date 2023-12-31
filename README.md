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

### Linux Results

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

**Linux Results**

Columns:
* **none:** Default rendering (no VBOs)
* **vbo-indexed:** vbo-new, but with indexed VBOs
* **vbo-old:** --enable=vertex-object-renderers
* **vbo-new:** --enable=vertex-object-renderers --enable=vertex-object-renderers-direct --enable=vertex-object-renderers-prealloc


For these results, we're mostly interested in validating that **vbo-new** is comparable to or better than **none**.

| File | none | vbo-indexed | vbo-new | vbo-old |
|:-----|----:|----:|----:|----:|
| data/vbo-tests/colorful-spheres.scad | 0.13 seconds | 0.44 seconds | 0.28 seconds | 0.45 seconds |
| data/vbo-tests/colorful-spheres.scad:step=10 | 0.40 seconds | 1.98 seconds | 1.09 seconds | 1.76 seconds |
| data/vbo-tests/colorful-spheres.scad:step=20 | 0.16 seconds | 0.84 seconds | 0.48 seconds | 0.81 seconds |
| data/vbo-tests/colorful-spheres.scad:step=5 | 2.03 seconds | 5.09 seconds | 3.78 seconds | 5.11 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad | 0.16 seconds | 0.20 seconds | 0.15 seconds | 0.20 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=10 | 0.47 seconds | 0.61 seconds | 0.40 seconds | 0.61 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=20 | 1.71 seconds | 2.25 seconds | 1.41 seconds | 2.25 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=50 | 11.75 seconds | 16.96 seconds | 8.63 seconds | 17.06 seconds |
| data/vbo-tests/large-sphere.scad | 0.05 seconds | 0.05 seconds | 0.04 seconds | 0.04 seconds |
| data/vbo-tests/large-sphere.scad:$fn=1000 | 0.27 seconds | 0.85 seconds | 0.64 seconds | 0.85 seconds |
| data/vbo-tests/large-sphere.scad:$fn=200 | 0.06 seconds | 0.08 seconds | 0.07 seconds | 0.08 seconds |
| data/vbo-tests/large-sphere.scad:$fn=2000 | 1.26 seconds | 3.96 seconds | 3.13 seconds | 3.97 seconds |
| data/vbo-tests/many-cubes.scad | 0.06 seconds | 0.07 seconds | 0.06 seconds | 0.07 seconds |
| data/vbo-tests/many-cubes.scad:NUM=100 | 9.38 seconds | 18.07 seconds | 15.24 seconds | 18.05 seconds |
| data/vbo-tests/many-cubes.scad:NUM=20 | 0.13 seconds | 0.20 seconds | 0.18 seconds | 0.20 seconds |
| data/vbo-tests/many-cubes.scad:NUM=50 | 1.21 seconds | 2.29 seconds | 1.93 seconds | 2.29 seconds |
| data/vbo-tests/many-spheres.scad | 0.14 seconds | 0.97 seconds | 0.56 seconds | 0.96 seconds |
| data/vbo-tests/many-spheres.scad:NUM=1000 | 0.86 seconds | 9.25 seconds | 5.04 seconds | 9.26 seconds |
| data/vbo-tests/many-spheres.scad:NUM=200 | 0.22 seconds | 1.87 seconds | 1.03 seconds | 1.87 seconds |
| data/vbo-tests/many-spheres.scad:NUM=500 | 0.46 seconds | 4.62 seconds | 2.48 seconds | 4.64 seconds |

**macOS Results**

| File | none | vbo-indexed | vbo-new | vbo-old |
|:-----|----:|----:|----:|----:|
| data/vbo-tests/colorful-spheres.scad | 0.37 seconds | 41.46 seconds | 0.50 seconds | 50.66 seconds |
| data/vbo-tests/colorful-spheres.scad:step=10 | 1.04 seconds | Timed out | 2.05 seconds | Timed out |
| data/vbo-tests/colorful-spheres.scad:step=20 | 0.50 seconds | Timed out | 0.90 seconds | Timed out |
| data/vbo-tests/colorful-spheres.scad:step=5 | 3.61 seconds | Timed out | 8.24 seconds | Timed out |
| data/vbo-tests/cube-with-half-spheres-dents.scad | 0.64 seconds | 16.11 seconds | 0.30 seconds | 17.36 seconds |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=10 | 2.16 seconds | Timed out | 0.74 seconds | Timed out |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=20 | 8.10 seconds | Timed out | 2.54 seconds | Timed out |
| data/vbo-tests/cube-with-half-spheres-dents.scad:N=50 | 50.58 seconds | Timed out | 16.13 seconds | Timed out |
| data/vbo-tests/large-sphere.scad | 0.13 seconds | 0.13 seconds | 0.11 seconds | 0.13 seconds |
| data/vbo-tests/large-sphere.scad:$fn=1000 | 0.59 seconds | Timed out | 0.96 seconds | Timed out |
| data/vbo-tests/large-sphere.scad:$fn=200 | 0.13 seconds | 2.64 seconds | 0.15 seconds | 2.65 seconds |
| data/vbo-tests/large-sphere.scad:$fn=2000 | 2.42 seconds | Timed out | 4.41 seconds | Timed out |
| data/vbo-tests/many-cubes.scad | 0.16 seconds | 0.91 seconds | 0.17 seconds | 0.90 seconds |
| data/vbo-tests/many-cubes.scad:NUM=20 | 0.25 seconds | 6.17 seconds | 0.45 seconds | 6.19 seconds |
| data/vbo-tests/many-cubes.scad:NUM=50 | 1.85 seconds | Timed out | 4.64 seconds | Timed out |
| data/vbo-tests/many-spheres.scad | 0.57 seconds | Timed out | 0.98 seconds | Timed out |
| data/vbo-tests/many-spheres.scad:NUM=1000 | 4.46 seconds | Timed out | 8.78 seconds | Timed out |
| data/vbo-tests/many-spheres.scad:NUM=200 | 1.00 seconds | Timed out | 1.99 seconds | Timed out |
| data/vbo-tests/many-spheres.scad:NUM=500 | 2.44 seconds | Timed out | 4.42 seconds | Timed out |


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

**Linux Results**

| File | none | vbo-indexed | vbo-new | vbo-old |
|:-----|----:|----:|----:|----:|
| data/numframes-tests/colorful-spheres.scad | 1.61 seconds | 0.77 seconds | 0.30 seconds | 0.77 seconds |
| data/numframes-tests/colorful-spheres.scad:step=10 | 6.03 seconds | 3.33 seconds | 1.43 seconds | 3.33 seconds |
| data/numframes-tests/colorful-spheres.scad:step=20 | 2.97 seconds | 1.60 seconds | 0.52 seconds | 1.45 seconds |
| data/numframes-tests/colorful-spheres.scad:step=5 | 14.21 seconds | 10.74 seconds | 6.81 seconds | 10.55 seconds |
| data/numframes-tests/cube-with-half-spheres-dents.scad | 5.32 seconds | 0.42 seconds | 0.24 seconds | 0.42 seconds |
| data/numframes-tests/cube-with-half-spheres-dents.scad:N=10 | 24.08 seconds | 1.45 seconds | 0.72 seconds | 1.45 seconds |
| data/numframes-tests/cube-with-half-spheres-dents.scad:N=20 | 1.0 minutes, 39.54 seconds | 5.81 seconds | 2.75 seconds | 5.82 seconds |
| data/numframes-tests/large-sphere.scad | 0.05 seconds | 0.04 seconds | 0.04 seconds | 0.04 seconds |
| data/numframes-tests/large-sphere.scad:$fn=1000 | 2.56 seconds | 1.41 seconds | 0.67 seconds | 1.41 seconds |
| data/numframes-tests/large-sphere.scad:$fn=200 | 0.15 seconds | 0.10 seconds | 0.07 seconds | 0.10 seconds |
| data/numframes-tests/large-sphere.scad:$fn=2000 | 10.40 seconds | 6.26 seconds | 3.24 seconds | 6.28 seconds |
| data/numframes-tests/many-cubes.scad | 0.10 seconds | 0.09 seconds | 0.08 seconds | 0.10 seconds |
| data/numframes-tests/many-cubes.scad:NUM=100 | 43.11 seconds | 45.06 seconds | 35.78 seconds | 45.32 seconds |
| data/numframes-tests/many-cubes.scad:NUM=20 | 0.40 seconds | 0.39 seconds | 0.32 seconds | 0.40 seconds |
| data/numframes-tests/many-cubes.scad:NUM=50 | 5.47 seconds | 5.68 seconds | 4.52 seconds | 5.77 seconds |
| data/numframes-tests/many-spheres.scad | 4.03 seconds | 1.79 seconds | 0.61 seconds | 1.79 seconds |
| data/numframes-tests/many-spheres.scad:NUM=1000 | 39.98 seconds | 17.36 seconds | 5.67 seconds | 17.51 seconds |
| data/numframes-tests/many-spheres.scad:NUM=200 | 7.95 seconds | 3.52 seconds | 1.15 seconds | 3.55 seconds |
| data/numframes-tests/many-spheres.scad:NUM=500 | 19.68 seconds | 8.73 seconds | 2.80 seconds | 8.77 seconds |

**macOS Results**

| File | none | vbo-indexed | vbo-new | vbo-old |
|:-----|----:|----:|----:|----:|
| data/numframes-tests/colorful-spheres.scad | 8.75 seconds | Timed out | 0.60 seconds | Timed out |
| data/numframes-tests/colorful-spheres.scad:step=10 | 30.05 seconds | Timed out | 3.24 seconds | Timed out |
| data/numframes-tests/colorful-spheres.scad:step=20 | 16.41 seconds | Timed out | 1.02 seconds | Timed out |
| data/numframes-tests/colorful-spheres.scad:step=5 | 1.0 minutes, 0.25 seconds | Timed out | 16.57 seconds | Timed out |
| data/numframes-tests/cube-with-half-spheres-dents.scad | 24.51 seconds | 1.0 minutes, 6.86 seconds | 1.23 seconds | 1.0 minutes, 7.08 seconds |
| data/numframes-tests/cube-with-half-spheres-dents.scad:N=10 | 1.0 minutes, 39.75 seconds | Timed out | 4.40 seconds | Timed out |
| data/numframes-tests/cube-with-half-spheres-dents.scad:N=20 | Timed out | Timed out | 16.16 seconds | Timed out |
| data/numframes-tests/large-sphere.scad | 0.15 seconds | 0.17 seconds | 0.14 seconds | 0.17 seconds |
| data/numframes-tests/large-sphere.scad:$fn=1000 | 13.49 seconds | Timed out | 1.03 seconds | Timed out |
| data/numframes-tests/large-sphere.scad:$fn=200 | 0.66 seconds | 10.17 seconds | 0.17 seconds | 10.14 seconds |
| data/numframes-tests/large-sphere.scad:$fn=2000 | 54.19 seconds | Timed out | 4.65 seconds | Timed out |
| data/numframes-tests/many-cubes.scad | 0.27 seconds | 3.26 seconds | 0.23 seconds | 3.28 seconds |
| data/numframes-tests/many-cubes.scad:NUM=100 | Timed out | Timed out | Timed out | Timed out |
| data/numframes-tests/many-cubes.scad:NUM=20 | 1.16 seconds | 25.48 seconds | 0.98 seconds | 27.29 seconds |
| data/numframes-tests/many-cubes.scad:NUM=50 | 16.37 seconds | Timed out | 12.40 seconds | Timed out |
| data/numframes-tests/many-spheres.scad | 21.84 seconds | Timed out | 1.35 seconds | Timed out |
| data/numframes-tests/many-spheres.scad:NUM=1000 | Timed out | Timed out | 11.99 seconds | Timed out |
| data/numframes-tests/many-spheres.scad:NUM=200 | 47.73 seconds | Timed out | 2.54 seconds | Timed out |
| data/numframes-tests/many-spheres.scad:NUM=500 | 1.0 minutes, 44.38 seconds | Timed out | 6.08 seconds | Timed out |
