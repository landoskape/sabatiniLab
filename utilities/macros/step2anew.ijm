
name=getInfo("image.filename");
dirimage=getInfo("image.directory");
roiManager("Save", dirimage+name+"_cellroi.zip");
roiManager("List");
selectWindow("Overlay Elements");
saveAs("Text","C:\\Users\\Adam Granger\\Desktop\\x");
//waitForUser;
selectWindow("Log");run("Close");


run("Colors...", "foreground=white background=black selection=yellow");
run("Options...", "iterations=1 count=1 black");

dir="C:\\Users\\Adam Granger\\Desktop\\ForMike\\test images\\";

//measure 2, generate the puncta.xls
measure2();


// ----------------------------------  functions  ------------------------


 function measure2()
 {

open(dir+"ch1th.tif");	rename("ch1");
  open(dir+"ch2th.tif");rename("ch2");
  open(dir+"ch3th.tif");rename("ch3");

    
  regioncellcount=roiManager("Count");
   max=0;
  maxch1=0;
  cell1=newArray(10);
  cell1hist=newArray(100000);
  selectWindow("ch1");
  for(i=0;i<=9;i++)
   {
   start=i+regioncellcount-10;  
   roiManager("Select",start);
   getStatistics(area); 
  roiManager("Measure");
   cell1[i]=round(getResult("IntDen")/255/area*1000);
   if( cell1[i] > max ) max=cell1[i];
   if( cell1[i] > maxch1 ) maxch1=cell1[i];
   cell1hist[parseInt(cell1[i])] = cell1hist[parseInt(cell1[i])] + 1 ;
   }
  run("Clear Results");

  maxch2=0; 
  cell2=newArray(10);
  cell2hist=newArray(100000);
  selectWindow("ch2");
 for(i=0;i<=9;i++)
   {
   start=i+regioncellcount-10;    
   roiManager("Select",start);
   getStatistics(area); 
  roiManager("Measure");
   cell2[i]=round(getResult("IntDen")/255/area*1000);
   if( cell2[i] > max ) max=cell2[i];
   if( cell2[i] > maxch2 ) maxch2=cell2[i];
   cell2hist[parseInt(cell2[i])] = cell2hist[parseInt(cell2[i])] + 1 ;
   }
  run("Clear Results");
maxch3=0;
  cell3=newArray(10);
 cell3hist=newArray(100000);
  selectWindow("ch3");
  for(i=0;i<=9;i++)
   {	
    start=i+regioncellcount-10;
    roiManager("Select",start);
    getStatistics(area); 
  roiManager("Measure");
    cell3[i]=round(getResult("IntDen")/255/area*1000);
    if( cell3[i] > max ) max=cell3[i];
    if( cell3[i] > maxch3 ) maxch3=cell3[i];
    cell3hist[parseInt(cell3[i])] = cell3hist[parseInt(cell3[i])] + 1 ;
   }
  run("Clear Results");
 run("Close All");

for(i=0;i<=max;i++)
print(i+" "+cell1hist[i]+" "+cell2hist[i]+" "+cell3hist[i]+" ");
open(dirimage+name);
}
	
