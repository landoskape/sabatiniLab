function acqs = compileAcquisitions(pth,average)
% average can be string or actual wave
% makes an array of the acquisitions in the average
% time on 1st dimension

clist = avgComponentList(average);
NC = length(clist);

L = length(getfield(average,'data')); %#ok can't for top level
acqs = zeros(L,NC);
for c = 1:NC
    loadWaveo(fullfile(pth,clist{c}));
    acqs(:,c) = getfield(clist{c},'data'); %#ok can't for top level
end






