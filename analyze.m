%% Master script for ePhys & imaging analysis

% Setup globals 
global meta 
global state 
global data 
global exp 
meta = struct(); 
state = struct(); 
data = struct(); 
exp = struct(); % To be updated later...

% Meta Data 
meta.dpath = '/Users/LandauLand/Documents/Research/SabatiniLab/data/AP Properties/ATL180513a'; 
meta.dstr = 180513; 
meta.cstr = 'a'; 

cpath = cd;
cd(meta.dpath);

%% retrieve data
retrieveData();

%% setup experiment structure
meta.NE = max([data(:).epoch]); % number of epochs
exp = setupExpFields(); % setup fields
exp(meta.NE) = setupExpFields(); % preallocate

%% compile data
% epipe.compileData;


%% After everything...
cd(cpath);
