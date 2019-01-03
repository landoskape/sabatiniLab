

#pragma rtGlobals=1		// Use modern global access method.
#pragma rtGlobals=1		// Use modern global access method.
//#include "utilities"
//#include "averaging"
#include <decimation>
#include <Concatenate Waves>

function initMiniAnalysis()
	newNVAR("maLowPassCorner", 500)
	newNVAR("maHighPassCorner", 5)
	newNVAR("maTimeToTrim", 500)
	newNVAR("maWaveCounter", 1)
	newNVAR("maStartWave", 1)
	newNVAR("maEndWave", 1)
	
	newNVAR("maDecimation", 5)
	newSVAR("maWavePrefix", "")
	
	newNVAR("maBaselineStart", 0)
	newNVAR("maBaselineEnd", 100)
	
	newNVAR("maRiseSpacer", 0.4)
	newNVAR("maDecaySpacer", 1)
	newNVAR("maMinRiseTime", 0.5)
	newNVAR("maMinRiseRate", 4)
	newNVAR("maMinAmplitude", 0)
	
	newNVAR("maMinDecayTime",1)
	newNVAR("maMinDecayTau", 1)
	newNVAR("maMaxDecayTau", 10)

	newNVAR("maMaxRiseDecaySeparation", 2)
	
	newNVAR("maRCPulseAmp", -5)
	newNVAR("maRCPulseDuration", 200)
	newNVAR("maRCPulseStart", 150)
	
	newNVAR("maRS", 0)
	newNVAR("maRS2", 0)
	newNVAR("maCM", 0)
	newNVAR("maRM", 0)
	newNVAR("maRM2", 0)
	newNVAR("maRMS", 0)
	newNVAR("maBaseline", 0)
	
	newNVAR("maMiniRefractoryTime", 2)
	newNVAR("maPeakPreSearch", 2)
	newNVAR("maPeakPostSearch", 0.2)

	newNVAR("maAnalyzedIPSC", 0)
	
	if (~iswave("maRaw"))
		make /o/n=50000 maRaw
		SetScale/P x 0,0.1,"", maRaw
	endif
	duplicate /o maRaw maFiltered
	maRecalculateFilter()
	maResetParameterWaves()
	maResetAccumulatedSummary()
	maDisplayParameterWaves()
	make /o/n=0 maAvgMini, maAvgMini2, maNDAvgMini, maNDAvgMini
	execute "maControls()"
	
end

function maResetAccumulatedSummary()
	make /o/n=0 maAccumulatedAvgMini, maAccumulatedAvgMini2, maAccumulatedNDAvgMini, maAccumulatedNDAvgMini2
	make /o/n=0 maAccumulatedAmp_sort, maAccumulatedAmp_index, maAccumulatedAmp
	make /o/n=0 maAccumulatedIEI_sort, maAccumulatedIEI_index, maAccumulatedIEI
end

function maPick(nEvents)
	variable nEvents
	wave maAccumulatedAmp
	wave maAccumulatedIEI
	
	make /o/n=(nEvents) maPickedAmp, maPickedIEI
	duplicate /o maAccumulatedAmp, maTempIndex, maTemp2
	maTempIndex=gnoise(1)
	maTemp2=p
	sort maTempIndex, maTemp2
	maPickedAmp=maAccumulatedAmp[maTemp2[p]]
	maPickedIEI=maAccumulatedIEI[maTemp2[p]]
	edit maPickedAmp, maPickedIEI
	
end


//add reject line KT
function maResetParameterWaves()
	make /o/n=500/t maWaveNames
	maWaveNames=""
	make /o/n=500 maWaveRS
	maWaveRS=nan
	duplicate /o maWaveRS maWaveRM, maWaveRS2, maWaveRM2, maWaveCM, maWaveRMS, maWaveBaseline
	duplicate /o maWaveRS maWaveNEvents, maWaveEventAmpAvg, maWaveEventAmpSEM
	duplicate /o maWaveRS maWaveEventIEIAvg, maWaveEventIEISEM, maWaveAnalyzed
end

function maDisplayParameterWaves()

	edit  maWaveNames, maWaveAnalyzed, maWaveRS, maWaveRM, maWaveRS2, maWaveRM2, maWaveCM, maWaveRMS, maWaveBaseline, maWaveNEvents, maWaveEventAmpAvg, maWaveEventAmpSEM, maWaveEventIEIAvg, maWaveEventIEISEM
end


function /t maTraceName()
	nvar maWaveCounter
	svar maWavePrefix
	return maWavePrefix+num2str(maWaveCounter)
end


function maRecalculateFilter()
	WAVE maDisplayRaw
	
	duplicate /o maRaw maFilterFFT
	fft maFilterFFT
	redimension /r maFilterFFT
	
	NVAR maLowPassCorner
	NVAR maHighPassCorner
	
	variable poles=4
	maFilterFFT=1/(1+((maHighPassCorner/1000)/x)^poles) * 1/(1+(x/(maLowPassCorner/1000))^poles) 
end

function maCalcBaseline()

	NVAR maBaselineStart
	NVAR maBaselineEnd
	NVAR maBaseline
	
	maBaseline=mean($maTraceName(), maBaselineStart, maBaselineEnd)
	
	return maBaseline
end

function maFilterData()

	wave wData=$maTraceName()
	
	nvar maTimeToTrim

	duplicate /o wData maRaw
	SetScale/P x 0, deltax(maRaw),"", maRaw
//	maRecalculateFilter()
	
	wave wFilt=$(nameofwave(wData)+"_filtered")
	nvar maDecimation
	if (maDecimation>1)
		make/o/n=(floor(numpnts(maRaw)/maDecimation)) $(nameofwave(wData)+"_filtered") 
		wave wFilt=$(nameofwave(wData)+"_filtered")
		SetScale/P x 0, maDecimation*deltax(maRaw), wFilt
		wFilt=mean(maRaw, x, x+(maDecimation-1)*deltax(maRaw))	
	else
		duplicate /o maRaw $(nameofwave(wData)+"_filtered") 
		wave wFilt=$(nameofwave(wData)+"_filtered")
	endif
	
	wFilt-=maCalcBaseline()
	deletepoints 0, x2pnt(wFilt, maTimeToTrim), wFilt

	NVAR maLowPassCorner
	NVAR maHighPassCorner
	variable lowN=deltax(wFilt)*maLowPassCorner/1000
	variable highN=deltax(wFilt)*maHighPassCorner/1000
	
	filterfir /LO={lowN, lowN*2, 101}/HI={highN/2, highN, 101} wFilt
	wFilt*=1

	if (deltax(wFilt)<1)
		variable decRatio=round(1/deltax(wFilt))	
		make/o/n=(floor(numpnts(wFilt)/decRatio)) maBottom
		SetScale/P x 0, decRatio*deltax(wFilt), maBottom
		maBottom=mean(wFilt, x, x+(decRatio-1)*deltax(wFilt))
	else
		duplicate /o wFilt maBottom
	endif
	sort maBottom, maBottom	
	variable offset=mean(maBottom, rightx(maBottom)*0.95, inf)
	wFilt-=offset
	
	SetScale/P x -maTimeToTrim,deltax(maRaw),"", maRaw, $maTraceName()
	duplicate /o wFilt maFiltered
	
	wave maWaveAnalyzed
	nvar maWaveCounter
	
	maWaveAnalyzed[maWaveCounter] = 0
	
