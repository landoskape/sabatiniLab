function makeBlank(epoch)

global exp meta
exp(epoch).epoch = epoch;
exp(epoch).type = 'blank';
exp(epoch).ename = meta.ename;
exp(epoch).meta = [];

