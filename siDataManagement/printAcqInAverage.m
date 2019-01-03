function printAcqInAverage(wnames, anames)

NW = length(wnames);
for w = 1:NW
    fprintf('Average: %s -- ',wnames{w});
    for a = 1:length(anames{w})
        fprintf('%d, ',acqNum(anames{w}(a)));
    end
    fprintf('\n');
end

