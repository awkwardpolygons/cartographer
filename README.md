[screenshot]: https://raw.githubusercontent.com/awkwardpolygons/cartographer/master/addons/cartographer/screenshot.png "Cartographer screenshot"
# Cartographer
Cartographer is a GPU powered terrain editor for Godot 3.

![][screenshot]

# Features

- [x] GPU Clipmap LOD terrain mesh
  - [x] Terrain sizes from 32 to 1024 units
- [x] Layered Terrain Material
  - [x] 16 layer Weightmap with GPU painting
  - [x] Triplanar texture mapping
  - [x] Full PBR material support
  - [x] Masked weight blending (Experimental)
  - [x] GPU Heightmap sculpting
    - [x] 16bit Heightmaps
    - [ ] Terrain holes (for caves etc.)
- [x] Physics
  - [x] Heightmap physics collision shape generator
  - [x] Terrain ray picking for painting and sculpting
    - [x] GPU ray picking
  - [ ] Friction map?
- [x] Dynamic lighting
  - [x] Lightmap baking
- [ ] Audio map?
- [ ] Customizable terrain visual shader
  - [ ] Custom visual shader nodes
- [ ] Undo / redo
- [x] TextureArray editing
  - [x] Custome TextureArray ResourceSaver (save as `.texarr`)
  - [x] Custom TextureArray importer/builder
- [x] Brushes panel
- [x] Custom Brushes
  - [x] Brush strength
  - [x] Brush scale
  - [ ] Brush rotation
  - [ ] Brush spacing
  - [ ] Brush strength jitter
  - [ ] Brush scale jitter
  - [ ] Brush rotation jitter
  - [ ] Brush spacing jitter
- [x] Editing tools
  - [x] Raise
  - [x] Lower
  - [x] Paint
  - [x] Erase
  - [x] Fill
  - [ ] Smooth
  - [ ] Sharpen
  - [ ] Level
  - [ ] Select
- [ ] Advanced editing with:
  - [ ] Anchors
  - [ ] Shapes


# Guide
## Terrain Editing

1. Install the addon into your project.
   1. Remember to enable the cartographer singleton.
2. In a spatial scene click add and type "cartoterrain".
3. Add a CartoTerrain node.
4. Inspect the terrain node, set the height, width, depth to desired size.
5. In the inspector select and expand the Material property.
   1. Under the **Albedo**, **Normal** or **Ao, Roughness, Metallic** group find the textures field.
   2. Click `New CartoMultiTexture` to create a new texture array, (or `Load` to load an existing array).
   3. Click the `Create` button to initialize the new texture array, choose the size and format from the dialog.
   4. You will now have an empty texture array, click the folder icon on a layer to load an image for that layer.
   5. Click the down arrow to edit the layer's image channels directly.
   6. Click on a layer to select it for paiting, it will highlight when selected.
   7. To enjoy PBR rendering you need to add matching textures to each group. So if you add an Albedo texture at index 2
   then you should add its NormalMap texture to index 2 of the Normal array. For AO, Roughness, and Mettalic textures
   add the AO texture to index 2 channel 0 (Red), the Roughness texture to index 2 channel 1 (Green),
   the Mettalic texture to index 2 channel 2 (Blue).
   8. If you add a NormalMap to a layer, don't forget to enable that layer for NormalMapping.
   7. **ATTENTION!** Godot's texture arrays are quite buggy. Cartographer comes with tools to help work around this.
   You should save your texture array to an external file for perfomance, but saving the texture array in the scene
   or as a standard Godot resource (.tres or .res) causes errors. Cartographer has a custom texture array resource saver,
   click the `Save` option and choose to save the texture array as a `.texarr` file type.
   **Even better**, use the custom TextureArray Importer that builds TextureArrays from JSON files. More info below.
6. Click on the Brushes tab on the right side of the editor, you must have a brush selected to do any editing.
7. Choose a brush or add a new brush
   1. If adding a brush make sure to set the channel for the brush mask.
   2. 16bit .exr brushes are best.
8. Make sure the terrain node is selected, and choose your terrain editing tool from the icons above the main view.
   1. You can choose to raise or lower terrain, or paint or fill a texture.
   2. Hold `alt` while using a tool to do the opposite, ie. while raising hold `alt` to lower.
9. Sculpt and paint your terrain.
10. Remember to save with `ctrl-s` while working.
11. **IMPORTANT!** To improve editing and runtime performance, under the Material property find the heightmap and
weightmap textures and save them to external files (as `.res`).

## Physics

1. To add collision physics to your terrain add a StaticBody to your terrain node.
2. Add a CollisionCartoTerrain node to the StaticBody.
3. Select the CollisionCartoTerrain node and in the inspector choose the Terrain Path, (select your terrain node).
4. The HeightmapShape will be auto generated and updated when the terrain changes.
5. **IMPORTANT!** Do not add the physics while sculpting your terrain, it will be very slow as the HeightMapShape will be forced to update as you make changes.
   1. Either only add the physics nodes once you are done editing.
   2. Or only add the Terrain Path to the CollisionCartoTerrain once you are done editing.

## Custom TextureArray Importer
Cartographer now comes with a custom TextureArray Importer, this is the most stable and performant way to generate TextureArrays for your terrain material.
Godot comes with a built-in TextureArray importer, but it works by requiring you to merge all your textures into one large image in a grid pattern, then importing that image and telling the importer how many rows and columns it should split the image by.

Cartographer's TextureArray Importer builds the TextureArray from a simple JSON file. In the JSON build file you can set the texture width and height, list the images you'd like to use for each layer, and even build a layer channel by channel. The format is simple:

```js
{
  // Set the width and height for each layer
  "size": [1024, 1024],
  // Set each layer in the array
  "layers": [
    // A layer in the array can be a resource path
    "res://assets/textures/rock_albedo.jpg",
    // or a file system path
    "file://home/user/project/assets/textures/rock_albedo.jpg",
    // or simply a hex color
    "#FFFFFF",
    // Layers can also be created by mixing channels directly, using an object like this
    {
      // The key selects the destination channels, the value is an array,
      // with the first item being the image (or color hex #FFFFFF) source,
      // the second item are the source channels, here they are being read in reverse,
      // mapping blue to red, green to green, and red to blue
      "rgb": ["res://assets/textures/rock_albedo.jpg", "bgr"],
      // Here the alpha channel is set to the red channel from the rock_mask image
      "a": ["res://assets/textures/rock_mask.jpg", "r"],
    },
  ],
}
```

Save the file with a `.tabld` file extension, select the file in the editor and go to the import tab to choose your build import options.

## Experimental Masked Weight Blending
