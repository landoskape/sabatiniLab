function y = smoothsmooth(data,kernel)
y = smooth(flipud(smooth(flipud(data),kernel)),kernel);