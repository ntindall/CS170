
/* Setup for Gametrack */
.032 => float DEADZONE;

// which joystick
0 => int device;
// get from command line
if( me.args() ) me.arg(0) => Std.atoi => device;

// data structure for gametrak
class GameTrak
{
    // timestamps
    time lastTime;
    time currTime;
    
    // previous axis data
    float lastAxis[6];
    // current axis data
    float axis[6];
}
// gametrack
GameTrak gt;

// HID objects
Hid trak;
HidMsg msg;

// open joystick 0, exit on fail
if( !trak.openJoystick( device ) ) me.exit();

// print
<<< "joystick '" + trak.name() + "' ready", "" >>>;


//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//------------------------- LISA HELPERS ---------------------------------------
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
//-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

.5 => float GRAIN_RAMP_FACTOR;

// max lisa voices
30 => int LISA_MAX_VOICES;

// grain sporkee
fun void grain(LiSa @ lisa,    //UGen       
               dur pos,        //position in buffer
               dur grainLen,   //length of grain
               dur rampUp,     //triangle envelope rampUp
               dur rampDown,   //triangle envelope rampDown
               float rate )    //sample playback rate
{
    // get a voice to use
    lisa.getVoice() => int voice;

    // if available
    if( voice > -1 )
    {
        // set rate
        lisa.rate( voice, rate );
        // set playhead
        lisa.playPos( voice, pos );
        // ramp up
        lisa.rampUp( voice, rampUp );
        // wait
        (grainLen - rampUp) => now;
        // ramp down
        lisa.rampDown( voice, rampDown );
        // wait
        rampDown => now;
    }
    500::ms => now; //decay
}

// load file into a LiSa
fun LiSa load( string filename )
{
    // sound buffer
    SndBuf buffy;
    // load it
    filename => buffy.read;
    
    // new LiSa
    LiSa lisa;
    // set duration
    buffy.samples()::samp => lisa.duration;
    
    // transfer values from SndBuf to LiSa
    for( 0 => int i; i < buffy.samples(); i++ )
    {
        // args are sample value and sample index
        // (dur must be integral in samples)
        lisa.valueAt( buffy.valueAt(i), i::samp );        
    }
    
    // set LiSa parameters
    lisa.play( false );
    lisa.loop( false );
    lisa.maxVoices( LISA_MAX_VOICES );
    
    return lisa;
}


/* PATCH */
dac.channels() => int N_CHANS;

NRev reverbs[N_CHANS];
HPF h[N_CHANS];

for (int i; i < N_CHANS; i++) {
  reverbs[i] => h[i] => dac.chan(i);
  h[i].freq(50);
  reverbs[i].mix(0.05);
}

1 => float register;

//todo... multichannel LiSa
load (me.sourceDir() + "enya2.wav") @=> LiSa lisa1;
load (me.sourceDir() + "giygas.wav") @=> LiSa lisa2;


fun void soundSource1() {
//  deltaX / 2 => deltaX; //make mouse a little less sensitive

  lisa1 => LPF l => PitShift p => NRev reverb => dac;

  l.freq(20000);

  while (true) {
    //<<<Std.fabs(gt.lastAxis[1] - gt.axis[1]) >>>;
    //have to trigger 
   // if (Std.fabs(gt.lastAxis[1] - gt.axis[1]) > 0.05) {
    2 => float rate;
    if (gt.axis[1] > 0.5) {
      4 => rate;
    } else if (gt.axis[1] > 0) {
      2 => rate;
    } else if (gt.axis[1] > 0.5) {
      1 => rate;
    } else {
      0.5 => rate;
    }

    if (gt.axis[2] > 0) {
      spork ~grain(lisa1,
                  gt.axis[2] * lisa1.duration(),
                  100::ms,
                  GRAIN_RAMP_FACTOR * 100::ms,
                  GRAIN_RAMP_FACTOR * 100::ms,
                  rate);

      if (gt.axis[0] > 0) {
        (5 / gt.axis[0])::ms => now;
      } else {
        5::ms * (gt.axis[0] + 2) * 8 => now;
      }
    } else {
      5::ms => now;
    }
  }
}


