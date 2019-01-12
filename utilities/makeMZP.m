function makeMZP(name, channel, fpath)
% name: string of .tif file in current directory
%       if isnumeric(name), finds .tif with name as last digits of file
% channel: green/red/dic, use integer (1 || 2 || 3) to define
% pth: file path to look for tiff if name is an acquisition number

if (nargin < 2), channel = 2; fpath = cd; end % default is red
if (nargin < 3), fpath = cd; end
if isempty(channel), channel = 2; end

if isnumeric(name)
    acqNum = name;
    % If name provided as acq number, find tiff in current directory
    currentTiffs = dir(fullfile(fpath,'*.tif')); % get .tif files in current directory
    currentTiffs = {currentTiffs(:).name}; % take filenames only
     % find filenames with "name" as last digits
    idx = cellfun(@(c) ~isempty(strfind(c,sprintf('%s.tif',zpadNum(name,3)))),currentTiffs, 'uni', 1);%#ok, using this code in earlier matlab releases.
    if sum(idx)>1, error('multiple tiff''s found with name ending in given acquisition number.'); end
    if sum(idx)==0, error('No tiff''s found for requested acquisition.'); end
    name = currentTiffs{idx};
else
    % if string as name provided retrieve acquisition number for naming
    acqNum = str2double(name(strfind(name,'.tif')-3:strfind(name,'.tif')-1));
end


