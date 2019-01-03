function createExp(id,date)

dataHeader = '/Volumes/MICROSCOPE/Andrew/Data';
expHeader = '/Volumes/MICROSCOPE/Andrew/expDirectory';

% Deal with inputs
if ~ischar(id)
    error('id must be a string');
end

if isnumeric(date)
    dstr = num2str(date);
else
    dstr = date;
    date = str2double(date);
end

% Data Header
ename = strcat('ATL',dstr);
dpath = fullfile(dataHeader,id,ename);

% Create new experiment directory
if ~exist(fullfile(expHeader,id),'file'), mkdir(expHeader,id); end
edir = fullfile(expHeader,id);
efold = fullfile(edir,ename);
mkdir(efold);


%% Experiment Pipelines
switch id
    case 'MSC' 
        % MSC: Measure Synaptic Cleft
        % Goal: Determine volume of synaptic cleft in live tissue
        % First Experiment: 171107
        epipe.msc(dpath,efold,dstr);
end







