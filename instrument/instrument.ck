/*
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
            // print
            <<< "down:", msg.which >>>;
        }
        else
        {
            // print
            <<< "up:", msg.which >>>;
        }
    }
}*/

//-----------------------------------------------------------------------------
// name: ks-chord.ck
// desc: karplus strong comb filter bank
//
// authors: Madeline Huberth (mhuberth@ccrma.stanford.edu)
//          Ge Wang (ge@ccrma.stanford.edu)
// date: summer 2014
//       Stanford Center @ Peking University
//-----------------------------------------------------------------------------

// single voice Karplus Strong chubgraph
class KS extends Chubgraph
{
    // sample rate
    second / samp => float SRATE;
    
    // ugens!
    DelayA delay;
    OneZero lowpass;
    
    // noise, only for internal use
    Noise n => delay;
    // silence so it doesn't play
    0 => n.gain;
    
    // the feedback
    inlet => delay => lowpass => delay => outlet;
    // max delay
    1::second => delay.max;
    // set lowpass
    -1 => lowpass.zero;
    // set feedback attenuation
    .9 => lowpass.gain;

    // mostly for testing
    fun void play( float pitch, dur T )
    {
        tune( pitch ) => float length;
        // turn on noise
        1 => n.gain;
        // fill delay with length samples
        length::samp => now;
        // silence
        0 => n.gain;
        // let it play
        T-length::samp => now;
    }
    
    // tune the fundamental resonance
    fun float tune( float pitch )
    {
        // computes further pitch tuning for higher pitches
        pitch - 43 => float diff;
        0 => float adjust;
        if( diff > 0 ) diff * .0125 => adjust;
        // compute length
        computeDelay( Std.mtof(pitch+adjust) ) => float length;
        // set the delay
        length::samp => delay.delay;
        //return
        return length;
    }
    
    // set feedback attenuation
    fun float feedback( float att )
    {
        // sanity check
        if( att >= 1 || att < 0 )
        {
            <<< "set feedback value between 0 and 1 (non-inclusive)" >>>;
            return lowpass.gain();
        }

        // set it        
        att => lowpass.gain;
        // return
        return att;
    }
    
    // compute delay from frequency
    fun float computeDelay( float freq )
    {
        // compute delay length from srate and desired freq
        return SRATE / freq;
    }
}

// chord class for KS
class KSChord extends Chubgraph
{
    // array of KS objects    
    KS chordArray[4];
    
    // connect to inlet and outlet of chubgraph
    for( int i; i < chordArray.size(); i++ ) {
        inlet => chordArray[i] => outlet;
    }

    // set feedback    
    fun float feedback( float att )
    {
        // sanith check
        if( att >= 1 || att < 0 )
        {
            <<< "set feedback value between 0 and 1 (non-inclusive)" >>>;
            return att;
        }
        
        // set feedback on each element
        for( int i; i < chordArray.size(); i++ )
        {
            att => chordArray[i].feedback;
        }

        return att;
    }
    
    // tune 4 objects
    fun float tune( float pitch1, float pitch2, float pitch3, float pitch4 )
    {
        pitch1 => chordArray[0].tune;
        pitch2 => chordArray[1].tune;
        pitch3 => chordArray[2].tune;
        pitch4 => chordArray[3].tune;
    }
}

int deltaX;
//cool
fun void gliss(float s_note, float e_note, float gain, dur hold) {
  Noise n => Gain g => KSChord object => JCRev r;
  (e_note - s_note) / 100 => float delta;
  g.gain(gain);
  object.feedback(0.98);
  r.mix(1);
  r => LPF h => dac;
  h.freq(800);
  <<< s_note, e_note >>>;
  
  0 => float shift;
  object.tune(s_note + shift, s_note + shift, s_note+12 + shift, s_note+12 + shift);
  0.1::second => now;
  while (true) {

    object.tune(s_note + shift, s_note + shift, s_note+12 + shift, s_note+12 + shift);
    deltaX => shift;
    10::ms => now;
  }
  hold => now;
  0 => g.gain;
  4::second => now;
}


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
                  msgM.deltaX => deltaX;
              }

          }
      }
  }
}

spork ~mouse();
gliss(50, 50, 0.01, 1::second);

//-----------------------------------------------------------------------------
// name: kb-fret.ck
// desc: this program attempts to open a keyboard; maps key-down events to
//       pitches via a fretboard-like mapping.
//
// authors: Rebecca Fiebrink and Ge Wang
// adapted from Crystalis and Joy of Chant
//
// to run (in command line chuck):
//     %> chuck kb-fret.ck
//
// to run (in miniAudicle):
//     (make sure VM is started, add the thing)
//-----------------------------------------------------------------------------

// base and register
12 => int base;
3 => int register;
0 => int reg_change;

// keyboard
HidIn kb;
// hid message
HidMsg msg;

// open
if( !kb.openKeyboard( 0 ) ) me.exit();
<<< "Ready?", "" >>>;

// sound synthesis
ModalBar bar => JCRev r => dac;
// set mix
.01 => r.mix;
// bar settings
4 => bar.preset;

// key map
int key[256];
// key and pitch
0 => key[29];
1 => key[27];
2 => key[6];
3 => key[25];
4 => key[5];
5 => key[4] => key[17];
6 => key[22] => key[16];
7 => key[7] => key[54];
8 => key[9] => key[55];
9 => key[10] => key[56];
10 => key[20] => key[11];
11 => key[26] => key[13];
12 => key[8] => key[14];
13 => key[21] => key[15];
14 => key[23] => key[51];
15 => key[28] => key[52];
16 => key[24];
17 => key[12];
18 => key[18];
19 => key[19];
20 => key[47];
21 => key[48];
22 => key[49];
// which is current
0 => int current;

// yes
fun void registerUp()
{
    if( register < 6 ) { register++; 1 => reg_change; }
    <<< "register:", register >>>;
}

// yes
fun void registerDown()
{
    if( register > 0 ) { register--; 1 => reg_change; }
    <<< "register:", register >>>;
}

float freq;

// infinite event loop
while( true )
{
    // wait for event
    kb => now;

    // get message
    while( kb.recv( msg ) )
    { 
        <<< msg.which >>>;
        // which
        if( msg.which > 256 ) continue;
        if( key[msg.which] == 0 && msg.which != 29 )
        {
            // register
            if( msg.which == 80 && msg.isButtonDown() )
                registerDown();
            else if( msg.which == 79 && msg.isButtonDown() )
                registerUp();
        }
        // set
        else if( msg.isButtonDown() )
        {
            // freq
            base + register * 12 + key[msg.which] => float note;
        }
    }
}

gliss(52,52,0.5,1::second);