function s = notch60(s, Fs, order)

if (nargin < 3)
    order = 2;
end

d = designfilt('bandstopiir','FilterOrder',order, ...
               'HalfPowerFrequency1',59,'HalfPowerFrequency2',61, ...
               'DesignMethod','butter','SampleRate',Fs);

           
s = filtfilt(d,s);