end

function maProcessFiltered()
	wave wFilt=$(maTraceName()+"_filtered")
	
	nvar maRiseSpacer
	nvar maDecaySpacer
	nvar maMaxRiseDecaySeparation
	
	variable separationPts=round(maMaxRiseDecaySeparation/deltax(wFilt))
	make /o/n=(2*separationPts) sepKernal
	sepKernal=0
	sepKernal[0, separationPts-1]=1/separationPts
	
	duplicate /o wFilt maDisplayFiltered
	duplicate /o wFilt maRatio, maDiff, maDiff2
	maRatio=wFilt(x+maDecaySpacer)/wFilt
	maDiff2=(wFilt-wFilt(x+maDecaySpacer))/maDecaySpacer
	maDiff=(wFilt-wFilt(x-maRiseSpacer))/maRiseSpacer
	duplicate /o maDiff maRise
	nvar maAnalyzeIPSCs
	if (~maAnalyzeIPSCs)
		maRise*=-1
	endif
	maRise*=maRise>0
	duplicate /o maRise maRiseCont
	
	variable counter
	nvar maMinRiseTime
	variable trendPoints=round(maMinRiseTime/deltax(wFilt))

	for (counter=1; counter<trendPoints; counter+=1)
		maRiseCont*=maRise[p-counter]
	endfor
	maRiseCont=maRiseCont^(1/trendPoints)
	
	nvar maMinRiseRate
	duplicate /o maRiseCont maRiseContThresh
	maRiseContThresh*=maRiseCont>maMinRiseRate

	nvar maMinDecayTime
	trendPoints=round(maMinDecayTime/deltax(wFilt))
	duplicate /o maRatio maDecay
	maDecay*=(maRatio>=0)*(maRatio<1)*(maDiff2<0)
	duplicate /o maDecay maDecayCont

	for (counter=1; counter<trendPoints; counter+=1)
		maDecayCont*=maDecay[p+counter]
	endfor
	maDecayCont=maDecayCont^(1/trendPoints)
	duplicate /o maDecayCont maDecayTauCont
	maDecayTauCont=-maDecaySpacer/ln(maDecayCont)

	nvar maMinDecayTau
	nvar maMaxDecayTau
	duplicate /o maDecayTauCont maDecayTauContThresh
	maDecayTauContThresh*=(maDecayTauCont>maMinDecayTau)*(maDecayTauCont<maMaxDecayTau)
	duplicate /o maDecayTauContThresh maDecayStart
//	maDecayStart=(maDecayTauContThresh>0)&&(maDecayTauContThresh[p-1]==0)
	
	duplicate /o maRiseContThresh maRiseContThreshStretch
	convolve sepKernal, maRiseContThreshStretch
	duplicate /o maRiseContThreshStretch maEvents
//	maEvents=(maRiseContThreshStretch>0.1)*maDecayStart
	maEvents=(maRiseContThreshStretch>0.1)*(maDecayTauContThresh>0)
	maEvents=(maEvents>0)&&(maEvents[p-1]==0)
	
	duplicate /o maEvents $(maTraceName()+"_Events")
	NVAR maMiniRefractoryTime
	NVAR maPeakPreSearch
	NVAR maPeakPostSearch
//	edited 2/12/10
	make /o/n=0 maRiseStarts
	findlevels /q/p/d=maRiseStarts/EDGE=1/m=2 maRiseContThresh, maMinRiseRate
	maRiseStarts=deltax(wFilt)*floor(maRiseStarts-1)
	make /o/n=0 maEventStarts
	findlevels /q/d=maEventStarts/EDGE=1/m=2 maEvents, 0.5
	
	make /o/n=(3*numpnts(maEventStarts)) maEventX, maEventY
	maEventX=NaN
	maEventY=NaN

	make /o/n=(ceil(30/deltax(wFilt))) $(maTraceName()+"_am"), $(maTraceName()+"_am2")
	
	wave aMini=$(maTraceName()+"_am")
	wave aMini2=$(maTraceName()+"_am2")
	SetScale/P x 0,deltax(wFilt),"", aMini, aMini2
	aMini=0
	aMini2=0
		
	wave maRaw
	make /o/n=(ceil(30/deltax(maRaw))) $(maTraceName()+"_ndam"), $(maTraceName()+"_ndam2")
	
	wave andMini=$(maTraceName()+"_ndam")
	wave andMini2=$(maTraceName()+"_ndam2")
	SetScale/P x 0,deltax(maRaw),"", andMini, andMini2
	andMini=0
	andMini2=0

	make /o/n=0 $(maTraceName()+"_amps")
	make /o/n=0 $(maTraceName()+"_ieis")
	wave amps=$(maTraceName()+"_amps")
	wave ieis=$(maTraceName()+"_ieis")

	nvar maMinAmplitude
	
	variable lastMin=0	
	variable lastMax=0	
	variable last=0
	nvar maMiniRefractoryTime
	
	variable found_v_min
	variable found_v_minloc
	variable maSearchStart
	
	for (counter=0; counter<numpnts(maEventStarts); counter+=1)
		findlevel /q/p maRiseStarts, maEventStarts[counter]
		if (v_flag==1)
			maSearchStart=maEventStarts[counter]-maPeakPreSearch
		else
			maSearchStart=min(maRiseStarts[floor(v_levelx)]-maPeakPreSearch, maEventStarts[counter]+maPeakPostSearch)
		endif
//		variable maSearchStart=maEventStarts[counter]-maPeakPreSearch

		wavestats /q/r=(maSearchStart, maEventStarts[counter]+maPeakPostSearch) wFilt
//print counter, maEventStarts[counter], maSearchStart, v_max, v_min, v_maxloc, v_minloc
		found_v_min=v_min
		found_v_minloc=v_minloc
