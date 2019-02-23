roiManager("Show All");
run("Set Measurements...", "mean redirect=None decimal=3");

ROIcount = roiManager("Count");
length = nSlices;
inside= newArray(length);
outside = newArray(length);
for(i=1; i<=length; i++)
		{
    roiManager("Select",0);
    Stack.setSlice(i);
    run("Measure");
    inside[i-1]= getResult("Mean");
    run("Clear Results");}

for(i=0;i<length;i++){
print(inside[i]);}

for(i=1; i<=length; i++)
		{
    roiManager("Select",1);
    Stack.setSlice(i);
    run("Measure");
    outside[i-1]= getResult("Mean");
		}

roiManager("Show All");


//roiManager("Deselect");
//roiManager("Measure");
