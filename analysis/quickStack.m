function quickStack(acq,chan2keep,medFiltSize)
% quickStack(acq,chan2keep,medFiltSize)
% quickStack grabs a tif file of a z-stack from the current directory and
% opens up imageDesigner to adjust the color axis and save somewhere.
%
% acquisition 'acq' needs to be available in the current directory
% chan2keep is an index of channels to make stacks for 
%       i.e. chan2keep = 1; if you want just the green channel
%       default is red channel (2)
%
% medFiltSize is an input to medfilt3, if none provided uses default
%
% Andrew Landau, 2018 

% deal with inputs
if (nargin < 2)
    medFiltSize = [];
    chan2keep = [];
elseif (nargin < 3)
    medFiltSize = [];
end

% Defaults
if isempty(chan2keep), chan2keep = 2; end % Default is Red, Green, and no DIC
if isempty(medFiltSize), medFiltSize = [3 3 3]; end % default is default for medfilt3

% Find all files with .tif extensions, load specified acquisition
files = retdir([],'.tif');
idx = cellfun(@(s) contains(s, sprintf('%s.tif',zpadNum(acq))),files, 'uni',1);
if sum(idx)>1
    file = uigetfile('*.tif');
else
    file = files{cellfun(@(s) contains(s, sprintf('%d.tif',acq)),files, 'uni',1)};
end
tifs = tifread(file);

% Separate tif by channel
allChannels = cell(1,3);
for c = 1:3
    allChannels{c} = tifs(:,:,c:3:end);
end

% Perform median filter on stack and make max z-projection
tif = medfilt3(allChannels{chan2keep}, medFiltSize); 
mzp = max(tif, [], 3);

% Open imageDesigner to do adjust the caxis, colormap, resolution, and save
imageDesigner(mzp);

    





