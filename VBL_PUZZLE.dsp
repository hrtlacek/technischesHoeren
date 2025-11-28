import("stdfaust.lib");

exTrig = button("New Example")<:_,_':-:max(0);
choice = no.noise : ba.sAndH(exTrig):_*0.5:_+0.5:_*(numExamples-1):round;


crackler = no.sparse_noise(4.0);
vibrato = de.fdelay(1000, (os.osc(1)+1)*200);
hum = os.osc(50)*(os.phasor(1,50)<0.1)*0.02;

combfilter = hgroup("Kammfilter", comb) with {
    combDel = vslider("Delay ms [scale:log]", 1, 0.001, 300, 0.01):si.smoo;
    comb = _<:_,(_:de.fdelay(1000, combDel/1000:ba.sec2samp)):+:_*0.5;
};


gsm = os.osc(150)*amp:_*70:ma.tanh:_*(1+os.osc(75)*0.7):fi.highpass(3,400):fi.lowpass(1,3000):gsmComb with {
gsmComb = _<:_,_:_-de.fdelay(1000, 1/1800:ba.sec2samp);
T = 0.45;//sec
t = os.phasor(1,1/T)*T;
shortBursts = (t<0.02) + (t>0.15)*(t<0.17) + (t>0.22)*(t<0.24);

seque = (os.phasor(1,1/8)>0.7) * (os.phasor(1,9)<0.9);
amp = shortBursts*(1-seque) + seque;
};

telefon = _+(gsm*0.051 + no.noise*0.0051);
hardclip = _*3:min(_,1):max(_,-1);

mode = _<:_+fi.resonbp(120, 350,20);

hochpass = fi.highpass(3,1000);

fx0 = _; // bypass, original. 
fx1 = _; // phase gedreht links/rechts. (geschieht nicht in dieser zeile)
fx2 = _:fi.lowpass(3,2000):_; // lowpass
fx3 = _:_+hum:_; // brumm 
fx4 = _*10:ma.tanh:_*0.1; // verzerrung
fx5 = combfilter;//_<:_,(_:de.fdelay(1000, combDel/1000:ba.sec2samp)):+:_*0.5; //kammfilter
fx6 = _:_+no.noise*0.001:_; // rauschen
fx7 = _:_+crackler:_; // knacksen
fx8 = _:vibrato:_; // gleichlauf schwankung / vibrato
fx9 = _:telefon:_; // GSM einstreuung
fx10 = hardclip; // diitales clipping
fx11 = mode; // raummode bei 120 Hz
fx12 = hochpass; // hochpass
// TODO:

// l/r inbalance
// aussetzer

numExamples = 13;
fxCollection = hgroup("fx",(fx0,fx1,fx2,fx3,fx4,fx5,fx6,fx7,fx8,fx9,fx10,fx11,fx12));

switcher(s) = par(i, numExamples, *(s==i)):>_;

source = _;

switcherGui = vgroup("[0]Puzzle", switcherMechanism(choiceSig):_*amp:toStereo:stereoFx) with {
    bypass = checkbox("Bypass");
    choiceSig = choice<:attach(_,choiceDisplay)*(1-bypass);
    choiceDisplay = vbargraph("Example[style:numerical]",0,5);
    amp = vslider("Out Gain", -20, -99,0, 0.1):si.smoo:ba,ba.db2linear;
    switcherMechanism(x) = switcher(x);
    toStereo = _<:_,_;
    stereoFx = _,(_<:_,_*-1:select2(choiceSig==1));
};




// process = hardclip<:_,_;
// process = no.noise:gsmComb;
// process = hochpass<:_,_;
process = hgroup("Puzzle", _<:fxCollection:switcherGui);
