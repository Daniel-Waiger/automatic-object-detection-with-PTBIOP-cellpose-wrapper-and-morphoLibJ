# Shape Detection and Analysis for Muscle Fibers with PTBIOP Cellpose Wrapper and MorphoLibJ

This repository contains an IJM script designed to automatically detect and analyze objects in images using the PTBIOP-Cellpose wrapper and the MorphoLibJ plugin. As published in [A deep learning-based automated image analysis for histological evaluation of broiler pectoral muscle] (https://www.sciencedirect.com/science/article/pii/S0032579123003115?via%3Dihub) 

## Author

- **Daniel Waiger**
  - Faculty of Agriculture, Food and Environment, Hebrew University of Jerusalem (HUJI)
  - Contact: [danielw@savion.huji.ac.il](mailto:danielw@savion.huji.ac.il) / [daniel.waiger@mail.huji.ac.il](mailto:daniel.waiger@mail.huji.ac.il)
  - Image.sc ID: Daniel_Waiger

## For

- **Noam Goldman**
  - Faculty of Agriculture, Food and Environment, HUJI
  - Zehava Uni Lab

## Overview

This IJM script provides a comprehensive workflow for detecting and analyzing star-convex shapes in biological images. The workflow includes:

1. **Image and Output Folder Selection:** User selects the input image and output directory.
2. **Image Name Collection:** The script collects the original image name and generates a new name for output files.
3. **Parameter Selection:** The script sets measurement parameters (e.g., area, fit).
4. **Object Detection with Cellpose:** User inputs the estimated diameter of objects, and the script sets the necessary parameters for object detection using Cellpose with GPU acceleration.
5. **MorphoLibJ Processing:** The script processes Cellpose results using various MorphoLibJ commands.
6. **Equivalent Ellipse Creation:** The script creates equivalent ellipses for detected objects and overlays them on the original image.
7. **Demo Image Creation:** The script generates a flat image with ROIs and axes for demonstration purposes.
8. **Cleanup:** The script closes all open windows and saves the results.

## Prerequisites

- Fiji (ImageJ) with the PTBIOP-Cellpose wrapper and MorphoLibJ plugin installed.
- A suitable GPU for acceleration (optional but recommended).

## Usage

1. **Select Image and Output Folder**
   - Run the script and select the input image and output folder when prompted.

2. **Collect Image Name**
   - The script will automatically collect the name of the original image.

3. **Select Parameters to Measure**
   - The script will set the measurement parameters.

4. **Cellpose Parameters for Object Detection with GPU**
   - Enter the estimated diameter of the objects in the image when prompted.

5. **MorphoLibJ Processing**
   - The script will process the Cellpose results using various commands.

6. **Equivalent Ellipse Creation**
   - The script will create and overlay equivalent ellipses on the original image.

7. **Demo Image Creation**
   - The script will generate a flat image with ROIs and axes for demonstration.

8. **Cleanup**
   - The script will close all open windows and save the results.

## Example Code

Below is an example of how the code is structured within the script:

```ijm
// Example of selecting an image and output folder
run("Open...");
outputDir = getDirectory("Output Folder Selection");

// Collecting the image name
orgName = getTitle();
newName = File.getNameWithoutExtension(orgName);

// Setting measurement parameters
run("Set Measurements...", "area fit display redirect=None decimal=3");

// Object detection with Cellpose
shapeDiameter = getNumber("What is the estimated diameter of your objects?", 150);
run("Cellpose Advanced", "diameter=" + shapeDiameter + " cellproba_threshold=0.0 flow_threshold=0.4 anisotropy=1.0 diam_threshold=12.0 model=cyto2_omni nuclei_channel=0 cyto_channel=0 dimensionmode=2D stitch_threshold=-1.0 omni=false cluster=false additional_flags= ");

// Processing with MorphoLibJ
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

// Creating equivalent ellipses
run("Equivalent Ellipse", "label=" + newName + "-cellpose-ext overlay overlay_0 image=" + orgName);

// Creating a flat image for demo
selectImage(orgName);
run("Duplicate...", "title=" + newName + "_with_ROIs_and_axes");
run("Show Overlay");
run("From ROI Manager");
run("Flatten");
flatImage = getTitle();
saveAs("Tiff", outputDir + flatImage + ".tif");

// Closing all windows
run("Close All");
close("ROI Manager");
close("Results");
```