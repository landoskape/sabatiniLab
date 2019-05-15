function assertPath(pth)
if ~strcmp(pth,pwd)
    cd(pth);
end