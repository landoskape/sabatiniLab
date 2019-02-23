
name=getInfo("image.filename");
dirimage=getInfo("image.directory");
selectWindow("Log");run("Close");


run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");

dir="C:\\Users\\Adam Granger\\Desktop\\ForMike\\test images\\";
var ch1_T, ch2_T, ch3_T;

//input prameters
parameterinput();
//measure, generate the puncta.xls
measure();


// ----------------------------------  functions  ------------------------
function parameterinput()
 {
  Dialog.create("Threshold");
  Dialog.addNumber("Channel 1 Threshold", 2);
  Dialog.addNumber("Channel 2 Threshold", 5);
  Dialog.addNumber("Channel 3 Threshold", 5);
Dialog.show();
  ch1_T = Dialog.getNumber();
  ch2_T = Dialog.getNumber();
  ch3_T = Dialog.getNumber();	
 }


 function measure()
 {

  open(dir+"ch1th.tif");rename("ch1");
  open(dir+"ch2th.tif");rename("ch2");
  open(dir+"ch3th.tif");rename("ch3");
    
  regioncellcount=roiManager("Count");
   max=0;
cell1=newArray(100000);
cell1hist=newArray(100000);

end=regioncellcount-11;

  selectWindow("ch1");
  run("Clear Results");
  for(i=0;i<=end;i++)
   {
roiManager("Select",i);
   getStatistics(area); 
  roiManager("Measure");
cell1[i]=round(getResult("IntDen")/255/area*1000);
if(cell1[i]>=ch1_T) roiManager("Fill");
      }
saveAs("tiff", dir+"ch1pos.tif");

run("Clear Results");
  cell2=newArray(100000);
  cell2hist=newArray(100000);
  selectWindow("ch2");
  run("Clear Results");
   for(i=0; i<=end; i++)
   {
roiManager("Select",i);
   getStatistics(area); 
 roiManager("Measure");
cell2[i]=round(getResult("IntDen")/255/area*1000);
if(cell2[i]>=ch2_T) roiManager("Fill");
      }
saveAs("tiff", dir+"ch2pos.tif");
  run("Clear Results");
  
cell3=newArray(100000);
cell3hist=newArray(100000);
  selectWindow("ch3");
  run("Clear Results");
  for(i=0;i<=end;i++)
   {
roiManager("Select",i);
   getStatistics(area); 
  roiManager("Measure");
cell3[i]=round(getResult("IntDen")/255/area*1000);
if(cell3[i]>=ch3_T) roiManager("Fill");
      }
saveAs("tiff", dir+"ch3pos.tif");
run("Clear Results");
print("0  "+ch1_T+" "+ch2_T+" "+ch3_T);
for(i=0;i<=end;i++)

print(i+1+" "+cell1[i]+" "+cell2[i]+" "+cell3[i]);

//selectWindow("Results"); run("Close");
//selectWindow("ROI Manager"); run("Close");

selectWindow("Log");
}
