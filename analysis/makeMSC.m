function msc(dpath,efold,dstr)

id = 'MSC';
ename = strcat('ATL',dstr);

%% Move data to experiment folder
dcontents = dir(dpath);  dcontents = dcontents(3:end);
econtents = dir(efold);  econtents = econtents(3:end);
dnames = {dcontents(:).name}';
enames = {econtents(:).name}';

datl = dnames(cellfun(@(c) contains(c,'ATL'), dnames, 'uni', 1));
eatl = enames(cellfun(@(c) contains(c,'ATL'), enames, 'uni', 1));

if ~isequal(datl,eatl)
    copyfile(fullfile(dpath,'ATL*'),efold);
end 

%% Look through txt files and create state structs
stnames = retdir([],'.txt',efold,1); 
nfiles = length(stnames);
stfiles = cell(nfiles,1);
state = struct(); %#ok
for n = 1:nfiles
    fid = fopen(stnames{n});
    stfiles{n} = textscan(fid,'%s','delimiter','\n');
    fclose(fid);
    
    lstate = length(stfiles{n});
    for lst = 1:lstate
        eval([sprintf('state(%d).',n),stfiles{n}{lst}(7:end)]);
    end
end




