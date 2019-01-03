function waveID = makeWaveID(wFiles)
% wFiles is cell
% each is a wave average name
% (works better without the .mat)
% doesn't distinguish between AD0 and AD1

idxPhys = double(cellfun(@(c) contains(c,'AD'),wFiles,'uni',1));
idxPhys(cellfun(@(c) contains(c,'AD1'),wFiles,'uni',1)) = 2;
imagChs = cellfun(@(c) str2double(c(strfind(c,'c')+1:strfind(c,'r')-1)), wFiles,'uni', 1);
imagRoi = cellfun(@(c) str2double(c(strfind(c,'r')+1:strfind(c,'_')-1)), wFiles,'uni', 1);
waveID = cat(2, idxPhys(:), imagChs(:), imagRoi(:));

