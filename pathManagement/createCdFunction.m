function fullFileName = createCdFunction(functionName,pathName,targetDirectory)
% creates standard cdPath function
% functionName: defines the name of the function (e.g. cdThisPath) and
%               defines name of pathName if not given
%               if functionName is fullpath, then makes function there
% pathName: name of pathVariable within function (does little)
% targetDirectory: defines name of path that new function cd's to.
%                  defaults to (1) full path of functionName
%                              (2) current directory
%
% if you want to define a functionDirectory but default pathName, set
%   'pathName = []';
%
% Andrew Landau - November 2018


% Check input arguments
[pathstr,name,~] = fileparts(functionName);

% Make function name into 
fname = name;
fname = fname(fname ~= ' ' & fname ~= 0);
if length(fname)>2
    if strcmp(fname([1 2]),'cd')
        fname = strcat(lower(fname(3)),fname(4:end)); % make sure it's camelCase
    end
end

% use conventional nomenclature - "cdCamelCase"
functionName = strcat('cd',upper(fname(1)),fname(2:end));

% Make sure there is a path name
if (nargin < 2)
    pathName = fname;
end
if isempty(pathName)
    pathName = fname;
end

% Make sure there is a function directory
if isempty(pathstr)
    if (nargin < 3)
        % Define path as current directory automatically
        targetDirectory = pwd;
        pathstr = pwd;
    else
        % Save path 
        pathstr = targetDirectory;
    end
end

% Make function name / check existence
fullFileName = fullfile(pathstr,strcat(functionName,'.m'));
if exist(fullFileName,'file')
    questTxt = sprintf('The defined filename: %s already exists... rename?',fullfile('*',functionName));
    response = questdlg(questTxt,'Overwrite?','Overwrite','Abort','Abort');
    if strcmp(response,'Abort')
        fprintf('Aborted.\n');
        return
    end
end

% Now make function
fid = fopen(fullFileName,'w+');

[~,NL] = getFunctionLine(1,functionName,pathName,targetDirectory);
for line = 1:NL
    fline = getFunctionLine(line,functionName,pathName,targetDirectory);
    fprintf(fid, fline);
    fprintf(fid, '\n');
end

fclose(fid);

matlab.desktop.editor.Document.openEditor(fullFileName);

if (nargout == 0)
    clear newFunctionName
end


% It wasn't necessary to do this but I wanted to so the main function was clean
function [fline,numberOfLines] = getFunctionLine(line,functionName,pathName,targetDirectory)
functionLines = { ...
    sprintf('function %s = %s()\n',pathName,functionName);
    sprintf('%s = ''%s'';\n',pathName,targetDirectory);
    'if nargout'
    '\treturn'
    'end\n'
    sprintf('cd(%s);',pathName);
    sprintf('clear %s',pathName);};

numberOfLines = numel(functionLines);
if line > numberOfLines
    fline = nan;
    return
end
fline = functionLines{line};
 

