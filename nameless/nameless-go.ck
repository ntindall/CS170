//name: nameless-go.ck
//Nathan james Tindall

// print
<<< "-----------------", "" >>>;
<<< "nameless - v0.0", "" >>>;
<<< "-----------------", "" >>>;
// print channels
<<< "* channels:", dac.channels() >>>;

if (me.arg(0) == "")
{
  <<< "You must specify the name of the server" >>>;
  <<< "- for local mode: \"local\"" >>>;
  <<< "- otherwise: the name of the machine running the server code." >>>;
  me.exit();
}

/******************************************************************** Welcome */

<<< 
"Control Information for Players

 - <SPACE>             to begin / enter world
 - ^v<> keys           to navigate world
 - d                   to rearticulate drone (on your current position)
 - 1-0                 to 'tinkle' (clocked by server)
 - j                   to 'jump' (clocked by server)

It is possible that the state of the world could change while you are on it.
The server may change global parameters and notify clients immediately.

By moving to a new cell, you will generate a tone. The envelope of the tone is
tuned by the server. Some envelopes will tend towards more or less movement.

 GESTURES
 - RAIN:     everyone drift downwards
 - ARP:      everyone drift to the right
 - TINKLE:   numbers 1-0 control number of tinkles (can strike successively)
 - JUMP:     percussive effect
 - DRIFT:    find a place sonically pleasing
"
>>>;


/******************************************************************** Globals */

//instantiated by first/subsequent server message
int id;

//global parameter for controlling when client should begin entering sound
//users should press spacebar to 'enter' the grid
int hasEntered;

//r g b MIDI values
int pitch;

int h;
int s;
int v;

//init to something reasonable
20000 => int attackMs;
0     => int decayMs;
1     => float sustainGain;
10000 => int releaseMs;

/*
0.1   => float coolGain;
0     => float warmGain;
*/

Event playerMoved;
Event stateChange;
Event clock;

// create our OSC receiver
OscRecv recv;
// use port 6449
6449 => recv.port;
// start listening (launch thread)
recv.listen();
<<< "OscRecv: listening on 6449" >>>;

// osc handle for server
OscSend xmit;
// server listening port
6451 => int port;

me.arg(0) => string host;
if ((host == "l") || (host == "local")) {
  "localhost" => host;
}

// aim the transmitter at port
xmit.setHost ( host, port );

/******************************************************************** Network */

// receiver
fun void network()
{
  // create an address in the receiver, store in new variable
  //id pitch r g b a d s r
  recv.event( "/slork/synch/synth, i i i i i s i i f i" ) @=> OscEvent oe;

  // count
  0 => int count;

  /*
  while (hasEntered == 0)
  {
    100::ms => now;
  }
  */

  // infinite event loop
  while ( true )
  {
      // wait for event to arrive
      oe => now;

      // count
      if( count < 5 ) count++;
      if( count < 4 ) <<< ".", "" >>>;
      else if( count == 4 ) <<< "network ready...", "" >>>;

      // grab the next message from the queue. 
      while( oe.nextMsg() != 0 )
      {

        pitch => int old_pitch;

        // get gain
        oe.getInt() => id;
        oe.getInt() => pitch;

        if ((pitch != old_pitch) && (hasEntered)) {
          spork ~drone();
        }

        oe.getInt() => h;
        oe.getInt() => s;
        oe.getInt() => v;

        <<< pitch, h,s,v >>>;

        <<< oe.getString() >>>;

        oe.getInt()   => attackMs;
        oe.getInt()   => decayMs;
        oe.getFloat() => sustainGain;
        oe.getInt()   => releaseMs;

        //signal that global state change has occured
        stateChange.broadcast();
      }
  }
}

fun void xmitMove(int deltaX, int deltaY)
{
  // a message is kicked as soon as it is complete 
  // - type string is satisfied and bundles are closed
  xmit.startMsg("/slork/synch/move", "i i i");
  id => xmit.addInt;
  deltaX => xmit.addInt;
  deltaY => xmit.addInt;

  playerMoved.broadcast();
}

fun void xmitAction(int actionId)
{
  xmit.startMsg( "/slork/synch/action", "i i i");
  id => xmit.addInt;
  actionId => xmit.addInt;
  -1 => xmit.addInt;
}

// overloaded to accomodate actionParam
fun void xmitAction(int actionId, int actionParam)
{
  xmit.startMsg( "/slork/synch/action", "i i i");
  id => xmit.addInt;
  actionId => xmit.addInt;
  actionParam => xmit.addInt;
}

