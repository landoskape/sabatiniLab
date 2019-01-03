function state = getState(dpath,dstr,cstr)
% dpath is the full path to the data
% dstr is a date string ('170710' means July, 10th 2017)
% cstr is a lower case letter indicating the cell ID

if isnumeric(dstr); dstr = num2str(dstr); end % Make sure dstr is char
id = 'cim';
ename = strcat('ATL',dstr,cstr);


%% Compile state struct
% Look through txt files and create state structs
stnames = retdir([],'.txt',dpath,1); 
nfiles = length(stnames);
stfiles = cell(nfiles,1);
state = struct();

fprintf('| %d files found. Working... ',nfiles);
cFileTimer = tic;
for n = 1:nfiles
    % Update screen
    if (n > 1), fprintf(repmat('\b',1,length(msg))); end
    msg = sprintf('compiling file %d / %d...',n,nfiles);
    fprintf(msg);
    
    fid = fopen(stnames{n});
    stfiles{n} = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
    stfiles{n} = stfiles{n}{1};
    
    lstate = length(stfiles{n});
    for lst = 1:lstate
        cString = stfiles{n}{lst}(7:end);
        eqidx = strfind(cString,'=');
        name = cString(1:eqidx(1)-1);
        post = cString(eqidx(1)+1:end);
        if isempty(post), post = '[]'; end
        eval(strcat(sprintf('state(%d).',n),name,'=',post,';'));
    end
end
fprintf(' finished compiling. %d seconds. \n',round(toc(cFileTimer)));
