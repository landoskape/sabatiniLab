// initialize ImageJ
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");

var dir, name, slice, width, height;
var th1, th2, th3;

dirimage=getInfo("image.directory");
dir="C:\\Users\\Adam Granger\\Desktop\\ForMike\\test images\\";
name=getInfo("image.filename");

//split schannel generate sum image
parameterinput();
open(dirimage+name);



// ----------------------------------  functions  ------------------------

function parameterinput()
 {
  Dialog.create("threshold");
  Dialog.addNumber("th1", 50);
  Dialog.addNumber("th2", 70);
  Dialog.addNumber("th3", 70);
Dialog.addCheckbox("th1thesholding", false);
Dialog.addCheckbox("th2thresholding", false);
Dialog.addCheckbox("th3thresholding", false);
Dialog.show();
th1=Dialog.getNumber();
th2=Dialog.getNumber();
th3=Dialog.getNumber();
th1thresholding=Dialog.getCheckbox;
th2thresholding=Dialog.getCheckbox;
th3thresholding=Dialog.getCheckbox;
 
//Seperate and rename each channel
  run("Split Channels");
  selectWindow("C4-"+name); rename("dapi"); //for images w/ no transmitted DIC, with DAPI
//selectWindow("C5-"+name); rename("dapi"); //for images w/ transmitted DIC
  selectWindow("C3-"+name); rename("ch3"); ch3=getTitle;
  selectWindow("C2-"+name); rename("ch2"); ch2=getTitle;
  selectWindow("C1-"+name); rename("ch1"); ch1=getTitle;
 

//Threshold each channel
selectWindow("ch1");
if (th1thresholding){
setAutoThreshold("Triangle dark");
}else{
setAutoThreshold("Default dark");
setThreshold(th1, 255);
}
run("Convert to Mask");
saveAs("tiff", dir+"ch1th.tif");  ch1=getTitle;

selectWindow("ch2");
if (th2thresholding){
setAutoThreshold("Triangle dark");
}else{
setAutoThreshold("Default dark");
setThreshold(th2, 255);
}
run("Convert to Mask");
saveAs("tiff", dir+"ch2th.tif");  ch2=getTitle;

selectWindow("ch3");
if (th3thresholding){
setAutoThreshold("RenyiEntropy dark");
}else{
setAutoThreshold("Default dark");
setThreshold(th3, 255);
}
run("Convert to Mask");
saveAs("tiff", dir+"ch3th.tif");  

//re-open image
open(dirimage+name);
run("Split Channels");
selectWindow("C4-"+name); rename("dapi"); // for images w/ no transmitted DIC
//selectWindow("C5-"+name); rename("dapi"); //for images w/ transmitted DIC
selectWindow("C3-"+name); rename("ch3"); ch3=getTitle;
selectWindow("C2-"+name); rename("ch2");  ch2=getTitle;
selectWindow("C1-"+name); rename("ch1"); ch1=getTitle;
slice= nSlices; width=getWidth(); height=getHeight();
selectWindow("ch1");
//Originally used Otsu dark, but was getting too much background for VIP images w/ little to no cells - swithc to Renyi
setAutoThreshold("RenyiEntropy dark");
run("Convert to Mask");

selectWindow("ch2");
setAutoThreshold("RenyiEntropy dark");
run("Convert to Mask");

selectWindow("ch3");
setAutoThreshold("RenyiEntropy dark");
run("Convert to Mask");
run("Add Slice");

selectWindow("ch1"); run("Copy");
selectWindow("ch3"); run("Paste");run("Add Slice");
selectWindow("ch2");run("Copy");
selectWindow("ch3");run("Paste");
run("Z Project...", "projection=[Max Intensity]");
run("Convert to Mask");
saveAs("tiff", dir+"MAX.tif");
getPixelSize(unit, pixelWidth, pixelHeight); 
print(pixelWidth);
print(height);
print(width);
run("Mean...", "radius 3");


//run("Merge Channels...", "red=["+ch3+"] green=["+ch1+"] blue=["+dapi+"] gray=*None* cyan=["+ch2+"] magenta=*None* keep ignore");
setAutoThreshold("Moments dark");

  run("Analyze Particles...", "size="+10+"-"+500+" exclude clear add");
  totalcellcount = roiManager("Count");
for(i=0; i<totalcellcount; i++) {
    roiManager("Select", i);
    run("Enlarge...", "enlarge=3");
    roiManager("Update");
roiManager("Fill");}
run("Convert to Mask");

//run("Watershed");
//run("Convert to Mask");
//run("Fill Holes");
//run("Mean...", "radius 1");

run("Analyze Particles...", "size="+150+"-"+1000+" exclude clear add");
totalcellcount = roiManager("Count");
for(i=0; i<totalcellcount; i++) {
    roiManager("Select", i);
    run("Enlarge...", "enlarge=-3");
    roiManager("Update");
}

if( roiManager("Count") > 0 )  roiManager("Save", dir+"cellroi.zip");


//selectWindow("dapi"); close();
selectWindow("ch1th.tif"); close(); 
selectWindow("ch2th.tif"); close(); 
selectWindow("ch3th.tif"); close();
selectWindow("ch1"); close(); 
selectWindow("ch2"); close(); 
selectWindow("ch3"); close();
//selectWindow("MAX_ch3th.tif"); close(); 

 }

roiManager("Show All");
 	
