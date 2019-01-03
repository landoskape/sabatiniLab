function varargout = stitchFigures(varargin)
% STITCHFIGURES MATLAB code for stitchFigures.fig
%      STITCHFIGURES, by itself, creates a new STITCHFIGURES or raises the existing
%      singleton*.
%
%      H = STITCHFIGURES returns the handle to a new STITCHFIGURES or the handle to
%      the existing singleton*.
%
%      STITCHFIGURES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STITCHFIGURES.M with the given input arguments.
%
%      STITCHFIGURES('Property','Value',...) creates a new STITCHFIGURES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before stitchFigures_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to stitchFigures_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help stitchFigures

% Last Modified by GUIDE v2.5 30-Apr-2018 17:58:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @stitchFigures_OpeningFcn, ...
                   'gui_OutputFcn',  @stitchFigures_OutputFcn, ...
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


% --- Executes just before stitchFigures is made visible.
function stitchFigures_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
file = uigetfile('*.tif','Select a tiff file to start...');
tif = tifread(file);
handles.loadButton.UserData.baseTiff = tif;  
handles.loadButton.UserData.buffTiff = [];   
handles.loadButton.UserData.stitchTiff = [];  
imagesc(handles.axes1, tif);
colormap('gray');
set(handles.axes1,'xtick',[]);
set(handles.axes1,'ytick',[]);
set(handles.axes2,'xtick',[]);
set(handles.axes2,'ytick',[]);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = stitchFigures_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in loadButton.
function loadButton_Callback(hObject, eventdata, handles)
file = uigetfile('*.tif','select a tiff file to stitch...');
tif = tifread(file);
handles.loadButton.UserData.buffTiff = tif;
imagesc(handles.axes2, tif);
colormap('gray');
guidata(hObject,handles);


% --- Executes on button press in stitchButton.
function stitchButton_Callback(hObject, eventdata, handles)
if isempty(handles.loadButton.UserData.buffTiff) 
    msgbox('select 2nd tiff to stitch');
    return;
elseif ~isempty(handles.loadButton.UserData.stitchTiff)
    return;
end
base = handles.loadButton.UserData.baseTiff;
new = handles.loadButton.UserData.buffTiff;
handles.loadButton.UserData.stitchTiff = stitch(base, new);
imagesc(handles.axes1,handles.loadButton.UserData.stitchTiff);
colormap('gray');
set(handles.axes1,'xtick',[]);
set(handles.axes1,'ytick',[]);
guidata(hObject,handles);


% --- Executes on button press in lockButton.
function lockButton_Callback(hObject, eventdata, handles)
handles.loadButton.UserData.baseTiff = handles.loadButton.UserData.stitchTiff;
handles.loadButton.UserData.stitchTiff = [];
cla(handles.axes2);
text(handles.axes2, 300, 500, 'select figure to stitch...','fontsize',16);
set(handles.axes2,'xtick',[]);
set(handles.axes2,'ytick',[]);
guidata(hObject,handles);


% --- Executes on button press in saveButton.
function saveButton_Callback(hObject, eventdata, handles)


% --- Executes on button press in removeButton.
function removeButton_Callback(hObject, eventdata, handles)
if isempty(handles.loadButton.UserData.stitchTiff)
    return;
end
imagesc(handles.axes1, handles.loadButton.UserData.baseTiff);
colormap('gray');
set(handles.axes1,'xtick',[]);
set(handles.axes1,'ytick',[]);
handles.loadButton.UserData.buffTiff = [];
handles.loadButton.UserData.stitchTiff = [];
guidata(hObject, handles);


function fName_Callback(hObject, eventdata, handles)
% hObject    handle to fName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fName as text
%        str2double(get(hObject,'String')) returns contents of fName as a double


% --- Executes on button press in saveLocButton.
function saveLocButton_Callback(hObject, eventdata, handles)
% hObject    handle to saveLocButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
