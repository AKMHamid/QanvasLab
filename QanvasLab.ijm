/* Author: Ahmad Kamal Hamid, University of Zurich
 * Version: 1.0, 27/11/2023
 * 
 * Description: This is the QanvasLab Microscopy Figure Builder, a tool aiming to optimize the balance between customizability and user-friendliness.
 * 		Anyone who prepared microscopy figures for manuscripts or presentations knows that it's very frustrating. This tool hopefully reduces
 * 		that frustration by allowing fellow scientists to prepare microscopy figures with the ability to customize panel distribution, zoomed insets,
 * 		borders, color, text and arrow annotations, etc. 
 * Environment: FIJI/ImageJ 1.54f with the following list of plugins. Please note, most of the plugins were not used in this macro, but to  
 * 		prevent incompatibility issues, the list contains everything in the ImageJ version that was used to develop the tool:
 * 			1) ImageJ
 * 			2) Fiji
 * 			3) Java-8
 * 			4) 3D ImageJ Suite
 * 			5) Bio-Formats
 * 			6) BioVoxxel
 * 			7) BioVoxxel 3D Box
 * 			8) BoneJ
 * 			9) clij
 * 			10) clij2
 * 			11) clijx-assistant
 * 			12) clijx-assistant-extensions
 * 			13) ElastixWrapper
 * 			14) IJ-Plugins
 * 			15) IJPB-plugins
 * 			16) Neuroanatomy
 * 	Workflow:
 * 			1) Crop images to desired size (or expand canvas of subsequent images if they are smaller than crop size)
 * 			2) Choose panel alignment in case of mismatch between number of images provided and panel distribution requested
 * 			3) Choose point of interest for a color-boredered (if requested) zoomed inset (if requested) and adjust position/size/shape of ROI.
 * 				Original inset borders (customizable) can also be drawn on the panel.
 * 			4) Choose zoomed inset position on panel with a given edge offset
 * 			5) Choose scale bar parameters (if requested, for panel or for zoomed inset)
 * 			6) Select corners to trace from original inset to zoomed inset (if requested)
 * 			7) Choose up to 5 text annotations (if requested) that can customized in terms of color, panel side, offset, etc. 
 * 			8) Draw arrow annotations for particular points of interest (if requested) with customizable color, shape, width, etc.
 * 			9) Redo last panel if requested
 * 			
 */

waitForUser("Warning", "All open images will be closed without saving. Click cancel to abort macro.");
close("*");
run("Collect Garbage");

while (true) {
	// GUI
	Dialog.create("QanvasLab Microscopy Figure Builder");
	// Directories
	Dialog.addDirectory("Images folder", "/Path/");
	Dialog.addDirectory("Output folder", "/Path/");
	// Image info
	Dialog.addCheckbox("Not all images are of the same size / enable cropping functionality", true);
	// Figure info
	Dialog.addMessage("General parameters", 20, "blue");
	Dialog.addChoice("Overall background", newArray("white", "black"), "white");
	Dialog.addChoice("Figure type", newArray("8-bit", "RGB"), "RGB");
	// Compression
	Dialog.addMessage("Without binning, a 'zoomed' inset is technically impossible. Please select a compression approach for the images:");
	Dialog.addChoice("Bin method ", newArray("Average", "Median", "Min", "Max", "Sum"), "Median");
	Dialog.addNumber("Image shrink factor", 4, 2, 27, "X");
	// Panel borders
	Dialog.addMessage("Panel parameters", 20, "blue");
	Dialog.addNumber("Panel border thickness (0 = none)", 50, 0, 27, "px");
	Dialog.addString("Panel border color (r,g,b)", "0, 0, 0", 27);
	// Panel distribution, dimensions, spacing
	Dialog.addString("Dimension in panels, W x H", "5 x 3", 27);
	Dialog.addNumber("Panel spacing (% of panel width)", 5, 2, 27, "%");
	// Panel annotation
	Dialog.addCheckbox("Add text annotations", true);
	Dialog.addCheckbox("Add arrow annotations", true);
	// Original inset info
	Dialog.addMessage("Original inset parameters", 20, "blue");
	Dialog.addCheckbox("Do not use zoomed inset functionality", false);
	Dialog.addNumber("Original inset border thickness (0 = none)", 5, 0, 27, "px");
	Dialog.addString("Original inset border color (r,g,b)", "255, 0, 0", 27);
	// Zoomed inset info
	Dialog.addMessage("Zoomed inset parameters", 20, "blue");
	Dialog.addNumber("Zoom factor", 4, 2, 27, "X");
	Dialog.addCheckbox("Zoomed inset border on top of panel border", false);
	Dialog.addNumber("Zoomed inset border thickness (0 = none)", 20, 0, 27, "px");
	Dialog.addString("Zoomed inset border color (r,g,b)", "0, 0, 0", 27);
	// Inset trace info
	Dialog.addCheckbox("Draw original to zoomed insets trace lines", true);
	Dialog.addNumber("Trace line thickness", 3, 0, 27, "px");
	Dialog.addString("Trace line color (r,g,b)", "0, 0, 0", 27);
	// Scale
	Dialog.addMessage("Calibration and scale bars", 20, "blue");
	Dialog.addNumber("Scale", 3, 10, 27, "unit per px");
	Dialog.addString("Scale unit", "unit", 27);
	Dialog.addCheckbox("Panel scale bar", true);
	Dialog.addCheckbox("Inset scale bar", true);
	Dialog.addCheckbox("Use metadata scale info, ignore manual input", false);
	// Notes
	Dialog.addMessage("", 20, "blue");
	Dialog.addMessage("Throughout the execution of this macro, a large number of windows and user prompts will appear. This is\n" + 
						"to maximize customizability and circumvent errors. Please note that for most prompts, clicking 'Cancel'\n" +
						"will abort the macro altogether. Also, please avoid using the 'enter' or 'space' keys to click a certain not\n" +
						"button in the prompts, as ImageJ does not always execute the highlighted button. It is also important to\n" + 
						"click any ImageJ windows during a processing step, as changing the active window can lead to unexpected\n" +
						"behavior. For more information please contact me on GitHub\n" + 
						"with the 'Help' button below. ");
	Dialog.addHelp("www.google.ca");
	
	
	Dialog.show();
	
	
	// Fetching inputs
	// Directories
	inputDir = Dialog.getString();
	outputDir = Dialog.getString();
	// Image info
	imageSizeHomogeneity = Dialog.getCheckbox();
	// Figure info
	overallBG = Dialog.getChoice();
	figType = Dialog.getChoice();
	// Compression
	binMethod = Dialog.getChoice();
	imgShrinkFactor = Dialog.getNumber();
	// Panel borders
	panelBorderThickness = Dialog.getNumber();
	panelBorderColor = Dialog.getString();
	// Panel dimensions and spacing
	dimensionPanels = Dialog.getString();
	panelSpacing = Dialog.getNumber();
	// Panel annotations
	addTextAnnotations = Dialog.getCheckbox();
	addArrowAnnotations = Dialog.getCheckbox();
	// Original inset info
	noInset = Dialog.getCheckbox();
	roiInPanelThickness = Dialog.getNumber();
	roiInPanelBorderColor = Dialog.getString();
	// Zoomed inset info
	insetZoom = Dialog.getNumber();
	insetBorderOnTop = Dialog.getCheckbox();
	insetBorderThickness = Dialog.getNumber();
	insetBorderColor = Dialog.getString();
	// Inset trace info
	drawTrace = Dialog.getCheckbox();
	traceLineThickness = Dialog.getNumber();
	traceLineColor = Dialog.getString();
	// Scale
	lenPerPx = Dialog.getNumber();
	scaleUnit = Dialog.getString();
	addPanelScaleBar = Dialog.getCheckbox();
	addInsetScaleBar = Dialog.getCheckbox();
	useMDScale = Dialog.getCheckbox();
	
	// Failsafe for binning and zoom combination
	if (insetZoom > imgShrinkFactor) {
		restart = !getBoolean("Error!\n " + 
					"\nYou have selected an immpossible combination of image shrink and inset zoom factors.\n " +
					"Maximum possible zoom factor = image shrink factor.", "Provide new factors", "Restart macro");
		if (restart) {
			continue;
		} else {
			Dialog.create("New Factors");
			Dialog.addNumber("Image shrink factor", 4, 2, 27, "X");
			Dialog.addNumber("Zoom factor", 4, 2, 27, "X");
			Dialog.show();
			imgShrinkFactor = Dialog.getNumber();
			insetZoom = Dialog.getNumber();
			break;
		}
	} else {
		break;
	}
}


