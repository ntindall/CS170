/* PATCH */
dac.channels() => int N_CHANS;

NRev reverbs[N_CHANS];
HPF h[N_CHANS];

for (int i; i < N_CHANS; i++) {
  reverbs[i] => h[i] => dac.chan(i);
  h[i].freq(50);
  reverbs[i].mix(0.05);
}

//Function to play a grain
fun void grain(SndBuf buf, Envelope e, float duration, int position, float pitch, int randompos, float randpitch, float gain)
{ 
    Math.random2f(pitch-randpitch,pitch+randpitch) => buf.rate;
    Math.random2(position-randompos,position+randompos) => buf.pos;
    gain => buf.gain;
    
    e.keyOn();
    duration*0.6::ms => now;
    e.keyOff();
    duration*0.4::ms => now;
}

fun void grainString(SndBuf buf, Envelope e, float duration, int position, float pitch, int randompos, float randpitch, float gain, int numGrains)
{
    duration $ int * 50  => int advancePerGrain;
    for(0 => int i; i < numGrains; i++)
    {
        position + (i * advancePerGrain) => int grainPos;
        grain(buf, e, duration, grainPos, pitch, randompos, randpitch, gain);
    }
}

fun void beep(float deltaX, float deltaY) {
    <<<deltaX>>>;
    
    //Decide how many grains to play of source file (based on delta X)
    (Math.fabs(deltaX) * 2) $ int => int numGrains;
    
    //Decide playback rate for grains (based on deltaX, swiping left causes backwards playback)
    //TODO: Maybe we should map pitch to deltaY instead, so we can de-couple the pitch and the number of grains?)
    (deltaY + 1) / 2.0 => float pitch;
    if(pitch < 0)
        1.0 / pitch => pitch;
    if(deltaX < 0)
        -pitch => pitch;
    //TODO: limits on pitch?
    
    //Set up sound buffer (TODO: may want to not have to load the file again for every new beep)
    SndBuf buf1 => Envelope e; //TODO: I'd like to try adding some of the "glitchy intruder" grain replacement stuff to this instrument
    for(0 => int i; i < N_CHANS; i++)
    {
        e => reverbs[i]; //TODO: variation between channels (different channel per grain in string? All grains on all channels but slightly offset?)
    }
    "pc_turnon.WAV" => string file1;
    //"drmario02.dsp.wav" => string file1; //UNCOMMENT HERE TO SWITCH SOURCE FILES
    me.sourceDir() + "/" + file1 => buf1.read;
    
    //Play grain string a set number of times, with a set delay between each playback
    4 => int numDelays;
    for(0 => int i; i < numDelays; i++)
    {
        (numDelays - i) $ float / (2.0 * numDelays $ float) => float gain;
        spork ~ grainString(buf1, e, 75.0, buf1.samples() / 2, pitch, 1000, 0, gain, numGrains);
        500::ms => now;
    }
}

fun void beep2(int deltaX, float yPos) {
    deltaX / 2 => deltaX; //make mouse a little less sensitive
    <<< deltaX >>>;
    1 => int register;
    SinOsc s => ADSR a => reverbs[Math.abs(deltaX) % N_CHANS];
    a.set(200::ms, 50::ms, Math.random2f(0.1,0.2), 10::ms);
    
    (yPos * 4) $ int => int y;
    
    250::ms  => dur duration; 
    
    if (y < 0) {
        Math.abs(y) * 250::ms => duration;
    } else if (y > 0) {
        250::ms / y => duration;
    }
    
    if (deltaX > 0) {
        //upper bound
        Math.max(1, s.freq() * deltaX) => float f;
        //lower bound
        Math.min(f, 16000) * register => s.freq;
        
        for (int i; i < 4; i++) {
            a.keyOn();
            duration => now;
            a.keyOff();
            duration => now;
        }
    } else {
        Math.max(55, s.freq() * register / Math.abs(deltaX)) => s.freq;
        
        for (int i; i < 2; i++) {
            a.keyOn();
            duration * 2 => now;
            a.keyOff();
            duration * 2 => now;
        }
    }
}

GameTrak gt;

// z axis deadzone
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


// HID objects
Hid trak;
HidMsg msg;

// open joystick 0, exit on fail
if( !trak.openJoystick( device ) ) me.exit();

// print
<<< "joystick '" + trak.name() + "' ready", "" >>>;

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

0 => int triggered;
fun void onNewGametrakEvent()
{       
    gt.axis[0] - gt.lastAxis[0] => float deltaX;
    gt.axis[1] - gt.lastAxis[1] => float deltaY;
    <<<"delta x",deltaX>>>;
    16 *=> deltaX;
    16 *=> deltaY;
    
    
    gt.axis[1] => float y;
    //if(0.5 < y)
    //{
    //    if(!triggered){
    //        1 => triggered;
    //        spork ~ beep(deltaX, deltaY);
    //        //spork ~ beep2(deltaY $ int);
    //    }
    //}
    //else
    //{
    //    0 => triggered;
    //}
    
    if(4 < Math.fabs(deltaX))
    {
        //spork ~ beep(deltaX, deltaY);
        spork ~ beep2(deltaX $ int,  y);
    }
}

// gametrack handling
fun void gametrak()
{
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
                    // check if fresh
                    if( now > gt.currTime )
                    {
                        // time stamp
                        gt.currTime => gt.lastTime;
                        // set
                        now => gt.currTime;
                    }
                    // save last
                    gt.axis[msg.which] => gt.lastAxis[msg.which];
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
        
        onNewGametrakEvent();
        125::ms => now;        
        while (trak.recv( msg )) {
            //clear
        }
        
    }
}

spork ~ gametrak();


// main loop
while( true )
{
    // synchronize to display
    100::ms => now;
}
