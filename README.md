# Line3D early development
<img src="icon.png"></img><br>
***This plugin is currently being developed in Godot 3.4 and is not guaranteed to function in 3.3***    

Adds new Line3D node that allows you to use the Path node to generate lines that face the camera.

[How it Works!](HOW.md)

# Usage Instructions

1.  Create a Line3D node (as a child of another node, for example)

2.  Setup the curve like you would with the Godot `Path` node. 
<details>

Select the `Line3D`, click the yellow-y "Add Points" icon at the top of the viewport and click around to create points.

To add handles to a point, click the greyish "Select Points" icon at the top of the viewport, hold Shift and click-and-drag on a point to add curve handles to it.

</details>

3.  Set the Line3D's `Material` property with a new ShaderMaterial

4. Drag-and-drop any of the shaders in `addons/godot-line3d/shaders/` into the "Shader" property slot of the ShaderMaterial
<details>

You can modify one of the provided shaders, but remember to copy it to a fresh-new Shader resource first by clicking the little down-arrow next to the Shader resource and clicking "Make Unique", so your cool changes don't overwrite the original Shader resource file!

![Godot UI with "Make Unique" highlighted](unique_shader.png)

</details>
<br>

5.  Enjoy your line!

# To-Do
- Custom curve system with orientable points 
- SpatialMaterial shader injection?