// Computing panel number and spatial distribution
toLowerCase(dimensionPanels);
print("\\Close");
dimensionPanelsSubstring = split(dimensionPanels, "x");
horizPanels = parseInt(String.trim(dimensionPanelsSubstring[0]));
vertPanels = parseInt(String.trim(dimensionPanelsSubstring[1]));
nPanels = horizPanels * vertPanels;

// Prepping image list
imageList = getFileList(inputDir);
if (imageList.length > nPanels) {
	exit("Error: input folder contains more images than desired panel number. Aborting macro");
}

alignment = "Left";
if (imageList.length < nPanels) {
	Dialog.create("Alignment");
	Dialog.addMessage("You seleced a " + nPanels + "-panel figure, but provided only " + imageList.length + " images." +
	"\nPlease select the panel alignment for the last row in the figure");
	Dialog.addRadioButtonGroup("Alignment:", newArray("Left", "Center", "Right"), 3, 1, "Left");
	Dialog.show();
	alignment = Dialog.getRadioButton();
}

// Processing border color
	// Panel borders
panelBorderColor = split(panelBorderColor, ",");
panelBorderR = parseInt(trim(panelBorderColor[0]));
panelBorderG = parseInt(trim(panelBorderColor[1]));
panelBorderB = parseInt(trim(panelBorderColor[2]));
	// Original inset borders
roiInPanelBorderColor = split(roiInPanelBorderColor, ",");
roiInPanelBorderR = parseInt(trim(roiInPanelBorderColor[0]));
roiInPanelBorderG = parseInt(trim(roiInPanelBorderColor[1]));
roiInPanelBorderB = parseInt(trim(roiInPanelBorderColor[2]));
	// Zoomed inset borders
insetBorderColor = split(insetBorderColor, ",");
insetBorderR = parseInt(trim(insetBorderColor[0]));
insetBorderG = parseInt(trim(insetBorderColor[1]));
insetBorderB = parseInt(trim(insetBorderColor[2]));
	// Trace line
traceLineColor = split(traceLineColor, ",");
traceLineR = parseInt(trim(traceLineColor[0]));
traceLineG = parseInt(trim(traceLineColor[1]));
traceLineB = parseInt(trim(traceLineColor[2]));	


