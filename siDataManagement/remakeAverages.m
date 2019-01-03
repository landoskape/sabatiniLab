function info = remakeAverages(pth,mask)
% remakeAverages gets the state structure from xfiles.mat
% and just makes average directly from epochs
% will do based on pulse pattern - not cycle position - 
%  *** but can include a check on state for cycle position later
% if included mask gives list of epochs to remake average for
if nargin<1 || isempty(pth)
    pth = pwd;
end
state = getXFile(pth,'state');
epochList = [state(:).epoch];
epochs = funique(epochList);
cycle = [state(:).cycle];
pulseList = [cycle(:).pulseToUse1]; 
fprintf(1, 'NOTE: defaulting to pulseToUse1\n'); % eventually make this link to correct phys channel

if nargin==2
    if ~all(ismember(mask,epochs))
        fprintf(1,'The following epochs in mask are not in data: ');
        fprintf(1,'%d,',mask(~ismember(mask,epochs)));
        fprintf(1,'\b\n');
        return
    else
        epochs = mask; % just keep epochs from mask
    end
end 
NE = numel(epochs);

% Conventions for making average names
phAvgName = @(epoch,pulse,channel) sprintf('AD%d_e%dp%davg',channel,epoch,pulse);
imAvgName = @(epoch,pulse,channel,roi) sprintf('e%dp%dc%dr%d_avg',epoch,pulse,channel,roi); 

% Identify phys channels recorded 
phFiles = dir(fullfile(pth,'AD*.mat'));
phNames = {phFiles(:).name};
phAcqChar = cellfun(@(name) name(strfind(name,'_')+1:strfind(name,'.')-1), phNames, 'uni', 0);
validAcquisition = cellfun(@(c) all(isstrprop(c,'digit')), phAcqChar, 'uni', 1);
phAcqChar = phAcqChar(validAcquisition);
phAcqs = cellfun(@str2double, phAcqChar(validAcquisition), 'uni', 1);
phChannels = cellfun(@(name) str2double(name(3)), phNames(validAcquisition), 'uni', 1);
phInfo = [phAcqs(:), phChannels(:)];
phChanList = funique(phChannels); %list of all channels

% Identify imaging channels and rois recorded
imFiles = dir(fullfile(pth,'c*r*.mat'));
imNames = {imFiles(:).name};
imAcqChar = cellfun(@(name) name(strfind(name,'_')+1:strfind(name,'.')-1), imNames, 'uni', 0);
validAcquisition = cellfun(@(c) all(isstrprop(c,'digit')), imAcqChar, 'uni', 1);
imAcqs = cellfun(@str2double, imAcqChar(validAcquisition), 'uni', 1);
imChannels = cellfun(@(name) str2double(name(strfind(name,'c')+1:strfind(name,'r')-1)), imNames(validAcquisition), 'uni', 1);
imROIs = cellfun(@(name) str2double(name(strfind(name,'r')+1:strfind(name,'_')-1)), imNames(validAcquisition), 'uni', 1);
imInfo = [imAcqs(:), imChannels(:), imROIs(:)];
imChanList = funique(imChannels); %list of all channels
imROIList = funique(imROIs); %list of all ROIs

% Setup info structure for output
info = struct();
info.directory = pth;
info.epochs = epochs;
info.phChanList = phChanList;
info.imChanList = imChanList;
info.imROIList = imROIList;
info.phInfo = phInfo;
info.imInfo = imInfo;
% 1st column is epoch number
% Next columns are number of acquisitions in average for each type
% phChannel(1:end), imChan x imROI so c1r1, c1r2, c2r1, c2r2 etc...
numReportColumns = numel(phChanList) + numel(imChanList)*numel(imROIList); 
info.pulses = cell(NE,1);
info.report = cell(NE,1);
info.saved = cell(NE,1);

