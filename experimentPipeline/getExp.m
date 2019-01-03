function getExp(pth)

if (nargin == 0), pth = cd; end

files = {'meta','state','data','exp'};
for f = 1:length(files)
    getXFile(pth,files{f});
end

