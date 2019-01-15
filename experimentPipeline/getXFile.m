function xfile = getXFile(pth,file)
% - rewriting - this used to check if variable already existed in global
% - this is simpler and just uses presence of nargout to optimize


if nargout==1
    cload = load(fullfile(pth,'xfiles.mat'));
    xfile = cload.(file);
else
    eval(['global ',file]); % open global variable
    if eval( ['~isempty(',file,')'] )
        fprintf(1,'overwriting %s in workspace...\n',file);
    end
    eval( [file, '=[];'] ); % (Re)initialize
    cload = load(fullfile(pth,'xfiles.mat')); %#ok learn eval dammit
    eval( [file, '=cload.', file,';'] ); % set variable
    clear cload
    evalin('base',['global ',file]); % Open global variable in workspace
end

