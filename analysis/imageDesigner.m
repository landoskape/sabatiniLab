function varargout = imageDesigner(varargin)
% IMAGEDESIGNER MATLAB code for imageDesigner.fig
%      IMAGEDESIGNER, by itself, creates a new IMAGEDESIGNER or raises the existing
%      singleton*.
%
%      H = IMAGEDESIGNER returns the handle to a new IMAGEDESIGNER or the handle to
%      the existing singleton*.
%
%      IMAGEDESIGNER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in IMAGEDESIGNER.M with the given input arguments.
%
%      IMAGEDESIGNER('Property','Value',...) creates a new IMAGEDESIGNER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before imageDesigner_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to imageDesigner_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help imageDesigner

% Last Modified by GUIDE v2.5 30-Apr-2018 09:44:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @imageDesigner_OpeningFcn, ...
                   'gui_OutputFcn',  @imageDesigner_OutputFcn, ...
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


% --- Executes just before imageDesigner is made visible.
function imageDesigner_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to imageDesigner (see VARARGIN)

if ~nargin || ~isnumeric(varargin{1})
    error('input needs to be a numeric array for making an image');
end

% Choose default command line output for imageDesigner
handles.output = hObject;

% some initialization ---
saveLoc = cd;
handles.saveLocation.UserData.saveLoc = saveLoc;
handles.saveLocation.String = sprintf('...%s',saveLoc(end-28:end)); % set string to display current location

mzp = varargin{1};
mzp = double(mzp); % necessary for interpolation
mn = min(mzp(:)); % minimum
mx = max(mzp(:)); % maximum
handles.revertAxis.UserData.ogMin = mn;
handles.revertAxis.UserData.ogMax = mx;

% Update values
handles.minPossible.Value = mn;
handles.maxPossible.Value = mx;
handles.minPossible.String = num2str(mn);
handles.maxPossible.String = num2str(mx);
handles.minEdit.Value = mn;
handles.maxEdit.Value = 300;
handles.minEdit.String = num2str(mn);
handles.maxEdit.String = num2str(300);
handles.minSlider.Min = mn;
handles.minSlider.Max = mx;
handles.minSlider.Value = mn;
handles.maxSlider.Min = mn;
handles.maxSlider.Max = mx;
handles.maxSlider.Value = 300;

handles.cMapDrop.UserData = []; % to deal with 'lol!'

handles.revertInterpolation.UserData.orig = mzp; % To always save the original as long as the figure is open
handles.revertInterpolation.UserData.interp = mzp; % where a new interpolated version will go
handles.revertInterpolation.UserData.cInterp = 0; % current interpolation value (based off of input)

axes(handles.axes1);
imagesc(mzp);
set(gca,'xtick',[]);
set(gca,'ytick',[]);
colormap(handles.cMapDrop.String{handles.cMapDrop.Value});

% Set max value to 300 - usually default within scanImage
changeAxis(mn,300,hObject,handles);

% Update handles structure
guidata(hObject, handles);


function figure1_CloseRequestFcn(hObject, eventdata, handles)
delete(hObject);

function saveButton_Callback(hObject, eventdata, handles)
% save figure in new file with associated data
name = fullfile(handles.saveLocation.UserData.saveLoc,handles.figName.String);
fType = handles.fileType.String{handles.fileType.Value};

if strcmp(handles.figName.String,'name')
    fprintf('saving requires a new name.\n');
    fprintf('add name in save panel, or uncheck save box...\n\n');
    return;
end

% Get Figure and normalize to axis
mzp = handles.revertInterpolation.UserData.interp;
cAxis = [handles.minEdit.Value handles.maxEdit.Value];
mzp = (mzp - cAxis(1)) ./ (diff(cAxis));
mzp(mzp < 0) = 0;
mzp(mzp > 1) = 1;

% Save data structure
figData = struct();
figData.path = name;
figData.fName = handles.figName.String;
figData.type = fType;
figData.mzp = mzp;
figData.caxis = cAxis;
figData.map = handles.cMapDrop.String{handles.cMapDrop.Value};
figData.color = handles.color4saba.String{handles.color4saba.Value};
figData.intFactor = handles.revertInterpolation.UserData.cInterp; 
save(name,'figData');

% Save figure
if strcmp(fType,'figure')
    savefig(name);
elseif strcmp(fType,'data only')
    fprintf('data saved.\n\n');
    return;
elseif strcmp(fType,'tiff')
    [fold,nme] = fileparts(name);
    imwrite(mzp, strcat(name,'.tif'), 'tiff');
    fprintf('tiff file saved as ''%s'' in %s.\n\n',nme,fold);
