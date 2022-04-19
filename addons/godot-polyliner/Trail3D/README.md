# Trail3D

Generates a line mesh from continuous samples of its own global transform (position, rotation) over time.

Properties:
- Max Points : `int` = 10
    - Specifies the highest number of transforms that will be stored.
- Damping : `float` = 0.5
    - Specifies how much the trail's "sampling transform" is interpolated with the `Trail3D`'s actual transform.
    - The generated line mesh will more slowly "follow" the `Trail3D` node as this value increases, while a value of 0 snaps the trail to the `Trail3D`'s transform.
        - Warning! High values will create a gap between the `Trail3D` node and the generated trail mesh, which may or may not be desirable.
- Tangent Axis : `TangentAxis` = X
    - Specifies which axis is used for tangent-facing line shaders.
- Skip Frames : `int` = 0
    - Specifies for how many frames `Trail3D` will not sample transforms or generate a mesh.
- Interpolate Skip : `bool` = false
    - Specifies whether or not to compensate for skipped frames using the `Trail3D`'s transform, at the cost of visual "jittering".
- Material
    - Specifies which material will be applied on the line mesh. If this is `null`, a default line material will be applied and made unique.

