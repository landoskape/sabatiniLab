function varargout = dataManagerImaging(varargin)
% DATAMANAGERIMAGING MATLAB code for dataManagerImaging.fig
%      DATAMANAGERIMAGING, by itself, creates a new DATAMANAGERIMAGING or raises the existing
%      singleton*.
%
%      H = DATAMANAGERIMAGING returns the handle to a new DATAMANAGERIMAGING or the handle to
%      the existing singleton*.
%
%      DATAMANAGERIMAGING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DATAMANAGERIMAGING.M with the given input arguments.
%      
%      DATAMANAGERIMAGING('Property','Value',...) creates a new DATAMANAGERIMAGING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before dataManagerImaging_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to dataManagerImaging_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help dataManagerImaging

% Last Modified by GUIDE v2.5 03-Jun-2018 19:06:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @dataManagerImaging_OpeningFcn, ...
                   'gui_OutputFcn',  @dataManagerImaging_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, ~, handles) %#ok
if isfield(handles.plotTifButton.UserData, 'cfig')
    if ishandle(handles.plotTifButton.UserData.cfig)
        delete(handles.plotTifButton.UserData.cfig);
    end
end
if isfield(handles.showInputs.UserData, 'cfig')
    if ishandle(handles.showInputs.UserData.cfig)
        delete(handles.showInputs.UserData.cfig);
    end
end
clearvars('-global',handles.ename.UserData.loadedWaves{:});
delete(hObject);

% --- Executes just before dataManagerImaging is made visible.
function dataManagerImaging_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to dataManagerImaging (see VARARGIN)


handles.ename.UserData.loadedWaves = {};
handles.output = hObject;
guidata(hObject, handles);

if isempty(varargin)
    return
elseif (length(varargin) == 1)
    if ischar(varargin{1}) 
        [pth,file,ext] = fileparts(varargin{1});
        if isempty(pth), pth = cd; end
        if isempty(ext), ext = '.mat'; end
        if ~exist(fullfile(pth,[file,ext]),'file')
            errordlg('Average not found. Select manually...');
            uiwait();
            loadButton_Callback(hObject, eventdata, handles);
            return
        end
        loadAverage(pth,file,hObject,eventdata,handles);
        plotAverageButton_Callback(hObject,eventdata,handles);
        plotTifButton_Callback(hObject, eventdata, handles);
    elseif isnumeric(varargin{1})
        d = dir(sprintf('*e%d*.mat',varargin{1}));
        dname = {d(:).name};
        if sum(cellfun(@(c) contains(c, 'AD0'), dname, 'uni', 1))>1
            errordlg('More than one average exist for the selected epoch. Select manually...');
            uiwait();
            loadButton_Callback(hObject, eventdata, handles);
            return
        end
        fpath = cd;
        file = dname{1};
        loadAverage(fpath, file, hObject, eventdata, handles);
        plotAverageButton_Callback(hObject, eventdata, handles);
        plotTifButton_Callback(hObject, eventdata, handles);
    else
        errordlg('Your input argument is crazy. Select manually');
        uiwait();
        loadButton_Callback(hObject, eventdata, handles);
        return
    end
elseif (length(varargin)==2)
    if ~isnumeric(varargin{1}) || ~isnumeric(varargin{2})
        errordlg('For 2 input arguments (epoch,pulse), they both have to be numeric');
        uiwait();
        loadButton_Callback(hObject, eventdata, handles);
        return
    end
    epoch = varargin{1};
    pulse = varargin{2};
    d = dir(sprintf('*e%dp%d*.mat',epoch,pulse));
    dname = {d(:).name};
    if sum(cellfun(@(c) contains(c, 'AD0'), dname, 'uni', 1))>1
        errordlg('More than one average exist for the selected epoch,pulse. Select manually...');
        uiwait();
        loadButton_Callback(hObject, eventdata, handles);
        return
    end
    fpath = cd;
    file = dname{1};
    loadAverage(fpath, file, hObject, eventdata, handles);
    plotAverageButton_Callback(hObject, eventdata, handles);
    plotTifButton_Callback(hObject, eventdata, handles);
else
    errordlg('Confused about input. Select an average manually...');
    uiwait();
    loadButton_Callback(hObject, eventdata, handles);
    return
end

% --- Outputs from this function are returned to the command line.
function varargout = dataManagerImaging_OutputFcn(hObject, ~, handles) %#ok
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output; 


% --- Executes on selection change in acqList.
function acqList_Callback(hObject, eventdata, handles) %#ok
plotTrialsButton_Callback(hObject, eventdata, handles); 
if isfield(handles.plotTifButton.UserData, 'cfig')
    if ishandle(handles.plotTifButton.UserData.cfig)
        plotTifButton_Callback(hObject, eventdata, handles);
    end
end

% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles) 
if isfield(handles.ename.UserData,'wpath')
    pth = handles.ename.UserData.wpath;
else
    pth = cd;
end
[file,fpath] = uigetfile(fullfile(pth,'*.mat')); % Have user select a file
cd(fpath); % Go to the path

loadAverage(fpath,file,hObject,eventdata,handles);
plotAverageButton_Callback(hObject,eventdata,handles);
plotTifButton_Callback(hObject, eventdata, handles);


% --- Executes on button press in plotAverageButton.
function plotAverageButton_Callback(hObject, ~, handles)
chnNum = handles.channelSelector.Value;
roiNum = handles.roiSelector.Value;
phIdx = handles.ename.UserData.waveID(:,1);
imIdx = (handles.ename.UserData.waveID(:,2) == chnNum) & (handles.ename.UserData.waveID(:,3) == roiNum);
phName = handles.ename.UserData.waveNames{phIdx};
imName = handles.ename.UserData.waveNames{imIdx};