//		wavestats /q/r=(found_v_minloc-maPeakPreSearch, found_v_minloc) wFilt
		wavestats /q/r=(maSearchStart, found_v_minloc) wFilt
		v_min=found_v_min
		v_minloc=found_v_minloc

		if ((v_max-v_min)>maMinAmplitude)
			if (((v_maxloc-lastMax)>maMiniRefractoryTime) && ((v_minloc-lastMax)>maMiniRefractoryTime) && ((v_maxloc-lastMin)>maMiniRefractoryTime) && ((v_minloc-lastMin)>maMiniRefractoryTime))
				maEventX[counter*3+1]=v_minloc
				maEventX[counter*3+2]=v_maxloc
					
				maEventY[counter*3+1]=v_min
				maEventY[counter*3+2]=v_max
		
				if (counter>1)
					addto(ieis, v_minloc-last)
					last=v_minloc
				endif
					
				aMini+=wFilt(x+maEventStarts[counter]-5)
				andMini+=maRaw(x+maEventStarts[counter]-5)
				addto(amps, v_max-v_min)
				
				aMini2+=wFilt(x+v_minloc-5)
				andMini2+=maRaw(x+v_minloc-5)
			endif
			lastMin=v_minloc
			lastMax=v_maxloc
				
		endif
	endfor
	
	duplicate /o maEventX $(maTraceName()+"_eventX")
	duplicate /o maEventY $(maTraceName()+"_eventY")
	
	wavestats /q amps
	wave maWaveNEvents
	nvar maWaveCounter
	
	maWaveNEvents[maWaveCounter]=v_npnts
	aMini2/=v_npnts
	aMini/=v_npnts
	aNDMini2/=v_npnts
	aNDMini/=v_npnts

	duplicate /o aMini maAvgMini
	duplicate /o aMini2 maAvgMini2
	duplicate /o aNDMini maNDAvgMini
	duplicate /o aNDMini2 maNDAvgMini2
		
	wave maWaveEventAmpAvg
	maWaveEventAmpAvg[maWaveCounter]=v_avg
	wave maWaveEventAmpSEM
	maWaveEventAmpSEM[maWaveCounter]=v_sdev/sqrt(v_npnts)
	
	wavestats /q ieis
	wave maWaveEventIEIAvg
	maWaveEventIEIAvg[maWaveCounter]=v_avg
	wave maWaveEventIEISEM	
	maWaveEventIEISEM[maWaveCounter]=v_sdev/sqrt(v_npnts)
	
	wave maWaveAnalyzed
	maWaveAnalyzed[maWaveCounter]=1
	
	duplicate /o amps $(nameofwave(amps)+"_index")
	wave ind=$(nameofwave(amps)+"_index")
	ind=p/numpnts(amps)
	duplicate /o amps $(nameofwave(amps)+"_sort")
	sort $(nameofwave(amps)+"_sort"), $(nameofwave(amps)+"_sort")
	
	duplicate /o $(nameofwave(amps)+"_index") maAmp_index
	duplicate /o $(nameofwave(amps)+"_sort") maAmp_sort

	duplicate /o ieis $(nameofwave(ieis)+"_index")
	wave ind=$(nameofwave(ieis)+"_index")
	ind=p/numpnts(ieis)
	duplicate /o ieis $(nameofwave(ieis)+"_sort")
	sort $(nameofwave(ieis)+"_sort"), $(nameofwave(ieis)+"_sort")

	duplicate /o $(nameofwave(ieis)+"_index") maIEI_index
	duplicate /o $(nameofwave(ieis)+"_sort") maIEI_sort

	maFlipCounter()
	doupdate
end





function maLoadone()

	string fullNewName=maTraceName()
	if (~exists(fullNewName))
		string wn=fullNewName+".itx"
		print "loading "+wn+" from disk..."
		loadwave /t/o/p=incoming wn
	endif
end



function cumm(whis)
	wave whis
	
	duplicate/o whis $(nameofwave(whis)+"c")
	wave wcum=$(nameofwave(whis)+"c")
	
	wcum=0
	variable i=0,s=0
	
	do
		s+=whis[i]
		wcum[i+1]=s	
		i+=1
	while (i<numpnts(whis))
	wcum/=s
	SetScale d -32000,32000,"", wcum
end


function maFlipCounter()

	if (exists(maTraceName()))
		duplicate /o $maTraceName() maRaw
	else
		make /o/n=0 maRaw
	endif
	if (exists(maTraceName()+"_filtered"))
		duplicate /o $(maTraceName()+"_filtered") maFiltered
	else
		make /o/n=0 maFiltered
	endif
	if (exists(maTraceName()+"_am"))
		duplicate /o $(maTraceName()+"_am") maAvgMini
	else
		make /o/n=0 maAvgMini
	endif
	if (exists(maTraceName()+"_am2"))
		duplicate /o $(maTraceName()+"_am2") maAvgMini2
	else
		make /o/n=0 maAvgMini2
	endif
	if (exists(maTraceName()+"_ndam"))
		duplicate /o $(maTraceName()+"_ndam") maNDAvgMini
	else
		make /o/n=0 maNDAvgMini
	endif
	if (exists(maTraceName()+"_ndam2"))
		duplicate /o $(maTraceName()+"_ndam2") mandAvgMini2
	else
		make /o/n=0 mandAvgMini2
	endif
	if (exists(maTraceName()+"_eventX"))
		duplicate /o $(maTraceName()+"_eventX") maEventX
	else
		make /o/n=0 maEventX
	endif
	if (exists(maTraceName()+"_eventY"))
		duplicate /o $(maTraceName()+"_eventY") maEventY
	else
		make /o/n=0 maEventY
	endif
	if (exists(maTraceName()+"_Events"))
		duplicate /o $(maTraceName()+"_Events") maEvents
	else
		make /o/n=0 maEvents
	endif
	if (exists(maTraceName()+"_amps"))
		duplicate /o $(maTraceName()+"_amps_sort") maAmp_sort
		duplicate /o $(maTraceName()+"_amps_index") maAmp_index
	else
		make /o/n=0 maAmp_sort, maAmp_index
	endif
	if (exists(maTraceName()+"_ieis"))
		duplicate /o $(maTraceName()+"_ieis_sort") maIEI_sort
		duplicate /o $(maTraceName()+"_ieis_index") maIEI_index
	else
		make /o/n=0 maIEI_sort, maIEI_index
	endif
end





