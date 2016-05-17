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
  // create our OSC receiver
  OscRecv recv;
  // use port 6449
  6449 => recv.port;
  // start listening (launch thread)
  recv.listen();

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

        if (msg.which == 44)
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

          playerMoved.broadcast();
        }
      }
    }
  }
}

/*********************************************************** Sound Production */

LPF globalLPF => Gain globalG => dac;
globalLPF.freq(1000);

fun void adjustLPF()
{
  int lpfCutoff;

  //wolfram alpha query
  //(300, 4000),(0,12000),(60, 8000),(120,3000),(180,1200),(235,525), (270,1200), (360, 12000) function

  0.000886329*h*h*h -0.131224*h*h -67.811*h +12057.1 => globalLPF.freq;
}

fun void stateMonitor()
{
  while (true)
  {
    //the global variables have shifted, update global warmness settings
    stateChange => now;
    <<< globalLPF.freq() >>>;
    adjustLPF();
  }
}

fun void jumpSound()
{


}

fun void tinkleSound(int amount)
{
  ModalBar tinkler => ResonZ z => globalLPF;
  tinkler.freq(Std.mtof(pitch));
  z.freq(Std.mtof(pitch));

  //amount bounded between 0 and 9
  for (int i; i <= amount; i++)
  {
    tinkler.noteOn(1);
    40::ms => now;
    tinkler.noteOff(1);
    40::ms => now;

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

spork ~stateMonitor();
spork ~network();
client();
