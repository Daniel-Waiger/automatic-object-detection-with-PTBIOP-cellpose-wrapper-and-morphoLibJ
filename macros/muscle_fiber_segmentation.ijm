// Muscle fiber segmentation and morphometry
// Cellpose (PTBIOP wrapper) + MorphoLibJ + ImageJ measurements, batch processing.
//
// Author : Daniel Waiger - Center for Scientific Imaging, Faculty of Agriculture,
//          Food and Environment, The Hebrew University of Jerusalem
// Method : Dayan J, Goldman N, Waiger D, et al. Poultry Science 2023;102(8):102792.
//          https://doi.org/10.1016/j.psj.2023.102792
// Docs   : see README.md (requirements, parameters, outputs)
// License: MIT

#@ File    (label = "Input folder", style = "directory") inputDir
#@ File    (label = "Output folder", style = "directory") outputDir
#@ String  (label = "File extension to process", value = ".tif") fileSuffix
#@ File    (label = "Cellpose Python environment folder", style = "directory") envPath
#@ String  (label = "Environment type", choices = {"conda", "venv"}) envType
#@ String  (label = "Cellpose model", value = "cyto2") model
#@ Float   (label = "Expected fiber diameter (pixels)", value = 150) diameter
#@ Integer (label = "Cytoplasm channel (0 = grayscale)", value = 0) cytoChannel
#@ Integer (label = "Nuclei channel (0 = none)", value = 0) nucleiChannel
#@ Float   (label = "Flow threshold", value = 0.4) flowThreshold
#@ Float   (label = "Cell probability threshold", value = 0.0) cellprobThreshold
#@ Boolean (label = "Use GPU", value = true) useGpu
#@ Integer (label = "Exclude fibers within N pixels of the image edge", value = 6, min = 1) borderMargin
#@ Integer (label = "Minimum fiber area (pixels)", value = 100, min = 0) minFiberArea
#@ Double  (label = "Fallback pixel size (um/pixel)", value = 0.151515, style = "format:0.000000") fallbackPixelSize
#@ Boolean (label = "Always use fallback pixel size (ignore image metadata)", value = false) forcePixelSize

requires("1.54f");

MACRO_VERSION = "2.0.0";

// ---------------------------------------------------------------------------
// Run log: parameters and per-image calibration are written next to the results
// ---------------------------------------------------------------------------
logPath = outputDir + File.separator + "run_log.txt";
File.saveString("Muscle fiber segmentation v" + MACRO_VERSION + "\n"
	+ "Started: " + timestamp() + "\n"
	+ "ImageJ: " + getVersion() + "\n"
	+ "Input folder: " + inputDir + "\n"
	+ "File extension: " + fileSuffix + "\n"
	+ "Cellpose environment: " + envPath + " (" + envType + ")\n"
	+ "Model: " + model + "\n"
	+ "Diameter (px): " + diameter + "\n"
	+ "Channels (cyto, nuclei): " + cytoChannel + ", " + nucleiChannel + "\n"
	+ "Flow threshold: " + flowThreshold + "\n"
	+ "Cell probability threshold: " + cellprobThreshold + "\n"
	+ "Use GPU: " + yesNo(useGpu) + "\n"
	+ "Border margin (px): " + borderMargin + "\n"
	+ "Minimum fiber area (px): " + minFiberArea + "\n"
	+ "Fallback pixel size (um/px): " + d2s(fallbackPixelSize, 6) + " (forced: " + yesNo(forcePixelSize) + ")\n"
	+ "\nfile\tpixel_width\tunit\tcalibration_source\tfibers\tfragments_removed\n", logPath);

cellposeFlags = "--flow_threshold, " + flowThreshold + ", --cellprob_threshold, " + cellprobThreshold;
// Macro booleans are numbers (1/0): parameters and function results are compared explicitly
if (useGpu == true)
	cellposeFlags = "--use_gpu, " + cellposeFlags;

// Area, fitted ellipse, shape descriptors and Feret diameters, labelled per fiber
run("Set Measurements...", "area fit shape feret's display redirect=None decimal=3");

files = getFileList(inputDir);
processed = 0;

