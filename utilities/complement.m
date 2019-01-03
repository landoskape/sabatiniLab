function Ac = complement(A,idx)
% Return elements of A not indexed by idx
% Essentially A(~idx) when idx is a numeric array instead of a logical 

Ic = true(numel(A),1);
Ic(idx) = false;

Ac = A(Ic);  

