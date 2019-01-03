function imag = makeImagingArray(names,waveID)

data = cell(numel(names),1);
for n = 1:numel(names)
    data{n} = getWave(names{n},'data');
end

data = cell2mat(data(~isnan(waveID(:,2))));
waveID = waveID(~isnan(waveID(:,2)),:);

NC = max(waveID(:,2));
NR = max(waveID(:,3));

imag = zeros(size(data,2),NC,NR);
for r = 1:NR
    for c = 1:NC
        imag(:,c,r) = data(waveID(:,2)==c & waveID(:,3)==r, :);
    end
end



