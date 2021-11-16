/*
 * This macro is designed to remove the background from combined 
 * GLO-Roots images. This is to be done after combining and before 
 * registering. As of Oct. 23, 2016 you must have the blank image 
 * open in ImageJ before you begin this script
 */

// Tell ImageJ not to display the images
setBatchMode(true);

// Get the image directory
dir = getDirectory("Where are your images");

// Get the image list
list = getFileList(dir);
num = list.length;
count = 0;

// Set the blank image
blank = "HL07_Blank.tif"

//Make new folder to save converted images
//dir1 = getDirectory("Where do you want to save the converted images");
str=split(dir,File.separator);
folderName = Array.reverse(str)
dir1 = dir + File.separator + folderName[0] + "_RemovedBackground" + File.separator
File.makeDirectory(dir1)

print("Processing of "+num+"images started.");

//----------------------------------------

// Loop over all the images
for (k = 0 ; k < num ; k++){

	// Compute the new final name

	str = list[k];
	i1 = indexOf(str, ".");
	nameC= substring(str,0,i1) + "_remove";

	print("- "+nameC);
	
	//----------------------------------------
	//OPEN IMAGES 
	
	image = dir + list[k];
	open(image); 
	
	imageCalculator("Subtract create", list[k] , blank);
	selectWindow("Result of " + list[k]);

	saveAs("TIFF", dir1 + nameC);
	close();

	count++;

}

print("Processing done. " + count + " complete images were created");
