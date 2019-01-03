function imag = compileImag(names,wID)
% waves from names need to be loaded as global variables

% Number of averages
NA = length(names);
NC = 2; % number of channels
NR = 2; % number of ROIs

imag = cell(1,NA);
cCount = zeros(1,NA);
rCount = zeros(1,NA);
for a = 1:NA
    cCount(a) = max(wID{a}(:,2));
    rCount(a) = max(wID{a}(:,3));
    
    temp = cell(1,NC,NR);
    for c = 1:cCount(a)
        for r = 1:rCount(a)
            cdata = getfield(names{a}{wID{a}(:,2)==c & wID{a}(:,3)==r},'data'); %#ok
            temp{1,c,r} = cdata(:);
        end
    end
    imag{a} = cell2mat(temp);
end
imag = cat(4,imag{:});




