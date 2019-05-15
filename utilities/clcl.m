function clcl(varargin)

if nargin==0
    clearvars -global;
    evalin('base','clearvars');
    clc;
    return
end

if nargin==1 && isnumeric(varargin{1})
    switch varargin{1}
        case 1
            clearvars -global;
            clc;
        case 2
            evalin('base','clearvars');
            clc;
    end
else
    listOfVars = sprintf('''%s'',',varargin{:});
    listOfVars = listOfVars(1:end-1);
    evalin('base',['clearvars(''-except'',',listOfVars,')']); % - can be a cell array of names, or list of nargin=N that is expanded
    clc;
end