Window maControls() : Panel
	PauseUpdate; Silent 1		// building window...
	NewPanel /W=(903,88,1484,405)
	SetDrawLayer UserBack
	SetDrawEnv fstyle= 1
	DrawText 210,163,"Graphs/Tables"
	SetVariable setvar1,pos={217,31},size={150,16},proc=waveCounterProc,title="Wave # "
	SetVariable setvar1,format="%g",value= maWaveCounter
	SetVariable setvar2,pos={3,40},size={200,16},title="Rise Trend Spacer"
	SetVariable setvar2,help={"The deltaT used to find strectches of rising or falling currents"}
	SetVariable setvar2,format="%g ms",limits={0,inf,0.1},value= maRiseSpacer
	SetVariable setvar3,pos={3,57},size={200,16},title="Min Rising Time"
	SetVariable setvar3,help={"The minimum length of rising points to be considered the start of a mini"}
	SetVariable setvar3,format="%g ms",limits={0,inf,0.1},value= maMinRiseTime
	SetVariable setvar5,pos={4,136},size={200,16},title="Minimum Decay Tau"
	SetVariable setvar5,help={"Minimum time constant of decay for the mini "}
	SetVariable setvar5,format="%g ms",limits={0,inf,0.1},value= maMinDecayTau
	SetVariable setvar6,pos={4,120},size={200,16},title="Min Decay Time"
	SetVariable setvar6,help={"The minimum length of rising points to be considered the decay phase of a mini"}
	SetVariable setvar6,format="%g ms",limits={0,inf,0.1},value= maMinDecayTime
	SetVariable setvar7,pos={3,74},size={200,16},title="Min Rise Rate"
	SetVariable setvar7,help={"The minimum rate of rise of currents to be considered the start of a mini"}
	SetVariable setvar7,format="%g pA/ms",limits={0,inf,0.1},value= maMinRiseRate
	SetVariable setvar8,pos={4,178},size={200,16},title="Max Rise/Decay Sep"
	SetVariable setvar8,help={"The maximum time that can elapse between the end of a rising phase and start of decay phase"}
	SetVariable setvar8,format="%g ms"
	SetVariable setvar8,limits={0,inf,0.1},value= maMaxRiseDecaySeparation
	SetVariable setvar9,pos={4,213},size={200,16},title="Min Mini Amplitude"
	SetVariable setvar9,help={"Minimum amplitude to be considered a real event"}
	SetVariable setvar9,format="%g pA",limits={0,inf,0.1},value= maMinAmplitude
	SetVariable setvar0,pos={215,9},size={200,16},title="File Base Name"
	SetVariable setvar0,value= maWavePrefix
	SetVariable setvar10,pos={217,58},size={150,16},title="Starting Wave #"
	SetVariable setvar10,value= maStartWave
	SetVariable setvar11,pos={217,76},size={150,16},title="Ending Wave #"
	SetVariable setvar11,value= maEndWave
	SetVariable setLowPass,pos={59,280},size={150,16},proc=maRecalcFilterVar,title="low pass corner (Hz)"
	SetVariable setLowPass,limits={0,inf,1},value= maLowPassCorner
	SetVariable setHighPass,pos={59,298},size={150,16},proc=maRecalcFilterVar,title="high pass corner (Hz)"
	SetVariable setHighPass,limits={0,inf,1},value= maHighPassCorner
	SetVariable setTimeToTrimVar,pos={218,195},size={150,16},title="Start dead time"
	SetVariable setTimeToTrimVar,format="%g ms",value= maTimeToTrim
	SetVariable setvar12,pos={218,213},size={150,16},title="Baseline start (ms)"
	SetVariable setvar12,limits={0,inf,1},value= maBaselineStart
	SetVariable setvar13,pos={218,230},size={150,16},title="Baseline end (ms)"
	SetVariable setvar13,limits={0,inf,1},value= maBaselineEnd
	ValDisplay valdisp0,pos={215,250},size={120,15},title="Baseline (pA)"
	ValDisplay valdisp0,limits={0,0,0},barmisc={0,1000},value= #"maBaseline"
	SetVariable setvar07,pos={4,153},size={200,16},title="Max Decay Tau"
	SetVariable setvar07,help={"Maximum time constant of decay for the mini "}
	SetVariable setvar07,format="%g ms",limits={0,inf,1},value= maMaxDecayTau
	Button button0,pos={220,98},size={50,20},proc=filtOneButtonProc,title="Filter One"
	Button button1,pos={220,122},size={50,20},proc=filtAllButtonProc,title="Filter All"
	Button button2,pos={272,98},size={100,20},proc=findEventsOneButtonProc,title="Find Events One"
	Button button3,pos={272,122},size={100,20},proc=findEventsAllButtonProc,title="Find Events All"
	ValDisplay valdisp1,pos={340,249},size={100,15},title="Rm",format="%g MOhm"
	ValDisplay valdisp1,limits={0,0,0},barmisc={0,1000},value= #"maRM"
	ValDisplay valdisp2,pos={445,249},size={100,15},title="Rm2",format="%g MOhm"
	ValDisplay valdisp2,limits={0,0,0},barmisc={0,1000},value= #"maRM2"
	ValDisplay valdisp3,pos={341,268},size={100,15},title="Rs",format="%g MOhm"
	ValDisplay valdisp3,limits={0,0,0},barmisc={0,1000},value= #"maRS"
	ValDisplay valdisp4,pos={446,272},size={100,15},title="Rs2",format="%g MOhm"
	ValDisplay valdisp4,limits={0,0,0},barmisc={0,1000},value= #"maRS2"
	ValDisplay valdisp5,pos={340,287},size={100,15},title="Cm",format="%g pF"
	ValDisplay valdisp5,limits={0,0,0},barmisc={0,1000},value= #"maCM"
	ValDisplay valdisp6,pos={235,269},size={100,15},title="Irms",format="%g pA"
	ValDisplay valdisp6,limits={0,0,0},barmisc={0,1000},value= #"maRMS"
	SetVariable setvar4,pos={379,194},size={150,16},title="RC pulse amp"
	SetVariable setvar4,format="%g mV",value= maRCPulseAmp
	SetVariable setvar95,pos={379,211},size={150,16},title="RC pulse start"
	SetVariable setvar95,format="%g ms",value= maRCPulseStart
	SetVariable setvar96,pos={379,229},size={150,16},title="RC pulse dur"
	SetVariable setvar96,format="%g ms",value= maRCPulseDuration
	Button button4,pos={374,98},size={100,20},proc=calcParamsOneButtonProce,title="Calc Params One"
	SetVariable setvar14,pos={54,195},size={150,16},title="Mini Refractory"
	SetVariable setvar14,help={"Minimum time between minis"},format="%g ms"
	SetVariable setvar14,limits={0,inf,0.1},value= maMiniRefractoryTime
	SetVariable setvar15,pos={54,230},size={150,16},title="Pre peak search"
	SetVariable setvar15,help={"Time to search before mini detection time for min amp in peak calculation"}
	SetVariable setvar15,format="%g ms",limits={0,inf,0.1},value= maPeakPreSearch
	SetVariable setvar16,pos={55,247},size={150,16},title="Post peak search"
	SetVariable setvar16,help={"Time to search after mini detection time for max amp in peak calculation"}
	SetVariable setvar16,format="%g ms",limits={0,inf,0.1},value= maPeakPostSearch
	CheckBox check0,pos={24,2},size={93,14},title="Analyze IPSCs?"
	CheckBox check0,variable= maAnalyzeIPSCs
	Button button5,pos={374,122},size={100,20},proc=calcParamsAllButtonProce,title="Calc Params All"
	Button button6,pos={476,98},size={100,20},proc=doEverythingOneButtonProc,title="Do everything One"
	Button button7,pos={476,122},size={100,20},proc=doEverythingAllButtonProc,title="Do everything All"
	Button button8,pos={233,168},size={60,20},proc=ButtonProc_3,title="See Events"
	Button button9,pos={298,168},size={50,20},proc=ButtonProc_4,title="Summary"
	Button button10,pos={387,32},size={50,20},proc=marejectAnaProc,title="reject"
	Button maButton99,pos={352,168},size={80,20},proc=maAccSummaryProc,title="Acc Summary"
	Button button11,pos={442,169},size={100,20},proc=maResetAccumProc,title="Reset Accum Stats"
	Button button11,help={"Reset Accumulated Statistics"}
	Button button12,pos={442,148},size={100,20},proc=maCalcAccumProc,title="Calc Accum Stats"
	Button button12,help={"Calculated the statistics across all traces"}
	Button button13,pos={374,73},size={100,20},proc=maResetCellParamsProc,title="Reset Cell Params"
	SetVariable setvar03,pos={4,102},size={200,16},title="Decay Trend Spacer"
	SetVariable setvar03,help={"The deltaT used to find stretches of rising or falling currents"}
	SetVariable setvar03,format="%g ms",limits={0,inf,0.1},value= maDecaySpacer
	SetVariable setvar17,pos={28,21},size={100,16},title="Decimation"
	SetVariable setvar17,limits={1,inf,1},value= maDecimation
	Button button14,pos={479,73},size={90,20},proc=ButtonProc_5,title="See Cell Params"
	Button button15,pos={465,5},size={75,40},proc=maResetAllProc,title="Reset All"
	Button button16,pos={465,48},size={75,20},proc=maResetRejects,title="Reset Rejects"
	Button button17,pos={220,290},size={75,20},proc=maGic,title="maGic8!"
