function raxis = readableMolar(axis)

pows = log10(axis); % Convert to log10 axis
relabel = fliplr({'f','p','n','µ','m','M'}); % labels
repower = fliplr([15,12,9,6,3,0]); % multiply to convert to standard metric
index = ceil(-pows/3) + 1; % index 
index(index>length(repower))=length(repower); % if too small represent as femto

% Readable axis
raxis = cell(1,length(axis));
for t = 1:length(axis)
    readableValue = round(10*axis(t)*10^repower(index(t)))/10;
    readableString = num2str(readableValue);
    raxis{t} = sprintf('%s%sM',readableString,relabel{index(t)});
    if axis(t)==0
        raxis{t} = '0M';
    end
end





    
    



