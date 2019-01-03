function siDir = cdScanImage(version)

if (nargin < 1)
    version = 2014; 
end

switch version
    case 2009
        siDir = '/Users/LandauLand/Documents/MATLAB/SabalabSoftware_Nov2009';
    case 2014
        siDir = '/Users/LandauLand/Documents/MATLAB/SabalabSoftware_Feb2014';
    otherwise
        fprintf(1,'don''t understand input argument, directing to scanImage 2014\n');
        siDir = '/Users/LandauLand/Documents/MATLAB/SabalabSoftware_Feb2014';
end

if nargout
    return
end

% Change directory to scan image code
cd(siDir);

clear siDir % clean living


