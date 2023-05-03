# Explanation of IJM Code for Starconvex Shape Detection

This IJM code is designed to automatically detect starconvex shapes using PTBIOP-cellpose wrapper and the morphoLibJ plugin.


Automatic Starconvex shape detection with PTBIOP-cellpose wrapper and morphoLibJ
Made by: Daniel Waiger - Faculty of Agriculture, Food and Environment - HUJI
Contact: danielw@savion.huji.ac.il / daniel.waiger@mail.huji.ac.il / image.sc_ID: Daniel_Waiger
For: Noam Goldman - Faculty of Agriculture, Food and Environment - HUJI - Zehava Uni Lab

This code automates the detection of star-convex-shaped objects in images using the PTBIOP-Cellpose wrapper and morphoLibJ plugin.
The script prompts the user to select an input image and output folder, and then collects the image name and sets measurement parameters.
The Cellpose advanced function is used to detect objects in the image, with GPU acceleration, and the resulting image is processed using morphoLibJ to remove border labels, convert the image to ROIs, and set measurements for area, fit, and display. The script also saves the results as a CSV file and ROIs zip file.

The code then creates an equivalent ellipse for each detected object and overlays it on the original image. It also creates a flat image with ROIs and axes to demonstrate the workflow. Finally, the script closes all windows and results, ready for the next run.

This code is useful for anyone who needs to detect and analyze star-convex-shaped objects in images. The Cellpose wrapper and morphoLibJ are powerful tools for object detection and processing, and this code streamlines the process of using them. Additionally, the script saves the results in a convenient format, making further analysis easier.

## Select Image and Output Folder
The user is prompted to select an input image and an output folder for the results.
```ijm
//Select an image and an output folder
run("Open...");
outputDir = getDirectory("Output Folder Selection");
```
## Collect Image Name
The script then collects the name of the original image and creates a new name to be used for the output files.
```ijm
//Collecting image name
orgName = getTitle();
newName = File.getNameWithoutExtension(orgName);
```
## Select Parameters to Measure
The script prompts the user to select which parameters to measure, such as area and fit.
```ijm
//Selecting parameters to measure
run("Set Measurements...", "area fit display redirect=None decimal=3");
```
## Cellpose Parameters for Object Detection with GPU
The script then prompts the user to enter the estimated diameter of the objects in the image and sets the necessary Cellpose parameters for object detection with GPU.
```ijm
//Cellpose parameters for object detection with GPU
shapeDiameter = getNumber("What is the estimated diameter of your objects?", 150 )
run("Cellpose Advanced", "diameter=" + shapeDiameter + " cellproba_threshold=0.0 flow_threshold=0.4 anisotropy=1.0 diam_threshold=12.0 model=cyto2_omni nuclei_channel=0 cyto_channel=0 dimensionmode=2D stitch_threshold=-1.0 omni=false cluster=false additional_flags= ");
```
## MorphoLibJ: Cellpose Result Image and Label Processing Commands
The script then performs MorphoLibJ cellpose result image and label processing commands.
```ijm
//MorphoLibJ: cellpose result image and label processing commands
run("Extend Image Borders", "left=-6 right=-6 top=-6 bottom=-6 fill=Replicate");
run("Remove Border Labels", "left right top bottom");
run("Label image to ROIs", "rm=[RoiManager[size=766, visible=true]]");
run("Set Measurements...", "area fit display add redirect=None decimal=3");
run("Set Scale...", "distance=330 known=50 unit=um");
roiManager("Show None");
roiManager("Show All");
roiManager("Measure");
run("3-3-2 RGB");
saveAs("Results", outputDir + newName + "_Results.csv");
roiManager("Save", outputDir + newName + "_ROIs.zip");
print(orgName + " analysis is done!");
```

## Equivalent Ellipse Creation
The macro creates an equivalent ellipse of the labeled objects and saves it as an overlay on the original image.
```ijm
run("Equivalent Ellipse", "label=" + newName + "-cellpose-ext overlay overlay_0 image=" + orgName);
```
## Demo Image Creation
The macro creates a flat image with ROIs and axes to create a workflow demo and saves it as a TIFF file.
```ijm
selectImage(orgName);
run("Duplicate...", "title=" + newName + "_with_ROIs_and_axes");
run("Show Overlay");
run("From ROI Manager");
run("Flatten");
flatImage = getTitle();
saveAs("Tiff", outputDir + flatImage + ".tif");
```
## Closing Windows
Finally, the macro closes all open windows, including the ROI Manager and Results.
```ijm
run("Close All");
close("ROI Manager");
close("Results");
```
