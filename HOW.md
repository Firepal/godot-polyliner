# How It Works
The built-in Path node in Godot provides an interface for  a Bézier curve with points and handles. Line3D extends from this node.

## Geometry

Drawing starts by getting an array of sampled points on the curve. (Godot's `Curve3D` resource makes this easy!)

Then for every two points in the array, we make two quads (using triangles with correct winding order). 
  - We do not move the vertices at all however. Thus each new quad is infinitely thin, and the vertices directly represent the sampled curve points' position.

The vertices of these quads are also fitted with UV coordinates and a *vertex color* representing the direction from the current vertex to the next vertex. (This data is the meat of the technique!)

What we did until now was simply setting up the fireworks, so to say. Now we actually make this string of vertices look like a line and face the camera using...

## Rendering
...A vertex shader function! Surprise! :trollface:

We take:
- The direction from this vertex to the next vertex (recall we calculated it on the CPU and stored it in the vertex color)
- The direction from this vertex to the camera's position (latter of which is available in Godot's built-in CAMERA_MATRIX shader uniform)

The normalized cross product of these two direction vectors is a vector perpendicular to both, the *golden vector*... (That's not its name in the code, but it is worthy!)

Finally, depending on the height value of the UV coordinates we planted into the mesh [which allows us to know if we're a top or bottom vertex on the quad], the *golden vector* is either added or substracted with the current vertex position. 
- In other words, we take the top and bottom quad vertices, we separate them using the *golden vector*, and the GPU will fill the separation with glorious [triangle] quad pixels!

Line width is just a matter of multiplying the *golden vector* by the requested width before adding it to the current vertex position.

<details>

Okay, but *why* a vertex shader? In short:

- CPUs were designed to run one instruction at a time. They are good at doing big sequential tasks, but can't efficiently do many things at the same time. (If you've heard of [operating system schedulers](https://en.wikipedia.org/wiki/Scheduling_(computing)), they are what enable computer multitasking to be possible and efficient!)

- GPUs were designed to run a hundred thousand instructions at a time, because they are fitted with hundreds of tiny calculators! They are good at [embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) tasks; specifically linear algebra.

If we were to try and convert the vertex shader function to a plain CPU-side function that ran every frame and did all the same math and vertex-manipulation, it definitely wouldn't be able to process as many vertices as a GPU could in the same processing timeframe.

By implementing the "camera-facing" part in the vertex shader, the CPU just has to provide the line mesh with the embedded direction/color data, and the GPU will handle processing all the vertices through the function in parallel.

</details>