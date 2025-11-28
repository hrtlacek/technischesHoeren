import("stdfaust.lib");

exTrig = button("New Example")<:_,_':-:max(0);
choice = no.noise : ba.sAndH(exTrig):_*0.5:_+0.5:_*(numExamples-1):round;


crackler = no.sparse_noise(4.0);
vibrato = de.fdelay(1000, (os.osc(1)+1)*200);
hum = os.osc(50)*(os.phasor(1,50)<0.3);


fx0 = _; // bypass, original. 
fx1 = _; // phase gedreht link/rechts. (geschieht nicht in dieser zeile)
fx2 = _:fi.lowpass(3,2000):_; // lowpass
fx3 = _:_+hum:_; // brumm 
fx4 = _*10:ma.tanh:_*0.1; // verzerrung
fx5 = _<:_,(_:de.fdelay(1000, 100)):+:_*0.5; //kammfilter
fx6 = _:_+no.noise*0.001:_; // rauschen
fx7 = _:_+crackler:_; // knacksen
fx8 = _:vibrato:_; // gleichlauf schwankung / vibrato

fxCollection = fx0,fx1,fx2,fx3,fx4,fx5,fx6,fx7,fx8;
numExamples = 9;
switcher(s) = par(i, numExamples, *(s==i)):>_;

source = _;

switcherGui = switcherMechanism(choiceSig):_*amp:toStereo:stereoFx with {
    bypass = checkbox("Bypass");
    choiceSig = choice<:attach(_,choiceDisplay)*(1-bypass);
    choiceDisplay = vbargraph("Example[style:numerical]",0,5);
    amp = vslider("Out Gain", -20, -99,0, 0.1):si.smoo:ba,ba.db2linear;
    switcherMechanism(x) = switcher(x);
    toStereo = _<:_,_;
    stereoFx = _,(_<:_,_*-1:select2(choiceSig==0));
};




// process = hum;
process = _<:fxCollection:switcherGui;
