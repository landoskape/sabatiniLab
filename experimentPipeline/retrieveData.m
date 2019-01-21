function retrieveData
% dpath is the full path to the data
% dstr is a date string ('170710' means July, 10th 2017)
% cstr is a lower case, single-letter string indicating the cell ID

global meta 
global state 
global data 

if isnumeric(meta.dstr)
    meta.dstr = num2str(meta.dstr); 
end % Make sure dstr is char

meta.ename = strcat('ATL',meta.dstr,meta.cstr); 


%% Compile state struct 
% Look through txt files and create state structs
stnames = dir(fullfile(meta.dpath,'*.txt')); 
stnames = {stnames(:).name};
stAcqNums = cellfun(@(c) str2double(c(strfind(c,'_')-3:strfind(c,'_')-1)), stnames, 'uni', 1);
NA = max(stAcqNums); 
NF = length(stnames);
stfiles = cell(NA,1); 
state = struct(); 

% check directory
cDir = cd;
if ~exist(stnames{1},'file'), cd(meta.dpath), end

fprintf(1,'| compiling file ');
cFileTimer = tic;
for n = 1:NF
    cacq = stAcqNums(n);
    % Update screen
    if (rem(n,10)==0) || (n==NF)
    	if n>10, fprintf(repmat('\b',1,length(msg))); end
        msg = sprintf('%d / %d ...',n,NF);
        fprintf(1,msg);
    end
    
    fid = fopen(stnames{n});
    stfiles{n} = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
    stfiles{n} = stfiles{n}{1};
    
    lstate = length(stfiles{n});
    for lst = 1:lstate
        cString = stfiles{n}{lst}(7:end);
        eqidx = strfind(cString,'=');
        name = cString(1:eqidx(1)-1);
        post = cString(eqidx(1)+1:end);
        if isempty(post), post = '[]'; end
        if ~contains(post,',')
            %evalc because sometimes it generates output for unknown reason. didn't investigate.
            evalc(strcat(sprintf('state(%d).',cacq),name,'=',post,';')); 
        else
            % lists of numbers are delimited by commas in headerString
            postElements = strsplit(post,',');
            evalc(strcat(sprintf('state(%d).',cacq),name,'=',strcat('[',sprintf('%s ',postElements{:}),']'),';'));
        end
    end
end
fprintf(1,' finished compiling. %d seconds. \n',round(toc(cFileTimer)));


%% Compile Data

% Initialize data structure
data(NF).epoch = [];
data(NF).ph = []; 
data(NF).pdata = [];
data(NF).pin = [];
data(NF).pt = [];
data(NF).pulse = [];
data(NF).pmode = [];
data(NF).im = [];
data(NF).idata = [];
data(NF).it = [];
data(NF).iprop = [];
data(NF).blast = [];
data(NF).tif = [];

% Get data file names (phys and imaging)
dnames = retdir([],'.mat',meta.dpath); 
NF = length(stfiles); 
dacqs = cellfun(@(s) str2double(s(strfind(s,'_')+1:strfind(s,'.')-1)), dnames, 'uni', 0);
bNums = cellfun(@(s) ~isnan(s), dacqs, 'uni', 1);
dacqs = cell2mat(dacqs(bNums));
dnames = dnames(bNums); 
[dacqs,idx] = sort(dacqs);  % This gives acqs in order and index of sort
dnames = dnames(idx); % This gives dnames in order of acq.
 
% Find tifs 
tnames = retdir([],'.tif',meta.dpath,1); 
tacqs = cellfun(@(s) str2double(s((-3:-1)+strfind(s,'.'))), tnames, 'uni', 1); %These already sorted

fprintf('| compiling data '); 
cDataTimer = tic;
for n = 1:NF
    % Update screen
    if (rem(n,10)==0) || (n==NF)
    	if n>10, fprintf(repmat('\b',1,length(msg))); end
        msg = sprintf('%d / %d ...',n,NF);
        fprintf(msg);
    end
     
    % Housekeeping 
    data(n).epoch = state(n).epoch; 
    % pulse pattern, info like that 
     
    % Physiology 
    phidx = find((dacqs == n) & cellfun(@(s) strncmp(s,'AD',1), dnames, 'uni', 1)); 
    if ~isempty(phidx), data(n).ph = 1; else, data(n).ph = 0; end % idx indicates phys=ON/OFF 
    if data(n).ph 
        for p = 1:length(phidx)
            evalc(['load ' dnames{phidx(p)}]); 
            eval(['cdata = ' dnames{phidx(p)}(1:end-4) ';']); 
            data(n).pdata(p,:) = cdata.data; % Row is channel 
            eval(['clear ' dnames{phidx(p)}(1:end-4)]); 
        end
        % The following IF is essentially a hack, in the future if I'm
        % using other rigs I should create a function that has a lookup
        % table for which AD# file is which signal that takes as input a
        % string denoting the current rig. 
        if length(phidx)>1
            data(n).pin = data(n).pdata(end,:); % (this always input)
            data(n).pdata(end,:) = [];
        end 
        data(n).pt = (1:length(cdata.data)) / 1000 * cdata.xscale(2); % Add time (same if multiple chs)
    end
    % Define recording mode, and setup input gain
    data(n).pulse = state(n).cycle.pulseToUse0;
    data(n).pmode = state(n).phys.settings.currentClamp0;
    gain = [20 400]; % [currentClamp voltageClamp] 
    data(n).pin = data(n).pin * gain(data(n).pmode + 1);
    clear cdata 
    % --- cell properties, etc. ---
    
    % Imaging
    imidx = find((dacqs == n) & cellfun(@(s) strncmp(s,'c',1), dnames, 'uni', 1));
    if ~isempty(imidx), data(n).im = 1; else; data(n).im = 0; end % idx indicates im=ON/OFF
    if data(n).im
        for i = 1:length(imidx)
            gIdx = [str2double(dnames{imidx(i)}(2)) str2double(dnames{imidx(i)}(4))]; % [CH,ROI]
            evalc(['load ' dnames{imidx(i)}]);
            eval(['cdata = ' dnames{imidx(i)}(1:end-4) ';']);
            data(n).idata(gIdx(1),:,gIdx(2)) = cdata.data;
            eval(['clear ' dnames{imidx(i)}(1:end-4)]);
        end
        data(n).it = (1:length(cdata.data)) / 1000 * cdata.xscale(2); % Add time (same if multiple chs)

        % There should be a tif file associated with imaging data
        if sum(tacqs == n) == 0
            fprintf(2,'no tif associated with imaging data on acquisition %d\n',n); 
        end
    end
    clear cdata
    % --- there's gotta be some imaging properties I want here --- 
    
    % Blaster settings
    data(n).blast = state(n).blaster.active;
    data(n).blastPos = [state(n).blaster.indexXList state(n).blaster.indexYList];
    
    % TIF files
    if any(tacqs == n)  
        data(n).tif = tnames{tacqs == n};
    end
    
    % Housekeeping
    % ????????????????????????????????????
end
fprintf(' finished compiling data. %d seconds. \n',round(toc(cDataTimer)));


cd(cDir); % Go back to current directory
