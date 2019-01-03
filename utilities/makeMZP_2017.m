function makeMZP(name, channel)
% name: string of .tif file in current directory
%       if isnumeric(name), finds .tif with name as last digits of file
% channel: green/red/dic, use integer (1 || 2 || 3) to define

if (nargin < 2), channel = 2; end % default is red

if isnumeric(name)
    % If name provided as acquisition number, find designated tiff
    currentTiffs = dir('*.tif'); % get .tif files in current directory
    currentTiffs = {currentTiffs(:).name}; % take filenames only
    idx = contains(currentTiffs, sprintf('%d.tif',name)); % find filenames with "name" as last digits
    if sum(idx)>1, error('multiple tiff''s found with name ending in given acquisition number.'); end
    name = currentTiffs{idx};
end

tif = loadtiff(name); % load up tiff file (it's usually a uint32)
data = double(tif(:,:,channel:3:end)); % get data from channel of interest and make into double
mzp = max(data,[],3); % grab maximum value for each pixel across slices

% Retrieve screen size to predefine figure sizing
pixelsInScreen = get(0,'screensize');
pixelsInScreen = pixelsInScreen([3 4]); 
widthFigure = max(pixelsInScreen)/3;
heightFigure = max(pixelsInScreen)/3 * 1.2; 

mzpFigure = figure; % make new figure
set(mzpFigure, 'units','pixels','outerposition',[pixelsInScreen/2 widthFigure heightFigure]); % make rectangle on screen
imagesc(mzp); % print image
ax = gca; % make axis a variable, get rid of x/y tick marks
ax.XTick = []; 
ax.YTick = [];
set(ax,'units','pixels','position',[widthFigure*0.02 heightFigure*0.05 widthFigure*0.96 widthFigure*0.96]);
colormap(ax,'gray'); % we want this to be grayscale
baseColorAxis = caxis(ax); % pull out the default color axis for making adjustments

% Make Slider
uicontrol('Style','text','String','cAxis: ','Fontsize',12,...
    'units','pixels','position',[widthFigure*0.02 heightFigure*0.01 widthFigure*0.1 heightFigure*0.033]);
uicontrol('Style','Slider','String','cAxis','BackgroundColor',[0.7 0.7 0.7],...
    'units','pixels','position',[widthFigure*0.12 heightFigure*0.018 widthFigure*0.86 heightFigure*0.02],...
    'Value',1,'Min',0.01,'Max',1,'SliderStep',[0.01 0.1],...
    'Callback',@(src,event)sliderCallback(src,event,ax,baseColorAxis));

% ------ Call back functions ------ 
function sliderCallback(slider,~,ax,baseColorAxis)
range = baseColorAxis(2) - baseColorAxis(1);
newMax = baseColorAxis(1) + slider.Value * range;
ax.CLim = [baseColorAxis(1) newMax];



% -- tried to add compression interface, this doesn't work yet -- 

% Make Compression interface
% compressionSlider = uicontrol('Style','Slider','String','Compression','Enable','off',...
%     'units','pixels','position',[widthFigure*0.32 heightFigure*0.01 widthFigure*0.635 heightFigure*0.033],...
%     'Value',1,'Min',1.1,'Max',20,'SliderStep',[0.01 0.1],...
%     'Callback',@(src,event)compressSliderCallback(src,event,ax,mzp,baseColorAxis,cAxisSlider));
% compressionToggle = uicontrol('Style','togglebutton','String','Compress MZP?','Fontsize',12,...
%     'units','pixels','position',[widthFigure*0.05 heightFigure*0.01 widthFigure*0.25 heightFigure*0.04],...
%     'Callback',@(src,event)compressToggleCallback(src,event,ax,mzp,baseColorAxis,compressionSlider));
% function compressSliderCallback(compressionSlider,~,ax,mzp)
% compressValue = compressionSlider.Value; % pull out compression value
% newData = log(mzp)./log(compressValue); % compress data
% imagesc(ax,newData); % plot data
% 
% function compressToggleCallback(src,~,ax,mzp,baseColorAxis,compressionSlider);
% if (src.Value == 0)
%     % Turning compression off
%     compressionSlider.Enable = 'off'; % disable compression slider
%     
%     % Get uncompressed color axis, replot and set axis
%     range = baseColorAxis(2) - baseColorAxis(1); 
%     newMax = baseColorAxis(1) + src.Value * range;
%     imagesc(ax,mzp);
%     ax.CLim = [baseColorAxis(1) newMax];
% else
%     % Turning compression on
%     compressionSlider.Enable = 'on'; % enable compression slider
%     compressValue = src.Value;
%     newData = log(mzp)./log(compressValue);
%     imagesc(ax,newData);
% end





