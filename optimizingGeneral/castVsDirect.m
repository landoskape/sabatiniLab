

M = 50;
N = 1000;
data = rand(M,M,'double');
check = zeros(M,M,N,2);

tic
for n = 1:N
    check(:,:,n,1)=cast(data,'single');
end
toc

tic 
for n = 1:N
    check(:,:,n,2)=single(data);
end
toc




