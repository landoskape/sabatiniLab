function [names,wID] = getAcqInAverage(averageID,pth,printFlag)

aname = makeAverageName(averageID);
if (nargin == 1)
    pth = cd;
end
if (nargin < 3)
    printFlag = 1;
end

d = dir(fullfile(pth,strcat('*',aname,'*')));
wfiles = {d(:).name};
wnames = cellfun(@(w) w(1:strfind(w,'.')-1), wfiles, 'uni', 0);

NW = length(wfiles);
names = cell(1,NW);
for w = 1:NW
    loadWaveo(fullfile(pth,strcat(wfiles{w})));
    names{w} = avgComponentList(wnames{w})';
end

wID = makeWaveID(wnames);

if printFlag
    printAcqInAverage(wnames, names);
end