fun void client()
{

  // the device number to open
  0 => int deviceNum;

  // instantiate a HidIn object
  HidIn hi;
  // structure to hold HID messages
  HidMsg msg;

  // open keyboard
  if( !hi.openKeyboard( deviceNum ) ) me.exit();
  // successful! print name of device
  <<< "keyboard '", hi.name(), "' ready" >>>;

  // infinite event loop
  while( true )
  {
    // wait on event
    hi => now;

    // get one or more messages
    while( hi.recv( msg ) )
    {
      if (msg.isButtonDown())
      {
        <<< msg.which >>>;

        if ((msg.which == 44) && (hasEntered == false))
        {
          <<< "YOU HAVE ENTERED THE GRID" >>>;
          true => hasEntered;
          xmitAction(ActionEnum.enter());
          xmitMove(0, 0);
          spork ~drone();
        }

        if (hasEntered == true)
        {
          /********************************************* Player Sound Control */

          //escape, allow nodes to leave
          if (msg.which == 41)
          {
            <<< "YOU HAVE DEPARTED THE GRID. PRESS SPACE TO RE-ENTER" >>>;
            false => hasEntered; //reset to allow spacebar for reentry
            xmitMove(0,0);
          }

          //d, rearticulate drone
          if (msg.which == 7) 
          {
            spork ~drone();
          }

          //j, send jump
          if (msg.which == 13)
          {
            xmitAction(ActionEnum.jump());
            spork ~jumpSound();
          }

          //number pad, send tinkle 0 - 9
          if (msg.which >= 30 && msg.which <= 39)
          {
            xmitAction(ActionEnum.tinkle(), (msg.which - 29) * 2);
            spork ~tinkleSound(msg.which - 29);
          }

          /************************************************ ARROW KEY CONTROL */
          //up
          if (msg.which == 82) xmitMove(1, 0);
          //down
          if (msg.which == 81) xmitMove(-1, 0);
          //left
          if (msg.which == 80) xmitMove(0, -1);
          //right
          if (msg.which == 79) xmitMove(0, 1);
        }
      }
    }
  }
}

/********************************************************************** Synch */

fun void stateMonitor()
{
  while (true)
  {
    //the global variables have shifted, update global warmness settings
    stateChange => now;
    // adjustLPF();
    adjustOsc();
  }
}

fun void clockBroadcast()
{
  recv.event( "/slork/synch/clock" ) @=> OscEvent ce;

  while (true)
  {  
      // wait for event to arrive
      ce => now;

      if (ce.nextMsg() != 0)
      {
        clock.broadcast();
      }
  }
}

fun void bassMonitor()
{
  recv.event( "/slork/synch/bass") @=> OscEvent be;

  while (true)
  {

    be => now;

    if (be.nextMsg() != 0)
    {
      spork ~bass();
    }


  }
}

/*********************************************************** Sound Production */

Gain globalG => NRev r => dac;
//LPF globalLPF => Gain globalG => NRev r => dac;
// globalLPF.freq(1000);
r.mix(0.05);

Gain redGain, blueGain, greenGain;
redGain => globalG;
blueGain => globalG;
greenGain => globalG;

fun void adjustOsc() {
  (h $ float ) / 120 => float oscBalance;
  if (oscBalance <= 1) 
  {
    1 - oscBalance => redGain.gain;
    oscBalance     => greenGain.gain;
    0              => blueGain.gain;
  } else if (oscBalance <= 2) 
  {
    oscBalance - 1 => oscBalance;

    1 - oscBalance => greenGain.gain;
    oscBalance     => blueGain.gain;
    0              => redGain.gain;
  } else 
  {
    //between 2 and 3
    oscBalance - 2 => oscBalance;

    1 - oscBalance => blueGain.gain;
    oscBalance     => redGain.gain;
    0              => greenGain.gain;
  }
}

fun void adjustLPF()
{
  //wolfram alpha query
  //(300, 4000),(0,12000),(60, 8000),(120,3000),(180,1200),(235,525), (270,1200), (360, 12000) function

  // 0.000886329*h*h*h -0.131224*h*h -67.811*h +12057.1 => globalLPF.freq;
}

fun void jumpSound()
{
  Sample moan;
  moan.getBuff() => KSChord ks => LPF lpf => ADSR env => globalG;

  lpf.freq(1000);

  moan.init("gasp.aif");

  24 => int offset;
  ks.tune(pitch - offset, pitch - offset - 12, pitch - offset - 24, pitch - offset - 36);
  ks.feedback(Math.random2f(0.95, 0.999999999999));

  env.set(0::ms, 0::ms, 1, 1::second);

  clock => now;

  env.keyOn();

  moan.playWithJitter(0.75, 1);
  moan.getBuff().samples()::samp => now;

  env.keyOff();

  env.releaseTime() => now;
}

