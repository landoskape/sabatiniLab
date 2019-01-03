function dcode = dateCode()
% creates 6-digit date code string YYMMDD

% i feel like this could be better...
% this is why I hid it behind a little function
% don't look at me
%
% i'm embarrassed

c = clock;
y = c(1)-2000;
m = c(2);
d = c(3);


dcode = '000000';
dcode((1:length(num2str(y)))+2-length(num2str(y))) = num2str(y);
dcode(2+(1:length(num2str(m)))+2-length(num2str(m))) = num2str(m);
dcode(4+(1:length(num2str(d)))+2-length(num2str(d))) = num2str(d);

