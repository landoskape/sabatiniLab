function [wnames,wid] = findWavesInAverage(pth,epoch,pulse,channel,msg)
% To be used with epoch as numeric

if (nargin < 3), pulse = []; channel = 'AD0'; msg = []; end
if (nargin < 4), channel = 'AD0'; msg = []; end
if (nargin < 5), msg = []; end

if ~isempty(pulse)
    dPhys = dir(fullfile(pth,sprintf('*e%dp%davg*.mat',epoch,pulse)));
    dImag = dir(fullfile(pth,sprintf('*e%dp%dc*.mat',epoch,pulse)));
    d = cat(1,dPhys,dImag);
else
    d = dir(fullfile(pth,sprintf('*e%dp*.mat',epoch)));
end

wnames = {d(:).name};

% If statement that only runs if same average name has multiple phys
% traces. Very unlikely if a pulse pattern number is assigned
if sum(cellfun(@(c) contains(c, channel), wnames, 'uni', 1))>1
    uiwait(errordlg(sprintf('%s\nMore than one average exist for epoch %d. Select manually...',msg,epoch)));
    [file,fpath] = uigetfile(fullfile(pth,'*.mat')); % Have user select a file
    
    [~,~,ext] = fileparts(file);
    if isempty(ext)
        file = [file,'.mat'];
    end
    if contains(file,'_e')
        idx = [strfind(file,'_e') strfind(file,'.')];
        id = file(idx(1)+1:idx(2)-4);
    elseif strcmp(file(1),'e')
        idx = strfind(file,'c');
        id = file(1:idx-1);
    end
    
    d = dir(fullfile(fpath,['*',id,'*.mat']));
    wnames = {d(:).name};
end

switch channel
    case 'AD0'
        idxInput = cellfun(@(c) contains(c,'AD1'),wnames, 'uni', 1);
    case 'AD1'
        idxInput = cellfun(@(c) contains(c,'AD0'),wnames, 'uni', 1);
end
wnames = wnames(~idxInput);

wnames = cellfun(@(c) c(1:strfind(c,'.')-1), wnames,'uni',0);
idxPhys = cellfun(@(c) contains(c,channel),wnames,'uni',1);
imagChs = cellfun(@(c) str2double(c(strfind(c,'c')+1:strfind(c,'r')-1)), wnames,'uni', 1);
imagRoi = cellfun(@(c) str2double(c(strfind(c,'r')+1:strfind(c,'_')-1)), wnames,'uni', 1);
wid = cat(2, idxPhys(:), imagChs(:), imagRoi(:));

