function num = zpadNum(num, len, out)

if nargin < 2
    len = 3;
    out = 0;
elseif nargin < 3
    out = 0;
end

str = num2str(num);
num = strcat(repmat('0',1, len-length(str)), str);

if out
    num = str2double(num);
end


