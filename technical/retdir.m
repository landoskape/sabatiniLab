function fNames = retdir(prefix,suffix,retPath,fullPath)
% fNames = retdir(prefix,suffix,path)
%
% Retrieve all file names from either the current directory or a specified
% path that have a given prefix, suffix, or both. At least prefix or suffix
% is required. If retPath is empty, uses the current directory.
%
% fullPath is a boolean - true if should return full path.
%

if isempty(prefix) && isempty(suffix)
    error('At least one specification parameter is required.');
end

if ~isempty(prefix)
    if ~isa(prefix,'char')
        error('Prefix must be a string.');
    end
end

if ~isempty(suffix)
    if ~isa(suffix,'char')
        error('Suffix must be a string.');
    end
end

if nargin < 3
    fullPath = false;
    retPath = cd;
end
if nargin < 4
    fullPath = false;
end
if isempty(retPath)
    retPath = cd;
end

pathContents = dir(retPath); % Retrieve path contents
fileNames = pathContents(3:end); % Remove last/next 

fileNames = {fileNames(:).name}'; % Retrieve names

% aMURica
validPre = true(numel(fileNames),1);
validSuf = true(numel(fileNames),1);

if ~isempty(prefix)
    numCmp = length(prefix);
    % Which ones are long enough?
    validPre = cellfun(@(str) length(str)>numCmp, fileNames, 'uni', 1); 
    % Of those, which have valid prefix?
    validPre(validPre) = cellfun(@(str) strcmp(str(1:numCmp),prefix), fileNames(validPre), 'uni', 1);
end

if ~isempty(suffix)
    numCmp = length(suffix) - 1;
    % Same as for prefix.
    validSuf = cellfun(@(str) length(str)>numCmp, fileNames, 'uni', 1);
    validSuf(validSuf) = cellfun(@(str) strcmp(str(end-numCmp:end),suffix), fileNames(validSuf), 'uni', 1);
end

% Require both.
validNames = (validPre & validSuf);

% Return names.
fNames = fileNames(validNames);

if fullPath
    for file = 1:numel(fNames)
        fNames{file} = fullfile(retPath,fNames{file});
    end
end


