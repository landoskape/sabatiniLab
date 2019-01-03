function info = tifinfo(tifname)
% see imfinfo. optimized for speed Andrew Landau January 2019

% Find the exact name of the file.
fid = fopen(tifname, 'r');
tifname = fopen(fid);
fclose(fid);

% Copy mex function to path from: 'Matlab/imagesci/+matlab/+io/+imagesci'
info = tifftagsread(tifname,0,0,0); 
% info = tifftagsprocess(info); % Andrew- unnecessary for this function


