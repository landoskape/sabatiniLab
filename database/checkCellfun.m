
[~,~,cdata] = xlsread(fullfile(cdDB,'database.xlsx'),'CellDatabase'); % get cell data

idx = any(cellfun(@(c) all(~isnan(c)), cdata, 'uni', 1),2); % Not all nan rows
cdata = cdata(idx,:); % Get rid of empty rows
idx = any(cellfun(@(c) all(~isnan(c)), cdata, 'uni', 1),1); % Not all nan columns
cdata = cdata(:,idx); % Get rid of empty columns

cdata = cdata(2:end,:); % Get rid of header


%% - the long column -
hdata = cdata{1,10};

N = 100;
for n = 1:N
    items = strsplit(hdata,',');
    items = cellfun(@(c) c(c~=' '), items, 'uni', 0);
    items = cellfun(@(c) strsplit(c,':'),items,'uni',0);
end

T = 100;
for t = 1:T
    fast = strsplsim(hdata,',');
    fast = cellfun(@(c) c(c~=' '), fast, 'uni', 0);
    fast = cellfun(@(c) strsplsim(c,':'), fast, 'uni', 0);
end

