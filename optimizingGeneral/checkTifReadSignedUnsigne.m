



fpath = '/Users/LandauLand/Documents/MATLAB/SabatiniLab/optimizingGeneral';

remake = false;
if remake
    s = cast(rand(100),'int16');
    u = cast(rand(100),'uint16');
    saveastiff(s,fullfile(fpath,'s.tif'));
    saveastiff(u,fullfile(fpath,'u.tif'));
end

ss = tifread(fullfile(fpath,'s.tif'));
uu = tifread(fullfile(fpath,'u.tif'));






