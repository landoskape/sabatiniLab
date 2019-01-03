function info = makePointScanWaves(anum,methods)
% info = makePointScanWaves(anum,methods)
% 
% make and save point scan waves (e.g. c1r1_35) from tif file
% currently only works for single-point scans 
%   (will eventually handle multiple point scans with >1 ROIs)
% anum is acquisition number 
%   - it can be a list of acquisition numbers
%   - note that this requires a unique file name with '3charstring.tif'
%   - e.g. ATL181201a001.tif for data header ATL181201a, acquisition 1
% methods is a structure that acts as a varargin, all fields optional
%     pth - path to get files from, current directory is default
%     dsfactor - raw downsample factor (number of samples, not time)
%     bswin - range in milliseconds to compute baseline from
%     bsMethod - 2dim array with channel to ratio baseline from (0 if raw)
%     overwrite - boolean to indicate whether we should overwrite ROIs
% ----------------

% Deal with inputs - 
if nargin<2, methods = struct(); end % initialize methods if not provided
if ~isfield(methods,'pth'), methods.pth=pwd; end % default is working directory
if ~isfield(methods,'dsfactor'), methods.dsfactor=16; end % for typical sample rate 16x gives ~0.1ms samples
if ~isfield(methods,'bswin'), methods.bswin=[20 95]; end % hello grandfather 
if ~isfield(methods,'bsmethod'), methods.bsmethod=[2 2]; end % default is to ratio from red channel baseline
if ~isfield(methods,'overwrite'), methods.overwrite=0; end % don't overwrite as default

% Get files 
tifDirectory = dir(fullfile(methods.pth,'*.tif')); % full list of tif files
tifNames = {tifDirectory(:).name};
tifAcqs = cellfun(@(c) str2double(c(strfind(c,'.tif')-3:strfind(c,'.tif')-1)), tifNames, 'uni', 1); 

state = getXFile(methods.pth,'state'); % Get state structure 
if isempty(anum)
    % default is to make point scans out of acquisitions where ps is active
    if isfield(state,'pointScan')
        pointScan = [state(:).pointScan];
        psActive = [pointScan(:).pointScanActive];
        anum = find(psActive); 
    else
        error('if pointScan is not a field in state, anum must be provided');
    end
end

anum = anum([logical(diff(sort(anum))),true]); % only keep unique acquisitions

% Check if all tif files exist for requested acquisitions
if any(~ismember(anum,tifAcqs)) 
    % Print report of acquisitions without tif files
    missingTifs = anum(~ismember(anum,tifAcqs));
    fprintf(1,'Missing tifs: ');
    fprintf(1,'%d,',missingTifs(:));
    fprintf(1,'\b\n');
    return % quit function immediately so user can get their shit together
end

% -------------------------------
% -- now make point scan waves --
% -------------------------------

NA = numel(anum); % Number of acquisitions

% Preallocate info structure for output
info = struct();
info(NA).anum=anum(NA);

% Make point scans
fprintf('Making point scans... A:');
message=[];
for a = 1:NA, cacq=anum(a);
    % Print update to screen
    fprintf(repmat('\b',1,length(message)));
    message=sprintf('%d, %d/%d',cacq,a,NA);
    fprintf(message);
    
    % Some basic data into info structure
    info(a).anum=cacq;
    info(a).psActive=isfield(state(cacq),'pointScan') && state(cacq).pointScan.pointScanActive; 
    
    pmtOffsets = [state(cacq).acq.pmtOffsetChannel1 state(cacq).acq.pmtOffsetChannel2];
    pmtOffsets = pmtOffsets * state(cacq).acq.binFactor;
    
    % Get tif and pull out green / red channels
    ctifname = tifNames{tifAcqs==cacq};
    tif = tifread(fullfile(methods.pth,ctifname));
    NOC = size(tif,3)/state(cacq).acq.numberOfFrames; % number of channels
    green = tif(:,:,1:NOC:end) - pmtOffsets(1); % And subtract PMT offset
    red = tif(:,:,2:NOC:end) - pmtOffsets(2);
    
    % Reshape and down-sample into point-scan as column vector
    gps = mean(reshape(permute(green,[2 1 3]),methods.dsfactor,numel(green)/methods.dsfactor,1),1)';
    rps = mean(reshape(permute(red,[2 1 3]),methods.dsfactor,numel(red)/methods.dsfactor,1),1)';
    
    pixelTime = state(cacq).acq.pixelTime; % pixel time of acquisition
    dt = pixelTime*methods.dsfactor; % sample period of down-sampled pointscan
    info(a).sr = 1000/pixelTime; % sample rate of acquisition (before down-sampling)
    
    if any(methods.bsmethod)
        psTime = 0:dt:numel(gps)*dt-dt; % Make time vector to find sample window for baseline estimation
        bsPoints = find(methods.bswin(1)>psTime, 1, 'last'):find(methods.bswin(2)>psTime,1,'last'); % idx directly
        baseline = [mean(gps(bsPoints)) mean(rps(bsPoints))]; % baselines of green and red channels
        if methods.bsmethod(1), gps = gps / baseline(methods.bsmethod(1)); end
        if methods.bsmethod(2), rps = rps / baseline(methods.bsmethod(2)); end
    end
    
    gname = sprintf('c1r1_%d',cacq);
    rname = sprintf('c2r1_%d',cacq);
    gpath = fullfile(methods.pth,strcat(gname,'.mat'));
    rpath = fullfile(methods.pth,strcat(rname,'.mat'));
    
    info(a).fileExisted = [exist(gpath,'file') exist(rpath,'file')];
    if ~any(info(a).fileExisted) || methods.overwrite
        % Make waves and save if files don't exist or if we're overwriting
        waveo(gname,gps,'xscale',[0 dt]);
        waveo(rname,rps,'xscale',[0 dt]);
        eval(['global ',gname]);
        eval(['global ',rname]);
        save(gpath,gname);
        save(rpath,rname);
        clearvars('-global',gname,rname);
        info(a).fileWritten = [1 1]; % indicate that files were saved
    else
        info(a).fileWritten = [0 0];
    end
end 
fprintf('\n'); 


