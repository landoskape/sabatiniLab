clear
clc
close all

%% Read files from the folder 

% Pick between two options to load data
%%--------1. Pick pathway folder---------------
acqPath = uigetdir; 
cd(acqPath)
%Read all files in the folder
acqList = dir('AD0_*.mat') ;

V = [];
%Concatenate all traces into a matrix (within a session)
for iFile = 1:length(acqList)
    acqName = acqList(iFile).name(1:end-4);
    acqNum(iFile) = str2num(acqList(iFile).name(5:end-4));
    try
        load(acqList(iFile).name)
        acqCurrent = eval(acqName);
        V(iFile,:) = acqCurrent.data;   % matrix V is not sorted based on numerical order (ordered based on acqNum sequence)
    catch err
    end
end
%%
clearvars -except acqCurrent acqList acqName acqNum V % delete intermediate variables
clearvars AD0_*

vClamp = [-60 0 40];
%*********** Change this trace num!!!***************
traceNum = [1:7 ; 8:14 ; 15:21];    % matrix of rows defining the vClamp number and colums defining trace numbers
%*******************************************
for i_vClamp = 1:length(vClamp)
    acqGroup = traceNum(i_vClamp,:);
    acqRange = sort(acqGroup);

biphasic=[];
if exist('acqRange')
    [LIA, LOCB] = ismember(acqRange,acqNum);
    
    plotV = V(LOCB,:);
    
else
    plotV = V;
end
t= linspace(0,10000,length(plotV));    % indicate the total length of a sweep (10s)
dt = t(2)-t(1); % ms / bin
stimT = 5000; % timing of Estim (in ms)
baseV = [];
aligned_plotV = [];
for stimT_i = 1:length(stimT)
    %%Baseline before the Estim
    baseV_i = mean(plotV(:,round((stimT(stimT_i)-105)/dt):round((stimT(stimT_i)-5)/dt)),2); % 100 ms before the stimT
    aligned_plotV = plotV(:,(stimT(stimT_i)-50)/dt:(stimT(stimT_i)+100)/dt)-repmat(baseV_i,1,round(150/dt));
end

%%Average evoked response after the Estim
meanV(i_vClamp,:)=mean(aligned_plotV,1); % from 50ms before until 100 ms after the stimT
seV(i_vClamp,:)=std(aligned_plotV,0,1)/sqrt(size(aligned_plotV,1)); % standard error mean
n_vClamp(i_vClamp) = size(aligned_plotV,1); % number of sweeps per condition
end

%%Plot