EndMacro

function maCellParameters()

	wave wData=$maTraceName()

	NVAR maRCPulseAmp
	NVAR maRCPulseDuration
	NVAR maRCPulseStart
	
	NVAR maRS
	NVAR maCM
	NVAR maRM
	NVAR maRS2
	NVAR maRM2
	NVAR maRMS
	NVAR maBaseline
	
	NVAR maBaselineStart
	NVAR maBaselineEnd
	NVAR maBaseline
	
	wavestats /q/r=(maBaselineStart, maBaselineEnd) wData
	maBaseline=v_avg
	maRMS=v_sdev		
	
	variable p1 = x2pnt(wData, maRCPulseStart)
	variable p2 = x2pnt(wData, maRCPulseStart+maRCPulseDuration)-1
			
	make /o/n = (p2-p1) tempExp
	variable oldLeft=leftx(wData)
	SetScale/P x leftx(wData), deltax(wData), "", tempExp
	
	tempExp=wData(x+maRCPulseStart)-maBaseline
	
	wavestats /q tempExp
	variable start
	if (maRCPulseAmp<0)
		start=v_minloc
	else
		start=v_maxloc
	endif
	
	curveFit/q  exp tempExp(start, inf) /D
	//print k0, k1, k2
	maRS= 1000*maRCPulseAmp/(k0 + k1)
	maRM=1000*maRCPulseAmp/k0-maRS
	maCM=(1000*k2)/maRS

	CurveFit/q dblexp_XOffset  tempExp(start, inf) /D
	maRS2 = 1000*maRCPulseAmp/(k0 + k1 + k3)
	maRM2=1000*maRCPulseAmp/k0-maRS2
	
	nvar maWaveCounter

	wave maWaveRM
	wave maWaveRS
	wave maWaveRS2
	wave maWaveRM2
	wave maWaveCM
	wave maWaveRMS
	wave maWaveBaseline
	wave /t maWaveNames

	maWaveNames[maWaveCounter]=maTraceName()
	maWaveRM[maWaveCounter]=maRM
	maWaveRS[maWaveCounter]=maRS
	maWaveRS2[maWaveCounter]=maRS2
	maWaveRM2[maWaveCounter]=maRM2
	maWaveCM[maWaveCounter]=maCM
	maWaveRMS[maWaveCounter]=maRMS
	maWaveBaseline[maWaveCounter]=maBaseline
	SetScale/P x oldLeft, deltax(wData), "", tempExp
	
end


function maAccumulateTraceStats()
	variable counter
	nvar maWaveCounter
	nvar maStartWave
	nvar maEndWave

	maResetAccumulatedSummary()
	wave maAccumulatedAvgMini
	wave maAccumulatedAvgMini2
	wave maAccumulatedAmp
	wave maAccumulatedIEI		
	
	variable lastGood=maStartWave
	variable anaCounter=0
	for (maWaveCounter=maStartWave; maWaveCounter<=maEndWave; maWaveCounter+=1)
		string wName=maTraceName()
		if (exists(wName+"_am"))
			anaCounter+=1
			lastGood=maWaveCounter
			if (anaCounter==1)
				duplicate /o $(maTraceName()+"_am") maAccumulatedAvgMini
				duplicate /o $(maTraceName()+"_am2") maAccumulatedAvgMini2
				duplicate /o $(maTraceName()+"_ndam") maAccumulatedNDAvgMini
				duplicate /o $(maTraceName()+"_ndam2") maAccumulatedNDAvgMini2
				duplicate /o $(maTraceName()+"_amps") maAccumulatedAmp
				duplicate /o $(maTraceName()+"_ieis") maAccumulatedIEI
			else
				wave am=$(maTraceName()+"_am")
				maAccumulatedAvgMini+=am
				wave am2=$(maTraceName()+"_am2")
				maAccumulatedAvgMini2+=am2
				wave amnd=$(maTraceName()+"_ndam")
				maAccumulatedNDAvgMini+=amnd
				wave amnd2=$(maTraceName()+"_ndam2")
				maAccumulatedNDAvgMini2+=amnd2
				wave amps=$(maTraceName()+"_amps") 
				concatenate {amps}, maAccumulatedAmp
				wave ieis=$(maTraceName()+"_ieis") 
				concatenate {ieis}, maAccumulatedIEI
			endif
		endif
	endfor
	maAccumulatedAvgMini/=anaCounter
	maAccumulatedAvgMini2/=anaCounter
	maAccumulatedNDAvgMini/=anaCounter
	maAccumulatedNDAvgMini2/=anaCounter
	
	duplicate /o maAccumulatedAmp maAccumulatedAmp_sort, maAccumulatedAmp_index
	maAccumulatedAmp_index=p/numpnts(maAccumulatedAmp)
	sort maAccumulatedAmp_sort, maAccumulatedAmp_sort
	wavestats /q maAccumulatedAmp
	print "AMPLITUDE: Average="+num2str(v_avg)+"  SDev: "+num2str(v_sdev)+ "  SEM: "+num2str(v_sdev/sqrt(v_npnts))
		
	duplicate /o maAccumulatedIEI maAccumulatedIEI_sort, maAccumulatedIEI_index
	maAccumulatedIEI_index=p/numpnts(maAccumulatedIEI)
	sort maAccumulatedIEI_sort, maAccumulatedIEI_sort
	wavestats /q maAccumulatedIEI
	print "IEI: Average="+num2str(v_avg)+"  SDev: "+num2str(v_sdev)+ "  SEM: "+num2str(v_sdev/sqrt(v_npnts))

	maWaveCounter=lastGood
	maFlipCounter()


end
	
	

