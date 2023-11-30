# QanvasLab
QanvasLab Microscopy Figure Builder, an ImageJ/FIJI macro

Author: Ahmad Kamal Hamid, University of Zurich

Version: 1.0, 27/11/2023 
 
Description: This is the QanvasLab Microscopy Figure Builder, a tool aiming to optimize the balance between customizability and user-friendliness. Anyone who prepared microscopy figures for manuscripts or presentations knows that it's very frustrating. This tool hopefully reduces that frustration by allowing fellow scientists to prepare microscopy figures with the ability to customize panel distribution, zoomed insets, borders, color, text and arrow annotations, etc. 

How to launch: There are many ways to launch a macro in ImageJ. The most straight forward approach is to open ImageJ/FIJI and then Plugins > Macros > Run > Select the IJM file and follow the GUI
    
Environment: FIJI/ImageJ 1.54f with the following list of plugins. Please note, most of the plugins were not used in this macro, but to prevent incompatibility issues, the list contains everything in the ImageJ version that was used to develop the tool:
  		
1) ImageJ
     
2) Fiji
  			
3) Java-8
  			
4) 3D ImageJ Suite
  			
5) Bio-Formats
  			
6) BioVoxxel
  			
7) BioVoxxel 3D Box
 	  	
8) BoneJ
  			
9) clij
  			
10) clij2
  			
11) clijx-assistant
  			
12) clijx-assistant-extensions
  			
13) ElastixWrapper
  			
14) IJ-Plugins
  			
15) IJPB-plugins
  			
16) Neuroanatomy

Workflow:
1) Crop images to desired size (or expand canvas of subsequent images if they are smaller than crop size)
  			
2) Choose panel alignment in case of mismatch between number of images provided and panel distribution requested
  			
3) Choose point of interest for a color-boredered (if requested) zoomed inset (if requested) and adjust position/size/shape of ROI. Original inset borders (customizable) can also be drawn on the panel.
  			
4) Choose zoomed inset position on panel with a given edge offset
  			
5) Choose scale bar parameters (if requested, for panel or for zoomed inset)
  			
6) Select corners to trace from original inset to zoomed inset (if requested)
  			
7) Choose up to 5 text annotations (if requested) that can customized in terms of color, panel side, offset, etc. 
  			
8) Draw arrow annotations for particular points of interest (if requested) with customizable color, shape, width, etc.
  			
9) Redo last panel if requested