for (i = 0; i < files.length; i++) {
	if (!endsWith(toLowerCase(files[i]), toLowerCase(fileSuffix)))
		continue;

	path = inputDir + File.separator + files[i];
	baseName = File.getNameWithoutExtension(path);
	print("[" + (processed + 1) + "] " + files[i]);

	roiManager("reset");
	run("Clear Results");

	open(path);
	originalId = getImageID();
	originalTitle = getTitle();

	// --- 1. Spatial calibration ------------------------------------------------
	getPixelSize(unit, pixelWidth, pixelHeight);
	calibrationSource = "metadata";
	if (forcePixelSize == true || isMicron(unit) == false) {
		pixelWidth = fallbackPixelSize;
		pixelHeight = fallbackPixelSize;
		unit = "micron";
		calibrationSource = "fallback";
	}
	setVoxelSize(pixelWidth, pixelHeight, 1, unit);

	// --- 2. Cellpose segmentation (output: "<title>-cellpose" label image) ----
	run("Cellpose ...", "imp=[" + originalTitle + "] env_path=[" + envPath + "] env_type=" + envType
		+ " model=" + model + " model_path= diameter=" + diameter
		+ " ch1=" + cytoChannel + " ch2=" + nucleiChannel
		+ " additional_flags=[" + cellposeFlags + "]");
	cellposeId = getImageID();
	if (cellposeId == originalId)
		exit("Cellpose returned no label image for " + files[i] + ".\nCheck the Cellpose environment path and the Log window.");

	// --- 3. Remove fibers within borderMargin pixels of the image edge -------
	// Crop the margin, drop labels touching the new edge, then pad the margin back
	// with background so label coordinates match the original image again.
	m = borderMargin;
	run("Extend Image Borders", "left=-" + m + " right=-" + m + " top=-" + m + " bottom=-" + m + " fill=Replicate");
	croppedId = getImageID();
	run("Remove Border Labels", "left right top bottom");
	cleanedId = getImageID();
	run("Extend Image Borders", "left=" + m + " right=" + m + " top=" + m + " bottom=" + m + " fill=Black");
	labelsId = getImageID();
	closeImages(newArray(cellposeId, croppedId, cleanedId));

	selectImage(labelsId);
	setVoxelSize(pixelWidth, pixelHeight, 1, unit); // MorphoLibJ does not keep calibration
	run("glasbey on dark");
	saveAs("Tiff", outputDir + File.separator + baseName + "_labels.tif");
	labelsTitle = getTitle();

	// --- 4. Per-fiber measurements -------------------------------------------
	run("Label image to ROIs", "imp=[" + labelsTitle + "]");
	selectImage(labelsId);
	if (roiManager("count") > 0)
		roiManager("Measure");

	// Cellpose labels can carry isolated stray pixels, which "Label image to ROIs"
	// turns into separate ROIs: drop ROIs smaller than minFiberArea pixels.
	minArea = minFiberArea * pixelWidth * pixelHeight; // pixels -> calibrated area
	fragments = 0;
	for (r = nResults - 1; r >= 0; r--) {
		if (getResult("Area", r) < minArea) {
			Table.deleteRows(r, r, "Results");
			roiManager("select", r);
			roiManager("delete");
			fragments++;
		}
	}
	nFibers = roiManager("count");

	if (nFibers > 0) {
		saveAs("Results", outputDir + File.separator + baseName + "_results.csv");
		roiManager("Save", outputDir + File.separator + baseName + "_rois.zip");

		// --- 5. QC image: fiber outlines (yellow) + equivalent ellipses and axes (blue)
		selectImage(originalId);
		run("Select None");
		run("Duplicate...", "title=[" + baseName + "_qc]");
		qcId = getImageID();
		run("Equivalent Ellipse", "label=[" + labelsTitle + "] overlay overlay_0 image=[" + baseName + "_qc]");
		closeWindowsEndingWith("-Ellipses");
		selectImage(qcId);
		for (r = 0; r < nFibers; r++) {
			roiManager("select", r);
			Overlay.addSelection("yellow");
		}
		run("Select None");
		run("Flatten");
		flatId = getImageID();
		saveAs("PNG", outputDir + File.separator + baseName + "_qc.png");
		closeImages(newArray(qcId, flatId));
	} else {
		print("    No fibers left after edge and size filtering; no results written.");
	}

	File.append(files[i] + "\t" + d2s(pixelWidth, 6) + "\t" + unit + "\t" + calibrationSource + "\t" + nFibers + "\t" + fragments, logPath);
	print("    " + nFibers + " fibers (" + fragments + " fragments removed), pixel size " + d2s(pixelWidth, 6) + " " + unit + " (" + calibrationSource + ")");

	closeImages(newArray(labelsId, originalId));
	roiManager("reset");
	run("Clear Results");
	processed++;
}

File.append("\nFinished: " + timestamp() + " - " + processed + " image(s) processed", logPath);
if (isOpen("Results"))
	close("Results");
print("Done: " + processed + " image(s) processed. Output: " + outputDir);

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// True if the calibration unit is micrometers (ImageJ reports several spellings)
function isMicron(unit) {
	u = toLowerCase(unit);
	if (u == "micron" || u == "microns" || u == "um")
		return true;
	if (u == fromCharCode(181) + "m" || u == fromCharCode(956) + "m")
		return true;
	return false;
}

function yesNo(flag) {
	if (flag == true)
		return "yes";
	return "no";
}

function closeImages(ids) {
	for (k = 0; k < ids.length; k++) {
		if (isOpen(ids[k])) {
			selectImage(ids[k]);
			close();
		}
	}
}

function closeWindowsEndingWith(suffix) {
	titles = getList("window.titles");
	for (k = 0; k < titles.length; k++) {
		if (endsWith(titles[k], suffix))
			close(titles[k]);
	}
}

// YYYY-MM-DD HH:MM:SS (getDateAndTime returns a 0-based month)
function timestamp() {
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	return "" + year + "-" + IJ.pad(month + 1, 2) + "-" + IJ.pad(dayOfMonth, 2)
		+ " " + IJ.pad(hour, 2) + ":" + IJ.pad(minute, 2) + ":" + IJ.pad(second, 2);
}
