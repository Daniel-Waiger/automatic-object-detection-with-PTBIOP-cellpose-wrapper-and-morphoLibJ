# Changelog

## 2.0.0 – 2026-10-14

New macro: `macros/muscle_fiber_segmentation.ijm`. The original is kept unchanged in
`legacy/muscle_fiber_seg_cellpose_morpholibj_v1.ijm`.

### Changed
- Processes every image in a folder instead of one image per run. All settings are
  collected in one dialog (SciJava script parameters) and can be recorded/re-used.
- Uses the current PTBIOP command `Cellpose ...` (cellpose ≤ 3.1.1.1) instead of the
  removed `Cellpose Advanced`. Default model `cyto2` (v1 used `cyto2_omni`).
- Pixel size is read from the image metadata; the paper's value
  (330 px = 50 µm, i.e. 0.151515 µm/px) is used only as a fallback or when forced.
- Measurements now include Feret diameters (`Feret`, `MinFeret`, …) and shape
  descriptors (`Circ.`, `AR`, `Round`, `Solidity`) in addition to area and fitted ellipse.
- QC image saved as PNG (`<name>_qc.png`), with fiber outlines and equivalent ellipses.
- Output file names: `<name>_results.csv`, `<name>_rois.zip`, `<name>_labels.tif` (new),
  `run_log.txt` (new: parameters, ImageJ version, pixel size and fiber count per image).
- Closes only the windows it opened; v1 ran `Close All`.
- Refuses to run when the output folder is the input folder, so outputs such as
  `<name>_labels.tif` are never re-processed as inputs on a later run.

### Fixed
- QC overlay was shifted by the border margin (6 px up and left): edge removal cropped
  the label image and the cropped coordinates were drawn on the uncropped original.
  The margin is now padded back after edge removal.
- ROI Manager is reset before each image, so ROIs from an interrupted run are not
  measured again.
- Objects smaller than a minimum area (default 100 px) are discarded. Cellpose labels
  can carry isolated stray pixels, which *Label image to ROIs* turned into extra
  1-pixel rows in the results table.
- Removed the macro-recorder artefact `rm=[RoiManager[size=766, visible=true]]`.
- The MorphoLibJ ellipse table is closed after each image instead of accumulating.

## 1.0.0 – 2023

Version used in Dayan et al., Poultry Science 2023
([doi:10.1016/j.psj.2023.102792](https://doi.org/10.1016/j.psj.2023.102792)).