tif = tifread(fullfile(fpath,name)); % load up tiff file (it's probably a uint16)
data = cast(tif(:,:,channel:3:end),'single'); % get data from channel of interest and make into double
mzp = max(data,[],3); % grab maximum value for each pixel across slices

% Retrieve screen size to predefine figure sizing
pixelsInScreen = get(0,'screensize');
pixelsInScreen = pixelsInScreen([3 4]); 

widthFigure = min([min(pixelsInScreen)/2 max(pixelsInScreen)/3]);
heightFigure = min([min(pixelsInScreen)/2 max(pixelsInScreen)/3])*1.2;

figurePosition = [pixelsInScreen(1)/2 pixelsInScreen(2)/3 widthFigure heightFigure];
axisPosition = [0.02 0.05 0.96 0.96];

mzpFigure = figure; % make new figure
set(mzpFigure, 'units','pixels','outerposition',figurePosition); % make rectangle on screen
imagesc(mzp); % print image
ax = gca; % make axis a variable, get rid of x/y tick marks
set(ax,'XTick',[]); 
set(ax,'YTick',[]);
set(ax,'units','normalized','position',axisPosition);
colormap(ax,'gray'); % we want this to be grayscale
baseColorAxis = caxis(ax); % pull out the default color axis for making adjustments
set(ax,'CLim',baseColorAxis);

% Make Slider
uicontrol('Style','text','String','cAxis: ','Fontsize',10,...
    'units','normalized','position',[0.01 0.01 0.09 0.033]);
slider = uicontrol('Style','Slider','Tag','cAxisSlider',...
    'String','cAxis','BackgroundColor',[0.7 0.7 0.7],...
    'units','normalized','position',[0.1 0.01 0.43 0.033],...
    'Value',1,'Min',0.01,'Max',1,'SliderStep',[0.01 0.1],...
    'Callback',@(src,event)sliderCallback(src,event,ax));

set(slider,'UserData',baseColorAxis); % put color axis in user data to make available within callbacks

% Make focus cAxis button
uicontrol('Parent',mzpFigure,'Style','pushbutton','String','focus axis','Fontsize',10,...
    'units','normalized','position',[0.535 0.01 0.15 0.035],...
    'Callback',@focusColorAxis);

% Make reset cAxis button
uicontrol('Parent',mzpFigure,'Style','pushbutton','Tag','resetButton','Enable','off',...
    'String','reset axis','Fontsize',10,...
    'units','normalized','position',[0.69 0.01 0.15 0.035],...
    'Callback',@(src,event)resetColorAxis(src,event,ax,baseColorAxis));

% Make saveFigure button
uicontrol('Parent',mzpFigure,'Style','pushbutton','String','saveTiff','Fontsize',10,...
    'units','normalized','position',[0.845 0.01 0.15 0.035],...
    'Callback',@(src,event)saveTiff(src,event,mzp,acqNum,fpath));

% ------ Call back functions ------ 

% -- sliderCallback - movement of slider adjusts the maximum value of cAxis
function sliderCallback(slider,~,ax)
adjustAxis = get(slider,'UserData');
range = adjustAxis(2) - adjustAxis(1);
newMax = adjustAxis(1) + get(slider,'Value') * range;
set(ax,'CLim',[adjustAxis(1) newMax]);

% pressing focusAxis button reduces min/max of slider to focus adjustment
function focusColorAxis(~,~)
slider = findobj(gcf,'Tag','cAxisSlider');
adjustAxis = get(slider,'UserData');
range = adjustAxis(2) - adjustAxis(1);
newMax = adjustAxis(1) + get(slider,'Value') * range;
set(slider,'UserData',[adjustAxis(1) newMax]);
set(slider,'Value',1);
resetButton = findobj(gcf,'Tag','resetButton');
set(resetButton,'Enable','on');

% pressing resetAxis button restores original color axis
function resetColorAxis(resetButton,~,ax,baseColorAxis)
slider = findobj(gcf,'Tag','cAxisSlider');
set(slider,'UserData',baseColorAxis);
adjustAxis = get(slider,'UserData');
range = adjustAxis(2) - adjustAxis(1);
newMax = adjustAxis(1) + get(slider,'Value') * range;
set(ax,'CLim',[adjustAxis(1) newMax]);
set(resetButton,'Enable','off');

function saveTiff(~,~,mzp,acqNum,fpath)
slider = findobj(gcf,'Tag','cAxisSlider'); % get slider object
% snapshot of current color axis
cAxis = get(slider,'UserData'); 
range = get(slider,'Value')*(cAxis(2) - cAxis(1));
% Normalize mzp to current axis
mzp = mzp - cAxis(1);
mzp = mzp ./ range;
mzp(mzp>1)=1;
mzp = cast(mzp*65000,'uint16'); % cast as uint16

% Get file name and path to save. This function won't work if there are
% multiple tif files that end in the same number, so if the given name will
% lead to ambiguous files, check if user wants to rename.
needName = 1;
while needName
    [fileName,savePath] = uiputfile('.tif','Name File');
    last3Digits = fileName(strfind(fileName,'.tif')-3:strfind(fileName,'.tif')-1);
    nameConflated = strcmp(last3Digits,zpadNum(acqNum,3));
    if strcmp(savePath(end),'/') || strcmp(savePath(end),'\')
        savePath = savePath(1:end-1);
    end
    if strcmp(fpath(end),'/') || strcmp(fpath(end),'\')
        fpath = fpath(1:end-1);
    end
    if nameConflated && strcmp(savePath,fpath)
        questTxt = {'Selected save name will make this file indistinguishable from original data to this function.'; 
            'Suggested naming convention: don''t end file name with acquisition number.'};
        response = questdlg(questTxt,'Filename?','Continue','Rename','Rename');
        if strcmp(response,'Continue')
            needName = 0;
        end
    else
        needName = 0;
    end
end

% Try to write tiff, report to user if failed
try
    t = Tiff(fullfile(savePath,fileName), 'w');
    tagstruct.ImageLength = size(mzp, 1);
    tagstruct.ImageWidth = size(mzp, 2);
    tagstruct.Compression = Tiff.Compression.None;
    tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
    tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
    tagstruct.BitsPerSample = 16; % uint16
    tagstruct.SamplesPerPixel = 1; % grayscale, only real values
    tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky; % who came up with this
    t.setTag(tagstruct);
    t.write(mzp);
    t.close();
    fprintf('mzp saved in: %s\n',fullfile(savePath,fileName));
catch
    h = warndlg('tiff file not saved');
    uiwait(h);
end




