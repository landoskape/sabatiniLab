%save databin: Number of cells per bin, distance of bin from pia, no of ch1 per bin, no ch2 per bin, no ch3 per bin, no ch1ch2 per bin, no ch2ch3 per bin, no ch1ch3 per bin, no ch1ch2ch3 per bin, ch1ch2/ch2, ch2ch3/ch2,ch1ch2/ch1, ch1ch3/ch1, ch1ch3/ch3, ch2ch3/ch3
%save Puncta: cell name, ch1Puncta, ch2Puncta, Ch3Puncta, x-coordinate,y-coordinate
%save Punctathresholding: Ch1 pos/neg, Ch2 pos/neg, ch3 pos/neg, x-coordinate, y-coordinate

binNo=12; %to analyze staining dependent on distance from pia, image is binned into equally-sized rows
type=0;
%type 0:punctate staining like GRPR.thresholding method is Triangle/Triangle/Renyi or manual. ROI script can be changed in step1new_Renyi.ijm;
%type 6: no ROIs and threshold set manually. Can be changed in step1human.ijm

Ch1probe='VGAT';%green
Ch2probe='GAD';%farred 
Ch3probe='ChAT';%red

javaaddpath('C:\Program Files\MATLAB\R2015a\java\jar\mij.jar')
javaaddpath('C:\Program Files\MATLAB\R2015a\java\jar\ij.jar')

folder = uigetdir('','Open folder containing .tif files');
cd(folder);
images = dir('*.tif');
nimages = length(images);

%generate progress bar
h = waitbar(0,['Analyzing image, 0/' num2str(nimages)]);

