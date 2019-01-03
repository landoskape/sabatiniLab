N = 4000;

idx = nan(N);
idx = repmat(1:N,N,1) + repmat((0:N-1)',1,N);
idx(idx > N-1) = nan;
withoutFor = toc(t);

idx1 = nan(N);
for n = 1:N
    idx1(1:N-1-n+1,n)=n:N-1;
end