phTime = handles.ename.UserData.waves.(phName).xscale(1):...
         handles.ename.UserData.waves.(phName).xscale(2):...
         length(handles.ename.UserData.waves.(phName).data)*handles.ename.UserData.waves.(phName).xscale(2)-...
         handles.ename.UserData.waves.(phName).xscale(2);
imTime = handles.ename.UserData.waves.(imName).xscale(1):...
         handles.ename.UserData.waves.(imName).xscale(2):...
         length(handles.ename.UserData.waves.(imName).data)*handles.ename.UserData.waves.(imName).xscale(2)-...
         handles.ename.UserData.waves.(imName).xscale(2);

% Plotting
hs = makeState(handles.ename.UserData.waves.(phName).UserData.headerString);
axes(handles.axes1);
cla;
plot(phTime,handles.ename.UserData.waves.(phName).data,'color','k','linewidth',2);
xlabel('Time (ms)');
if hs.phys.settings.currentClamp0
    ylabel('mV');
else
    ylabel('pA');
end
title('Physiology Average');
set(gca,'fontsize',14);

axes(handles.axes2);
cla;
plot(imTime,handles.ename.UserData.waves.(imName).data,'color','k','linewidth',2);
xlabel('Time (ms)');
ylabel('Fluorescence');
title(sprintf('Fluor Average: Channel %d, ROI %d',handles.channelSelector.Value, handles.roiSelector.Value));
set(gca,'fontsize',14);

handles.plotAverageButton.UserData.Value = 1;
handles.plotTrialsButton.UserData.Value = 0;
handles.plotAcquisition.UserData.Value = 0;
guidata(hObject,handles);


% --- Executes on button press in plotTrialsButton
function plotTrialsButton_Callback(hObject, ~, handles)
if ~isfield(handles.plotTrialsButton.UserData,'showTrialFlag')
    handles.plotTrialsButton.UserData.showTrialFlag = 1;
end
if ~isfield(handles.plotTrialsButton.UserData,'more10')
    handles.plotTrialsButton.UserData.more10 = [];
end
chnNum = handles.channelSelector.Value;
roiNum = handles.roiSelector.Value;
phIdx = handles.ename.UserData.waveID(:,1);
imIdx = (handles.ename.UserData.waveID(:,2) == chnNum) & (handles.ename.UserData.waveID(:,3) == roiNum);
phName = handles.ename.UserData.waveNames{phIdx};
imName = handles.ename.UserData.waveNames{imIdx};

phTime = handles.ename.UserData.waves.(phName).xscale(1):...
         handles.ename.UserData.waves.(phName).xscale(2):...
         length(handles.ename.UserData.waves.(phName).data)*handles.ename.UserData.waves.(phName).xscale(2)-...
         handles.ename.UserData.waves.(phName).xscale(2);
imTime = handles.ename.UserData.waves.(imName).xscale(1):...
         handles.ename.UserData.waves.(imName).xscale(2):...
         length(handles.ename.UserData.waves.(imName).data)*handles.ename.UserData.waves.(imName).xscale(2)-...
         handles.ename.UserData.waves.(imName).xscale(2);