%Loop through all images
for k = 1:nimages
    
    waitbar(k/nimages, h,['Analyzing image, ' num2str(k) '/' num2str(nimages)]); %update progress bar   
    outputcell=strcat('A',num2str(k+2)); %stores values in file called 'table'. Path defined at end of script!
    filename=images(k).name;%choose name under which to store it in excel sheet!
    MIJ.start;
    MIJ.run('Open...',strcat('path=[',folder,'\',images(k).name,']'))



%Run step 1: Assign ROIs to each cell
if type==0  
    MIJ.run('Run...','path=[C:\Fiji.app\macros\step1new_Renyi.ijm]')
elseif type==6
    MIJ.run('Run...','path=[C:\Fiji.app\macros\step1human.ijm]')
    type=0;
end

PixelWidth=str2num(MIJ.getLog);
area=PixelWidth(1)*PixelWidth(2)*PixelWidth(1)*PixelWidth(3);
Scale=PixelWidth(1);
Width=PixelWidth(3)*PixelWidth(1);
pause on
pause;
%optimize ROIs and click somewhere in Matlab command window, draw 10
%non-cell ROIs

%Run step 2: Measure background signal of 10 non-cell ROIs drawn by user
MIJ.run('Run...','path=[C:\Fiji.app\macros\step2anew.ijm]')
Punctahist=str2num(MIJ.getLog);
%save Overlay Elements as defined in line 110

figure
subplot(3,1,1)
bar(Punctahist(:,1),Punctahist(:,2))
title({Ch1probe})

subplot(3,1,2)
bar(Punctahist(:,1),Punctahist(:,3))
title({Ch2probe})
subplot(3,1,3)
bar(Punctahist(:,1),Punctahist(:,4))
title({Ch3probe})
pause
%get threshold for negative control and click in matlab command window

%Run step 3: Measure promille coverage of each cell body
MIJ.run('Run...','path=[C:\Fiji.app\macros\step2bnew.ijm]')

Punctahist=str2num(MIJ.getLog);
figure
subplot(3,1,1)
bar(Punctahist(:,1),Punctahist(:,2))
title({Ch1probe})
subplot(3,1,2)
bar(Punctahist(:,1),Punctahist(:,3))
title({Ch2probe})
title({Ch2probe})
subplot(3,1,3)
bar(Punctahist(:,1),Punctahist(:,4))
title({Ch3probe})
pause
%find thresholds for promille coverage of cell body

%Base on thresholds, save ROIs of positive cells in each channel
MIJ.run('Run...','path=[C:\Fiji.app\macros\step3new.ijm]');

Puncta=str2num(MIJ.getLog);
figure
subplot(2,3,1)
plot(Puncta(2:end,2),Puncta(2:end,3),'.k')
ylabel({Ch2probe});xlabel({Ch1probe});axis('tight')
subplot(2,3,2)
plot(Puncta(2:end,3),Puncta(2:end,4),'.k')
axis('tight');ylabel({Ch3probe});xlabel({Ch2probe})
subplot(2,3,3)
plot(Puncta(2:end,2),Puncta(2:end,4),'.k')
ylabel({Ch3probe});xlabel({Ch1probe});axis('tight')
%save List


coordinates=[];
coordinateslist=textread('C:\Users\Adam Granger\Desktop\x.txt','%s');%
for i=4:14:(length(coordinateslist))
   coordinates=[coordinates;[coordinateslist(i),coordinateslist(i+1)]];
end
coordinatesnew=[];
for i=1:length(coordinates)
   j=1:2;
  coordinatesnew(i,j)=str2double(coordinates(i,j));
end
 Puncta=[Puncta,coordinatesnew(1:(length(coordinatesnew)-10),:)];
 [m,n]=size(Puncta);
 Puncta=[Puncta(:,1:(n-2)),(Puncta(:,(n-1):n).*Scale)];

 colabeling=Puncta;
 Punctathresholding=Puncta(:,2:n).*0;
 Punctathresholding(:,(n-2):(n-1))=Puncta(:,(n-1):n);
 C1intensityinC3cellsCFC=Puncta(:,2);
 C1intensityinC3cellsCFC(1)=NaN;
 C1intensityinC3negativecellsCFC=Puncta(:,2);
 C1intensityinC3negativecellsCFC(1)=NaN;
 
 for i=2:length(Puncta)
     if Puncta(i,2)>=Puncta(1,2)
         Punctathresholding(i,1)=1;
         if Puncta(i,3)>=Puncta(1,3);
             colabeling(i,1)=1;
         else colabeling(i,1)=0;
         end
     else colabeling(i,1)=0;
     end
     if Puncta(i,3)>=Puncta(1,3)
         Punctathresholding(i,2)=1;
         if Puncta(i,4)>=Puncta(1,4);
             colabeling(i,2)=1;
         else colabeling(i,2)=0;
         end
     else colabeling(i,2)=0;
     end
     if Puncta(i,4)>=Puncta(1,4)
         Punctathresholding(i,3)=1;
         C1intensityinC3negativecellsCFC(i)=NaN;
         if Puncta(i,2)>=Puncta(1,2);
             colabeling(i,3)=1;
         else colabeling(i,3)=0;
             C1intensityinC3cellsCFC(i)=NaN;
         end
     else colabeling(i,3)=0;
     end
     if Puncta(i,2)>=Puncta(1,2)
         if Puncta(i,3)>=Puncta(1,3)
             if Puncta(i,4)>=Puncta(1,4);
                 colabeling(i,4)=1;
             else colabeling(i,4)=0;
             end
         else colabeling(i,4)=0;
         end
     else colabeling(i,4)=0;
     end
 end
 
 sumcolabeling=sum(colabeling(2:end,1:4));

%figure
%subplot(1,3,2)
%location=find(Punctathresholding(:,1));
%location=(Punctathresholding(location(1:end),(n-1)));
%plotSpread(location,'distributionColors',[0 0.5 0],'binWidth',[0.01])
%location=find(Punctathresholding(:,2));
%location=Punctathresholding(location(1:end),(n-1));
%plotSpread(location,'distributionColors',[0 0.8 0.8],'binWidth',[0.04])
%location=find(Punctathresholding(:,3));
%if sum(location)>0;
%    location=(Punctathresholding(location(1:end),5));
%    plotSpread(location,'distributionColors',[0.749019622802734 0 0.749019622802734],'binWidth',[0.02])
%end
%title('distribution of positive cells')
%ylabel('#distance from pia')
%xlim([0.5 1.5])
%axis ij;
   
 %# cells labeled per bin, always 10 bins
 Ch1bin=[];
 for i=(max(colabeling(:,n))/binNo):(max(colabeling(:,n))/binNo):max(colabeling(:,n));
     Ch1=0;
     all=0;
     for j=2:length(colabeling)
        if colabeling(j,n)<=i;
             if colabeling(j,n)>(i-(max(colabeling(:,n))/binNo));
                 all=all+1;
                 if Punctathresholding(j,1)==1;
                 Ch1=Ch1+1;
                 end
             end
        end
     end
     Ch1bin=[Ch1bin;all,i,Ch1];
 end
 
 Ch2bin=[];
 for i=(max(colabeling(:,n))/binNo):(max(colabeling(:,n))/binNo):max(colabeling(:,n));
     Ch2=0;
     for j=2:length(colabeling)
        if colabeling(j,n)<=i;
             if colabeling(j,n)>(i-(max(colabeling(:,n))/binNo));
                 if Punctathresholding(j,2)==1;
                 Ch2=Ch2+1;
                 end
             end
        end
     end
     Ch2bin=[Ch2bin;Ch2];
 end
 
 Ch3bin=[];
    for i=(max(colabeling(:,6))/binNo):(max(colabeling(:,6))/binNo):max(colabeling(:,6));
        Ch3=0;
        for j=2:length(colabeling)
            if colabeling(j,6)<=i;
                if colabeling(j,6)>(i-(max(colabeling(:,6))/binNo));
                    if Punctathresholding(j,3)==1;
                        Ch3=Ch3+1;
                    end
                end
            end
        end
        Ch3bin=[Ch3bin;Ch3];
    end
    Chbin=[Ch1bin,Ch2bin,Ch3bin];%makes matrix with number of cells, number of ch1, number of ch2, number of ch3, localization
    
  %  figure;
  %  subplot(1,2,1)
  %  plot(Chbin(:,3),Chbin(:,2),'-.g')
  %  hold on
  %  plot(Chbin(:,4),Chbin(:,2),'-.c') 
  %  plot(Chbin(:,5),Chbin(:,2),'-.r') 
  %  title('distribution of positive cells')
  %  ylabel('distance from pia')
  %  xlabel('# positive cells')    
  %  axis ij
 

 %# cells colabeled per bin, always 10 bins
 Ch1Ch2bin=[];
 distance=[];
 for i=(max(colabeling(:,n))/binNo):(max(colabeling(:,n))/binNo):max(colabeling(:,n));
     Ch1Ch2=0;
     for j=2:length(colabeling)
        if colabeling(j,n)<=i;
             if colabeling(j,n)>(i-(max(colabeling(:,n))/binNo));
                 if colabeling(j,1)==1;
                 Ch1Ch2=Ch1Ch2+1;
                 end
             end
        end
     end
     Ch1Ch2bin=[Ch1Ch2bin;Ch1Ch2];
     distance=[distance;i];
 end
     Ch2Ch3bin=[];
     for i=(max(colabeling(:,n))/binNo):(max(colabeling(:,n))/binNo):max(colabeling(:,n));
         Ch2Ch3=0;
         for j=2:length(colabeling)
             if colabeling(j,n)<=i;
                 if colabeling(j,n)>(i-(max(colabeling(:,n))/binNo));
                     if colabeling(j,2)==1;
                         Ch2Ch3=Ch2Ch3+1;
                     end
                 end
             end
         end
         Ch2Ch3bin=[Ch2Ch3bin;Ch2Ch3];
     end
     Ch1Ch3bin=[];
     for i=(max(colabeling(:,n))/binNo):(max(colabeling(:,n))/binNo):max(colabeling(:,n));
         Ch1Ch3=0;
         for j=2:length(colabeling)
             if colabeling(j,n)<=i;
                 if colabeling(j,n)>(i-(max(colabeling(:,n))/binNo));
                     if colabeling(j,3)==1;
                         Ch1Ch3=Ch1Ch3+1;
                     end
                 end
             end
         end
         Ch1Ch3bin=[Ch1Ch3bin;Ch1Ch3];
     end
     Ch1Ch2Ch3bin=[];
     for i=(max(colabeling(:,n))/binNo):(max(colabeling(:,n))/binNo):max(colabeling(:,n));
         Ch1Ch2Ch3=0;     
         for j=2:length(colabeling)
             if colabeling(j,n)<=i;
                 if colabeling(j,n)>(i-(max(colabeling(:,n))/binNo));
                     if colabeling(j,4)==1;
                         Ch1Ch2Ch3=Ch1Ch2Ch3+1;
                     end
                 end
             end
         end
         Ch1Ch2Ch3bin=[Ch1Ch2Ch3bin;Ch1Ch2Ch3];
     end

 
Ch1bin(find(Ch1bin==0))=NaN;
Ch2bin(find(Ch2bin==0))=NaN;
Ch3bin(find(Ch3bin==0))=NaN;
databin=[Chbin,Ch1Ch2bin,Ch2Ch3bin,Ch1Ch3bin,Ch1Ch2Ch3bin,(Ch1Ch2bin./Ch2bin),(Ch2Ch3bin./Ch2bin),(Ch1Ch2bin./Ch1bin(:,3)),(Ch1Ch3bin./Ch1bin(:,3)),(Ch1Ch3bin./Ch3bin),(Ch2Ch3bin./Ch3bin)];
%subplot(1,2,2)
%plot(databin(:,12),distance, 'LineStyle','-.','Color',[0 1 0],'MarkerSize',20,'Marker','.','LineWidth',2)
%hold on
%plot(databin(:,10),distance,'LineStyle',':','Color',[0 0.600000023841858 0.600000023841858],'MarkerSize',20,'LineWidth',2)
%plot(databin(:,13),distance,'Color',[0 0.498039215803146 0],'MarkerSize',20,'LineWidth',2)
%plot(databin(:,14),distance,'.-m','MarkerSize',20,'LineWidth',2)
%plot(databin(:,11),distance,'LineStyle',':','Color',[0.635294139385223 0.0784313753247261 0.184313729405403],'MarkerSize',20,'LineWidth',2)
%plot(databin(:,15),distance,'MarkerSize',20,'Marker','.','LineWidth',2,'LineStyle','-.','Color',[0.494117647409439 0.184313729405403 0.556862771511078])

%title('colabeling distribution')
%ylabel('distance from pia')
%xlabel('proportion of colabeled cells')
%axis ij
 
thresholdCh1=Puncta(1,2);
thresholdCh2=Puncta(1,3);
thresholdCh3=Puncta(1,4);
NoCh1cell=sum(Punctathresholding(:,1));
NoCh2cell=sum(Punctathresholding(:,2));
NoCh3cell=sum(Punctathresholding(:,3));

for j=2:4;
     for i=2:length(Puncta);
         if Puncta(i,j)<Puncta(1,j);
             Puncta(i,j)=0;
         else Puncta(i,j)=Puncta(i,j)-Puncta(1,j)+1;
         end
     end
end
R1_2=corrcoef(Puncta(2:end,2),Puncta(2:end,3));
R2_3=corrcoef(Puncta(2:end,3),Puncta(2:end,4));
R1_3=corrcoef(Puncta(2:end,2),Puncta(2:end,4));
R1_2(2)
R2_3(2)
R1_3(2)

%figure
%subplot(2,3,1)
%plot(Puncta(2:end,2),Puncta(2:end,3),'.k')
%ylabel({Ch2probe});xlabel({Ch1probe});axis('tight')
%title(num2str(R1_2(2)))
%subplot(2,3,2)
%plot(Puncta(2:end,3),Puncta(2:end,4),'.k')
%axis('tight');ylabel({Ch3probe});xlabel({Ch2probe})
%title(num2str(R2_3(2)))
%subplot(2,3,3)
%plot(Puncta(2:end,2),Puncta(2:end,4),'.k')
%ylabel({Ch3probe});xlabel({Ch1probe});axis('tight')
%title(num2str(R1_3(2)))


C1intensityinC3cellsCFC(isnan(C1intensityinC3cellsCFC))=[];
for i=1:length(C1intensityinC3cellsCFC);
    if C1intensityinC3cellsCFC(i)<Puncta(1,2);
        C1intensityinC3cellsCFC(i)=0;
    else C1intensityinC3cellsCFC(i)=C1intensityinC3cellsCFC(i)-Puncta(1,2)+1;
    end
end
C1intensityinC3negativecellsCFC(isnan(C1intensityinC3negativecellsCFC))=[];
for i=1:length(C1intensityinC3negativecellsCFC);
    if C1intensityinC3negativecellsCFC(i)<Puncta(1,2);
        C1intensityinC3negativecellsCFC(i)=0;
    else C1intensityinC3negativecellsCFC(i)=C1intensityinC3negativecellsCFC(i)-Puncta(1,2)+1;
    end
end
averageC1inC3=mean(C1intensityinC3cellsCFC);
stdC1inC3=std(C1intensityinC3cellsCFC);
averageC1inC3neg=mean(C1intensityinC3negativecellsCFC);
stdC1inC3neg=std(C1intensityinC3negativecellsCFC);
averageCh3=sum(Puncta(2:end,4))/NoCh3cell;
onlyArcinGrp=find(Puncta(:,4));
onlyArcinGrp=[Puncta(onlyArcinGrp,2),Puncta(onlyArcinGrp,4)];
R1_3Ch3only=corrcoef(onlyArcinGrp(2:end,1),onlyArcinGrp(2:end,2));
%R1_3Ch3only(2) %% unclear what this is for
avgCh2=sum(Puncta(2:end,3))/NoCh2cell;
avgCh1=sum(Puncta(2:end,2))/NoCh1cell;

if length(R1_3Ch3only) == 1; %need to code in a fix if there is only 1 positive cell
A={filename,Ch1probe,Ch2probe,Ch3probe,thresholdCh1,thresholdCh2,thresholdCh3, NoCh1cell,NoCh2cell, NoCh3cell,Scale,sum(Ch1Ch2bin),sum(Ch2Ch3bin),sum(Ch1Ch3bin),sum(Ch1Ch2Ch3bin),averageC1inC3,stdC1inC3,averageC1inC3neg,stdC1inC3neg,avgCh1,avgCh2,averageCh3,R1_2(2),R2_3(2),R1_3(2),R1_3Ch3only(1),Width};
else
A={filename,Ch1probe,Ch2probe,Ch3probe,thresholdCh1,thresholdCh2,thresholdCh3, NoCh1cell,NoCh2cell, NoCh3cell,Scale,sum(Ch1Ch2bin),sum(Ch2Ch3bin),sum(Ch1Ch3bin),sum(Ch1Ch2Ch3bin),averageC1inC3,stdC1inC3,averageC1inC3neg,stdC1inC3neg,avgCh1,avgCh2,averageCh3,R1_2(2),R2_3(2),R1_3(2),R1_3Ch3only(2),Width};
end

%Save databin, puncta, punctathreshold matrices for MIJfollowup, to combine
%all images from a given data set

cd(folder)
save(strcat(strtok(images(k).name,'.'),'_Puncta'),'Puncta');
save(strcat(strtok(images(k).name,'.'),'_Punctathresholding'),'Punctathresholding');
save(strcat(strtok(images(k).name,'.'),'_databin'),'databin');

%Save quantification from each folder
if k ==1
    title2 ={'File Name', 'Ch 1', 'Ch 2', 'Ch 3', 'Ch1 Th', 'Ch2 Th', 'Ch3 th', '# of Pos Ch1','# of Pos Ch2','# of Pos Ch3','bin size', '# of Colabled ch1/2', '# of Colabeled Ch2/3', '# of Colabeled Ch1/3', '# of Colabeled Ch1/2/3','Average C1 intensity in C3','std','Ave Ch1','Ave Ch2','Ave Ch3','R1-2','R2-3','R1-3','R1-3 only Ch3 positive cells','Width'}; 
    xlswrite(strcat(folder,'\Quantification.xls'),title2,1,'A1')
end
xlswrite(strcat(folder,'\Quantification.xls'),A,1,outputcell)

pause
%close all imagej windows

MIJ.run('Run...','path=[C:\Fiji.app\macros\closer.ijm]');
close all;

end