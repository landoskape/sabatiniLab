


N = 100000;
x = randi(10,500,1);
clear y z zz

zz = cell(N,1);
tic
for n = 1:N
    zz{n} = funique(x);
end
toc

y = cell(N,1);
tic
for n = 1:N
    y{n} = unique(x);
end
toc


% diffIndexing is faster by 3x if already sorted
% funique faster by 2x only because it sorts first


