# Polyliner early development
<img src="icon.png"></img><br>
***This plugin is currently being developed in Godot 3.4 and is not guaranteed to function in 3.3***    

Adds 3D thick line rendering capabilities.

# Usage Instructions

1.  Create a LinePath3D node

2.  Setup the curve like you would with the Godot `Path` node. 
<details>

Select the `LinePath3D`, click the yellow-y "Add Points" icon at the top of the viewport and click around to create points.

To add handles to a point, click the greyish "Select Points" icon at the top of the viewport, hold Shift and click-and-drag on a point to add curve handles to it.

</details><br>

3. ???

4. Profit!

You can drag-and-drop any of the shaders from `addons/godot-polyliner/shaders/` into the "Shader" property slot. Remember to click "Make Unique" on it so you don't overwrite the original plugin data when you edit them.


# To-Do
- Implement curve system with a fully custom "tangent"
- SpatialMaterial shader injection
