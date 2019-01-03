


[~,~,xls] = xlsread(fullfile(dbFolder,'database.xlsx'),'CellDatabase'); % get cell data

strfmt = '%d %s %d %d %d %s %d %d %s %s %s %d';
fid = fopen(fullfile(dbFolder,'database.xlsx'),'r');
ts = textscan(fid,strfmt);
fclose(fid);


















