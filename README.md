[screenshot]: https://raw.githubusercontent.com/awkwardpolygons/cartographer/master/addons/cartographer/screenshot.png "Cartographer screenshot"
# Cartographer
Cartographer is a GPU powered terrain editor for Godot 3.

![][screenshot]

# Features

- [x] Terrain sizes from 32 to 1024 units
- [x] Upto 16 texture layers
- - [x] 16 layer Weightmap with GPU painting
- - [x] Triplanar texture mapping
- - [ ] Full PBR material support
- [x] GPU Heightmap sculpting
- - [x] 16bit Heightmaps
- [x] GPU Clipmap LOD terrain mesh
- [x] Heightmap physics collision shape generator
- [x] Terrain ray picking for painting and sculpting
- - [ ] Improve ray picking performance
- [x] Dynamic lighting
- - [ ] Lightmap baking
- [ ] Customizable terrain visual shader
- - [ ] Custom visual shader nodes
- [ ] Undo / redo
- [x] Brushes panel
- [x] Custom Brushes
- - [x] Brush strength
- - [x] Brush scale
- - [ ] Brush rotation
- - [ ] Brush spacing
- - [ ] Brush strength jitter
- - [ ] Brush scale jitter
- - [ ] Brush rotation jitter
- - [ ] Brush spacing jitter
- [x] Editing tools
- - [x] Raise
- - [x] Lower
- - [x] Paint
- - [x] Erase
- - [x] Fill
- - [ ] Smooth
- - [ ] Sharpen
- - [ ] Level
- [ ] Advanced editing with:
- - [ ] Anchors
- - [ ] Shapes


# Guide
## Terrain Editing

1. Install the addon into your project.
2. In a spatial scene click add and type "cartoterrain".
3. Add a CartoTerrain node.
4. Inspect the terrain node, set the height, width, depth to desired size.
5. In the inspector select and expand the Material property.
   1. Click `new` to create a new texture array, (or `load` to load an existing array).
   2. Select a location for the textures and name your file.
   3. Click `save`.
   4. Choose upto 16 textures to add.
      1. Ensure all the textures are the same size and have the same import settings.
   5. Click `save`.
   6. Wait while the texture array is created (this may take a while).
      1. If there are errors ensure all the textures are the same size and have the same import settings.
   7. Once created you should have a list of textures to choose from, click on a texture to select it for painting.
6. Click on the Brushes tab on the right side of the editor, you must have a brush selected to do any editing.
7. Choose a brush or add a new brush
   1. If adding a brush make sure to set the channel for the brush mask.
   2. 16bit .exr brushes are best.
8. Make sure the terrain node is selected, and choose your terrain editing tool from the icons above the main view.
   1. You can choose to raise or lower terrain, or paint or fill a texture.
   2. Hold `alt` while using a tool to do the opposite, ie. while raising hold `alt` to lower.
9. Sculpt and paint your terrain.
10. Remember to save with `ctrl-s` while working.
11. **IMPORTANT!** To improve the editing experience, under the Material property find the HeightMap and MaskMap textures and save them to external files.

## Physics

1. To add collision physics to your terrain add a StaticBody to your terrain node.
2. Add a CollisionCartoTerrain node to the StaticBody.
3. Select the CollisionCartoTerrain node and in the inspector choose the Terrain Path, (select your terrain node).
4. The HeightMapShape will be auto generated and updated when the terrain changes.
5. **IMPORTANT!** Do not add the physics while sculpting your terrain, it will be very slow as the HeightMapShape will be forced to update as you make changes.
   1. Either only add the physics nodes once you are done editing.
   2. Or only add the Terrain Path to the CollisionCartoTerrain once you are done editing.