fun void tinkleSound(int amount)
{
  <<< amount >>>;
  //global tinkler outgraph
  ResonZ tinklerZ => globalG;

  //blue patch
  Rhodey blueTinkler => HPF blueTinklerHPF;
  blueTinklerHPF => Gain blueTinklerGain => blueGain => tinklerZ;
  blueTinklerHPF.freq(8000);

  //red patch
  ModalBar redTinkler => Gain redTinklerGain => redGain => tinklerZ;
  redTinkler.stickHardness(0);
  redTinkler.controlChange(16, 2);

  //green patch
  Wurley greenTinkler => HPF greenTinklerHPF;
  greenTinklerHPF => Gain greenTinklerGain => greenGain => tinklerZ;
  greenTinklerHPF.freq(4000);

  //ramp gain
  2 => blueTinklerGain.gain => redTinklerGain.gain;
  0.5 => greenTinkler.gain;

  //constrain pitch
  pitch => int realpitch;
  while (realpitch < 60 || realpitch > 80)
  {
    if (realpitch < 60) realpitch + 12 => realpitch;
    if (realpitch > 80) realpitch - 36 => realpitch;
  }

  //set pitch
  Std.mtof(realpitch) => blueTinkler.freq => redTinkler.freq => greenTinkler.freq;
  Std.mtof(realpitch) => tinklerZ.freq;

  SinOsc lfo => blackhole;
  lfo.freq(0.1);

  //amount bounded between 0 and 9
  for (0 => int i; i < amount * 2; i++)
  {
    clock => now; //sync
    blueTinkler.noteOn(lfo.last() + 1);
    greenTinkler.noteOn(lfo.last() + 1);
    redTinkler.noteOn((lfo.last() + 1) / 2);
    <<< "." >>>;

    clock => now; 

    redTinkler.noteOff(1);
    greenTinkler.noteOff(1);
    blueTinkler.noteOff(1);

  }

  //let die
  clock => now;
}


fun void drone()
{
  ADSR redEnv;
  ADSR blueEnv;
  ADSR greenEnv;

  redEnv => redGain;
  blueEnv => blueGain;
  greenEnv => greenGain;
  
  //* warm osc */
  BeeThree redOsc;
  redOsc.lfoSpeed(1);
  redOsc.lfoDepth(0.01);
  redOsc.controlOne(0);
  LPF redLPF;
  12000 => redLPF.freq;
  redOsc => redLPF => redEnv;

  // blue osc
  Clarinet blueOsc;
  Math.random2f(0.8, 0.9) => float p;
  p => blueOsc.pressure;
  spork ~modBlueOscVib(blueOsc);
  LPF blueLPF;
  1000 => blueLPF.freq;
  blueOsc => blueLPF => blueEnv;

  // green osc
  HevyMetl greenOsc;

  greenOsc => greenEnv;

  /* Pitch selection */
  Std.mtof(pitch) => redOsc.freq;
  Std.mtof(pitch) / 2 => blueOsc.freq;
  Std.mtof(pitch) => greenOsc.freq;

  /* ADSR Tuning (controlled by server) */

  //ephemeral, have to cache
  releaseMs::ms => dur releaseTime;

  redEnv.set(attackMs::ms, decayMs::ms, sustainGain, releaseMs::ms);
  blueEnv.set(attackMs::ms, decayMs::ms, sustainGain, releaseMs::ms);
  greenEnv.set(attackMs::ms, decayMs::ms, sustainGain, releaseMs::ms);

    /* Patch */
  1 => redOsc.noteOn;
  1 => blueOsc.noteOn;
  1 => greenOsc.noteOn;

  //sync!
  clock => now;

  redEnv.keyOn();
  blueEnv.keyOn();
  greenEnv.keyOn();
  playerMoved => now;
  redEnv.keyOff();
  greenEnv.keyOff();
  blueEnv.keyOff();

  //release
  releaseTime => now;

  1 => redOsc.noteOff;
  1 => blueOsc.noteOff;
  1 => greenOsc.noteOff;
}

/* modulators */
fun void modBlueOscVib(Clarinet @osc) {
  SinOsc lfo => blackhole;
  0.5 => lfo.freq;

  // does child die when parent die?
  // existentialism
  while (true) {
    (lfo.last() + 1) / 10.0 + 0.1 => osc.vibratoGain;
    1::samp => now;
  }
}

fun void bass()
{
  <<< "hello" >>>;
  SinOsc s => ADSR env => globalG;
  s.freq(Std.mtof(pitch) / 2);
  s.gain(0.4); //tone it down

  env.set(10::second, 0::second, 0.5, 10::second);

  env.keyOn();
  10::second => now; 
  env.keyOff();

  env.releaseTime() => now;


}

/******************************************************************** CONTROL */

spork ~clockBroadcast();
spork ~bassMonitor();
spork ~stateMonitor();
spork ~network();
client();
