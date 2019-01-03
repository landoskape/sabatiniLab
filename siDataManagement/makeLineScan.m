function flag = makeLineScan(anum,base,mode)
% flag = makeLineScan(anum,base,mode)
% 
% make line scan files out of tiff ex. ('c1r1_1.mat') 
% you have to be in the directory you want it to do this for
% does not overwrite files
% ROI defined by conventional scanImage method
%
% anum is the acquisition number
% base is a 2 component array defining when to start and end the baseline
%      calculation
% mode is the way to compute the values, it's 2 components for each channel
%      see inside code to get lookup table for integer --> mode

tName = strcat('*',zpadNum(anum,3),'.tif'); % tiff name (find based only on acquisition)
d = dir(fullfile(cd,tName));

% If this went wrong deal with it
if (numel(d) ~= 1)
    if numel(d) == 0
        fprintf(2,'no tifs found under this acquisition num.\n');
    else
        fprintf(2,'multiple tiffs found under this acquisition number.\n');
    end
    flag = false;
    return
end
    
fName = fullfile(cd,d.name);
tif = tifread(fName);

% Get imageData and reshape into long raster in 2 dimensions 
g = tif(:,:,1:3:end);
r = tif(:,:,2:3:end);
g = transpose(reshape(permute(g,[2 1 3]),size(g,1),size(g,2)*size(g,3)));
r = transpose(reshape(permute(r,[2 1 3]),size(r,1),size(r,2)*size(r,3)));

% Compute ROI from red channel (take from center of line scan to avoid
% initial artifacts)









