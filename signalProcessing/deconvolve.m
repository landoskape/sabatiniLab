% function output = deconvolve(ir,sig)

boxWidth = 3;

irSig = ap ./ 1.6;
tgSig = glu ./ 1.6; % target signal
tgSig2 = both ./ 1.6;

[~,pk] = max(irSig);  
irBase = mean(irSig(10:49));  

ir = irSig(pk:end) - irBase;  
irX = 0:2:2*length(ir)-2;  
 
f = fit(irX(:),ir(:),'exp1');  
tc = -1/f.b;  

xVal = (0:2:2*length(tgSig)-2);
irFit = f.a * exp(f.b * xVal);

irFFT = fft(irFit);

boxKernel = ones(1,boxWidth) / boxWidth; % n-point boxcar kernel
irSmooth = conv(irSig,boxKernel,'same');
irSmFFT = fft(irSmooth);

ogIrFFT = (irSmFFT .* conj(irFFT)) ./ (irFFT .* conj(irFFT));
ogIrSig = ifft(ogIrFFT);

%% Just GLU
tgBase = mean(tgSig(10:49));
tgSig(50) = tgBase;
tgSmooth = conv(tgSig, boxKernel, 'same');

tgFFT = fft(tgSmooth);

ogFFT = (tgFFT .* conj(irFFT)) ./ (irFFT .* conj(irFFT));
ogSig = ifft(ogFFT);


%% Glu+AP

tg2Base = mean(tgSig2(10:49));
tgSig2(50) = tg2Base;
boxKernel = ones(1,boxWidth) / boxWidth; % n-point boxcar kernel
tg2Smooth = conv(tgSig2, boxKernel, 'same');

tg2FFT = fft(tg2Smooth);

og2FFT = (tg2FFT .* conj(irFFT)) ./ (irFFT .* conj(irFFT));
og2Sig = ifft(og2FFT);


%% Synthetic

synSig = tgSig + tgSig2 - tgBase;
synBase = mean(synSig(10:49));
synSig(50) = synBase;
boxKernel = ones(1,boxWidth) / boxWidth; % n-point boxcar kernel
synSmooth = conv(synSig, boxKernel, 'same');

synFFT = fft(synSmooth);

ogSynFFT = (synFFT .* conj(irFFT)) ./ (irFFT .* conj(irFFT));
ogSynSig = ifft(ogSynFFT);


%% Plot
callFigs;

subplot(3,2,1);
hold on;
plot(xVal, irSig);
plot(xVal, irSmooth,'r');
plot(xVal(pk:end), irBase + irFit(1:end-pk+1),'k');
yMin = -1.2*abs(min(irSig(10:end)));
yLim = ylim;
ylim([yMin yLim(2)]);
xlabel('Time');
ylabel('G/G_{max}');
title('Single AP response');
set(gca,'fontsize',16);

subplot(3,2,3);
plot(xVal, tgSig);
yMin = -1.2*abs(min(tgSig(10:end)));
yLim = ylim;
ylim([yMin yLim(2)]);
xlabel('Time');
ylabel('G/G_{max}');
title('Uncaging response');
set(gca,'fontsize',16);

subplot(3,2,5);
hold on;
plot(xVal, tgSig2);
plot(xVal, synSig, 'r');
yMin = -1.2*abs(min(cat(2,tgSig2(10:end),synSig(10:end))));
yLim = ylim;
ylim([yMin yLim(2)]);
xlabel('Time');
ylabel('G/G_{max}');
title('Glu + AP(+5ms) response');
set(gca,'fontsize',16);

subplot(3,2,2);
plot(xVal, ogIrSig);
xlim([50 200]);
xlabel('Time');
ylabel('Units : ???');
title('Impulse Response');
set(gca,'fontsize',16);

subplot(3,2,4);
plot(xVal, ogSig);
yMin = -1.2*abs(min(ogSig(10:end)));
xlim([50 200]);
yLim = ylim;
ylim([yMin yLim(2)]);
xlabel('Time');
ylabel('Calcium Input');
title('Deconvolved Uncaging Response');
set(gca,'fontsize',16);

subplot(3,2,6);
hold on;
plot(xVal, og2Sig);
plot(xVal, ogSynSig,'r');
xlim([50 200]);
yMin = -1.2*abs(min(cat(2,og2Sig(10:end),ogSynSig(10:end))));
yLim = ylim;
ylim([yMin yLim(2)]);
xlabel('Time');
ylabel('Calcium Input');
title('Deconvolved Glu+AP Response');
set(gca,'fontsize',16);




