//macro for Matthew       Bernardo Sabatini lab
// step 2
//raw data has filename_chxsum.tif  and filename_cellroi.zip  filename_ROI.zip
// open filename_cellroi in each region based on the center mass position. 

// version 2 use puncta count to decide positive or not.
// also generate a puncta.xls to show puncta (ch1/ch2/ch3) in each cellroi region 

// initialize ImageJ
name=getInfo("image.filename");
dirimage=getInfo("image.directory");
selectWindow("Log");run("Close");


run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");

var dir, name, slice, width, height;
var totalcellcount, totalROIcount;
var cellROI=newArray(10000);
dir="C:\\Users\\Adam Granger\\Desktop\\ForMike\\test images\\";



// initialize
initialize();
//measure 2, generate the puncta.xls
measure();


// ----------------------------------  functions  ------------------------

function initialize()
 {
  width=getWidth(); height=getHeight();
 }


 function measure()
 {

  open(dir+"ch1th.tif");rename("ch1");
  open(dir+"ch2th.tif");rename("ch2");
  open(dir+"ch3th.tif");rename("ch3");
  
//roiManager("Open",  dirimage+name+"_cellroi.zip" );
    
  regioncellcount=roiManager("Count");
   max=0;
   cell1=newArray(100000);
  cell1hist=newArray(1000000);

end=regioncellcount-11;
  selectWindow("ch1");
  run("Clear Results");

for(i=0;i<=end;i++)
   {
roiManager("Select",i);
getStatistics(area); 
roiManager("Measure");

cell1[i]=round(getResult("IntDen")/255/area*1000);
    if( cell1[i] > max ) max=cell1[i];
    cell1hist[parseInt(cell1[i])] = cell1hist[parseInt(cell1[i])] + 1 ;
   }
  run("Clear Results");

cell2=newArray(100000);
cell2hist=newArray(1000000);
  selectWindow("ch2");

  for(i=0; i<=end; i++)
   {
roiManager("Select",i);
   getStatistics(area); 
  roiManager("Measure");
cell2[i]=round(getResult("IntDen")/255/area*1000);
    if( cell2[i] > max ) max=cell2[i];
   cell2hist[parseInt(cell2[i])] = cell2hist[parseInt(cell2[i])] + 1 ;
   }
  run("Clear Results");

cell3=newArray(100000);
cell3hist=newArray(1000000);
  selectWindow("ch3");
  for(i=0;i<=end;i++)
   {
roiManager("Select",i);
   getStatistics(area); 
  roiManager("Measure");

cell3[i]=round(getResult("IntDen")/255/area*1000);
    if( cell3[i] > max ) max=cell3[i];
   cell3hist[parseInt(cell3[i])] = cell3hist[parseInt(cell3[i])] + 1 ;
   }

  run("Clear Results");
  run("Close All");
//print("Cell#	Ch1#	Ch2#	Ch3#");
//for(i=0;i<regioncellcount;i++)
//print(i+1+" "+cell1[i]+" "+cell2[i]+" "+cell3[i]);
//selectWindow("Results"); run("Close");
//selectWindow("ROI Manager"); run("Close");
//selectWindow("Log"); run("Close");

for(i=0;i<=max;i++)
print(i+" "+cell1hist[i]+" "+cell2hist[i]+" "+cell3hist[i]+" ");
open(dirimage+name);
}
	
