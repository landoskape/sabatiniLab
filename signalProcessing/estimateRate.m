function rate = estimateRate(s)
% operates on columns if S is a matrix
% uses sparse matrices to help with space
% in practice, signals with more than 10000 points will be very burdensome

if size(s,1) == 1
    s = s(:);
end

N = size(s,1); % Number of points in signal
C = size(s,2); % Number of signals
idx = createShiftedIndexMatrix(N);

logDifferenceArrays = cell(1,C);
for c = 1:C
    csignal = s(:,c);
    N = length(csignal); 
    dMatrix = nan(N); 
    for n = 1:N-2
        cidx = ~isnan(idx(:,n+1));
        dMatrix(cidx,n) = s(idx(cidx,n+1)) - s(idx(cidx,1));
    end
    
    clda = sparse(N,N,N);
    for t = 1:N-2
        for dt = 1:N-2
            for ddtt = 1:N-2
                clda(t,dt,ddtt) = dMatrix(t,dt) - dMatrix(t+ddtt,dt);
            end
        end
    end
        
    dmat = [];
    dmat = differenceMatrix(csignal);
end



function dMatrix = differenceMatrix(s,idx)
N = length(s); 
dMatrix = nan(N); 
for n = 1:N-2
    cidx = ~isnan(idx(:,n+1));
    dMatrix(cidx,n) = s(idx(cidx,n+1)) - s(idx(cidx,1));
end

function lda = logDifferenceArray(dMatrix,idx)
lMatrix = log(dMatrix);
N = size(lMatrix,1);
lda = sparse(N-1);
for n = 1:N-2
    



function idx = createShiftedIndexMatrix(N)
% the for loop is faster than repmat
% idx = repmat(1:N,N,1)+repmat((0:N-1)',1,N); idx(idx>N-1)=nan;
idx = zeros(N-1);
for n = 1:N-1
    idx(1:N-1-n+1,n)=n:N-1;
end
idx = sparse(idx);






