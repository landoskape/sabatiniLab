function xfile(file)
% simple version of getXFile
% must be in the current path of the desired xfile
% file must be from {'state','data','meta','exp'};

cload = load(fullfile(cd,'xfiles.mat'));
xfile = cload.(file);

assignin('base',file,xfile);
