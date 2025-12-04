import("stdfaust.lib");

exTrig = button("[1]New Example")<:_,_':-:max(0);
randChoice = no.noise : ba.sAndH(exTrig):_*0.5:_+0.5:_*(numExamples-1):round;
manual = checkbox("[2]Random/Manual");
manChoice = vslider("[4]Choice", 0,0,1,0.01)*(numExamples-1):round;
choice = randChoice*(1-manual) + manChoice*manual;
diff = vslider("Difficulty", 0.5, 0,1,0.01):si.smoo;

mapTo(lowOut, hiOut, x) = x*(hiOut-lowOut)+lowOut; 

crackler = no.sparse_noise(4.0);
vibrato = de.fdelay(1000, (os.osc(1)+1)*(diff:mapTo(300,50)));
hum = os.osc(50)*(os.phasor(1,50)<0.1)*(diff:mapTo(0.1, 0.001));
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

telefon = _+(gsm*(diff:mapTo(0.08,0.02)) + no.noise*0.0051);
hardclip = _*(diff:mapTo(4,2)):min(_,1):max(_,-1);

mode = _<:_+fi.resonbp(120, 350,diff:mapTo(30,10));
hochpass = fi.highpass(3,diff:mapTo(1900,100));
aussetzer = _*(no.sparse_noise(10.0):abs:fi.lowpass(1,1)*10<0.0015);
tiefpass = fi.lowpass(3,diff:mapTo(200,3800));
analogDist = _*preGain:ma.tanh:_*postGain with{
    preGain = (diff:mapTo(18,2));
    postGain = 1/preGain;
};

fx0 = _; // bypass, original. 
fx1 = _; // phase gedreht links/rechts. (geschieht nicht in dieser zeile)
fx2 = tiefpass; // tiefpass, lowpass, hicut
fx3 = _:_+hum:_; // brumm 
fx4 = analogDist; // verzerrung
fx5 = combfilter;//_<:_,(_:de.fdelay(1000, combDel/1000:ba.sec2samp)):+:_*0.5; //kammfilter
fx6 = _:_+no.noise*(diff:mapTo(0.01, 0.001)); // weisses rauschen
fx7 = _:_+crackler:_; // (digitales) knacksen
fx8 = _:vibrato:_; // gleichlauf schwankung / vibrato
fx9 = _:telefon:_; // (GSM, telefon) einstreuung, interferenzen
fx10 = hardclip; // diitales clipping
fx11 = mode; // raummode bei 120 Hz
fx12 = hochpass; // hochpass
fx13 = aussetzer; //aussetzer (kurze stille), digitales  system, vlt buffersize zu klein.
fx14 = vinyl;

// TODO:
// l/r inbalance
// sr reduction ohne aa filter
// mono vs stereo
// compression?
// peak eq/bell?

numExamples = 15;
fxCollection = hgroup("fx",(fx0,fx1,fx2,fx3,fx4,fx5,fx6,fx7,fx8,fx9,fx10,fx11,fx12, fx13,fx14));

switcher(s) = par(i, numExamples, *(s==i)):>_;

switcherGui = hgroup("[0]Puzzle", switcherMechanism(choiceSig):_*amp:toStereo:stereoFx) with {
    bypass = checkbox("[0]Bypass");
    choiceSig = choice<:attach(_,choiceDisplay)*(1-bypass);
    choiceDisplay = vbargraph("[2]Example[style:numerical]",0,5);
    amp = vslider("[3]Out Gain", -20, -99,0, 0.1):si.smoo:ba,ba.db2linear;
    switcherMechanism(x) = switcher(x);
    toStereo = _<:_,_;
    stereoFx = _,(_<:_,_*-1:select2(choiceSig==1));
};


vinyl = (_+vinylSounds*(diff:mapTo(4,0.5))):pitchModulator;
// 45rpm Vinyl -> 0.75Hz  
pitchModulator = de.fdelay(1000, (os.osc(0.75)+1)*(diff:mapTo(40,10)));

vinylSounds = vinNoise + vinHiCrackle*0.2 + vinLoCrackle with{
    vinNoise = no.pink_noise*0.005;
    vinHiCrackle = no.sparse_noise(4.0)+no.sparse_noise(8.0)*0.125:crackleResHi;
    crackleResHi(x) = x:fi.resonbp(fc, 1, 1) with{
        fc = no.noise*4000:ba.sAndH(x>0.01)+4050;
    };
    vinLoCrackle = no.sparse_noise(1.0):crackleResLo;
    crackleResLo(x) = x:fi.resonbp(fc, 2, 3) with{
        fc = no.noise*50:ba.sAndH(x>0.01)+55;
    };
} ;
// process = hardclip<:_,_;
// process = no.noise:gsmComb;
// process = hochpass<:_,_;
// process = aussetzer;
process = hgroup("Puzzle", _<:fxCollection:switcherGui);
// process = vinyl<:_,_;
