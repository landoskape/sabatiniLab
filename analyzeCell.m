function analyzeCell(dpath, dstr, cstr)
% Give full data path as dpath, the YYMMDD date string as dstr, and cell id
% as cstr
% Master script for ePhys & imaging analysis

if ~nargin
    dpath = cd;
    [~,cfolder] = fileparts(dpath);
    if strcmp(cfolder(1:3),'ATL')
        dstr = str2double(cfolder(4:9));
        cstr = cfolder(10:end);
    else
        error('folder name needs to be ATLYYMMDDi to decode without inputs');
    end
end

% Setup globals 
global meta 
global state 
global data 
global exp 
meta = struct(); 
state = struct(); 
data = struct(); 

% Meta Data 
meta.dpath = dpath; 
meta.dstr = dstr; 
meta.cstr = cstr; 

cpath = cd;
cd(meta.dpath);

%% retrieve data
retrieveData();

%% setup experiment structure
meta.NE = max([data(:).epoch]); % number of epochs
exp = setupExpFields(); % setup fields
exp(meta.NE) = setupExpFields(); % preallocate

%% After everything...
saveCell();
cd(cpath);
