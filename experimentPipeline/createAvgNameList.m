function list = createAvgNameList(epoch,pulse,phChans,imChans,imROIs)

NP = numel(phChans);
NC = numel(imChans);
NR = numel(imROIs);
list = cell(1, NP + NC*NR);
for p = 1:NP
    list{p} = sprintf('AD%d_e%dp%davg',phChans(p),epoch,pulse);
end

for ic = 1:NC
    for ir = 1:NR
        idx = NR*(ic-1) + ir;
        list{NP+idx} = sprintf('e%dp%dc%dr%d_avg',epoch,pulse,imChans(ic),imROIs(ir));
    end
end