else
    switch fType 
        case 'pdf'
            fOut = '-dpdf';
        case 'jpeg'
            fOut = '-djpeg';
        case 'eps'
            fOut = '-depsc';
    end
    fig2save = figure;
    clf;
    set(gcf,'units','pixels','outerposition',[86 110 589 625]);
    imagesc(handles.revertInterpolation.UserData.interp);
    set(gca,'xtick',[]);
    set(gca,'ytick',[]);
    caxis([handles.minEdit.Value handles.maxEdit.Value]);
    if (handles.cMapDrop.Value ~= 1) && isempty(strfind(handles.cMapDrop.String{handles.cMapDrop.Value},'lol!'))
        colormap(handles.cMapDrop.String{handles.cMapDrop.Value});
    elseif strfind(handles.cMapDrop.String{handles.cMapDrop.Value},'lol!')
        options = {'lines','colorcube','prism','flag','hsv'};
        choice = randi(length(options));
        if ~isempty(handles.cMapDrop.UserData)
            while choice == handles.cMapDrop.UserData
                choice = randi(length(options));
            end
        end
        handles.cMapDrop.UserData = choice;
        colormap(options{choice});
    else
        fprintf('Can''t use SABA map yet... using gray\n');
        handles.cMapDrop.Value = 1; % value for 'gray'
        colormap(handles.cMapDrop.String{handles.cMapDrop.Value});
    end
    tightfig(fig2save);
    print('-painters',fig2save,name,fOut);
    close(fig2save);
end



% --- Outputs from this function are returned to the command line.
function varargout = imageDesigner_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in saveLocation.
function saveLocation_Callback(hObject, eventdata, handles)
saveLoc = uigetdir; % choose folder
handles.saveLocation.UserData.saveLoc = saveLoc;
handles.saveLocation.String = sprintf('...%s',saveLoc(end-28:end)); % set string to display current location
guidata(hObject, handles); % output


% --- Executes on selection change in cMapDrop.
function cMapDrop_Callback(hObject, eventdata, handles)
if (handles.cMapDrop.Value ~= 1)
    handles.color4saba.Value = 1; % irrelevant for all other maps... set to '---'
end
guidata(hObject, handles);
changeMap(hObject,handles);

