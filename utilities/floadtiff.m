function oimg = floadtiff(path)
% Copyright (c) 2012, YoonOh Tak
% EDITED January 2019- Andrew
% optimized for speed and simplicity
% assumes that each frame is the same size
% assumes that tiff is grayscale


tiff = Tiff(path,'r'); % open tiff

% Load image information
tfl = 0;
while true
    tfl = tfl+1; % increase frame count
    if tiff.lastDirectory(), break; end
    tiff.nextDirectory();
end
tiff.setDirectory(1);
cols = tiff.getTag('ImageWidth');
rows = tiff.getTag('ImageLength');
% iinfo.spp = tiff.getTag('SamplesPerPixel'); ### assuming grayscale
    
oimg = zeros(rows,cols,tfl);
for tf = 1:tfl
    tiff.setDirectory(tfl);
    oimg(:,:,tf) = tiff.read();
end

tiff.close(); % closZ