fun void soundSource2() {

  lisa2 => LPF l2 => Echo e => NRev r => dac;

  0 => int cur;
  0 => int numToPlay;
  float pos[16];
  [10, 5, 2, 6, 8, 11, 3, 7, 15, 14, 4, 9, 1, 0, 13, 12] @=> int permutation[];
  for (int i; i < 16; i++) {
    Std.rand2f(0,1) => pos[i];
  }

  e.delay(125::ms);
  e.mix(0.1);
  r.mix(0.1);
  

  l2.freq(20000);

  while (true) {
    (gt.axis[5] * 16) $ int => numToPlay;
    <<< numToPlay >>>;

    for (int i; i < 16; i++) {
      if (numToPlay > 0) {
        spork ~grain(lisa2,
              pos[permutation[i]] * lisa1.duration(),
              10::ms,
              GRAIN_RAMP_FACTOR * 10::ms,
              GRAIN_RAMP_FACTOR * 10::ms,
              1);
        numToPlay - 1 => numToPlay;
      }
      125::ms => now;
    }
  }
}

spork ~soundSource1();
spork ~soundSource2();




fun void mouse() {
  // the device number to open
  0 => int deviceNum;

  // instantiate a HidIn object
  HidIn hi;
  // structure to hold HID messages
  HidMsg msgM;

  // open mouse 0, exit on fail
  if( !hi.openMouse( deviceNum ) ) me.exit();
  // successful! print name of device
  <<< "mouse '", hi.name(), "' ready" >>>;

  // infinite event loop
  while( true )
  {
      // wait on HidIn as event
      hi => now;

      // messages received
      while( hi.recv( msgM ) )
      {
          // mouse motion
          if( msgM.isMouseMotion() )
          {
              // axis of motion
              if( msgM.deltaX )
              {
                  
               // spork ~beep(msgM.deltaX);
                200::ms => now; //TODO... rate limit the sporking a bit.
                               //what is the optimal value????

                //TODO
                while (hi.recv (msgM)) {
                  //noop
                  //clear queue
                }
              }

          }
      }
  }
}

fun void keyboard() {
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
          // check for action type
          if( msg.isButtonDown() )
          {
            if (msg.which == 82) { //up
              register + 0.1 => register;
              <<< "[!] REGISTER CHANGE: UP" >>>;
              <<< "[!] " + register >>>;
            } 
            if (msg.which == 81) { //down
              register - 0.1 => register;
              <<< "[!] REGISTER CHANGE: DOWN" >>>; 
              <<< "[!] " + register >>>;
            }
          }
          else
          {
              // print
              // <<< "up:", msg.which >>>;
          }
      }
  }
}

/* CONTROL */
spork ~keyboard();

// print
fun void print()
{
    // time loop
    while( true )
    {
        // values
        <<< "axes:", gt.axis[0],gt.axis[1],gt.axis[2], gt.axis[3],gt.axis[4],gt.axis[5] >>>;
        // advance time
        100::ms => now;
    }
}

// gametrack handling
fun void gametrak()
{
  0 => int i;
    while( true )
    {
        // wait on HidIn as event
        trak => now;
        
        // messages received
        while( trak.recv( msg ) )
        {
            // joystick axis motion
            if( msg.isAxisMotion() )
            {            
                // check which
                if( msg.which >= 0 && msg.which < 6 )
                {
                    i++;
                    // check if fresh
                    if( now > gt.currTime )
                    {
                        // time stamp
                        gt.currTime => gt.lastTime;
                        // set
                        now => gt.currTime;
                    }
                    // save last
                    if (i % 100 == 0) {
                      gt.axis[msg.which] => gt.lastAxis[msg.which];
                    }
                    // the z axes map to [0,1], others map to [-1,1]
                    if( msg.which != 2 && msg.which != 5 )
                    { msg.axisPosition => gt.axis[msg.which]; }
                    else
                    {
                        1 - ((msg.axisPosition + 1) / 2) - DEADZONE => gt.axis[msg.which];
                        if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which];
                    }
                }
            }
            
            // joystick button down
            else if( msg.isButtonDown() )
            {
                <<< "button", msg.which, "down" >>>;
            }
            
            // joystick button up
            else if( msg.isButtonUp() )
            {
                <<< "button", msg.which, "up" >>>;
            }
        }
    }
}

// spork control
spork ~ gametrak();
// print
spork ~ print();

// main loop
while( true )
{
    // synchronize to display
    100::ms => now;
}