% --- Executes on selection change in color4saba.
function color4saba_Callback(hObject, eventdata, handles)
% hObject    handle to color4saba (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns color4saba contents as cell array
%        contents{get(hObject,'Value')} returns selected item from color4saba


% --- Executes on slider movement.
function minSlider_Callback(hObject, eventdata, handles)
% check validity
val = round(handles.minSlider.Value);
if val >= handles.maxEdit.Value, val = handles.maxEdit.Value - handles.minSlider.SliderStep(2); end
if val < handles.minPossible.Value, val = handles.minPossible.Value; end
handles.minSlider.Value = val;
% update
mn = val;
mx = handles.maxEdit.Value;
changeAxis(mn,mx,hObject,handles);


% --- Executes on slider movement.
function maxSlider_Callback(hObject, eventdata, handles)
% check validity
val = round(handles.maxSlider.Value);
if val <= handles.minEdit.Value, val = handles.minEdit.Value + handles.maxSlider.SliderStep(2); end
if val > handles.maxPossible.Value, val = handles.maxPossible.Value; end
handles.maxSlider.Value = val;
% update
mn = handles.minEdit.Value;
mx = val;
changeAxis(mn,mx,hObject,handles);


function minEdit_Callback(hObject, eventdata, handles)
% check validity
val = str2double(handles.minEdit.String);
if val >= handles.maxEdit.Value, val = handles.maxEdit.Value - handles.minSlider.SliderStep(2); end
if val < handles.minPossible.Value, val = handles.minPossible.Value; end
handles.minEdit.String = num2str(val);
% update
handles.minEdit.Value = val;
mn = handles.minEdit.Value;
mx = handles.maxEdit.Value;
changeAxis(mn,mx,hObject,handles);


function maxEdit_Callback(hObject, eventdata, handles)
% check validity
val = str2double(handles.maxEdit.String);
if val <= handles.minEdit.Value, val = handles.minEdit.Value + handles.maxSlider.SliderStep(2); end
if val > handles.maxPossible.Value, val = handles.maxPossible.Value; end
handles.maxEdit.String = num2str(val);
% update
handles.maxEdit.Value = val;
mn = handles.minEdit.Value;
mx = handles.maxEdit.Value;
changeAxis(mn,mx,hObject,handles);


function minPossible_Callback(hObject, eventdata, handles)
% check validity
if ~isstrprop(handles.minPossible.String,'digit')
    handles.minPossible.String = num2str(handles.minPossible.Value);
    fprintf('Need to input a digit...\n');
    return;
end
handles.minPossible.Value = str2double(handles.minPossible.String);
if handles.minEdit.Value < handles.minPossible.Value
    handles.minEdit.Value = handles.minPossible.Value; 
end
mn = handles.minEdit.Value;
mx = handles.maxEdit.Value;
handles.maxSlider.Min = mn;
handles.minSlider.Min = mn;
changeAxis(mn,mx,hObject,handles);


function maxPossible_Callback(hObject, eventdata, handles)
% check validity
if ~isstrprop(handles.maxPossible.String,'digit')
    handles.maxPossible.String = num2str(handles.maxPossible.Value);
    fprintf('Need to input a digit...\n');
    return;
end
handles.maxPossible.Value = str2double(handles.maxPossible.String);
if handles.maxEdit.Value > handles.maxPossible.Value
    handles.maxEdit.Value = handles.maxPossible.Value; 
end
mn = handles.minEdit.Value;
mx = handles.maxEdit.Value;
handles.maxSlider.Max = mx;
handles.minSlider.Max = mx;
changeAxis(mn,mx,hObject,handles);


function interpGo_Callback(hObject, eventdata, handles)
val = handles.interpFactor.Value;
if (val ~= 0) && (handles.revertInterpolation.UserData.cInterp ~= val)
    mzp = interp2(handles.revertInterpolation.UserData.orig, val);
    handles.revertInterpolation.UserData.interp = mzp;
    handles.revertInterpolation.UserData.cInterp = val;
    axes(handles.axes1);
    imagesc(mzp);
    set(gca,'xtick',[]);
    set(gca,'ytick',[]);
    mn = handles.minEdit.Value;
    mx = handles.maxEdit.Value;
    changeAxis(mn,mx,hObject,handles);
    changeMap(hObject,handles);
end
guidata(hObject,handles);


function interpFactor_Callback(hObject, eventdata, handles)
val = str2double(handles.interpFactor.String);
handles.interpFactor.Value = val;
handles.interpFactor.String = sprintf('%dx',val);
guidata(hObject, handles);    


function revertInterpolation_Callback(hObject, eventdata, handles)
handles.interpFactor.Value = 0;
handles.interpFactor.String = '0x';
mzp = handles.revertInterpolation.UserData.orig;
handles.revertInterpolation.UserData.interp = mzp;
handles.revertInterpolation.UserData.cInterp = 0;
axes(handles.axes1);
imagesc(mzp);
set(gca,'xtick',[]);
set(gca,'ytick',[]);
mn = handles.minEdit.Value;
mx = handles.maxEdit.Value;
changeAxis(mn,mx,hObject,handles);
changeMap(hObject,handles);
guidata(hObject, handles);  


function changeAxis(mn,mx,hObject,handles)
% everything bottlenecks through here to change the caxis
axes(handles.axes1);
caxis([mn mx]);
handles.minEdit.Value = mn;
handles.maxEdit.Value = mx;
handles.minEdit.String = num2str(mn);
handles.maxEdit.String = num2str(mx);
handles.minSlider.Value = mn;
handles.maxSlider.Value = mx;
handles.minSlider.Min = handles.minPossible.Value;
handles.maxSlider.Min = handles.minPossible.Value;
handles.minSlider.Max = handles.maxPossible.Value;
handles.maxSlider.Max = handles.maxPossible.Value;

% deal with saba style colormap
if (handles.cMapDrop.Value == 2)
    fprintf('Can''t deal with caxis changes on saba lab colormap right now... \n');
    fprintf('Something weird might happen!!\n\n');
end
guidata(hObject, handles);


function changeMap(hObject,handles)
% everything bottlenecks through here to change the colormap
axes(handles.axes1);
% Check if value is set to saba style or lol!
if (handles.cMapDrop.Value ~= 2) && isempty(strfind(handles.cMapDrop.String{handles.cMapDrop.Value},'lol!'))
    % otherwise just call the map
    colormap(handles.cMapDrop.String{handles.cMapDrop.Value});
elseif strfind(handles.cMapDrop.String{handles.cMapDrop.Value},'lol!')
    options = {'lines','colorcube','prism','flag','hsv'};
    choice = randi(length(options));
    if ~isempty(handles.cMapDrop.UserData)
        while choice == handles.cMapDrop.UserData
            choice = randi(length(options));
        end
    end
    handles.cMapDrop.UserData = choice;
    colormap(options{choice});
else
    fprintf('Can''t use SABA map yet... using gray\n');
    handles.cMapDrop.Value = 1; % value for 'gray'
    colormap(handles.cMapDrop.String{handles.cMapDrop.Value});
end
guidata(hObject,handles);


function revertAxis_Callback(hObject, eventdata, handles)
mn = handles.revertAxis.UserData.ogMin;
mx = handles.revertAxis.UserData.ogMax;
handles.minPossible.Value = mn;
handles.maxPossible.Value = mx;
handles.minPossible.String = num2str(mn);
handles.maxPossible.String = num2str(mx);
handles.minSlider.Min = mn;
handles.minSlider.Max = mx;
handles.maxSlider.Min = mn;
handles.maxSlider.Max = mx;
changeAxis(mn,mx,hObject,handles);
guidata(hObject,handles);

function setBoundAxis_Callback(hObject, eventdata, handles)
mn = handles.minSlider.Value;
mx = handles.maxSlider.Value;
handles.minPossible.Value = mn;
handles.maxPossible.Value = mx;
handles.minPossible.String = num2str(mn);
handles.maxPossible.String = num2str(mx);
handles.minSlider.Min = mn;
handles.minSlider.Max = mx;
handles.maxSlider.Min = mn;
handles.maxSlider.Max = mx;
guidata(hObject,handles);