% plot components phys
clist = eval(['avgComponentList(''',phName,''')']);
cAcqNums = cellfun(@(c) str2double(c(strfind(c,'_')+1:end)), clist, 'uni', 1);
NC = length(clist);
axes(handles.axes1);
cla;
hold on;
if NC>10
    plot(phTime,handles.ename.UserData.waves.(phName).data,'color','k','linewidth',2);
    if ~ishandle(handles.plotTrialsButton.UserData.more10)
        handles.plotTrialsButton.UserData.more10 = msgbox('more than 10 trials in average, plotting average and selected trial only.');
    else
    end
    axes(handles.axes1);
else
    for c = 1:NC
        load(clist{c});
        if contains(clist{c},'.mat')
            handles.ename.UserData.loadedWaves{end+1} = clist{c}(1:strfind(clist{c},'.mat')-1);
        else
            handles.ename.UserData.loadedWaves{end+1} = clist{c};
        end
        col = 'k'; 
        lwid = '0.5';
        if handles.plotTrialsButton.UserData.showTrialFlag
            if (cAcqNums(c) == handles.acqList.UserData.acqs(handles.acqList.Value))
                continue
            end
        end
        eval(['plot(phTime,',clist{c},'.data,''color'',''',col,''',''linewidth'',',lwid,')']);
    end
end
if handles.plotTrialsButton.UserData.showTrialFlag
    col = 'r'; lwid = '2';
    idx = (cAcqNums == handles.acqList.UserData.acqs(handles.acqList.Value));
    load(clist{idx});
    if contains(clist{idx},'.mat')
        handles.ename.UserData.loadedWaves{end+1} = clist{idx}(1:strfind(clist{idx},'.mat')-1);
    else
        handles.ename.UserData.loadedWaves{end+1} = clist{idx};
    end
    eval(['plot(phTime,',clist{idx},'.data,''color'',''',col,''',''linewidth'',',lwid,')']);
end
xlabel('Time (ms)');
hs = makeState(handles.ename.UserData.waves.(phName).UserData.headerString);
if hs.phys.settings.currentClamp0
    ylabel('mV');
else
    ylabel('pA');
end
title('Physiology Trials');
set(gca,'fontsize',14);

% plot components imag
clist = eval(['avgComponentList(''',imName,''')']);
cAcqNums = cellfun(@(c) str2double(c(strfind(c,'_')+1:end)), clist, 'uni', 1);
NC = length(clist);
axes(handles.axes2);
cla;
hold on;
if NC>10
    plot(imTime,handles.ename.UserData.waves.(imName).data,'color','k','linewidth',2);
else
    for c = 1:NC
        load(clist{c});
        if contains(clist{c},'.mat')
            handles.ename.UserData.loadedWaves{end+1} = clist{c}(1:strfind(clist{c},'.mat')-1);
        else
            handles.ename.UserData.loadedWaves{end+1} = clist{c};
        end
        xscale = getfield(eval(clist{c}),'xscale');
        imTime = xscale(1):xscale(2):length(eval(clist{c}))*xscale(2)-xscale(2); %#ok yes it is
        col = 'k'; 
        lwid = '0.5';
        if handles.plotTrialsButton.UserData.showTrialFlag
            if (cAcqNums(c) == handles.acqList.UserData.acqs(handles.acqList.Value))
                continue
            end
        end
        try
            eval(['plot(imTime,',clist{c},'.data,''color'',''',col,''',''linewidth'',',lwid,')']);
        catch
            disp('here')
        end
    end
end
if handles.plotTrialsButton.UserData.showTrialFlag
    col = 'r'; lwid = '2';
    idx = (cAcqNums == handles.acqList.UserData.acqs(handles.acqList.Value));
    load(clist{idx});
    if contains(clist{idx},'.mat')
        handles.ename.UserData.loadedWaves{end+1} = clist{idx}(1:strfind(clist{idx},'.mat')-1);
    else
        handles.ename.UserData.loadedWaves{end+1} = clist{idx};
    end
    xscale = getfield(eval(clist{idx}),'xscale'); 
    imTime = xscale(1):xscale(2):length(eval(clist{idx}))*xscale(2)-xscale(2); %#ok yes it is
    eval(['plot(imTime,',clist{idx},'.data,''color'',''',col,''',''linewidth'',',lwid,')']);
end
xlabel('Time (ms)');
ylabel('Fluorescence');
title(sprintf('Fluor Trials: Channel %d, ROI %d',handles.channelSelector.Value, handles.roiSelector.Value));
set(gca,'fontsize',14);

handles.plotAverageButton.UserData.Value = 0;
handles.plotTrialsButton.UserData.Value = 1;
handles.plotAcquisition.UserData.Value = 0;
guidata(hObject,handles);


% --- Executes on button press in showInputs.
function showInputs_Callback(~, ~, handles) %#ok
handles.plotTrialsButton.UserData.showTrialFlag = 1;
inIdx = handles.ename.UserData.waveID(:,1);
inName = handles.ename.UserData.waveNames{inIdx};

inTime = handles.ename.UserData.waves.(inName).xscale(1):...
         handles.ename.UserData.waves.(inName).xscale(2):...
         length(handles.ename.UserData.waves.(inName).data)*handles.ename.UserData.waves.(inName).xscale(2)-...
         handles.ename.UserData.waves.(inName).xscale(2);  %#ok - used in eval

if isfield(handles.showInputs.UserData,'cfig')
    if ishandle(handles.showInputs.UserData.cfig)
        figure(handles.showInputs.UserData.cfig);
    else
        handles.showInputs.UserData.cfig = figure; 
        set(gcf,'units','normalized','outerposition',[0.6539 0.4200 0.3398 0.5138]);
    end
else
    handles.showInputs.UserData.cfig = figure;
    set(gcf,'units','normalized','outerposition',[0.6539 0.4200 0.3398 0.5138]);
end

% plot components phys
idx = strfind(inName, 'AD0');
inName(idx+2) = '1'; % rename to AD1
loadWaveo(inName);
if ~any(strcmp(handles.ename.UserData.loadedWaves,inName))
    if contains(strfind(inName,'.mat'))
        handles.ename.UserData.loadedWaves{end+1} = inName(1:strfind(inName,'.')-1);
    else
        handles.ename.UserData.loadedWaves{end+1} = inName;
    end
end
clist = eval(['avgComponentList(''',inName,''')']);
NC = length(clist);

% Set gain
hs = evalin('base',['makeState(',inName,'.UserData.headerString);']);
gain = [20 400]; % [currentClamp voltageClamp] 
gain = gain(hs.phys.settings.currentClamp0 + 1);

clf;
hold on;
checkClamp = zeros(NC,1);
clampMode = zeros(NC,1);
for c = 1:NC
    load(clist{c});
    if contains(clist{c},'.mat')
        handles.ename.UserData.loadedWaves{end+1} = clist{c}(1:strfind(clist{c},'.mat')-1);
    else
        handles.ename.UserData.loadedWaves{end+1} = clist{c};
    end
    cstate = eval(['makeState(',clist{c},'.UserData.headerString);']);
    clampMode(c,1) = cstate.phys.settings.currentClamp0;
    if ~isequal(cstate.phys.settings.currentClamp0,hs.phys.settings.currentClamp0)
        checkClamp(c) = 1;
    end
    col = 'k'; 
    lwid = '0.5';
    if handles.plotTrialsButton.UserData.showTrialFlag
        if (c == handles.acqList.Value)
            continue
        end
    end
    eval(['plot(inTime,',clist{c},'.data * ',num2str(gain),',''color'',''',col,''',''linewidth'',',lwid,')']);
end
if handles.plotTrialsButton.UserData.showTrialFlag
    col = 'r'; lwid = '2';
    eval(['plot(inTime,',clist{handles.acqList.Value},'.data * ',num2str(gain),',''color'',''',col,''',''linewidth'',',lwid,')']);
end
xlabel('Time (ms)');
if hs.phys.settings.currentClamp0
    ylabel('pA');
else
    ylabel('mV');
end
title('Physiology Input');
set(gca,'fontsize',14);

if any(checkClamp)
    errordlg('Some inputs are in different clamp mode. See workspace.');
    fprintf('Average Mode: %d\n', hs.phys.settings.currentClamp0);
    for c = 1:NC
        fprintf('Acq %d Mode: %d\n',clist{c}(strfind(clist{c},'_')+1:end),clampMode(c));
    end
end
axes(handles.axes1);


% --- Executes on selection change in channelSelector.
function channelSelector_Callback(hObject, eventdata, handles) %#ok
if handles.plotTrialsButton.UserData.Value
    plotTrialsButton_Callback(hObject, eventdata, handles);
elseif handles.plotAcquisition.UserData.Value
    plotAcquisition_Callback(hObject, eventdata, handles);
else
    plotAverageButton_Callback(hObject, eventdata, handles);
end


% --- Executes on selection change in roiSelector.
function roiSelector_Callback(hObject, eventdata, handles) %#ok
if handles.plotTrialsButton.UserData.Value
    plotTrialsButton_Callback(hObject, eventdata, handles);
elseif handles.plotAcquisition.UserData.Value
    plotAcquisition_Callback(hObject, eventdata, handles);
else
    plotAverageButton_Callback(hObject, eventdata, handles);
end


% --- Executes on button press in avgOutButton.
function avgOutButton_Callback(hObject, eventdata, handles) %#ok
outNum = handles.acqList.UserData.acqs(handles.acqList.Value);
for wf = 1:length(handles.ename.UserData.waveNames)
    evalin('base', ...
        ['idxOut = cellfun(@(c) contains(c,[''_'',''',num2str(outNum),''']),'...
        handles.ename.UserData.waveNames{wf},'.UserData.Components, ''uni'', 1);']);
    evalin('base', ['fName = ',handles.ename.UserData.waveNames{wf},'.UserData.Components{idxOut};']);
    evalin('base', 'load(fName{1});');
    evalin('base', ['avgout(fName{1},''',handles.ename.UserData.waveNames{wf},''');']);
    evalin('base', ['cd(''',handles.ename.UserData.wpath,''')']);
    evalin('base', ['save(''',handles.ename.UserData.waveNames{wf},...
        ''',''',handles.ename.UserData.waveNames{wf},''');']);
    if contains(fName{1},'.mat')%#ok
        handles.ename.UserData.loadedWaves{end+1} = fName{1}(1:strfind(fName{1},'.mat')-1);
    else
        handles.ename.UserData.loadedWaves{end+1} = fName{1};
    end
end
handles.acqList.Value = 1;
handles.channelSelector.UserData.lastChannel = handles.channelSelector.Value;
handles.roiSelector.UserData.lastROI = handles.roiSelector.Value;
loadAverage(handles.ename.UserData.wpath,handles.ename.UserData.waveNames{1},hObject,eventdata,handles);
plotTrialsButton_Callback(hObject,eventdata,handles);
plotTifButton_Callback(hObject, eventdata, handles);
guidata(hObject,handles);


% --- Executes on button press in avgInButton.
function avgInButton_Callback(hObject, eventdata, handles) %#ok

for wf = 1:length(handles.ename.UserData.waveNames)
    if handles.ename.UserData.waveID(wf,1)
        id = handles.ename.UserData.waveNames{wf}(1:3);
    else
        idx = strfind(handles.ename.UserData.waveNames{wf},'_');
        id = handles.ename.UserData.waveNames{wf}(idx-4:idx-1);
    end
    name = sprintf('%s_%s',id,handles.acqNumEditor.String(2:end));
    evalin('base', ['avgin(''',name,''',''',handles.ename.UserData.waveNames{wf},''');']);
    evalin('base', ['cd(''',handles.ename.UserData.wpath,''')']);
    evalin('base', ['save(''',handles.ename.UserData.waveNames{wf},''',''',handles.ename.UserData.waveNames{wf},''');']);
end
loadAverage(handles.ename.UserData.wpath,handles.ename.UserData.waveNames{1},hObject,eventdata,handles);
if find(handles.acqList.UserData.acqs == handles.acqNumEditor.UserData.lastAcq) <= length(handles.acqList.String)
    handles.acqList.Value = find(handles.acqList.UserData.acqs == handles.acqNumEditor.UserData.lastAcq);
else
    handles.acqList.Value = 1;
end
plotTrialsButton_Callback(hObject,eventdata,handles);
plotTifButton_Callback(hObject, eventdata, handles);
guidata(hObject,handles);


% --- Executes on button press in findAcq button.
function findAcqButton_Callback(hObject, eventdata, handles) %#ok
[file,fpath] = uigetfile(fullfile(handles.ename.UserData.wpath,'*.mat')); % Select an acquisition
if ~strcmp(fpath(1:end-1),handles.ename.UserData.wpath)
    errordlg('Selected acquistion is from a different folder than the average. Not allowed.');
    return
end
acqNum = file(strfind(file,'_')+1:strfind(file,'.')-1);
handles.acqNumEditor.String = sprintf('A%s',acqNum);
handles.acqNumEditor.UserData.lastAcq = str2double(acqNum);
loadAcq(hObject,eventdata,handles);
plotAcquisition_Callback(hObject,eventdata,handles);
plotTifButton_Callback(hObject, eventdata, handles, acqNum);
guidata(hObject,handles);


function acqNumEditor_Callback(hObject, eventdata, handles) %#ok
acqNum = handles.acqNumEditor.String;
if strcmp(acqNum,'A') && ~isnan(str2double(acqNum(2:end)))
    acqNum = str2double(acqNum(2:end));
elseif ~isnan(str2double(acqNum))
    acqNum = str2double(acqNum);
else
    handles.acqNumEditor.String = 'invalid';
    return
end
handles.acqNumEditor.String = sprintf('A%d',acqNum);
handles.acqNumEditor.UserData.lastAcq = acqNum;
loadAcq(hObject,eventdata,handles);
guidata(hObject,handles);


% --- Executes on button press in plotAcquisition.
function plotAcquisition_Callback(hObject, eventdata, handles)
handles.plotTrialsButton.UserData.showTrialFlag = 0;
plotTrialsButton_Callback(hObject,eventdata,handles)
handles.plotTrialsButton.UserData.showTrialFlag = 1; % Put back to default

chnNum = handles.channelSelector.Value;
roiNum = handles.roiSelector.Value;
phIdx = handles.acqNumEditor.UserData.aID(:,1);
imIdx = (handles.acqNumEditor.UserData.aID(:,2) == chnNum) & ...
        (handles.acqNumEditor.UserData.aID(:,3) == roiNum);
phName = handles.acqNumEditor.UserData.aNames{phIdx};
imName = handles.acqNumEditor.UserData.aNames{imIdx};

phTime = handles.acqNumEditor.UserData.acqs.(phName).xscale(1):...
         handles.acqNumEditor.UserData.acqs.(phName).xscale(2):...
         length(handles.acqNumEditor.UserData.acqs.(phName).data)*...
         handles.acqNumEditor.UserData.acqs.(phName).xscale(2)-...
         handles.acqNumEditor.UserData.acqs.(phName).xscale(2);
imTime = handles.acqNumEditor.UserData.acqs.(imName).xscale(1):...
         handles.acqNumEditor.UserData.acqs.(imName).xscale(2):...
         length(handles.acqNumEditor.UserData.acqs.(imName).data)*...
         handles.acqNumEditor.UserData.acqs.(imName).xscale(2)-...
         handles.acqNumEditor.UserData.acqs.(imName).xscale(2);

% Plotting
hs = makeState(handles.acqNumEditor.UserData.acqs.(phName).UserData.headerString);
axes(handles.axes1);
hold on;
plot(phTime,handles.acqNumEditor.UserData.acqs.(phName).data,'color','b','linewidth',2);
xlabel('Time (ms)');
if hs.phys.settings.currentClamp0
    ylabel('mV');
else
    ylabel('pA');
end
title('Physiology Acquisition');
set(gca,'fontsize',14);

axes(handles.axes2);
hold on;
plot(imTime,handles.acqNumEditor.UserData.acqs.(imName).data,'color','b','linewidth',2);
xlabel('Time (ms)');
ylabel('Fluorescence');
title(sprintf('Fluor Acquisition: Channel %d, ROI %d',handles.channelSelector.Value, handles.roiSelector.Value));
set(gca,'fontsize',14);

handles.plotAverageButton.UserData.Value = 0;
handles.plotTrialsButton.UserData.Value = 0;
handles.plotAcquisition.UserData.Value = 1;
guidata(hObject,handles);


% --- Executes on button press in plotTifButton.
function plotTifButton_Callback(hObject, eventdata, handles, acq)
if (nargin == 4)
    acqNum = acq;
else
    acqNum = handles.acqList.UserData.acqs(handles.acqList.Value);
end
tnum = acqNum - 2 + handles.tifType.Value;
tname = dir(fullfile(handles.ename.UserData.wpath,sprintf('*%s.tif',zeroPadNum2Str(tnum))));
if length(tname) > 1
    msgbox(sprintf('Multiple tif files exist for acquisition %d. Select manually...',tnum),'get tif','warn');
    uiwait();
    tname = uigetfile(fullfile(handles.ename.UserData.wpath,'*.tif'));
elseif isempty(tname)
    msgbox('Tif file does not exist. Select manually...','get tif','warn');
    uiwait();
    tname = uigetfile(fullfile(handles.ename.UserData.wpath,'*.tif'));
else
    tname = tname.name;
end
state = loadCell(handles.ename.UserData.wpath,'state');
tif = tifread(fullfile(handles.ename.UserData.wpath,tname));
NOC = size(tif,3)/state(tnum).acq.numberOfFrames; 
tif = tif(:,:,handles.tifChanMenu.Value:NOC:end);
tif = reshape(permute(tif,[2 1 3]),size(tif,2),size(tif,1)*size(tif,3),1)';

% Get ROIs
roiIsPS = isfield(state(acqNum),'pointScan') && state(acqNum).pointScan.pointScanActive;
if roiIsPS
    % ROIs defined as points located in state.blaster
    linkedPosition = state(acqNum).pointScan.blasterPosition;
    nROI = state(acqNum).pointScan.numberOfValidPoints;
    rois = [state(acqNum).blaster.indexXList(linkedPosition), state(acqNum).blaster.indexYList(linkedPosition)]; 
else
    % ROIs are from line scans
    nROI = max(handles.ename.UserData.waveID(:,3));
    rois = zeros(nROI,2);
    for r = 1:nROI
        % First logical is default to green - is this because we just need one?
        idxRoi = (handles.ename.UserData.waveID(:,2) == 1) & (handles.ename.UserData.waveID(:,3) == r);
        idxAcq = cellfun(@(c) contains(c, sprintf('_%d',acqNum)), ...
            handles.ename.UserData.waves.(handles.ename.UserData.waveNames{idxRoi}).UserData.Components,'uni',1);
        acqName = handles.ename.UserData.waves...
            .(handles.ename.UserData.waveNames{idxRoi}).UserData.Components{idxAcq};
        load(fullfile(handles.ename.UserData.wpath,acqName{1}));
        rois(r,:) = eval([acqName{1},'.UserData.ROIDef']);
    end
end

if isfield(handles.plotTifButton.UserData,'cfig')
    if ishandle(handles.plotTifButton.UserData.cfig)
        figure(handles.plotTifButton.UserData.cfig);
    else
        handles.plotTifButton.UserData.cfig = figure; 
    end
else
    handles.plotTifButton.UserData.cfig = figure;
    set(gcf,'units','normalized','outerposition',[0.6539 0.4200 0.3398 0.5138]);
end
imagesc(tif);
colormap('gray');

% Plot ROIs
cMap = 'brkgmcykkkkkkkkkk';
if roiIsPS
    roiRadius = 0.5;
    ppm=10;  %approximate for 256x256, 20x zoom....
    NOP=100;
    radius=roiRadius*ppm; %ppm=pixels per micron
    THETA=linspace(0,2*pi,NOP);                  
    RHO=ones(1,NOP)*radius;
    for r = 1:nROI
        [X,Y] = pol2cart(THETA,RHO);
        X=X+rois(r,1);
        Y=Y+rois(r,2);
        line(X, Y, 'color',cMap(r),'linewidth',1.5);
    end
else
    for r = 1:nROI
        line([rois(r,1) rois(r,2)],[size(tif,1)/2 size(tif,1)/2],'linewidth',2,'color',cMap(r));
    end
end

%{
SHIT WHERE DO I FIND WHICH BLASTER POSITION WAS ACTIVE

NOWHERE FUCK FUCKITY FUCK
%}

if handles.tifType.Value == 1
    if state(acqNum).blaster.active
        idxUncagingSpot = 1;
        %fprintf(1,'NOTE: assuming that uncaging spot is blaster position 1\n');
        
        cBlast = 'cyan';

        blastRadius = 0.5;
        ppm=10;  %approximate for 256x256, 20x zoom....

        NOP=100;
        radius=blastRadius*ppm; %ppm=pixels per micron
        THETA=linspace(0,2*pi,NOP);                  
        RHO=ones(1,NOP)*radius;
        [X,Y] = pol2cart(THETA,RHO);
        X=X+state(acqNum).blaster.indexXList(idxUncagingSpot);
        Y=Y+state(acqNum).blaster.indexYList(idxUncagingSpot);
        line(X, Y, 'color',cBlast);
    end
end
handles.plotTrialsButton.UserData.showTrialFlag = 1; % Make sure this is on
plotTrialsButton_Callback(hObject, eventdata, handles); % Show the trials


% --- Executes on selection change in tifChanMenu.
function tifChanMenu_Callback(hObject, eventdata, handles) %#ok
plotTifButton_Callback(hObject,eventdata,handles);


% --- Executes on selection change in tifType.
function tifType_Callback(hObject, eventdata, handles) %#ok
plotTifButton_Callback(hObject,eventdata,handles);


% --- Executes on button press in updateROI.
function updateROI_Callback(hObject, eventdata, handles) %#ok
if ~isfield(handles.plotTifButton.UserData,'cfig')
    errordlg('no tif displayed. plot tif.');
    return
end
if ~ishandle(handles.plotTifButton.UserData.cfig)
    errordlg('tif figure closed. reopen.');
    return
end

h = msgbox(sprintf('updating ROI %d, press any key to abort',handles.roiSelector.Value));

figure(handles.plotTifButton.UserData.cfig);
k = waitforbuttonpress;

if (k == 1)
    msgbox('aborted');
    axes(handles.axes1);
    close(h);
    return
end

point1 = get(gca,'CurrentPoint');    % button down detected
finalRect = rbbox;                   %#ok return figure units

point2 = get(gca,'CurrentPoint');    % button up detected
newROI = [round(point1(1)) round(point2(2))];
if newROI(2) < newROI(1)
    newROI = fliplr(newROI);
end

%GOAL:
%open acquisition and linescan
roiNum = handles.roiSelector.Value;
acqNum = handles.acqList.UserData.acqs(handles.acqList.Value);

% Load Tif
tname = dir(fullfile(handles.ename.UserData.wpath,sprintf('*%s.tif',zeroPadNum2Str(acqNum))));
tname = tname.name;
tif = tifread(fullfile(handles.ename.UserData.wpath,tname));

% Need this to extract correct data
state = getXFile(handles.ename.UserData.wpath,'state');
pmtOffsets = [state(acqNum).acq.pmtOffsetChannel1 state(acqNum).acq.pmtOffsetChannel2];
pmtOffsets = pmtOffsets * state(acqNum).acq.binFactor;

% Get tif and subtract pmt offsets from appropriate channel
NOC = size(tif,3)/state(acqNum).acq.numberOfFrames; 
green = tif(:,:,1:NOC:end) - pmtOffsets(1); % Green 
red = tif(:,:,2:NOC:end) - pmtOffsets(2); % Red

% Reshape to handle multiple frames
green = reshape(permute(green,[2 1 3]),size(green,2),size(green,1)*size(green,3),1)';
red = reshape(permute(red,[2 1 3]),size(red,2),size(red,1)*size(red,3),1)';
tif = cat(3, green, red);

idxROI = find(handles.ename.UserData.waveID(:,3) == roiNum);
for c = 1:length(idxROI)
    idxAcq = cellfun(@(c) contains(c, sprintf('_%d',acqNum)), ...
            handles.ename.UserData.waves.(...
            handles.ename.UserData.waveNames{idxROI(c)}).UserData.Components,'uni',1);
    acqName = handles.ename.UserData.waves.(...
            handles.ename.UserData.waveNames{idxROI(c)}).UserData.Components{idxAcq};
    loadWaveo(fullfile(handles.ename.UserData.wpath,acqName{1}));
    if ~any(strcmp(handles.ename.UserData.loadedWaves,acqName{1}))
        if contains(acqName{1},'.mat')
            handles.ename.UserData.loadedWaves{end+1} = acqName{1}(1:strfind(acqName{1},'.mat')-1);
        else
            handles.ename.UserData.loadedWaves{end+1} = acqName{1};
        end
    end
    
    chNum = str2double(acqName{1}(strfind(acqName{1},'c')+1:strfind(acqName{1},'r')-1));
    ctif = tif(:,:,chNum);
    btif = tif(:,:,2);
    base = mean(mean(btif(5:49, newROI(1):newROI(2)),2),1);
    
    evalin('base', ['avgout(',acqName{1},',''',handles.ename.UserData.waveNames{idxROI(c)},''');']);
    eval(['global ',acqName{1}]);
    cdata = mean(ctif(:,newROI(1):newROI(2)),2)'/base;
    setWave(acqName{1}, 'data', cdata);
    eval([acqName{1},'.UserData.ROIDef = [',num2str(newROI(1)),' ',num2str(newROI(2)),'];']);
    save(fullfile(handles.ename.UserData.wpath,acqName{1}),acqName{1});
    evalin('base', ['avgin(''',acqName{1},''',''',handles.ename.UserData.waveNames{idxROI(c)},''');']);
    evalin('base', ['cd(''',handles.ename.UserData.wpath,''')']);
    evalin('base', ['save(''',handles.ename.UserData.waveNames{idxROI(c)},...
        ''',''',handles.ename.UserData.waveNames{idxROI(c)},''')']);
end
handles.channelSelector.UserData.lastChannel = handles.channelSelector.Value;
handles.roiSelector.UserData.lastROI = handles.roiSelector.Value;
loadAverage(handles.ename.UserData.wpath, handles.ename.UserData.waveNames{1}, hObject, eventdata, handles);
plotTrialsButton_Callback(hObject, eventdata, handles); % Show the trials
plotTifButton_Callback(hObject,eventdata,handles);
close(h);

% -------------------- USEFUL FUNCTIONS --------------------
function loadAverage(fpath,file,hObject,~,handles)

loadWaveo(fullfile(fpath,file)); % Load the wave
if ~any(strcmp(handles.ename.UserData.loadedWaves,file))
    if contains(file,'.mat')
        handles.ename.UserData.loadedWaves{end+1} = file(1:strfind(file,'.mat')-1);
    else
        handles.ename.UserData.loadedWaves{end+1} = file;
    end
end

% Find other waves in average
[wFiles,waveID] = findWavesInAverage(file,fpath);
handles.ename.UserData.waveNames = wFiles;
handles.ename.UserData.waveID = waveID;
handles.ename.UserData.wpath = fpath;
for wf=1:length(wFiles)
    % Load wave data to ename
    handles.ename.UserData.waves.(wFiles{wf}) = loadWaveo(wFiles{wf});
    if ~any(strcmp(handles.ename.UserData.loadedWaves,wFiles{wf}))
        if contains(wFiles{wf},'.mat')
            handles.ename.UserData.loadedWaves{end+1} = wFiles{wf}(1:strfind(wFiles{wf},'.mat')-1);
        else
            handles.ename.UserData.loadedWaves{end+1} = wFiles{wf};
        end
    end
end

% Make list of averages
[list,flag] = makeAvgList(wFiles);
if flag
    % The average loaded is broken... 
    % Make a nested function to handle this.
    return
end

% Set variables
handles.acqList.UserData.acqs = list{1};
handles.acqList.UserData.type = list{2};
handles.acqList.String = cellfun(@(a) ['A',num2str(a),':  ',list{2}], num2cell(list{1}),'uni',0);

handles.acqNumEditor.String = 'ACQ';

% Average Name
if strcmp(file(1),'e')
    avgName = file(1:strfind(file,'c')-1);
else
    avgName = file(strfind(file,'e'):strfind(file,'avg')-1);
end
handles.ename.String = avgName;

handles.channelSelector.String = cell(length(list{3}),1);
for c = 1:length(list{3})
    handles.channelSelector.String{c,1} = ['Channel: ',num2str(list{3}(c))];
end
handles.roiSelector.String = cell(length(list{4}),1);
for r = 1:length(list{4})
    handles.roiSelector.String{r,1} = ['ROI: ',num2str(list{4}(r))];
end
if isfield(handles.channelSelector.UserData, 'lastChannel')
    handles.channelSelector.Value = handles.channelSelector.UserData.lastChannel;
else
    handles.channelSelector.Value = 1;
end
if isfield(handles.roiSelector.UserData, 'lastROI')
    handles.roiSelector.Value = handles.roiSelector.UserData.lastROI;
else
    handles.roiSelector.Value = length(handles.roiSelector.String);
end

guidata(hObject, handles);
% ---------------------------------------------- END loadAverage ----------


function [wFiles,waveID] = findWavesInAverage(file,fpath)
[~,~,ext] = fileparts(file);
if isempty(ext)
    file = [file,'.mat'];
end
if contains(file,'_e')
    idx = [strfind(file,'_e') strfind(file,'.')];
    id = file(idx(1)+1:idx(2)-4);
elseif strcmp(file(1),'e')
    idx = strfind(file,'c');
    id = file(1:idx-1);
end
% Directory
d = dir(fullfile(fpath,['*',id,'*.mat']));
wFiles = {d(:).name};
idxInput = cellfun(@(c) contains(c,'AD1'),wFiles, 'uni', 1);
fprintf(1,'NOTE: hard coding out AD1 because only used for input.\n');
wFiles = wFiles(~idxInput);
wFiles = cellfun(@(c) c(1:strfind(c,'.')-1), wFiles,'uni',0);
idxPhys = cellfun(@(c) contains(c,'AD0'),wFiles,'uni',1);
imagChs = cellfun(@(c) str2double(c(strfind(c,'c')+1:strfind(c,'r')-1)), wFiles,'uni', 1);
imagRoi = cellfun(@(c) str2double(c(strfind(c,'r')+1:strfind(c,'_')-1)), wFiles,'uni', 1);
waveID = cat(2, idxPhys(:), imagChs(:), imagRoi(:));
% --------------------------------------- END findWavesInAverage ----------
    

function [wFiles,waveID] = findWavesInAcquisition(acqNum,fpath)
d = dir(fullfile(fpath,sprintf('*_%s.mat',acqNum)));
wFiles = {d(:).name};
idxInput = cellfun(@(c) contains(c,'AD1'),wFiles, 'uni', 1);
fprintf(1,'NOTE: hard coding out acquisition AD1 because only used for input.\n');
wFiles = wFiles(~idxInput);
wFiles = cellfun(@(c) c(1:strfind(c,'.')-1), wFiles,'uni',0);
idxPhys = cellfun(@(c) contains(c,'AD0'),wFiles,'uni',1);
imagChs = cellfun(@(c) str2double(c(strfind(c,'c')+1:strfind(c,'r')-1)), wFiles,'uni', 1);
imagRoi = cellfun(@(c) str2double(c(strfind(c,'r')+1:strfind(c,'_')-1)), wFiles,'uni', 1);
waveID = cat(2, idxPhys(:), imagChs(:), imagRoi(:));
% --------------------------------------- END findWavesInAcquisition ------

function [list,flag] = makeAvgList(wFiles)
flag = 0;
acqs = cell(length(wFiles),1); % lists of acquisition numbers in each
for wf = 1:length(wFiles)
    comp = avgComponentList(wFiles{wf});
    ncomp = avgNComponents(wFiles{wf});
    acqs{wf} = nan(ncomp,1);
    for a = 1:ncomp
        idx = strfind(comp{a},'_');
        acqs{wf}(a) = str2double(comp{a}(idx+1:end));
    end
    acqs{wf} = sort(acqs{wf});
end
if length(acqs)>1
    if ~isequal(acqs{:})
        errordlg('Aquistions in averages are not the same. Check results in workspace.');
        for wf = 1:length(wFiles)
            fprintf('Average: %s -- ',wFiles{wf});
            for a = 1:length(acqs{wf})
                fprintf('A%d, ',acqs{wf}(a));
            end
            fprintf('\n');
        end
        % If acquisitions not same, throw a flag and go back. I'll make another
        % nested function to reset the gui for a "bad" set of averages. 
        list = [];
        flag = 1;
        return
    end
end
% Make the list
list = cell(1,3); % {AcqList, AcqType, Channels, ROIs}
list{1} = acqs{1};
chns = [];
rois = [];
for wf = 1:length(wFiles)
    if strcmp(wFiles{wf}(1),'A')
        idx = strfind(wFiles{wf},'_');
        id = wFiles{wf}(1:idx-1);
    else
        idx = strfind(wFiles{wf},'_');
        id = wFiles{wf}(idx-4:idx-1);
    end
    % Add channel/roi info
    if strcmp(id(1),'c')
        chns = cat(2, chns, str2double(id(2)));
        rois = cat(2, rois, str2double(id(4)));
    end
    
    if (wf < length(wFiles)), app = ', '; else, app = ''; end
    list{2} = cat(2, list{2}, [id,app]);
end
list{3} = unique(chns);
list{4} = unique(rois);
% ----------------------------------------- END Make Avg List -------------

function loadAcq(hObject, eventdata, handles)
acqStr = handles.acqNumEditor.String(2:end);
fpath = handles.ename.UserData.wpath;
[aFiles,aID] = findWavesInAcquisition(acqStr,fpath);

handles.acqNumEditor.UserData.aNames = aFiles;
handles.acqNumEditor.UserData.aID = aID;
handles.acqNumEditor.UserData.lastAcq = str2double(acqStr);

for a = 1:length(aFiles)
    handles.acqNumEditor.UserData.acqs.(aFiles{a}) = loadWaveo(fullfile(fpath,aFiles{a}));
    if ~any(strcmp(handles.ename.UserData.loadedWaves,aFiles{wf}))
        if contains(aFiles,'.mat')
            handles.ename.UserData.loadedWaves{end+1} = aFiles{wf}(1:strfind(aFiles{wf},'.mat'));
        else
            handles.ename.UserData.loadedWaves{end+1} = aFiles{wf};
        end
    end
end

plotAcquisition_Callback(hObject,eventdata,handles);
% ----------------------------------------- END load Acq List -------------
