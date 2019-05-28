function matlabpath = cdMatlab()

matlabpath = '/Users/landauland/Documents/MATLAB';

if nargout
	return
end

cd(matlabpath);
clear matlabpath
