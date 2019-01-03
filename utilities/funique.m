function uniqArray = funique(array)
% 3x faster than unique, turns non vectors into vectors
sortArray = sort(array);
uniqArray = sortArray([logical(diff(sort(array(:))));true]); 
