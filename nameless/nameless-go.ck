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
  //id pitch r g b
  recv.event( "/slork/synch/synth, i i i i i s" ) @=> OscEvent oe;

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
  xmit.startMsg( "/slork/synch/action", "i i");
  id => xmit.addInt;
  actionId => xmit.addInt;

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
          1 => hasEntered;
          xmitMove(0, 0);
          spork ~drone();
        }

        if (hasEntered == 1)
        {
          /********************************************* Player Sound Control */

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
            xmitAction(ActionEnum.tinkle());
            spork ~tinkleSound(msg.which - 30);
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
    adjustLPF();
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

/*********************************************************** Sound Production */

LPF globalLPF => Gain globalG => NRev r => dac;
globalLPF.freq(1000);
r.mix(0.05);

fun void adjustLPF()
{
  int lpfCutoff;

  //wolfram alpha query
  //(300, 4000),(0,12000),(60, 8000),(120,3000),(180,1200),(235,525), (270,1200), (360, 12000) function

  0.000886329*h*h*h -0.131224*h*h -67.811*h +12057.1 => globalLPF.freq;
}

fun void jumpSound()
{
  ModalBar m1 => Gain g;
  ModalBar m2 => g;

  m1.controlChange(16,0);
  m2.controlChange(16,0);

  0 => m1.stickHardness => m2.stickHardness;

  g => LPF l => globalLPF;

  l.freq(2000);

  pitch => int realpitch;
  if (pitch > 40) pitch - 12 => realpitch; 

  m1.freq(Std.mtof(realpitch));
  m2.freq(Std.mtof(realpitch + 7)); //fifth

  clock => now;

  for (int i; i < 2; i++)
  {
    m1.strike(1);
    m2.strike(1);
    clock => now;
    clock => now;
  }

  1::second => now;
}

fun void tinkleSound(int amount)
{
  ModalBar tinkler => ResonZ z => globalLPF;
  tinkler.freq(Std.mtof(pitch));
  z.freq(Std.mtof(pitch/2));

  tinkler.controlChange(16, 6);
  tinkler.damp(0.5);
  tinkler.stickHardness(0);

  //amount bounded between 0 and 9
  for (int i; i <= amount; i++)
  {
    clock => now; //sync
    tinkler.noteOn(1);
    clock => now;
    tinkler.noteOff(1);
  }
}


fun void drone()
{
  ADSR a => globalLPF;

  BeeThree cool => Gain coolGain => a;
  cool.lfoSpeed(1);
  cool.lfoDepth(0.01);
  cool.controlOne(1);

  /*
  SqrOsc warm => Gain warmGain => a;
  warmGain.gain(0.1);
  */

  1 => cool.noteOn;
  a.set(20::second, 0::second, 1, 10::second);
  Std.mtof(pitch) => cool.freq;

  a.keyOn();
  // 10::second => now;

  playerMoved => now;

  a.keyOff();
  10::second => now;

  1 => cool.noteOff;
}

spork ~clockBroadcast();
spork ~stateMonitor();
spork ~network();
client();
