function acqNames = loadAcquisitions(avgName,fpath)

if (nargin < 2)
    fpath = pwd;
end

acqNames = evalin('base',sprintf('%s.UserData.Components',avgName));

NA = length(acqNames);
for a = 1:NA
    try
        loadWaveo(fullfile(fpath,acqNames{a}));
    catch
        error('% some weird shit! -- ');
    end
end
        





