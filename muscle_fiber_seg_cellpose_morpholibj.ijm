//Automatic Starconvex shape detection with PTBIOP-cellpose wrapper and morphoLibJ
//Made by: Daniel Waiger - Faculty of Agriculture, Food and Environment - HUJI
//danielw@savion.huji.ac.il / daniel.waiger@mail.huji.ac.il / image.sc_ID: Daniel_Waiger
//For: Noam Goldman - Faculty of Agriculture, Food and Environment - HUJI - Zehava Uni Lab


//Select an image and an output folder
run("Open...");
outputDir = getDirectory("Output Folder Selection");

//Colecting image name
orgName = getTitle();
newName = File.getNameWithoutExtension(orgName);

//Selecting parameters to measure
run("Set Measurements...", "area fit display redirect=None decimal=3");

//Cellpose parameters for object detection with GPU
shapeDiameter = getNumber("What is the estimated diameter of your objects?", 150 )
run("Cellpose Advanced", "diameter=" + shapeDiameter + " cellproba_threshold=0.0 flow_threshold=0.4 anisotropy=1.0 diam_threshold=12.0 model=cyto2_omni nuclei_channel=0 cyto_channel=0 dimensionmode=2D stitch_threshold=-1.0 omni=false cluster=false additional_flags= ");


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
run("Equivalent Ellipse", "label=0-ext overlay overlay_0 image=" + orgName);

//Create a flat image with ROIs and axes to create a workflow demo
selectImage(orgName);
run("Duplicate...", "title=" + orgName + "_with_ROIs_and_axes");
run("Show Overlay");
run("From ROI Manager");
run("Flatten");
flatImage = getTitle();
saveAs("Tiff", outputDir + flatImage + ".tif");

//Close everything before next run
run("Close All");
close("ROI Manager");
close("Results");
