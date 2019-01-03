function aname = makeAverageName(aID)
% aID = average ID
% aID(1) = epoch
% aID(2) = pulse
% 
% makes string with '*' if info not given
% inputs must be numbers
% to provide pulse only, make aID(1)=nan


if any(ischar(aID))
    fprintf(1, 'must provide numeric inputs\n');
    return;
end

if numel(aID) == 1
    epoch = num2str(aID);
    pulse = '*';
elseif numel(aID) == 2
    if isnan(aID(1))
        epoch = '*';
        pulse = num2str(aID(2));
    else
        epoch = num2str(aID(1));
        pulse = num2str(aID(2));
    end
else
    fprintf(1,'aID must be 1 or 2 numeric elements\n');
    return
end

aname = sprintf('e%sp%s',epoch,pulse);

    
    
    
