function [state,erThread] = retState(fpath)

fid = fopen(fpath);
frewind(fid); % Make sure it starts at beginning

st = textscan(fid,'%s','Delimiter','\n');
st = st{1};

nline = size(st,1);

state = struct(); % Initialize struct

% erThread keeps track of lines that didn't work
erThread = cell(nline,1);
erNum = 0;

% Evaluate each line. Should be strings that create state struct naturally
for ln = 1:nline
    try
        eval(st{ln});
    catch m
        erNum = erNum + 1;
        erThread{erNum} = {erNum, st{ln}, m}; % Add error #, line that didn't work, and error message
    end
end
erThread(erNum+1:end) = [];






