//DECIDE THINGS ABOUT IMAGE
//Size of the border
border = 10; 
//Number of columns
plantsPerRow = 12;
//Root image size
rootWidth = 450;
rootHeight = 900;
//Shoot image size
shootWidth = 30;
shootHeight = shootWidth;
// number of plants
numPlants = 96;
// number of rows
numRows = (numPlants+numPlants%plantsPerRow)/plantsPerRow;

startImaging = 9


// Tell ImageJ not to display the images
setBatchMode(true);

// Get the image directory
dirRoot = getDirectory("Where are your ROOT images");
//dirShoot = getDirectory("Where are your SHOOT images");
dir1 = getDirectory("Where do you want to save the assembled images");

// Get the image list
rootList = getFileList(dirRoot);
Array.sort(rootList);
//shootList = getFileList(dirShoot)
numRootImages = rootList.length;
//numShootImages = shootList.length;

//Determine the number of plants
//if (numRootImages != numShootImages)
//{
//	exit("There are unequal numbers of shoot and root images");
//} 

numImages = numRootImages;
numDays = numImages/numPlants;


//Information about the images that are processed
//print("Processing of "+numRoot+" root images started.");
//print("Processing of "+numShoot+" shoot images started.");
//count = 0;

//Make a blank canvas for each day
for(day = 0; day < numDays; day++)
{
	newImage("Day-"+(day+1), "RGB black", plantsPerRow*(rootWidth+2*border), border+numRows*(shootHeight+rootHeight+border), 1);
}

for (plant = 0; plant < numPlants; plant++)
{
	for(day = 0; day < numDays; day++)
	{
		row = plant/plantsPerRow - (plant%plantsPerRow)/plantsPerRow;// want integer division here
 		column = plant%plantsPerRow;

		//Assemble root image
		image = dirRoot + rootList[plant*numDays+day];
		open(image); 

		//Shrink root image and copy it
		run("Size...", "width=rootWidth height=rootHeight constrain average interpolation=Bilinear");
		run("Select All");
		run("Copy");
	
		//Paste root image
		selectWindow("Day-"+(day+1));
		makeRectangle(border+column*(rootWidth+2*border), border+shootHeight+row*(shootHeight+rootHeight+border), rootWidth, rootHeight);
		run("Paste");

		//Assemble shoot image
		//image = dirShoot + shootList[plant*numDays+day];
		//open(image); 

		//Shrink shoot image and copy it
		//run("Size...", "width=shootWidth height=shootHeight constrain average interpolation=Bilinear");
		//run("Select All");
		//run("Copy");
	
		//Paste shoot image
		//selectWindow("Day-"+(day+1));
		//makeRectangle(border+(rootWidth-shootWidth)/2+column*(rootWidth+2*border), border+row*(shootHeight+rootHeight+border), shootWidth, shootHeight);
		//run("Paste");
	}
}

//Save each assembled image
for(day = 0; day < numDays; day++)
{
	selectWindow("Day-"+(day+1));
	h = getHeight();
	w = getWidth(); 
	setColor("white");
	setFont("SansSerif", 40); 
	drawString(IJ.pad((day+startImaging),2)+ " DAS", (50) ,(h-50));
	saveAs("Jpeg", dir1 + "day-"+IJ.pad((day+startImaging),2));
}

print("Done processing images!");