subplot(3,1,1)
plot(t((stimT-50)/dt:(stimT+100)/dt),meanV')
legend(sprintf('n = %d',n_vClamp(1)))
xlim([5000-50 5000+100])
ylim([-1500 1000])
hold on
h=fill([t((stimT-50)/dt:(stimT+100)/dt), fliplr(t((stimT-50)/dt:(stimT+100)/dt))],...
    [meanV+seV , fliplr(meanV-seV)],'k','EdgeColor','none','FaceAlpha',0.05);    % Coloring SEM
xlabel('Time (ms)')
ylabel('I (pA)')
title('Cell 5 AMPAR Erev')

subplot(3,1,2)
plot(t((stimT-50)/dt:(stimT+100)/dt),repmat(vClamp',1,1500).*ones(size(meanV)))
xlim([5000-50 5000+100])
ylim([min(vClamp)-10 max(vClamp)+10])
xlabel('Time (ms)')
ylabel('Voltage clamp (mV)')
%% Physiology quality check

RC_t = 9800;
stepVm = 3; % in mV
I1=mean(V(:,(RC_t-100)/dt:(RC_t-5)/dt),2);
I2=min(V(:,(RC_t-3)/dt:(RC_t+3)/dt)')';
dI = I1-I2;
Rs = stepVm./dI.*1000;   % in MOhm

I3=mean(V(:,(RC_t+20)/dt:(RC_t+45)/dt),2);
dI2 = I1-I3;
Ri = stepVm./dI2.*1000; % in MOhm

Rm = Ri-Rs; 
figure;subplot(3,1,1); plot(Rs,'ro');legend('Rs');
subplot(3,1,2);plot(Ri,'bo');legend('Ri');ylabel('Resistance (MOhm)')
subplot(3,1,3); plot(Rm,'ko');legend('Rm');xlabel('Sweeps')
%% I-V curve

% Find peaks, max or min to detect where the current flips its sign.
for i_IV = 1:length(vClamp)
    peak_min = min(meanV(i_IV,550:900));
    peak_max =max(meanV(i_IV,550:900)); 
    if abs(peak_min)>abs(peak_max)
    I_peak(i_IV)=peak_min;
    else
    I_peak(i_IV)=peak_max;
    end
end

% Fit a linear line
p = polyfit(vClamp,I_peak,1);
% Scatter plot: I-V
subplot(3,1,3)
plot(vClamp,I_peak,'o')
hold on
% Plot the fitted line 
plot(vClamp,p(1)*vClamp+p(2),'-.','LineWidth',1,'Color',[136 86 167]/255);
plot(get(gca,'xlim'), [0 0],'k:'); % Adapts to x limits of current axes
plot([0 0] ,get(gca,'ylim'),'k:'); % Adapts to y limits of current axes
xlabel('E(mV)')
ylabel('I (pA)')
diag_prompt = {'Enter the Cell #'};
dlg_title = 'Input: cell number';
defaultans = {'1'};
num_lines = 1;
% Save the Ipeak vs. Vclamp as a .mat file  
answer = inputdlg(diag_prompt,dlg_title,num_lines,defaultans);
Ipeak_filename = sprintf('I_peak_Cell%s',string(char(answer)));
save(Ipeak_filename,'vClamp','I_peak')
%Save the figure
savefig(sprintf('I-V_Cell%s',string(char(answer))));

%% combineCellIV


cd('/Volumes/Neurobio/MICROSCOPE/SeulAh/Ephys');
files = uipickfiles('REFilter','\I_peak_Cell*');

I_peak = [];
for file_i = 1:length(files)
    Cell=load(char(files(file_i)));
    IV(file_i).vClamp = Cell.vClamp;
    IV(file_i).Ipeak = Cell.I_peak;
    I_peak = [I_peak;Cell.I_peak];
    vClamp = Cell.vClamp;
end

x = vClamp;


normI_peak = zeros(length(files),length(vClamp));
for norm_i = 1:length(files)
    ymin = abs(min(I_peak(norm_i,:)));
    normI_peak(norm_i,:) = I_peak(norm_i,:)/ymin;
end

 y = mean(normI_peak,1);
 err = std(normI_peak,1)/sqrt(size(normI_peak,1));
 figure
 %errorbar(x,y,err,'--o')
 plot(vClamp,I_peak','--o')
 hold on
 % Fit a linear line
 p = polyfit(repmat(vClamp,size(I_peak,1),1),I_peak,1);
 plot(vClamp,p(1)*vClamp+p(2),'-','LineWidth',2,'Color',[136 86 167]/255);
 
 hold on
 plot(get(gca,'xlim'), [0 0],'k:'); % Adapts to x limits of current axes
plot([0 0] ,get(gca,'ylim'),'k:'); % Adapts to y limits of current axes
xlabel('E(mV)')
ylabel('normalized I')
title(sprintf('AMPAR I-V curve (%d cells)',length(files)))

%% Compare with Excel data

% Baseline corrected average EPSC/IPSC from 5003 to 5015ms per sweep
cd('/Volumes/Neurobio/MICROSCOPE/SeulAh/Ephys')
Excel = uipickfiles('REFilter','\Cell*');
figure
for excel_i = 1:length(Excel)
filename = char(Excel(excel_i));
A=xlsread(filename);
%cellNum = filename(end-5:end-1);
%For 
rowidx_Excel = [24:26 ; 27:29 ; 30:32];
colidx_Excel = [111, 114 ; 
                116,  118 ; 
                120,  122];
% rowidx_Excel = [24:30 ; 31:37 ; 38:44];
% colidx_Excel = [111, 114 ; 
%                 116,  118 ; 
%                 120,  122];
I_mean=[];
I_mean_err = [];
for i_vClamp = 1:length(vClamp)
    a= [];
    a = A(rowidx_Excel(i_vClamp,:),colidx_Excel(i_vClamp,:)); %subset matrix of A 
    a(isnan(a)) = [];
    I_mean(i_vClamp) = mean(a);
    I_mean_err(i_vClamp) = std(a)/sqrt(length(i_vClamp));

    
    tot_I_mean(excel_i,i_vClamp)=mean(a); %saves all mean values per cell as a row in a cell for vClamp
%     I_mean(i_vClamp) = mean(a); % numSweep x TestVoltage 
%     I_mean_err(i_vClamp) = std(a,1)/sqrt(size(a,1));
end

    subplot(2,1,1)
    errorbar(vClamp,I_mean,I_mean_err,'--o')
    hold on
%tot_I_mean{excel_i} =I_mean; 

%Ipeak_filename = sprintf('I_mean_Cell%s',string(char(answer)));
%save(Ipeak_filename,'vClamp','I_mean')

end
title(sprintf('GABAR I-V curve based on mean value from 3ms to 15ms(%d cells)',length(tot_I_mean)))

%Average across cells and plot
    %normalize per cell
    norm_I_mean = tot_I_mean./ abs(tot_I_mean(:,1));
    y = mean(norm_I_mean,1);
    err = std(norm_I_mean,0,1)/sqrt(length(vClamp));   %std normalizes by n-1 (unbiased), and error mean normalizes by another sqrt(n)
    subplot(2,1,2)
 errorbar(vClamp,y,err,'--o')
 hold on
 plot(get(gca,'xlim'), [0 0],'k:'); % Adapts to x limits of current axes
plot([0 0] ,get(gca,'ylim'),'k:'); % Adapts to y limits of current axes
xlim([min(vClamp) max(vClamp)])
xlabel('E(mV)')
ylabel('normalized I')
title(sprintf('GABAR I-V curve based on mean value from 3ms to 15ms(%d cells)',length(tot_I_mean)))
