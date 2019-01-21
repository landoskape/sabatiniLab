function array = dsarray(array,dsfactor)
% array must be a N x M x 1 dimensional array where N is the dimension to
% downsample on.
% dsfactor must be a integer factor of N

N = size(array,1);
M = size(array,2);

arr1 = permute(array,[3 1 2]);
arr2 = reshape(arr1, dsfactor, N/dsfactor, M);
arr3 = mean(arr2,1);
array = permute(arr3, [2 3 1]);


