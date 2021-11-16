// May 13, 2019 - 


// if setBatchMode is true, then imagej will no display the images, which is faster
setBatchMode(true);

// Get the directory for the folders of aligned images
dir = getDirectory("Where are your image folders");
dir1 = getDirectory("Where do you want to save your images");

// Get the list of folders of aligned images
folder_list = getFileList(dir);
folder_num = folder_list.length;
folder_count = 0;

Array.sort(folder_list);
Array.print(folder_list);

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
		nameC= substring(str,0,i1) +"-invert";
		print("- "+nameC);
		
		// Open the 'k' image in the folder and store its title
		t1 = dirTemp + list[k];
		open(t1);
	
		run("Invert");
		saveAs("TIFF", dir1 + nameC);
		close();

	}
	folder_count++;
}

print("Processing done. "+folder_count+" rhizotrons folders were processed");