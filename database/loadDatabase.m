function dbs = loadDatabase(varargin)

db = cell(1,4); % dbNames = {'cellData','spineData','expProtocol','drugs'};
[~,~,db{1}] = xlsread(fullfile(dbFolder,'database.xlsx'),'CellDatabase'); % get cell data
[~,~,db{2}] = xlsread(fullfile(dbFolder,'database.xlsx'),'SpineDatabase'); % get spine data
[~,~,db{3}] = xlsread(fullfile(dbFolder,'database.xlsx'),'ExperimentProtocols'); % get spine data
[~,~,db{4}] = xlsread(fullfile(dbFolder,'database.xlsx'),'Drugs'); % get spine data

dbHeader = cell(1,4);
for d = 1:4
    idx = any(cellfun(@(c) all(~isnan(c)), db{d}, 'uni', 1),2); % Not all nan rows
    db{d} = db{d}(idx,:); % Get rid of empty rows
    idx = any(cellfun(@(c) all(~isnan(c)), db{d}, 'uni', 1),1); % Not all nan columns
    db{d} = db{d}(:,idx); % Get rid of empty columns
    
    dbHeader{d} = db{d}(1,:); % Header strings
    db{d} = db{d}(2:end,:); % Get rid of header
end

% Make list of unique cell IDs - check whether they're unique
cUID = getUID(db{1});
if ~isequal(cUID,unique(cUID))
    [~,idx] = unique(cUID);
    idxDuplicate = true(length(cUID),1);
    idxDuplicate(idx) = false;
    fprintf(2,'Duplicate found in CellDatabase:\n');
    fprintf(2,'%s\n',cUID{idxDuplicate});
    return
end

% Make list of spine UIDs - make sure they're in CellDatabases
sUID = getUID(db{2});
if any(~ismember(sUID,cUID))
    fprintf(2,'Spine UID found that isn''t present in CellDatabase:\n');
    fprintf(2,'%s\n',sUID(~ismember(sUID,cUID)));
    return
end

% Make database structure
NC = length(cUID);
dbs = struct(); % Preallocate
dbs(NC).uid = '';
for c = 1:NC
    % Load in cell data
    currentCell = dbProcessCellData(cUID{c},dbHeader{1},db{1}(c,:));
    flds = fields(currentCell);
    for f = 1:numel(flds)
        dbs(c).(flds{f}) = currentCell.(flds{f});
    end
    
    % Load in spine data
    spineData = dbProcessSpineData(dbHeader{2}, db{2}(strcmp(sUID,cUID{c}),:));
    NS = numel(spineData);
    for s = 1:NS
        dbs(c).spineData(s) = spineData(s);
    end
end



% ------- LOCAL FUNCTIONS ---------
function uid = getUID(db)
% returns uid: list of unique cellID strings and idx: db row to uid mapping
dates = db(:,1);
cid = db(:,2);
uid = cellfun(@(d,c) strcat(num2str(d),c),dates,cid,'uni',0);





