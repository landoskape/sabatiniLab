function state = makeStateFromCell(cellPath)
% compile state struct from cell path, cell path should be full path,
% otherwise uses current directory

if (nargin < 1)
    cellPath = cd;
end

if ~exist(cellPath,'file')
    cellPath = cd;
end

% Look through txt files and create state structs
stnames = retdir([],'.txt',cellPath); 
nfiles = length(stnames); 
stfiles = cell(nfiles,1); 
state = struct(); 

fprintf('| %d files found... \n| compiling file ',nfiles);
cFileTimer = tic;
for n = 1:nfiles
    % Update screen
    if (rem(n,10)==0) || (n==nfiles)
    	if n>10, fprintf(repmat('\b',1,length(msg))); end
        msg = sprintf('%d / %d ...',n,nfiles);
        fprintf(msg);
    end
    
    fid = fopen(fullfile(cellPath,stnames{n}));
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
        if ~contains(post,',')
            evalc(strcat(sprintf('state(%d).',n),name,'=',post,';')); %evalc because sometimes it generates output for unknown reason. didn't investigate.
        else
            % lists of numbers are delimited by commas in headerString
            postElements = strsplit(post,',');
            evalc(strcat(sprintf('state(%d).',n),name,'=',strcat('[',sprintf('%s ',postElements{:}),']'),';'));
        end
    end
end
fprintf(' finished compiling. %d seconds. \n',round(toc(cFileTimer)));