Function maRecalcFilterVar(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	maRecalculateFilter()
	return 0
End

Function filtOneButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			string wName=maTraceName()
			if (exists(wName))
				maFilterData()
			else
				
				print "**** WAVE: "+wName+" does not exist"
			endif
			break
	endswitch

End

Function filtAllButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			variable counter
			nvar maWaveCounter
			nvar maStartWave
			nvar maEndWave
			
			variable lastGood=maStartWave			
			for (maWaveCounter=maStartWave; maWaveCounter<=maEndWave; maWaveCounter+=1)
				string wName=maTraceName()
				if (exists(wName))
					lastGood=maWaveCounter
					maFlipCounter()
					maFilterData()
					doupdate
				else
					print "**** WAVE: "+wName+" does not exist"
				endif
			endfor
			maWaveCounter=lastGood
			maFlipCounter()	
		break
	endswitch
End

Function findEventsOneButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string wName=maTraceName()+"_filtered"
			if (exists(wName))
				maProcessFiltered()
				doupdate
			else			
				print "**** WAVE: "+wName+" does not exist. Filter first ***"
			endif
			break
	endswitch	
	return 0
End

Function findEventsAllButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			variable counter
			nvar maWaveCounter
			nvar maStartWave
			nvar maEndWave
			wave maWaveAnalyzed
			
			variable lastGood=maStartWave			
			for (maWaveCounter=maStartWave; maWaveCounter<=maEndWave; maWaveCounter+=1)
				string wName=maTraceName()+"_filtered"
				if (exists(wName))
					if (maWaveAnalyzed[maWaveCounter] != -1)
						lastGood=maWaveCounter
						maFlipCounter()
						maProcessFiltered()
						doupdate
					else
						print "**** WAVE: "+wName+" rejected.  Skipping ***"
					endif
				else
					print "**** WAVE: "+wName+" does not exist. Filter first ***"
				endif
			endfor
			maWaveCounter=lastGood
			maFlipCounter()	
				break
	endswitch

End

Function calcParamsOneButtonProce(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string wName=maTraceName()
			if (exists(wName))
				maCellParameters()
			else
				print "**** WAVE: "+wName+" does not exist"
			endif
			break
	endswitch

	return 0
End

Function calcParamsAllButtonProce(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			variable counter
			nvar maWaveCounter
			nvar maStartWave
			nvar maEndWave
			
			variable lastGood=maStartWave			
			for (maWaveCounter=maStartWave; maWaveCounter<=maEndWave; maWaveCounter+=1)
				string wName=maTraceName()
				if (exists(wName))
					lastGood=maWaveCounter
					maFlipCounter()
					maCellParameters()
				else
					print "**** WAVE: "+wName+" does not exist"
				endif
			endfor
			maWaveCounter=lastGood
			maFlipCounter()	
				break
	endswitch

	return 0
End

Function doEverythingOneButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			string wName=maTraceName()
			if (exists(wName))
				maCellParameters()
				maFilterData()
				maProcessFiltered()
			else
				print "**** WAVE: "+wName+" does not exist"
			endif
			break
	endswitch

	return 0
End

Function doEverythingAllButtonProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			variable counter
			nvar maWaveCounter
			nvar maStartWave
			nvar maEndWave
			wave maWaveAnalyzed

			variable lastGood=maStartWave			
			for (maWaveCounter=maStartWave; maWaveCounter<=maEndWave; maWaveCounter+=1)
				string wName=maTraceName()
				if (exists(wName))
					if (maWaveAnalyzed[maWaveCounter] != -1)
						lastGood=maWaveCounter
						maFlipCounter()
						maCellParameters()
						maFilterData()
						maProcessFiltered()
						doupdate
					else
						print "**** WAVE: "+wName+" rejected.  Skipping ***"
					endif
				else
					print "**** WAVE: "+wName+" does not exist"
				endif
			endfor
			maWaveCounter=lastGood
			maFlipCounter()	
				break
	endswitch

	return 0
End

Window accumulatedAnaSummaryWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(349.5,44.75,662.25,392.75) maAccumulatedAmp_index vs maAccumulatedAmp_sort as "Accumulated Summary"
	AppendToGraph/L=l2/B=b2 maAccumulatedIEI_index vs maAccumulatedIEI_sort
	AppendToGraph/L=l3/B=b3 maAccumulatedAvgMini,maAccumulatedAvgMini2,maAccumulatedNDAvgMini
	AppendToGraph/L=l3/B=b3 maAccumulatedNDAvgMini2
	ModifyGraph rgb(maAccumulatedAvgMini2)=(0,0,0),rgb(maAccumulatedNDAvgMini2)=(0,0,0)
	ModifyGraph standoff=0
	ModifyGraph lblPos(left)=54,lblPos(bottom)=38
	ModifyGraph freePos(l2)=0
	ModifyGraph freePos(b2)={0,l2}
	ModifyGraph freePos(l3)=0
	ModifyGraph freePos(b3)={-63.56429854962,l3}
	ModifyGraph axisEnab(left)={0,0.3}
	ModifyGraph axisEnab(l2)={0.35,0.65}
	ModifyGraph axisEnab(l3)={0.7,1}
	SetAxis/E=1 left 0,1.1
	SetAxis/A/E=1 bottom
	SetAxis l2 0,1.1
	SetAxis/A/E=1 b2
	SetAxis/A/E=1 l3
	SetAxis/A/E=1 b3
	TextBox/C/N=text0/X=13.93/Y=82.37 "Amplitudes"
	TextBox/C/N=text1/X=25.08/Y=45.84 "ieis"
EndMacro

Function waveCounterProc(sva) : SetVariableControl
	STRUCT WMSetVariableAction &sva

	switch( sva.eventCode )
		case 1: // mouse up
		case 2: // Enter key
		case 3: // Live update
			Variable dval = sva.dval
			String sval = sva.sval
			maFlipCounter()
			break
	endswitch

	return 0
End

Window procDataWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(95.25,343.25,1036.5,551.75)/R maFiltered as "Processed Data"
	AppendToGraph/R maEventY vs maEventX
	ModifyGraph mode(maEventY)=4
	ModifyGraph marker(maEventY)=8
	ModifyGraph lSize(maEventY)=2
	ModifyGraph rgb(maEventY)=(0,52224,26368)
	ModifyGraph opaque(maEventY)=1
	ModifyGraph standoff(bottom)=0
EndMacro

Window risingDiagWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(40.5,224.75,981.75,433.25) maRiseCont as "Rising Processed Data"
	AppendToGraph/R maFiltered
	AppendToGraph/R maEventY vs maEventX
	AppendToGraph maRiseContThresh,maEvents
	ModifyGraph mode(maEventY)=4
	ModifyGraph marker(maEventY)=8
	ModifyGraph lSize(maEventY)=2
	ModifyGraph lStyle(maRiseCont)=1
	ModifyGraph rgb(maRiseCont)=(26112,52224,0),rgb(maEventY)=(0,52224,26368),rgb(maRiseContThresh)=(0,12800,52224)
	ModifyGraph opaque(maEventY)=1
	ModifyGraph standoff(left)=0,standoff(bottom)=0
EndMacro

Window fallingDiagWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(34.5,467,975.75,675.5) maDecayTauCont as "Falling Processed Data"
	AppendToGraph/R maFiltered
	AppendToGraph/R maEventY vs maEventX
	AppendToGraph maDecayStart,maDecayTauContThresh,maRiseContThreshStretch
	ModifyGraph mode(maEventY)=4
	ModifyGraph marker(maEventY)=8
	ModifyGraph lSize(maEventY)=2
	ModifyGraph lStyle(maDecayTauCont)=1,lStyle(maRiseContThreshStretch)=1
	ModifyGraph rgb(maDecayTauCont)=(26112,52224,0),rgb(maEventY)=(0,52224,26368),rgb(maDecayStart)=(0,0,0)
	ModifyGraph rgb(maDecayTauContThresh)=(0,12800,52224),rgb(maRiseContThreshStretch)=(0,0,0)
	ModifyGraph opaque(maEventY)=1
	ModifyGraph standoff(left)=0,standoff(bottom)=0
EndMacro

Function ButtonProc_3(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			execute "procDataWin()"
			break
	endswitch

	return 0
End

Function ButtonProc_4(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			execute "sweepAnaSummaryWin()"
			break
	endswitch

	return 0
End

function maRejectAnalysis()
	
			killwaves /z $(maTraceName()+"_am")
			killwaves /z  $(maTraceName()+"_am2")
			killwaves /z $(maTraceName()+"_ndam")
			killwaves /z  $(maTraceName()+"_ndam2")
			killwaves /z $(maTraceName()+"_eventX") 
			killwaves /z $(maTraceName()+"_eventY") 
			killwaves /z $(maTraceName()+"_Events") 
			killwaves /z $(maTraceName()+"_amps") 
			killwaves /z $(maTraceName()+"_amps_sort") 
			killwaves /z $(maTraceName()+"_amps_index") 
			killwaves /z  $(maTraceName()+"_ieis") 
			killwaves /z  $(maTraceName()+"_ieis_sort") 
			killwaves /z $(maTraceName()+"_ieis_index") 

			nvar maWaveCounter
			wave maWaveNEvents
			maWaveNEvents[maWaveCounter]=nan
			
			wave maWaveEventAmpAvg
			maWaveEventAmpAvg[maWaveCounter]=nan
			wave maWaveEventAmpSEM
			maWaveEventAmpSEM[maWaveCounter]=nan
			
			wave maWaveEventIEIAvg
			maWaveEventIEIAvg[maWaveCounter]=nan
			wave maWaveEventIEISEM		
			maWaveEventIEISEM[maWaveCounter]=nan
			
			wave maWaveAnalyzed
			maWaveAnalyzed[maWaveCounter]=-1
			
			maFlipCounter()
end
			
Function maRejectAnaProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
		maRejectAnalysis()

		break
		endswitch
	
	return 0
End

Window sweepAnaSummaryWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(19.5,44.75,332.25,392.75) maAmp_index vs maAmp_sort as "Trace Summary"
	AppendToGraph/L=l2/B=b2 maIEI_index vs maIEI_sort
	AppendToGraph/L=l3/B=b3 maAvgMini,maAvgMini2,maNDAvgMini,mandAvgMini2
	ModifyGraph rgb(maAvgMini2)=(0,0,0),rgb(mandAvgMini2)=(0,0,0)
	ModifyGraph standoff=0
	ModifyGraph lblPos(left)=54,lblPos(bottom)=38
	ModifyGraph freePos(l2)=0
	ModifyGraph freePos(b2)={0,l2}
	ModifyGraph freePos(l3)=0
	ModifyGraph freePos(b3)={-42.1599546801142,l3}
	ModifyGraph axisEnab(left)={0,0.3}
	ModifyGraph axisEnab(l2)={0.35,0.65}
	ModifyGraph axisEnab(l3)={0.7,1}
	SetAxis/E=1 left 0,1.1
	SetAxis/A/E=1 bottom
	SetAxis l2 0,1.1
	SetAxis/A/E=1 b2
	SetAxis/A/E=1 l3
	SetAxis/A/E=1 b3
	TextBox/C/N=text0/X=7.12/Y=88.66 "Amplitudes"
	TextBox/C/N=text1/X=10.84/Y=52.90 "ieis"
EndMacro

Function maAccSummaryProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			execute "accumulatedAnaSummaryWin()"
			break
	endswitch

	return 0
End

Function maResetAccumProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			
			maResetAccumulatedSummary()
			break
	endswitch

	return 0
End

Function maCalcAccumProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			maAccumulateTraceStats()
	endswitch

	return 0
End


Function maResetCellParamsProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			maResetParameterWaves()
			break
	endswitch

	return 0
End



Window maDiagnosticsWindow() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(76.5,130.25,1017.75,601.25)/L=l3 maRiseCont,maRiseContThresh as "Diagnostics"
	AppendToGraph maFiltered
	AppendToGraph maEventY vs maEventX
	AppendToGraph/L=l2 maDecayTauCont,maDecayStart,maDecayTauContThresh
	AppendToGraph/L=l3 maRiseContThreshStretch
	AppendToGraph/L=l4 maEvents
	ModifyGraph mode(maEventY)=4,mode(maEvents)=3
	ModifyGraph marker(maEventY)=8,marker(maEvents)=8
	ModifyGraph lSize(maEventY)=2
	ModifyGraph lStyle(maRiseCont)=1,lStyle(maRiseContThresh)=1,lStyle(maDecayTauCont)=1
	ModifyGraph rgb(maRiseCont)=(26112,52224,0),rgb(maRiseContThresh)=(0,0,0),rgb(maEventY)=(0,52224,26368)
	ModifyGraph rgb(maDecayTauCont)=(26112,52224,0),rgb(maDecayStart)=(0,0,0),rgb(maDecayTauContThresh)=(0,12800,52224)
	ModifyGraph rgb(maRiseContThreshStretch)=(0,12800,52224),rgb(maEvents)=(0,0,0)
	ModifyGraph opaque(maEventY)=1,opaque(maEvents)=1
	ModifyGraph standoff=0
	ModifyGraph lblPos(left)=57
	ModifyGraph freePos(l2)=0
	ModifyGraph freePos(l3)=0
	ModifyGraph freePos(l4)=0
	ModifyGraph axisEnab(left)={0.7567,0.999}
	ModifyGraph axisEnab(l2)={0.5045,0.7467}
	ModifyGraph axisEnab(l3)={0.2522,0.4945}
	ModifyGraph axisEnab(l4)={0,0.2}
	TextBox/C/N=text0/H={5,1,10}/A=MC/X=33.13/Y=38.83 "Trace and Events"
	TextBox/C/N=text1/H={5,1,10}/A=MC/X=31.52/Y=8.61 "Decay taus"
	TextBox/C/N=text2/H={5,1,10}/A=MC/X=32.59/Y=-17.40 "Rising rates"
	TextBox/C/N=text3/H={5,1,10}/A=MC/X=33.21/Y=-39.93 "Candidate events"
EndMacro

Function ButtonProc_5(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			maDisplayParameterWaves()
		endswitch

	return 0
End


Window AMPIEISummaryWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(818.25,245,1212.75,660.5) maWaveEventAmpAvg as "AMP IEI Summary"
	AppendToGraph/L=l2 maWaveEventIEIAvg
	ModifyGraph mode=3
	ModifyGraph marker=8
	ModifyGraph rgb(maWaveEventIEIAvg)=(0,0,0)
	ModifyGraph opaque=1
	ModifyGraph standoff=0
	ModifyGraph lblPos(left)=46
	ModifyGraph freePos(l2)=0
	ModifyGraph axisEnab(left)={0.5045,0.999}
	ModifyGraph axisEnab(l2)={0,0.4945}
	SetAxis/A/E=1 left
	SetAxis bottom -13.8932714617169,90.3062645011601
	SetAxis/A/E=1 l2
	ErrorBars maWaveEventAmpAvg Y,wave=(maWaveEventAmpSEM,maWaveEventAmpSEM)
	ErrorBars maWaveEventIEIAvg Y,wave=(maWaveEventIEISEM,maWaveEventIEISEM)
	TextBox/C/N=text0/H={5,1,10}/A=MC/X=28.61/Y=33.26 "Mini Amp"
	TextBox/C/N=text1/H={5,1,10}/A=MC/X=30.32/Y=-23.73 "Mini IEI"
EndMacro

Window CellParametersWin() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(35.25,41.75,444,574.25) maWaveRM,maWaveRM2 as "Cell Parameters"
	AppendToGraph/L=l2 maWaveRS,maWaveRS2
	AppendToGraph/L=l3 maWaveCM
	AppendToGraph/L=l4 maWaveRMS,maWaveBaseline
	ModifyGraph rgb(maWaveRMS)=(0,0,0)
	ModifyGraph standoff=0
	ModifyGraph lblPos(left)=48
	ModifyGraph freePos(l2)=0
	ModifyGraph freePos(l3)=0
	ModifyGraph freePos(l4)=0
	ModifyGraph axisEnab(left)={0.7567,0.999}
	ModifyGraph axisEnab(l2)={0.5045,0.7467}
	ModifyGraph axisEnab(l3)={0.2522,0.4945}
	ModifyGraph axisEnab(l4)={0,0.2422}
	SetAxis left 0,2000
	SetAxis bottom -4.62037037037037,63.5300925925926
	SetAxis/A/E=1 l2
	SetAxis/A/E=1 l3
	TextBox/C/N=text0/H={5,1,10}/A=MC/X=23.10/Y=42.34 "Input R"
	TextBox/C/N=text1/H={5,1,10}/A=MC/X=21.91/Y=6.79 "Series R"
	TextBox/C/N=text2/H={5,1,10}/A=MC/X=27.51/Y=-13.74 "Membrane C"
	TextBox/C/N=text3/H={5,1,10}/A=MC/X=30.77/Y=-38.55 "Current Baseline/RMS"
EndMacro
Function maResetAllProc(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			maRejectAnalysis()
			maResetAccumulatedSummary()
			maResetParameterWaves()
			killwaves /a/z
			nvar maWaveCounter
			maWaveCounter=1;
			maFlipCounter()
			break
	endswitch

	return 0
End
// save data for KT
Function SaveSummaryData(prefix)
	string prefix
	wave maAccumulatedAmp_index
	wave maAccumulatedAmp_sort
	wave maAccumulatedIEI_index
	wave maAccumulatedIEI_sort
	
	Duplicate /o maAccumulatedAmp_index, $(prefix+"Amp_index")
	Duplicate /o maAccumulatedAmp_sort, $(prefix+"Amp_sort")
	Duplicate /o maAccumulatedIEI_index, $(prefix+"IEI_index")
	Duplicate /o maAccumulatedIEI_sort, $(prefix+"IEI_sort")
	
	Save/T $(prefix+"Amp_index"),$(prefix+"Amp_sort"),$(prefix+"IEI_index"),$(prefix+"IEI_sort") as prefix+"sum.itx"
END
// save mini data for KT
Function SaveMiniData(prefix)
	string prefix
	wave maAccumulatedAvgMini
	wave maAccumulatedAvgMini2
	wave maAccumulatedNDAvgMini
	wave maAccumulatedNDAvgMini2
	
	Duplicate /o maAccumulatedAvgMini, $(prefix+"Avg_Mini")
	Duplicate /o maAccumulatedAvgMini2, $(prefix+"Avg_Mini2")
	Duplicate /o maAccumulatedNDAvgMini, $(prefix+"NDAvg_Mini")
	Duplicate /o maAccumulatedNDAvgMini2, $(prefix+"NDAvg_Mini2")
	
	Save/T $(prefix+"Avg_Mini"),$(prefix+"Avg_Mini2"),$(prefix+"NDAvg_Mini"),$(prefix+"NDAvg_Mini2") as prefix+"mini.itx"
END
// initialize rejected list wave maWaveAnalyzed
Function InitRejectedWaves()
	make /o/n=500 maWaveAnalyzed
	maWaveAnalyzed=nan
	
	nvar maStartWave
	nvar maEndWave
	nvar maWaveCounter
	wave maWaveNEvents
	wave maWaveAnalyzed
				
	variable lastWave=maWaveCounter
				
	for (maWaveCounter=maStartWave; maWaveCounter<=maEndWave; maWaveCounter+=1)
		string wName=maTraceName()+"_filtered"
		if (exists(wName))
			if (maWaveNEvents[maWaveCounter]>=0)
				maWaveAnalyzed[maWaveCounter]=1
			else
				maWaveAnalyzed[maWaveCounter]=-1
				print "**** WAVE: "+wName+" rejected.***"
			endif
		else
			print "**** WAVE: "+wName+" does not exist.***"
		endif
	endfor
	maWaveCounter=lastWave
	maFlipCounter()
	
	maDisplayParameterWaves()
END
// clear rejection list
Function maResetRejects(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			wave maWaveAnalyzed
			maWaveAnalyzed+=1
			maWaveAnalyzed*=0.6
			maWaveAnalyzed=trunc(maWaveAnalyzed)
			break
	endswitch

	return 0
End
// new button
Function maGic(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			variable num=enoise(4)
			num=round(num)
			Make/W/O/N=(10000,2) stereoSineSound		// 16 bit data
			SetScale/P x,0,1e-4,stereoSineSound		// Set sample rate to 10Khz
			stereoSineSound= 20000*sin(2*Pi*(1000 + (1-2*q)*150*x)*x)
			PlaySound/A stereoSineSound				// 16 bit, asynchronous
			switch(num)
				case -4:
					print "Yes!"
					break
				case -3:
					print "No!"
					break
				case -2:
					print "Maybe..."
					break
				case -1:
					print "Outlook good."
					break
				case 1:
					print "Outlook bad."
					break
				case 2:
					print "Filter harder"
					break
				case 3:
					print "Work harder"
					break
				case 4:
					print "Get better data"
					break
			endswitch		
	endswitch

	return 0
End

