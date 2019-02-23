function idxSuccess = loadWaveFiles(list,fpath)

if (nargin < 2)
    fpath = pwd;
end

NW = length(list);
idxSuccess = false(1,NW);
for w = 1:NW
    try
        loadWaveo(fullfile(fpath,list{w}));
        idxSuccess(w) = true;
    catch
        error('% some weird shit! -- ');
    end
end
        




