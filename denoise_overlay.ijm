
// if setBatchMode is true, then imagej will no display the images, which is faster
setBatchMode(true);

// Get the directory for the folders of aligned images
dir = getDirectory("Where are your image folders");

// Get the list of folders
folder_list = getFileList(dir);
folder_num = folder_list.length;
folder_count = 0;

Array.print(folder_list);

print("Processing of "+folder_num+" rhizotron folders started.");

// Loop over all the folders

for(j = 0 ;j < folder_num ; j = j+1){
	
	name = split(folder_list[j], "/"); 		//this part doesnt make sense to me... oh well.
	name = name[0];
	print(name);

	// Get the files inside the "rhizotron number" folder
	dirTemp = dir+name+File.separator;
		//print(dirTemp);
	list = getFileList(dirTemp);
	num = list.length;

	Array.sort(list);
	Array.print(list);

	// Make new directory to store the converted images 
	str=split(dirTemp,File.separator);
	folderName = Array.reverse(str);
	newfolderName = split(folderName[0],"_");
	dir1 = dir + newfolderName[0] + "_for_therese_B" + File.separator;
	File.makeDirectory(dir1);

	// Loop over all the images
	for(k = 0 ;k < num ; k++){

	// Open the 'k' image in the folder and store its title (easier to find it after)
		t1 = dirTemp + list[k];
			//print(t1);
		open(t1);
		ti1=getTitle();

		run("Subtract...", "value=1.5");
		run("Multiply...", "value=3");
		run("Subtract...", "value=8");

		run("Despeckle");  // Remove the small particles
		setOption("BlackBackground", false); 
		setThreshold(1, 200);  // Set the threshold value   --> THIS IS MANUAL, SO IT MIGHT CHANGE FOR OTHER IMAGES  <---	
		
		run("Convert to Mask");  // Create the binary image
		run("Despeckle");   // Remove the small particles, again
		run("Erode");     // Erode will remove one layer of pixel around each object in the image. Small very small object (1 pixel), will disappear
		run("Dilate");	  // Dilate adds one layer of pixel around each object, to give them their original size (but not for the very small ones that have disappeared)

		run("Invert");
		run("Analyze Particles...", "size=4-Infinity show=Masks");
		selectWindow(ti1);
		close();
		selectWindow("Mask of "+ti1);
		run("Invert");

		if(k == 0){
   			// if this is the first image in the time series, 
   			// then just save it in the destination folder	
				
			saveAs("Tiff", dir1 + ti1);
			close();
		}else{ 
			// If this is not the first image, then, open the 
			// previous image in the destination folder.
			// The image calculator function merge both images, by addind their pixels values
			// The result is saved in the destination folder and will be reused in te next time step.
			// By doing so, the destination folder contains images that are all the sum
			// of all the previous ones.
			t2 = dir1 + list[k-1];
			open(t2);
			ti2=getTitle();
			imageCalculator("Add create","Mask of "+ ti1,ti2);  // This function can be access with "Process > Image calculator" in ImageJ	
			saveAs("Tiff", dir1 + ti1);
			close();
			selectWindow(ti2);
			close();
			selectWindow("Mask of "+ti1);
			close();		
		}
	
	}

	folder_count++;
}

print("Processing done. "+folder_count+" rhizotrons folders were processed");

