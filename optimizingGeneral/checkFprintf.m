

N = 1000;
clear n k

tic
for n = 1:N 
    fprintf('hi'); clc
end
toc

tic
for k = 1:N
    fprintf(1,'hi'); clc
end
toc

% including first argument specifying target location is slightly faster



