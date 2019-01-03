function der = fivePointDer(f, h)
% conventional five-point stencil derivative estimation
% f'(x) = (-f(x+2h) + 8f(x+h) -8f(x-h) + f(x-2h)) / 12h;
% deals with edge effects by ignoring the edges
% shift determined by h

if (nargin < 2)
    h = 1;
end

D = ndims(f);
if (D > 2)
    error('fivePointDer can''t do 3 dimensional arrays');
end
if (round(h) ~= h) || h<1
    error('h must be a positive integer');
end

NT = size(f,1);
NC = size(f,2);
der = zeros(NT-h*4, NC);
for c = 1:NC
    for t = 1:NT-h*4
        ct = t+h*2; % index of f
        der(t,c) = (-f(ct+2*h,c) + 8*f(ct+h,c) - 8*f(ct-h,c) + f(ct-2*h,c)) / 12*h;
    end
end