% Make averages 
% ---*--- rewrite after for p=1:NP when no longer defaulting to pulseToUse1
message = [];
fprintf(1,'Remaking averages...\n');
for e = 1:NE, cepoch = epochs(e);
    epochIdx = (epochList==cepoch); % idx of acquisitions in epoch
    upulses = funique(pulseList(epochIdx)); % unique pulses in epoch
    NP = numel(upulses); 
    info.pulses{e} = upulses;
    info.report{e} = cellfun(@(c) zeros(1,numReportColumns), num2cell(upulses), 'uni', 0);
    info.saved{e} = cellfun(@(c) zeros(1,numReportColumns), num2cell(upulses), 'uni', 0);
    
    % Loop through each pulse and make averages from that pulse
    for p = 1:NP, cpulse = upulses(p); 
        fprintf(1,repmat('\b',1,length(message)));
        message = sprintf('%d/%d || Epoch %d - Pulse %d (%d/%d) ...',e,NE,cepoch,cpulse,p,NP);
        fprintf(1,message);
        avgIdx = epochIdx & (pulseList==cpulse); % index of acquisitions that go in this pulse
        anums = find(avgIdx); % list of acquisition numbers 
        
        % Initialize average waves
        for pc = phChanList
            waveo(phAvgName(cepoch,cpulse,pc),[]);
        end
        for ic = imChanList
            for ir = imROIList
                waveo(imAvgName(cepoch,cpulse,ic,ir),[]); 
            end
        end
        
        % Now add data from each acquisition 
        for cacq = anums
            for pc = phChanList
                ridx = phChanList==pc;
                cidx = phInfo(:,1)==cacq & phInfo(:,2)==pc;
                if sum(cidx)==1
                    cname = sprintf('AD%d_%d',pc,cacq);
                    loadWaveo(fullfile(pth,cname));
                    avgin(cname,phAvgName(cepoch,cpulse,pc));
                    info.report{e}{p}(ridx) = info.report{e}{p}(ridx)+1;
                    clearvars('-global',cname);
                elseif sum(cidx)>1
                    fprintf(1, 'found multiple phys acquisitions with same acq number.\n');
                    fprintf(1, 'On epoch: %d, pulse: %d, acquisition %d, channel %d\n',cepoch,cpulse,cacq,pc);
                    fprintf(1, 'quitting before saving on this epoch.\n');
                    return
                end
            end
            for ic = imChanList
                for ir = imROIList
                    % idx of column in info.report
                    ridx = numel(phChanList) + find(imChanList==ic) + numel(imROIList)*(ir-1);
                    % idx of data from cacq, in current channel and roi
                    cidx = imInfo(:,1)==cacq & imInfo(:,2)==ic & imInfo(:,3)==ir;
                    if sum(cidx)==1
                        cname = sprintf('c%dr%d_%d',ic,ir,cacq);
                        loadWaveo(fullfile(pth,cname));
                        avgin(cname,imAvgName(cepoch,cpulse,ic,ir));
                        info.report{e}{p}(ridx) = info.report{e}{p}(ridx)+1;
                        clearvars('-global',cname);
                    elseif sum(cidx)>1
                        fprintf(1, 'found multiple imaging acquisitions with same acq number, channel, and ROI.\n');
                        fprintf(1, 'On epoch %d, pulse %d, acquisition %d, channel %d, roi %d\n',cepoch,cpulse,cacq,ic,ir);
                        fprintf(1, 'quitting before saving on this epoch.\n');
                        return
                    end 
                end
            end
        end
        % Now we're done with all acquisition in current epoch & pulse
        % Check if average has components, yes:save, no:delete 
        for pc = phChanList
            ridx = phChanList==pc;
            if info.report{e}{p}(ridx)>0
                eval(['global ',phAvgName(cepoch,cpulse,pc)]); % load global in this workspace
                save(fullfile(pth,phAvgName(cepoch,cpulse,pc)),phAvgName(cepoch,cpulse,pc));
                info.saved{e}{p}(ridx) = 1;
            end
            clearvars('-global',phAvgName(cepoch,cpulse,pc));
        end
        % Same for imaging
        for ic = imChanList
            for ir = imROIList
                ridx = numel(phChanList) + find(imChanList==ic) + numel(imROIList)*(ir-1);
                if info.report{e}{p}(ridx)>0
                    eval(['global ',imAvgName(cepoch,cpulse,ic,ir)]); % load global in this workspace
                    save(fullfile(pth,imAvgName(cepoch,cpulse,ic,ir)),imAvgName(cepoch,cpulse,ic,ir));
                    info.saved{e}{p}(ridx) = 1;
                end
                clearvars('-global',imAvgName(cepoch,cpulse,ic,ir)); % clean workspace
            end
        end
    end
end
fprintf(1,repmat('\b',1,length(message)+1));
fprintf(1,'finished.\n');


    
    
    




