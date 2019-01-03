
N = 10000;
x = 1:1000;
divisor = 10;

clear y z
y = cell(N,1);
z = cell(N,1);

tic
for n = 1:N
    y{n} = x / (~divisor || divisor);
end
toc

tic
for n = 1:N
    if divisor > 0
        z{n} = x / divisor;
    else
        z{n} = x;
    end
end
toc


% despite my aesthetics the if statement is very slightly faster once compiled