// Main iteration 
acceptPanel = true;
// Iterating over images
for (i = 0; i < imageList.length; i++) {
	// Repeat last iteration if requested
	if (!acceptPanel) {
		i -= 1;
	}
	// Protection from user clicks
	setTool("hand");
	print("Opening image... Please be patient.");
	open(inputDir + imageList[i]);
	originalImg = getTitle();
	
	// Assigning calibration variables if metadata scale chosen
	if (useMDScale) {
		getPixelSize(scaleUnit, lenPerPx, discard);
	}
	// Removing scale
	Image.removeScale();

	// Checking if image is a stack
	if (nSlices != 1) {
		exit("Error!\n \nImage " + originalImg + " is a stack. Aborting macro.");
	}

	// Converting to RGB to facilitate potential colorization
	if (figType == "8-bit") {
		run("8-bit");
	} else {
		run("RGB Color");
	}
	
	// Cropping if needed
	if (!imageSizeHomogeneity) {
		interimImgSelW = getWidth();
		interimImgSelH = getHeight();
	}
	if (imageSizeHomogeneity && i == 0) {
		initImgSelW = getWidth();
		initImgSelH = getHeight();
		while (true) {
			run("Select None");
			setTool("rectangle");
			waitForUser("Crop Selection Step", "Please draw a cropping rectangle; all images will be cropped to this aspect ratio and size, but the position can be adjusted each time.\n \nClick OK when done.");
			// Check for selection existing
			if (selectionType() == -1) {
				redoCropSel = getBoolean("No selection detected.", "Try again", "Use whole image");
				if (redoCropSel) {
					continue;
				} else {
					run("Select All");
					break;
				}
			} else {
				// If selection is not a rectangle or multiple rectangles
				if (selectionType() != 0) {
					waitForUser("Error", "You made a non- or multi-rectangular selection. Click OK to redo the selection");
					continue;
				}
				// If selection is indeed a rectangle
				if (selectionType() == 0) {
					redoCropSel = getBoolean("Please confirm your cropping selection.", "Redo", "Confirm");
					if (redoCropSel) {
						continue;
					} else {
						break;
					}
				}
			}
		}
		getSelectionBounds(initImgCropX, initImgCropY, initImgSelW, initImgSelH);
		print("Cropping image");
		run("Crop");
		updateDisplay();
	}
		
	
	if (imageSizeHomogeneity && i != 0) {
		canvasExpanded = false;
		// Check for image shape with respect to cropping rectangle
		if (getWidth() < initImgSelW || getHeight() < initImgSelH) {
			waitForUser("Error: crop not possible", "Image is smaller than the initial crop selection.\n" +
						"If you'd like to continue with that selection size, the current image canvas needs to be enlarged.\n" +
						"Either click OK to proceed to the expansion operation, or cancel to abort macro.");
			Dialog.create("Canvas Color");
			Dialog.addChoice("Canvas color", newArray("Black", "White"), "Black");
			Dialog.show();
			canvasColor = Dialog.getChoice();
			if (canvasColor == "Black") {
				cR = 0;
				cG = 0;
				cB = 0;
			} else {
				cR = 255;
				cG = 255;
				cB = 255;
			}
			setBackgroundColor(cR, cG, cB);
			if (getWidth() < initImgSelW) {
				imgExpansionTargetW = initImgSelW;
			} else {
				imgExpansionTargetW = getWidth();
			}
			if (getHeight() < initImgSelH) {
				imgExpansionTargetH = initImgSelH;
			}
			print("Expanding canvas");
			run("Canvas Size...", "width=" + imgExpansionTargetW + " height=" + imgExpansionTargetH + " position=Center");
			canvasExpanded = true;
		}
		
		// Drawing centered cropping rectangle origin coords	
		imgCenterX = getWidth() / 2;
		imgCenterY = getHeight() / 2;
		cropOriginX = imgCenterX - (initImgSelW / 2);
		cropOriginY = imgCenterY - (initImgSelH / 2);
		while (true) {
			makeRectangle(cropOriginX, cropOriginY, initImgSelW, initImgSelH);
			if (!canvasExpanded) {
				setTool("rectangle");
				waitForUser("Crop Selection Step", "Please adjust the position but not size of the cropping selection then click OK");
				getSelectionBounds(discard, discard, tempW, tempH);
				if (tempW != initImgSelW || tempH != initImgSelH) {
					waitForUser("Error", "Crop selection dimensions do not match the initial one.\n \n Click OK to reset this selection.");
					continue;
				} else {
					print("Cropping image");
					run("Crop");
					updateDisplay();
					break;
				}
			}
			break;
		}
	}
	
	// If zoomed inset requested
	if (!noInset) {
		// Defaulting initial inset ROI size to 10% of image size, defaults to adjusted size in subsequent iterations 
		if (i == 0) {
			initRoiW = getWidth() / 10;
			initRoiH = getWidth() / 10;
		}
		
		// Selecting and extracting ROI for magnification
		run("Select None");
		while (true) {
			setTool("multipoint");
			// If no selection was made
	    	if (selectionType() == -1) {
	    		waitForUser("Inset ROI Selection Step", "Please click the position on the image that would be the center of the ROI that will be magnified.\n \n Click OK when done.");
				wait(100);
	    	} else {
				getSelectionCoordinates(nPointSelX, nPointSelY);
				// If more than one selection was made
				if (nPointSelX.length > 1) {
					run("Select None");
					showMessage("Error: You've selectioned a non-point or multi-point selection. Please make only one point selection.");
				} else {
					// If exactly one selection was made
					break;
				}
	    	}
		}
	 
		getSelectionBounds(roiX, roiY, discard, discard);
		
		
		while (true) {
			if (i == 0) {
				makeRectangle(roiX - (initRoiW / 2), roiY - (initRoiH / 2), initRoiW, initRoiH);
				setTool("rectangle");
				waitForUser("Inset ROI Adjustment Step", "If you'd like to adjust the position or size of the selection, please do so then click OK");
				if (selectionType() == 0) {
					getSelectionBounds(roiX, roiY, initRoiW, initRoiH);
				} else {
					waitForUser("Error", "Single rectangular selection not found. Click OK to redo this step.");
					continue;
				}
			} else {
				setTool("rectangle");
				makeRectangle(roiX - (initRoiW / 2), roiY - (initRoiH / 2), initRoiW, initRoiH);
				waitForUser("ROI Positional Adjustment", "If you'd like to adjust the position of the selection, please do so then click OK");
				if (selectionType() == 0) {
					getSelectionBounds(discard, discard, tempRoiW, tempRoiH);
					if (tempRoiW != initRoiW || tempRoiH != initRoiH) {
						redoInsetROI = getBoolean("Warning!\n \nThe selection does not have the same dimension as the one from the other panels", "Redo this step", "Continue");
						if (redoInsetROI) {
							continue;
						}
					}
					getSelectionBounds(roiX, roiY, initRoiW, initRoiH);
				} else {
					waitForUser("Error", "Single rectangular selection not found. Click OK to redo this step.");
				}
			}
			// Check if selected size is reasonable in the context of the final panel size and inset zoom requested
			predCombinedInsetsW = (initRoiW * (insetZoom / imgShrinkFactor)) + (initRoiW / imgShrinkFactor);
			predCombinedInsetsH = (initRoiH * (insetZoom / imgShrinkFactor)) + (initRoiH / imgShrinkFactor);
			predPanelW = initImgSelW / imgShrinkFactor;
			predPanelH = initImgSelH / imgShrinkFactor;
			if (predCombinedInsetsW > (0.8 * predPanelW) || predCombinedInsetsH > (0.8 * predPanelH)) {
				percentTotalInsetW = d2s(((predCombinedInsetsW / predPanelW) * 100), 0);
				percentTotalInsetH = d2s(((predCombinedInsetsH / predPanelH) * 100), 0);
				redoInsetROI = getBoolean("Warning!\n \nThe combined dimensions of the two insets (original and zoomed) will amount to\n" + 
											percentTotalInsetW + "% of the width and " + percentTotalInsetH + "% of the height of a given panel without accounting for borders.\n " +
											"\nWould you like to redo the inset ROI adjustment or continue?", "Redo", "Continue");
				if (redoInsetROI) {
					continue;
				} else {
					break;
				}
			} else {
				break;
			}
		}
		print("Extracting ROI");
		run("Duplicate...", "title=ROI_" + i);
		
		// User input for inset pasting position
		if (i == 0) {
			insetCorner = "Right bottom";
			insetOffset = 5;
		}
		Dialog.create("Inset Positioning");
		Dialog.addMessage("Please choose where you'd like to paste this specific inset in its respective panel");
		Dialog.addChoice("Inset position in panel", newArray("Left top", "Right top", "Left bottom", "Right bottom"), insetCorner);
		Dialog.addSlider("Inset offset from panel edge (% of panel width)", 0, 100, insetOffset);
		Dialog.show();
		insetCorner = Dialog.getChoice();
		insetOffset = Dialog.getNumber();
		
		// Implementing inset zoom factor by relative binning
		insetShrinkFactor = imgShrinkFactor / insetZoom;
		if (insetShrinkFactor != 1) {
			selectWindow("ROI_" + i);
			print("Binning inset");
			run("Bin...", "x=" + insetShrinkFactor + " y=" + insetShrinkFactor + " bin=" + binMethod);
		}
		finalRoiW = getWidth();
		finalRoiH = getHeight();
		
		// Adding scale bar to inset if requested
		if (addInsetScaleBar) {
			// Restoring scale to image
			insetLenPerPx = lenPerPx * insetShrinkFactor;
			selectWindow("ROI_" + i);
			run("Set Scale...", "distance=1 known=" + insetLenPerPx + " unit=" + scaleUnit);
			waitForUser("Inset Scale Bar Step", "Please select scale bar parameters for the zoomed inset in the next prompt.");
			run("Scale Bar...");
			selectWindow("ROI_" + i);
			run("Flatten");
			close("ROI_" + i);
			rename("ROI_" + i);
			// Removing scale once again
			Image.removeScale();
		}
			
		// Adding inset border if requested
		if (insetBorderThickness > 0) {
			if (overallBG == "white") {
				r = 255; g = 255; b = 255;
			} else {
				r = 0; g = 0; b = 0;
			}
			setBackgroundColor(insetBorderR, insetBorderG, insetBorderB);
			selectWindow("ROI_" + i);
			print("Adding inset border");
			run("Canvas Size...", "width=" + finalRoiW + (2 * insetBorderThickness) + " height=" + finalRoiH + (2 * insetBorderThickness) + " position=Center");
			makeRectangle(insetBorderThickness, insetBorderThickness, finalRoiW, finalRoiH);
			run("Make Band...", "band=" + insetBorderThickness);
			setColor(insetBorderR, insetBorderG, insetBorderB);
			fill();
			run("Select None");
		}
	}
	
	// Binning panel
	selectWindow(originalImg);
	print("Binning panel image");
	run("Bin...", "x=" + imgShrinkFactor + " y=" + imgShrinkFactor + " bin=" + binMethod);
	interimImgSelW = initImgSelW / imgShrinkFactor;
	interimImgSelH = initImgSelH / imgShrinkFactor;

	// If zoomed inset requested
	if (!noInset) {
		// Adding original inset in full panel at its native position	
		roiInPanelX = roiX / imgShrinkFactor;
		roiInPanelY = roiY / imgShrinkFactor;
		roiInPanelW = initRoiW / imgShrinkFactor;
		roiInPanelH = initRoiH / imgShrinkFactor;
		
		selectWindow(originalImg);
		print("Drawing original inset border");
		makeRectangle(roiInPanelX, roiInPanelY, roiInPanelW, roiInPanelH);
		run("Make Band...", "band=" + roiInPanelThickness);
		setColor(roiInPanelBorderR, roiInPanelBorderG, roiInPanelBorderB);
		fill();
		run("Select None");
		run("Flatten");
		close(originalImg);
		rename(originalImg);
	}
	
	// Adding scale bar to panel if requested
	if (addPanelScaleBar) {
		// Restoring scale to image
		panelLenPerPx = lenPerPx * imgShrinkFactor;
		selectWindow(originalImg);
		run("Set Scale...", "distance=1 known=" + panelLenPerPx + " unit=" + scaleUnit);
		waitForUser("Panel Scale Bar Step", "Please select scale bar parameters for the panel in the next prompt.");
		run("Scale Bar...");
		selectWindow(originalImg);
		run("Flatten");
		close(originalImg);
		rename(originalImg);
		// Removing scale once again
		Image.removeScale();
	}
	
	// Adding panel border if requested
	if (panelBorderThickness > 0) {
		if (overallBG == "white") {
			r = 255; g = 255; b = 255;
		} else {
			r = 0; g = 0; b = 0;
		}
		setBackgroundColor(panelBorderR, panelBorderG, panelBorderB);
		selectWindow(originalImg);
		print("Preparing to add panel border");
		run("Canvas Size...", "width=" + interimImgSelW + (2 * panelBorderThickness) + " height=" + interimImgSelH + (2 * panelBorderThickness) + " position=Center");
		finalImgSelW = getWidth();
		finalImgSelH = getHeight();

		// If zoomed inset requested
		if (!noInset) {
		// Pasting zoomed inset as an overlay before border is added, in case of different border colors (panel border goes on top)
			if (!insetBorderOnTop) {
				if (insetCorner == "Left top") {
					insetPastingX = panelBorderThickness - insetBorderThickness + ((insetOffset / 100) * finalImgSelW);
					insetPastingY = panelBorderThickness - insetBorderThickness + ((insetOffset / 100) * finalImgSelW);
					overlapCornerX = 1;
					overlapCornerY = 1;
				}
				if (insetCorner == "Right top") {
					insetPastingX = finalImgSelW - finalRoiW - panelBorderThickness - insetBorderThickness - ((insetOffset / 100) * finalImgSelW);
					insetPastingY = panelBorderThickness - insetBorderThickness + ((insetOffset / 100) * finalImgSelW);
					overlapCornerX = finalImgSelW - 1;
					overlapCornerY = 1;
				}
				if (insetCorner == "Left bottom") {
					insetPastingX = panelBorderThickness - insetBorderThickness + ((insetOffset / 100) * finalImgSelW);
					insetPastingY = finalImgSelH - finalRoiH - panelBorderThickness - insetBorderThickness - ((insetOffset / 100) * finalImgSelW);
					overlapCornerX = 1;
					overlapCornerY = finalImgSelH - 1;
				}
				if (insetCorner == "Right bottom") {
					insetPastingX = finalImgSelW - finalRoiW - panelBorderThickness - insetBorderThickness - ((insetOffset / 100) * finalImgSelW);
					insetPastingY = finalImgSelH - finalRoiH - panelBorderThickness - insetBorderThickness - ((insetOffset / 100) * finalImgSelW);
					overlapCornerX = finalImgSelW - 1;
					overlapCornerY = finalImgSelH - 1;
				}
				selectWindow(originalImg);
				print("Pasting zoomed inset");
				run("Add Image...", "image=ROI_" + i + " x=" + insetPastingX + " y=" + insetPastingY + " opacity=100");	
				run("Select None");
				run("Flatten");
				close(originalImg);
				rename(originalImg);
			}
			// Memory management
			close("ROI_" + i);
		}
		// Coloring-in border
		print("Finalizing panel border");
		makeRectangle(panelBorderThickness, panelBorderThickness, interimImgSelW, interimImgSelH);
		run("Make Band...", "band=" + panelBorderThickness);
		setColor(panelBorderR, panelBorderG, panelBorderB);
		fill();
		run("Select None");
		
		// If zoomed inset requested
		if (!noInset) {	
			// Changing back corner color to panel border color after it changed to inset border color due to pasting inset
			run("Flatten");
			close(originalImg);
			rename(originalImg);
			if (!insetBorderOnTop) {
				setForegroundColor(panelBorderR, panelBorderG, panelBorderB);
				floodFill(overlapCornerX, overlapCornerY);
			}
			run("Select None");
		}
	}
	
	// Adjusting dimension variables
	finalImgSelW = getWidth();
	finalImgSelH = getHeight();
	
	// If zoomed inset and trace requested
	if (!noInset) {
		// Pasting zoomed inset as an overlay (if the panel has no border)
		if (panelBorderThickness == 0 || insetBorderOnTop) {
			if (insetCorner == "Left top") {
				insetPastingX = panelBorderThickness - insetBorderThickness + ((insetOffset / 100) * finalImgSelW);
				insetPastingY = panelBorderThickness - insetBorderThickness + ((insetOffset / 100) * finalImgSelW);
			}
			if (insetCorner == "Right top") {
				insetPastingX = finalImgSelW - finalRoiW - panelBorderThickness - insetBorderThickness - ((insetOffset / 100) * finalImgSelW);
				insetPastingY = panelBorderThickness - insetBorderThickness + ((insetOffset / 100) * finalImgSelW);
			}
			if (insetCorner == "Left bottom") {
				insetPastingX = panelBorderThickness - insetBorderThickness + ((insetOffset / 100) * finalImgSelW);
				insetPastingY = finalImgSelH - finalRoiH - panelBorderThickness - insetBorderThickness - ((insetOffset / 100) * finalImgSelW);
			}
			if (insetCorner == "Right bottom") {
				insetPastingX = finalImgSelW - finalRoiW - panelBorderThickness - insetBorderThickness - ((insetOffset / 100) * finalImgSelW);
				insetPastingY = finalImgSelH - finalRoiH - panelBorderThickness - insetBorderThickness - ((insetOffset / 100) * finalImgSelW);
			}
			print("Pasting zoomed inset");
			run("Add Image...", "image=ROI_" + i + " x=" + insetPastingX + " y=" + insetPastingY + " opacity=100");	
			run("Select None");
			run("Flatten");
			close(originalImg);
			rename(originalImg);
		}
		
		// Trace line functionality if requested
		if (drawTrace) {
			// Tracing original inset to zoomed inset
				// Assigning corner coord variables (T = top, B = bottom, R = right, L = left)
					// Original inset
			origInsetTLX = roiInPanelX + panelBorderThickness - roiInPanelThickness;
			origInsetTLY = roiInPanelY + panelBorderThickness - roiInPanelThickness;
			origInsetTRX = origInsetTLX + roiInPanelW + (2 * roiInPanelThickness);
			origInsetTRY = origInsetTLY;
			origInsetBLX = origInsetTLX;
			origInsetBLY = origInsetTLY + roiInPanelH + (2 * roiInPanelThickness);
			origInsetBRX = origInsetTRX;
			origInsetBRY = origInsetBLY;
			origInsetCoordArray = newArray(origInsetTLX, origInsetTLY, origInsetTRX, origInsetTRY, origInsetBLX, origInsetBLY, origInsetBRX, origInsetBRY);
					// Zoomed inset
			zoomedInsetTLX = insetPastingX;
			zoomedInsetTLY = insetPastingY;
			zoomedInsetTRX = zoomedInsetTLX + finalRoiW + (2 * insetBorderThickness);
			zoomedInsetTRY = zoomedInsetTLY;
			zoomedInsetBLX = zoomedInsetTLX;
			zoomedInsetBLY = zoomedInsetTLY + finalRoiH + (2 * insetBorderThickness);
			zoomedInsetBRX = zoomedInsetTRX;
			zoomedInsetBRY = zoomedInsetBLY;
			zoomedInsetCoordArray = newArray(zoomedInsetTLX, zoomedInsetTLY, zoomedInsetTRX, zoomedInsetTRY, zoomedInsetBLX, zoomedInsetBLY, zoomedInsetBRX, zoomedInsetBRY);
			
		
			// Fetching approximate coords for corners to connect
			while (true) {
				run("Select None");
				// If no selection has been made
				while (selectionType() == -1) {
					setTool("multipoint");
					waitForUser("Inset Tracing Step", "Please click roughly near the corners you'd like to draw a line between.\n " +
				    "\nClick 1 to 4 should be in this order to produce 2 tracing lines:\n " + 
				    "\n1) Original inset corner 1" + 
				    "\n2) Corresponding zoomed inset corner 1" + 
				    "\n3) Original inset corner 2" + 
				    "\n4) Corresponding zoomed inset corner 2\n " +
				    "\nThe macro will identify the nearest corner and draw the lines properly, no need for the click to be accurate\n" +
				    "\nIf you'd like to draw only one tracing line then point selections must be made such that corner 1 and 2 are the same");
				    wait(100);
				}
				// If a non-multipoint selection has been made
				if (selectionType() != 10) {
					run("Select None");
					waitForUser("Error", "You've made a non-multipoint-type selection. Click OK to redo this step.");
					continue;
				}
				
				getSelectionCoordinates(cornerXArray, cornerYArray);
				// If not exactly 4 point selections have been made
				if (cornerXArray.length != 4) {
					run("Select None");
					waitForUser("Error", "Exactly 4 point selections must be made. Click OK to redo this step");
					continue;
				} else {
					// If exactly 4 point selections have been made
					break;
				}
			}
			
			// Find nearest corners
			selectedOrigCornerXArray = newArray();
			selectedOrigCornerYArray = newArray();
			selectedZoomedCornerXArray = newArray();
			selectedZoomedCornerYArray = newArray();
			
				// Original inset corner 1
			x1 = cornerXArray[0];
			y1 = cornerYArray[0];
			dist = 1.0e100;
			
			for (accuCoord = 0; accuCoord < origInsetCoordArray.length; accuCoord += 2) {
			    x2 = origInsetCoordArray[accuCoord];
			    y2 = origInsetCoordArray[accuCoord + 1];
			    tempDist = sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2));
			
			    if (tempDist < dist) {
			        dist = tempDist;
			        selectedOrigCornerXArray[0] = x2;
			        selectedOrigCornerYArray[0] = y2;
			    }
			}
			
				// Zoomed inset corner 1
			x1 = cornerXArray[1];
			y1 = cornerYArray[1];
			dist = 1.0e100;
			
			for (accuCoord = 0; accuCoord < zoomedInsetCoordArray.length; accuCoord += 2) {
			    x2 = zoomedInsetCoordArray[accuCoord];
			    y2 = zoomedInsetCoordArray[accuCoord + 1];
			    tempDist = sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2));
			
			    if (tempDist < dist) {
			        dist = tempDist;
			        selectedZoomedCornerXArray[0] = x2;
			        selectedZoomedCornerYArray[0] = y2;
			    }
			}
			
				// Original inset corner 2
			x1 = cornerXArray[2];
			y1 = cornerYArray[2];
			dist = 1.0e100;
			
			for (accuCoord = 0; accuCoord < origInsetCoordArray.length; accuCoord += 2) {
			    x2 = origInsetCoordArray[accuCoord];
			    y2 = origInsetCoordArray[accuCoord + 1];
			    tempDist = sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2));
			
			    if (tempDist < dist) {
			        dist = tempDist;
			        selectedOrigCornerXArray[1] = x2;
			        selectedOrigCornerYArray[1] = y2;
			    }
			}
			
				// Zoomed inset corner 2
			x1 = cornerXArray[3];
			y1 = cornerYArray[3];
			dist = 1.0e100;
			
			for (accuCoord = 0; accuCoord < zoomedInsetCoordArray.length; accuCoord += 2) {
			    x2 = zoomedInsetCoordArray[accuCoord];
			    y2 = zoomedInsetCoordArray[accuCoord + 1];
			    tempDist = sqrt(pow((x2 - x1), 2) + pow((y2 - y1), 2));
			
			    if (tempDist < dist) {
			        dist = tempDist;
			        selectedZoomedCornerXArray[1] = x2;
			        selectedZoomedCornerYArray[1] = y2;
			    }
			}
		
			// Draw lines
			run("Select None");
			setColor(traceLineR, traceLineG, traceLineB);
			setLineWidth(traceLineThickness);
			drawLine(selectedZoomedCornerXArray[0], selectedZoomedCornerYArray[0], selectedOrigCornerXArray[0], selectedOrigCornerYArray[0]);
			drawLine(selectedZoomedCornerXArray[1], selectedZoomedCornerYArray[1], selectedOrigCornerXArray[1], selectedOrigCornerYArray[1]);
		}
	}
	
	// Adding text annotations if requested
	if (addTextAnnotations) {
		// GUI
		Dialog.create("Text Annotations");
		fontList = getFontList();
		Dialog.addMessage("Please configure the text you'd like to add to this panel", 20, "blue");
		Dialog.addString("Text 1", "", 27);
		Dialog.addString("Text 1 color (r,g,b)", "255, 255, 255", 27);
		Dialog.addString("Text 2", "", 27);
		Dialog.addString("Text 2 color (r,g,b)", "255, 255, 255", 27);
		Dialog.addString("Text 3", "", 27);
		Dialog.addString("Text 3 color (r,g,b)", "255, 255, 255", 27);
		Dialog.addString("Text 4", "", 27);
		Dialog.addString("Text 4 color (r,g,b)", "255, 255, 255", 27);
		Dialog.addString("Text 5", "", 27);
		Dialog.addString("Text 5 color (r,g,b)", "255, 255, 255", 27);
		Dialog.addChoice("Text background color", newArray("None", "White", "Black"), "None");
		
		Dialog.addChoice("Position", newArray("Horizontal top", "Horizontal bottom", "Vertical left", "Vertical right (offset crucial)"), "Horizontal top");
		Dialog.addNumber("Offset from edge (% panel width)", 10, 2, 27, "%");
		Dialog.addChoice("Font", fontList, "Arial");
		Dialog.addNumber("Font size", 150, 0, 27, "");
		Dialog.addCheckbox("Bold", true);
		Dialog.addCheckbox("Italic", false);
		Dialog.addCheckbox("Antialiased", true);
		Dialog.addNumber("Space between text annotations (% first textbox width)", 20, 0, 27, "%");
		
		
		Dialog.show();
		
		// Fetching inputs
		text1 = Dialog.getString();
		text1Color = Dialog.getString();
		text2 = Dialog.getString();
		text2Color = Dialog.getString();
		text3 = Dialog.getString();
		text3Color = Dialog.getString();
		text4 = Dialog.getString();
		text4Color = Dialog.getString();
		text5 = Dialog.getString();
		text5Color = Dialog.getString();
		textBGColor = Dialog.getChoice();
		
		textPosition = Dialog.getChoice();
		textOffset = Dialog.getNumber();
		font = Dialog.getChoice();
		fontSize = Dialog.getNumber();
		fontBold = Dialog.getCheckbox();
		fontItalic = Dialog.getCheckbox();
		fontAntialiased = Dialog.getCheckbox();
		textSpacing = Dialog.getNumber();
		
		// Processing text style
		if (fontBold) {
			bold = "Bold";
		} else {
			bold = "";
		}
		if (fontItalic) {
			italic = "Italic";
		} else {
			italic = "";
		}
		
		// Concatenating text input
		textArray = newArray(text1, text2, text3, text4, text5);
		textColorArray = newArray(text1Color, text2Color, text3Color, text4Color, text5Color);
		
		// Processing text position and orientation
		textOffsetPx = (textOffset / 100) * (finalImgSelW - panelBorderThickness);
		if (textPosition == "Horizontal top") {
			textX = textOffsetPx;
			textY = textOffsetPx;
			textRot = 0;
		} else if (textPosition == "Horizontal bottom") {
			textX = textOffsetPx;
			textY = finalImgSelH - textOffsetPx;
			textRot = 0;
		} else if (textPosition == "Vertical left") {
			textX = textOffsetPx;
			textY = finalImgSelH - textOffsetPx;
			textRot = 90;
		} else if (textPosition == "Vertical right (offset crucial)") {
			textX = finalImgSelW - textOffsetPx;
			textY = finalImgSelH - textOffsetPx;
			textRot = 90;
		}
		
		// Adding text annotations
		noTextAnnotationsGiven = true;
		cumulativeTextW = 0;
		for (t = 0; t < textArray.length; t++) {
			if (textArray[t] == "") {
				continue;
			} else {
				noTextAnnotationsGiven = false;
			}

			colorInput = split(textColorArray[t], ",");
			textR = parseInt(trim(colorInput[0]));
			textG = parseInt(trim(colorInput[1]));
			textB = parseInt(trim(colorInput[2]));	
			setFont(font, fontSize, bold + " " + italic + " Left antialiased");
			setColor(textR, textG, textB);
			
			// If horizontal text requested
			if (textRot == 0) {
				if (t == 0) {
					// Adding first text to get dimensions
					Overlay.drawString(textArray[t], textX, textY, textRot);
					Overlay.show();
					Overlay.activateSelection(0);
					getSelectionBounds(discard, discard, textWidth, textHeight);
					textSpacingPx = (textSpacing / 100) * textWidth;
					
					// Adding BG on top, then re-adding text
					if (textBGColor != "None") {
						Overlay.addSelection("", 0, textBGColor);
						Overlay.drawString(textArray[t], textX, textY, textRot);
					}
				} else {
					// Computing spacing and adding subsequent texts
					cumulativeTextW += textWidth;
					Overlay.drawString(textArray[t], textX + cumulativeTextW + (textSpacingPx * t), textY, textRot);
					Overlay.show();
					Overlay.activateSelection(0);
					getSelectionBounds(discard, discard, textWidth, textHeight);
					
					// Adding BG on top, then re-adding text
					if (textBGColor != "None") {
						Overlay.addSelection("", 0, textBGColor);
						Overlay.drawString(textArray[t], textX + cumulativeTextW + (textSpacingPx * t), textY, textRot);
					}
				}
				// If vertical text requested
			} else {
				if (t == 0) {
					// Adding first text to get dimensions
					Overlay.drawString(textArray[t], textX, textY, textRot);
					Overlay.show();
					Overlay.activateSelection(0);
					getSelectionBounds(discard, discard, textWidth, textHeight);
					textSpacingPx = (textSpacing / 100) * textWidth;
					
					// Adding BG on top, then re-adding text
					if (textBGColor != "None") {
						Overlay.addSelection("", 0, textBGColor);
						Overlay.drawString(textArray[t], textX, textY, textRot);
					}
				} else {
					// Computing spacing and adding subsequent texts
					cumulativeTextW += textWidth;
					Overlay.drawString(textArray[t], textX, textY - cumulativeTextW - (textSpacingPx * t), textRot);
					Overlay.show();
					Overlay.activateSelection(0);
					getSelectionBounds(discard, discard, textWidth, textHeight);
					
					// Adding BG on top, then re-adding text
					if (textBGColor != "None") {
						Overlay.addSelection("", 0, textBGColor);
						Overlay.drawString(textArray[t], textX, textY - cumulativeTextW - (textSpacingPx * t), textRot);
					}
				}
			}
		}
		// In case text annotation functionality was selected but no text was provided
		if (noTextAnnotationsGiven) {
			waitForUser("Warning", "No text annotations were added. The text fields were empty. Click OK to continue.");
		} else {
			// Flattening
			tempTitle = getTitle();
			Overlay.flatten;
			close(tempTitle);
			rename(tempTitle);		
		}
	}
	
	// Adding arrow annotations if requested
	if (addArrowAnnotations) {
		roiManager("reset");
		moreArrowSets = true;
		// Loop for iterating over sets of arrows where each set has a given length, orientation, color, etc.
		while (moreArrowSets) {
			waitForUser("Arrow Annotation Step", "Please set up arrow parameters in the next prompt.");
			satisfiedModelArrow = false;
			// Looping until model arrow satisfactory
			while (!satisfiedModelArrow) {
				run("Arrow Tool...");
				// If no model arrow was drawn
				while (selectionType() == -1) {
					waitForUser("Done?", "Please draw the model arrow and click OK when done");
				}
				if (selectionType() == 5) {
					satisfiedModelArrow = getBoolean("Please confirm your arrow drawing", "Confirm", "Try again");
					if (!satisfiedModelArrow) {
						run("Select None");
						continue;
					} else {
						roiManager("add");
						Overlay.addSelection;
					}
				}
			}
			// Prompting user for whether they'd like to make more arrows of the same type/set
			moreArrowsInSet = getBoolean("Would you like to draw more arrows of this type (identical including angle)?");
			while (moreArrowsInSet) {
				roiManager("select", 0);
				Roi.move(0, 0);
				waitForUser("Positional Adjustment", "Please adjust the position of the new arrow (currently in top left corner) to another point of interest and click OK when done");
				if (selectionType() == 5) {
					Overlay.addSelection;
				} else {
					showMessage("Selection was deleted. Click OK to continue");
				}
				moreArrowsInSet = getBoolean("Would you like to draw more arrows of this type (identical including angle)?");
			}
			// Wrappig up previous set
			roiManager("reset");
			tempTitle = getTitle();
			run("Flatten");
			close(tempTitle);
			rename(tempTitle);
			
			moreArrowSets = getBoolean("Would you like to draw a an arrow of a different type (manual length similar to the first time)?");
			if (moreArrowSets) {
				continue;
			}
		}	
	}
	
	// Initializing figure
	if (i == 0) {	
		print("Initializing figure");
		figW = (horizPanels * finalImgSelW) + ((horizPanels - 1) * ((panelSpacing / 100) * finalImgSelW));
		figH = (vertPanels * finalImgSelH) + ((vertPanels - 1) * ((panelSpacing / 100) * finalImgSelW));
		newImage("Figure", figType + " " + overallBG, figW, figH, 1);
	}
	
	// Computing panel position
	colIndex = i % horizPanels;
    rowIndex = Math.floor(i / horizPanels);
	panelPosX = colIndex * (finalImgSelW + ((panelSpacing / 100) * finalImgSelW));

     // Checking the alignment for the last row
    if (rowIndex == vertPanels - 1) {
        lastRowSpace = horizPanels - (imageList.length % horizPanels);
        if (alignment == "Right") {
            panelPosX += lastRowSpace * (finalImgSelW + ((panelSpacing / 100) * finalImgSelW));
        } else if (alignment == "Center") {
            panelPosX += (lastRowSpace / 2) * (finalImgSelW + ((panelSpacing / 100) * finalImgSelW));
        } 
    }
    panelPosY = rowIndex * (finalImgSelH + ((panelSpacing / 100) * finalImgSelW));
	
	// Pasting image as overlay 
	selectWindow("Figure");
	print("Pasting panel");
	run("Add Image...", "image=" + originalImg + " x=" + panelPosX + " y=" + panelPosY + " opacity=100");
	run("Flatten");
	close("Figure");
	rename("Figure");
	
	// Memory management
	close(originalImg);
	
	// Redo opportunity
	acceptPanel = getBoolean("Panel successfully created. Are you satisifed with the current result?", "Yes, continue to next panel", "No, redo last panel from scratch");
	
	// Memory management
	run("Collect Garbage");
}

// Exporting figure
selectWindow("Figure");
saveAs("Tiff", outputDir + "Figure");















































