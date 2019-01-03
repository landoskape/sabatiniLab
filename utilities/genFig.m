function gfig = genFig(handle,opts)

if (nargin < 2), opts = 'standard'; end
switch opts
    case 'standard'
        sizFig = [0 0 1 0.9];
    case 'square'
        sizFig = [0 0 0.7 0.8];
end

gfig = figure(handle);
clf;
set(gcf,'units','normalized','outerposition',sizFig);

