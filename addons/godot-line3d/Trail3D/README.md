# Trail3D

Samples and stores its own global transform (position, rotation) over time, then renders it as a trailling line.

Properties:
- Max Points : `int` = 10
    - Specifies the highest number of transforms that will be stored.
- Extra Points : `int` = 0
    - It is extremely advisable to set this as low as possible, vertex count will increase *exponentially* as you increase this.
    - Specifies how many *new* transforms will be stored from interpolating between this frame and last frame's transforms.
- Damping : `float` = 0.0
    - Specifies how much the trail's "sampling transform" is interpolated with the `Trail3D`'s actual transform.
    - The generated trail mesh will more gradually "follow" the `Trail3D` node as this value increases, while a value of 0 snaps the trail to the `Trail3D`'s transform.
        - Warning! High values will create a gap between the `Trail3D` node and the generated trail mesh, which may or may not be desirable.
- Render As Line : `bool` = false
    - Specifies if the trail mesh should be generated like a Line3D line mesh, thus being compatible with its camera-facing shaders.
        - Note: Setting this without a Line3D material applied will make the trail mesh infinitely thin. This is due to how Line3D line meshes are generated.
- Material
    - Specifies which material will be applied on the line mesh.

