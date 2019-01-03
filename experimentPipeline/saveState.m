function saveState(cellPath)

if (nargin < 1)
    cellPath = cd;
end

if ~exist(cellPath,'file')
    cellPath = cd;
end

global state %#ok

save(fullfile(cellPath,'xState.mat'),'state');
