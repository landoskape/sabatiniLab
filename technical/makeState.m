function state = makeState(headerString)

if isfield(headerString,'UserData') && isfield(headerString.UserData,'headerString')
    headerString = headerString.UserData.headerString;
    stateStrings = splitlines(headerString);
elseif exist(headerString,'file')
    [pathstr,name,ext] = fileparts(headerString);
    if isempty(pathstr), pathstr = pwd; end % default is working directory
    if isempty(ext), ext = '.txt'; end 

    fid = fopen(fullfile(pathstr,[name,ext]),'r');
    stateStrings = textscan(fid,'%s','Delimiter','\n');
    stateStrings = stateStrings{1};
    fclose(fid);
elseif ischar(headerString)
    stateStrings = splitlines(headerString);
else
    error('input must be wave with headerString, filePath to hdr.txt file, or headerString as char...');
end

lstate = length(stateStrings);

state = struct();
for lst = 1:lstate
    if isempty(stateStrings{lst}), continue; end
    cString = stateStrings{lst}(7:end);
    eqidx = strfind(cString,'=');
    name = cString(1:eqidx(1)-1);
    post = cString(eqidx(1)+1:end);
    if ~isempty(post) && strcmp(post(end),','), post = post(1:end-1); end % comma generates output to workspace and is unnecessary
    if isempty(post), post = '[]'; end
    
    % Make sure eval command is rendered correctly
    if ~fcontains(post,',')
        eval(strcat('state.',name,'=',post,';')); 
    else
        % lists of numbers are delimited by commas in headerString
        postElements = strsplsim(post,',');
        eval(strcat('state.',name,'=',strcat('[',sprintf('%s ',postElements{:}),']'),';'));
    end
end

