// September 29, 2018 - This macro is designed to subtract raw images from each other
// so we can track the tips 
//***May 14, 2019 edits to remove day labeling

// if setBatchMode is true, then imagej will no display the images, which is faster
setBatchMode(true);

// Get the directory for the folders of aligned images
dir = getDirectory("Where are your image folders");
dir1 = getDirectory("Where do you want to save your images"); // Images are all saved in one location

// Get the list of folders of aligned images 
folder_list = getFileList(dir);
folder_num = folder_list.length;
folder_count = 0;

Array.sort(folder_list);
Array.print(folder_list);
// Prints out what it will look like 

print("Processing of "+folder_num+" aligned rhizotron folders started.");

// Loop over all the folders
for(j = 0 ;j < folder_num ; j = j+1){ 
	
	rhizotron = split(folder_list[j], "/"); 					//FOR RDS 
	//rhizotron = split(folder_list[j], File.separator); 		//FOR MAC
	rhizotron = rhizotron[0];
	print(rhizotron);

	// Get the files inside the aligned folders 
	dirTemp = dir+rhizotron+File.separator;
	list = getFileList(dirTemp);
	num = list.length;

	Array.sort(list);
	Array.print(list);

	// Loop over all the images
	for(k = 0 ;k < num ; k++){

		// Compute new name for the images. This includes the "day bin" at the end of the name 
		str = list[k];
		i1 = indexOf(str, ".");
		nameC= substring(str,0,i1) +"-tip";
		print("- "+nameC);
		
		// Open the 'k' image in the folder and store its title (easier to find it after)
		t1 = dirTemp + list[k];
		open(t1);
		ti1=getTitle();

		// If it is the first image in the time series just save it.
		if(k == 0){
	
			saveAs("Tiff", dir1 + nameC);
			close();
		}else{ 
		//If it is not the first image, get the previous "raw" (i.e. combined and aligned) image and process that one
			t2 = dirTemp + list[k-1]; // 
			open(t2);
			ti2=getTitle();

			setThreshold(12, 800);  // Set the threshold value   **SOMETHING TO EDIT**
			setOption("BlackBackground", false); 
			run("Convert to Mask");  // Create the binary image
		
			run("Dilate");	  // Dilate twice to make the rotos of the previous day larger 
			run("Dilate");	// This way you are able to subtract more of the root 

			imageCalculator("Subtract create",ti1, ti2); // Do the subtraction 
			
			saveAs("Tiff", dir1 + nameC);
// Save it
			close();
			selectWindow(ti2);
			close();
			selectWindow(ti1);
			close();	
		}
 
	}
	folder_count++;
}

print("Processing done. "+folder_count+" rhizotrons folders were processed");

