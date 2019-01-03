function out = loadCell(varargin)

needOut = 0;
vars = {'meta','state','data','exp'};
if (nargin == 0)
    pth = cd;
elseif (nargin == 1)
    if any(strcmp(vars, varargin{1}))
        needOut = 1;
        pth = cd;
        var = varargin{1};
    else
        pth = varargin{1};
    end
elseif (nargin == 2)
    idxVar = cellfun(@(c) any(strcmp(c, vars)), varargin, 'uni', 1);
    var = varargin{idxVar};
    pth = varargin{~idxVar};
    needOut = 1;
else 
    error('Don''t understand inputs');
end


if ~exist(fullfile(pth,'xfiles.mat'),'file')
    fprintf('Cell files do not exist.\n');
    return
end

xfiles = load(fullfile(pth,'xfiles.mat')); 

if ~needOut
    for v = 1:length(vars)
        eval(['global ',vars{v}]);
        evalin('base',['global ',vars{v}]);
        eval([vars{v},'=xfiles.',vars{v},';']);
    end
end

if needOut
    out = xfiles.(var);
end
    
    

