import("stdfaust.lib");

numExamples = 6;
exTrig = button("New Example")<:_,_':-:max(0);
choice = no.noise : ba.sAndH(exTrig):_*0.5:_+0.5:_*(numExamples-1):round;


switcher(s) = *(s==0),*(s==1),*(s==2),*(s==3),*(s==4),*(s==5),*(s==6) :> _;

hum = (os.osc(50)+0.5):_*10:ma.tanh:_*0.001;

fx0 = _; //no effect but phase reversal in stereo fx section.
fx1 = _; //bypass, no effect.

fx2 = _:fi.lowpass(3,2000):_;
fx3 = _:_+hum:_;
fx4 = _*10:ma.tanh:_*0.1;
fx5 = _<:_,(_:de.fdelay(1000, 100)):+:_*0.5;
fx6 = _:_+no.noise*0.001:_;


source = _;

switcherGui = switcherMechanism(choiceSig):toStereo:stereoFx with {
    choiceSig = choice<:attach(_,choiceDisplay);
    choiceDisplay = vbargraph("Example[style:numerical]",0,5);
    switcherMechanism(x) = switcher(x);
    toStereo = _<:_,_;
    stereoFx = _,(_<:_,_*-1:select2(choiceSig<1)) ;//_<:_*(choiceSig==6) + _*-1;
    // stereoFx = _,(_<:_,_*-1:select2(choiceSig<1)) ;

};
choiceSig =3;
stereoFx = _,(_<:_,_*-1:select2(choiceSig<1)) ;//_<:_*(choiceSig==6) + _*-
// process = stereoFx;
process = _<:fx0,fx1,fx2,fx3,fx4,fx5,fx6:switcherGui;


