function zp = zproj(A)
% zp = zproj(A)
% zproj takes the z-projection of 3dimensional array A
% right now it only does maximum z-projection
% will code in a switch statement to do other kinds of projections

zp = max(A,[],3);




