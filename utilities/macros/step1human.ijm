// initialize ImageJ
run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");

var dir, name, slice, width, height;
var th1, th2, th3;

dirimage=getInfo("image.directory");
dir="\\\\commons.med.harvard.edu\\COMMONS\\Neurobiology\\MICROSCOPE\\Sarah\\ISH analysis\\";
name=getInfo("image.filename");

//split schannel generate sum image
initialize();
open(dirimage+name);



// ----------------------------------  functions  ------------------------




// initialze opened raw data, split into 4 raw images. name ch1, ch2, ch3 and dapi(ch4)
function initialize()
 {
   Dialog.create("threshold");
  Dialog.addNumber("th1", 78);
  Dialog.addNumber("th2", 80);
  Dialog.addNumber("th3", 70);
  Dialog.show();
  th1 = Dialog.getNumber();
  th2 = Dialog.getNumber();
  th3 = Dialog.getNumber();

  run("Split Channels");
  selectWindow("C4-"+name); rename("dapi"); 
  selectWindow("C3-"+name); rename("ch3"); ch3=getTitle;
  selectWindow("C2-"+name); rename("ch2");  ch2=getTitle;
  selectWindow("C1-"+name); rename("ch1"); ch1=getTitle;
  slice= nSlices; width=getWidth(); height=getHeight();



selectWindow("ch1");
//run("Subtract Background...", "rolling="+10);
setAutoThreshold("Default dark");
setThreshold(th1, 255);
run("Convert to Mask");
saveAs("tiff", dir+"ch1th.tif");  ch1=getTitle;

selectWindow("ch2");
//run("Subtract Background...", "rolling="+10);
setAutoThreshold("Default dark");
setThreshold(th2, 255);
run("Convert to Mask");
saveAs("tiff", dir+"ch2th.tif");  ch2=getTitle;

selectWindow("ch3");
//run("Subtract Background...", "rolling="+10);
setAutoThreshold("Default dark");
setThreshold(th3, 255);
run("Convert to Mask");
saveAs("tiff", dir+"ch3th.tif");
getPixelSize(unit, pixelWidth, pixelHeight); 
print(pixelWidth);
print(height);
print(width);


selectWindow("dapi"); close(); 
selectWindow("ch1th.tif"); close(); 
selectWindow("ch2th.tif"); close(); 
selectWindow("ch3th.tif"); close();


 }


 	
