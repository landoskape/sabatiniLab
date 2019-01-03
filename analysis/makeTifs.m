function makeTifs(epoch)

global meta
global state
global data
global exp

% exp(epoch) = output; % output will be the structure I make here
out = setupExpFields();
out.type = 'tifs';

% Retrieve data specific to this epoch
edata = getEpoch(data, epoch);
estate = getEpoch(state, epoch);
NA = length(edata);

out.epoch = epoch;
out.ename = meta.ename;
out.data.tif = cell(NA,3); % Data for tifs (g, r, dic)


% Find acquisitions with tif files
tif = {edata(:).tif};
idx = find(cellfun(@(t) ~isempty(t), tif, 'uni', 1));
NT = length(idx);

% Get tif files
for t = 1:NT
    ct = idx(t);
    ctif = tifread(tif{ct});
    for c = 1:3
        out.data.tif{ct,c} = ctif(:,:,c:3:end);
    end
end

exp(epoch) = out;



