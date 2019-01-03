
profile on
N = 10000;

clear y
clear x

left = zeros(50,1);
right = zeros(50,1);

tic
y = cell(N,1);
for j = 1:N
    y{j} = [left, right];
end
toc

tic
x = cell(N,1);
for i = 1:N
    x{i} = cat(2, left, right);
end
toc


profile viewer








