function [names,waveID] = loadAverage(varargin)
% [names,waveID] = loadAverage(varargin)
% varargin:
% epoch,pulse,folder,loadFlag
% epoch is necessary
% pulse optional if two averages in same epoch
% folder- default is current folder
% loadFlag - load the waves to workspace? (uses loadwaveo)

epoch = varargin{1}; 
pulse = []; 
folder = cd; 
loadFlag = true; 

if length(varargin) > 1
    if ~isempty(varargin{2})
        pulse = varargin{2};
    end
end
if length(varargin) > 2
    if ~isempty(varargin{3})
        folder = varargin{3};
    end
end
if length(varargin) > 3
    if ~isempty(varargin{4})
        loadFlag = varargin{4};
    end
end

% Find / Load Averages
if length(epoch)==1
    if isnumeric(epoch)
        epoch = strcat('*e',num2str(epoch));
    else
        epoch = strcat('*e',epoch);
    end
    if isnumeric(pulse)
        pulse = strcat('p',num2str(pulse),'*');
    elseif ischar(pulse)
        pulse = strcat('p',pulse,'*');
    else
        pulse = '*';
    end

    avgName = strcat(epoch,pulse);
    d = dir(fullfile(folder,avgName));
    names = {d(:).name}';
    if sum(contains(names,'AD0'))>1
        fprintf(2, 'more than one average found in this epoch, provide pulse number.\n');
        return;
    end

    idxInput = cellfun(@(c) contains(c,'AD1'), names, 'uni', 1); 
    fprintf(1,'NOTE: hard coding out AD1 because only used for input.\n'); 
    names = names(~idxInput); 
    names = cellfun(@(c) c(1:strfind(c,'.')-1), names,'uni',0); 
    idxPhys = cellfun(@(c) contains(c,'AD0'),names,'uni',1); 
    imagChs = cellfun(@(c) str2double(c(strfind(c,'c')+1:strfind(c,'r')-1)), names,'uni', 1); 
    imagRoi = cellfun(@(c) str2double(c(strfind(c,'r')+1:strfind(c,'_')-1)), names,'uni', 1); 
    waveID = cat(2, idxPhys(:), imagChs(:), imagRoi(:)); 

    if loadFlag
        for n = 1:numel(names)
            loadWaveo(fullfile(folder,names{n}));
        end
    end
else
    if ~isempty(pulse)
        if length(epoch) ~= length(pulse)
            fprintf(2, 'epochs and pulses provided are not equal');
            return;
        end
    end
    % Find / Load Multiple Epochs
    names = cell(1, length(epoch));
    waveID = cell(1, length(epoch));
    for e = 1:length(epoch)
        cepoch = strcat('*e',num2str(epoch(e)));
        if ~isempty(pulse)
            cpulse = strcat('p',num2str(pulse(e)),'*');
        else
            cpulse = 'p*';
        end
        avgName = strcat(cepoch,cpulse);
        d = dir(fullfile(folder,avgName));
        names{e} = {d(:).name}';
        if sum(contains(names{e},'AD0'))>1
            fprintf(2, 'more than one average found in this epoch, provide pulse number.\n');
            return
        end
        
        idxInput = cellfun(@(c) contains(c,'AD1'), names{e}, 'uni', 1); 
        fprintf(1,'NOTE: hard coding out AD1 because only used for input.\n'); 
        names{e} = names{e}(~idxInput); 
        names{e} = cellfun(@(c) c(1:strfind(c,'.')-1), names{e},'uni',0); 
        idxPhys = cellfun(@(c) contains(c,'AD0'),names{e},'uni',1); 
        imagChs = cellfun(@(c) str2double(c(strfind(c,'c')+1:strfind(c,'r')-1)), names{e},'uni', 1); 
        imagRoi = cellfun(@(c) str2double(c(strfind(c,'r')+1:strfind(c,'_')-1)), names{e},'uni', 1); 
        waveID{e} = cat(2, idxPhys(:), imagChs(:), imagRoi(:)); 
        
        if loadFlag
            for n = 1:numel(names{e})
                loadWaveo(fullfile(folder,names{e}{n}));
            end
        end
    end
end




