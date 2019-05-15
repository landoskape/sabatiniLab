function pth = cdCode

% Change directory to Sabalab code
pth = '/Users/LandauLand/Documents/MATLAB/SabatiniLab';

if (nargout == 0)
    % if no output requested, cd to code path and block output
    cd(pth); 
    clear pth; 
else
    % if output requested, return code path
    return
end

