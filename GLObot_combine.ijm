
/*
 * Designed by Ruben Rellan Alvarez  @ Carnegie Institution for Plant Sciences
 * Coded by Guillaume Lobet  @ Universite de Liege, Belgium
 * Edited by Therese LaRue @ Stanford University
 *
 * With this macro we merge and combine the 4 individual images
 * that are taken with the GLO-Bot and GLO-Roots imaging systems. The format
 * of the file_name will be:
 *
 * ExpID-RhizotronID-Year-Month-Day-Time-Side A - Filter-LowerCamera-Pepe_000.tif
 * ExpID-RhizotronID-Year-Month-Day-Time-Side A - Filter-UpperCamera-Lucy_000.tif
 * ExpID-RhizotronID-Year-Month-Day-Time-Side B - Filter-LowerCamera-Pepe_000.tif
 * ExpID-RhizotronID-Year-Month-Day-Time-Side B - Filter-UpperCamera-Lucy_000.tif
 *
 * Example: 
 * HL05-R001-2016-06-19-1232-Side A - No Filter-LowerCamera-Pepe_000.tif
 * HL05-R001-2016-06-19-1232-Side A - No Filter-UpperCamera-Lucy_000.tif
 * HL05-R001-2016-06-19-1232-Side B - No Filter-LowerCamera-Pepe_000.tif
 * HL05-R001-2016-06-19-1232-Side B - No Filter-UpperCamera-Lucy_000.tif
 *
 * The macro create from this images a 2048x4096 px image,
 * Conserve all the parts of the name until "Side..." and replace with "-C" 
 *
 * It works on batch mode and process several images in a single folder
 *
 */

//------------------ UPDATE HERE  ----------------------

/// FL and BL
a1 = 0.4;
x1 = -53; 
y1 = 1.4375;

// FU and BU
a2 = -0.1; 
x2 = -23; 
y2 = -0.476;

// Up and down
x3 = 14;
y3 = -22;

//Crop
y4 = 23;
calibration = false;


//----------------------------------------

// Tell ImageJ not to display the images
setBatchMode(true);

// Get the image directory
dir = getDirectory("Where are your images");
dir1 = getDirectory("Where do you want to save the converted images");

// Get the image list
list = getFileList(dir);
num = list.length;
count = 0;

print("Processing of "+num+"images started.");

// Loop over all the images
// Open 4 images at the same time (up/down-front/back)
for(k = 0 ;k < num ; k = k+4){

	bl = dir + list[k];  	// Back Low
	bu = dir + list[k+1]; 	// Back Up
	fl = dir + list[k+2];	// Front Low
	fu = dir + list[k+3]; 	// Front Up

	// Compute the new final name

	str = list[k+1];
	i1 = indexOf(str, "Side");
	nameC=substring(str,0,i1)+"C";

	print("- "+nameC);

	// ------------------------------------------------------
	// OPEN IMAGES
	// Open the different images and perform the individual
	// operations on them (rotate, translate)

	open(bl);
	tiBL = getTitle();
	run("Rotate 90 Degrees Left");
	if(calibration){
        run("RGB Color");
		saveAs("Tiff", dir1+"BL.tiff");
		rename(tiBL);
	}

	open(bu);
	tiBU = getTitle();
	run("Rotate 90 Degrees Left");
	if(calibration){
        run("RGB Color");
		saveAs("Tiff", dir1+"BU.tiff");
		rename(tiBU);
	}

	open(fl);
	tiFL = getTitle();
	run("Rotate 90 Degrees Left");
  	run("Flip Horizontally");
	if(calibration){
        run("RGB Color");
		saveAs("Tiff", dir1+"FL.tiff");
		rename(tiFL);
	}

//-----------  FIRST STEP ----------
	run("Rotate... ", "angle="+a1+" grid=1 interpolation=Bilinear");
	run("Translate...", "x="+x1+" y="+y1+" interpolation=None");

	open(fu);
	tiFU = getTitle();
	run("Rotate 90 Degrees Left");
	run("Flip Horizontally");
	if(calibration){
        run("RGB Color");
		saveAs("Tiff", dir1+"FU.tiff");
		rename(tiFU);
	}

//-----------  SECOND STEP ----------
	run("Rotate... ", "angle="+a2+" grid=1 interpolation=Bilinear");
	run("Translate...", "x="+x2+" y="+y2+" interpolation=None");

	h = getHeight();
	w = getWidth();



	// ------------------------------------------------------
	// COMBINE FRONT AND BACK IMAGES

	imageCalculator("Max create", tiBU, tiFU);
	tiU = "Up";
	rename(tiU);	// Rename the image to easily retrieve them later

	imageCalculator("Max create", tiBL, tiFL);
	tiL = "Low";
	rename(tiL);	// Rename the image to easily retrieve them later

	// Close the original images
	selectWindow(tiFU);
	close();
	selectWindow(tiBU);
	close();
	selectWindow(tiFL);
	close();
	selectWindow(tiBL);
	close();



	// ------------------------------------------------------
	// INTENSITY NORMALISATION

	// Up image
	selectWindow(tiU);
	makeRectangle(1948, 548, 50, 1200);
	getStatistics(area, mean);
	run("Select None");	// select the whole image
	run("Add...", "value="+(200 - mean));

	// Low image
	selectWindow(tiL);
	makeRectangle(1948, 548, 50, 1200);
	getStatistics(area, mean);
	run("Select None");	// select the whole image
	run("Add...", "value="+(200-mean));

	// ------------------------------------------------------
	// CROP LOWER IMAGE
	selectWindow(tiL);
	makeRectangle(0, y4, 2048, 2048);
	run("Crop");

	// ------------------------------------------------------
	// MERGE LOWER AND UPPER IMAGES
	// First we increase the size of the Up and Low image to the final size.
	// We create zero-value pixels either above or below the image to increase the size.
	// For the Low image, we also translate it.
	// Then we combine both to create the final image

	// Up image
	selectWindow(tiU);
	run("Canvas Size...", "width=2048 height=4096 position=Top-Center zero");
	if(calibration){
        run("RGB Color");
		saveAs("Tiff", dir1+"UP.tiff");
		rename(tiU);
	}

	// Low image
	selectWindow(tiL);
	run("Canvas Size...", "width=2048 height=4096 position=Bottom-Center zero");
	if(calibration){
        run("RGB Color");
		saveAs("Tiff", dir1+"LOW.tiff");
		rename(tiL);
	}
	run("Translate...", "x="+x3+" y="+y3+" interpolation=None");

	// Combine both
	imageCalculator("Max create", tiU, tiL);

	//makeRectangle(84, 0, 1854, 3936);
	//run("Crop");


	// ------------------------------------------------------
	// SAVE AND CLOSE THE FINAL IMAGES
	
	saveAs("Tiff", dir1+nameC);
	close();

	selectWindow(tiU);
	close();

	selectWindow(tiL);
	close();	
	

	count++;
}

print("Processing done. "+count+" complete images were created");
