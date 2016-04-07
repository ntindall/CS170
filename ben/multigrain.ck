//Work out number of channels
dac.channels() => int numChannels;
<<<"Using", numChannels, "channels">>>;

// Signal Chains
SndBuf buf1 => Envelope e1 => JCRev R;
SndBuf buf2 => Envelope e2 => R;
0.05 => R.mix;
for(0 => int i; i < numChannels; i++)
{
    R => dac.chan(i);
}


//Read in source files
"enya2.wav" => string file1;
"giygas.wav" => string file2;
me.sourceDir() + "/" + file1 => buf1.read;
me.sourceDir() + "/" + file2 => buf2.read;

//Open mouse
1 => int deviceNum_mouse; // the device number to open
Hid mouse; // instantiate an Hid object for the mouse
if( !mouse.openMouse( deviceNum_mouse ) ) me.exit(); // open mouse 0, exit on fail
<<< "mouse '", mouse.name(), "' ready" >>>; // successful! print name of device

//Open keyboard
0 => int deviceNum_kb; //Keyboard device number to open
Hid kb; // instantiate an Hid object for the keyboard
if( !kb.openKeyboard( deviceNum_kb ) ) me.exit(); // open keyboard (exit on fail)
<<< "keyboard '", kb.name(), "' ready" >>>; // successful! print name of device

12.0 => float pitch_pow_1;

//Synthesis Parameters - source 1
60 => float grain_duration_1; 
1020 => int position_1; 
1.0 => float base_pitch_1;
10000 => int rand_position_1;
0.0 => float rand_pitch_1;

//Synthesis Parameters - source 2
200 => float grain_duration_2; 
10000 => int position_2; 
1.0 => float base_pitch_2;
0 => int rand_position_2;
0.0 => float rand_pitch_2;

//Mix between sources (0 = all source 1, 1 = all source 2)
0.00 => float source_mix;

//Mouse handling function
fun void handleMouse()
{
	HidMsg msg; // structure to hold HID messages
    buf1.samples() => int samples_1;
    buf2.samples() => int samples_2;
    while( true )
    {   
        mouse => now; // wait on HidIn as event
        while( mouse.recv( msg ) ) //Handle all messages before waiting for next event
        {
            if( msg.isMouseMotion() )
            {
                if( msg.deltaX )
                {
                    msg.deltaX * 200 +=> position_1;
                    if(position_1 < 0)
                        0 => position_1;
                    if(position_1 >= samples_1)
                        samples_1 - 1 => position_1;
                    <<<position_1>>>;
                }
                else if( msg.deltaY )
                {
                    //msg.deltaY * -300 +=> position_2;
                    //if(position_2 < 0)
                    //    0 => position_2;
                    //if(position_2 >= samples_2)
                    //    samples_2 - 1 => position_2;
                    //<<<position_2>>>;
                    
                    /*msg.deltaY * -.001 +=> base_pitch_1;
                    if(base_pitch_1 < 0.1)
                        0.1 => base_pitch_1;
                    if(base_pitch_1 > 2.0)
                        2.0 => base_pitch_1;
                    <<<"pitch: " + base_pitch_1>>>;*/
                    
                    msg.deltaY * -0.4 +=> grain_duration_1;
                    if(grain_duration_1 < 20)
                        30 => grain_duration_1;
                    if(grain_duration_1 > 100)
                        90 => grain_duration_1;
                }
            }
            else if( msg.isButtonDown() )
            {
                //This space intentionally left blank
            }
            else if( msg.isButtonUp() )
            {
                //This space intentionally left blank
            }
            else if( msg.isWheelMotion() ) //(requires chuck 1.2.0.8 or higher)
            {
                // axis of motion
                if( msg.deltaX )
                {
                    //This space intentionally left blank
                }            
                else if( msg.deltaY )
                {
                    //This space intentionally left blank
                }
            }
        }
    }
} //End mouse handling function

//Keyboard handling function
fun void handleKeyboard()
{
    HidMsg msg; // structure to hold HID messages
    while(true)
    {
        kb => now; //Wait on HID as event
        while( kb.recv( msg ) ) //Handle all messages before waiting for next event
        {
            if( msg.isButtonDown() ) //Key down events
            {
                <<<"which",msg.which>>>;
                if(msg.which == 55) //greater than (period)
                {
                    .01 +=> source_mix;
                    if(source_mix > 1.0)
                        1.0 => source_mix;
                    <<<source_mix>>>;
                }
                else if(msg.which == 54) //Less than (comma)
                {
                    .01 -=> source_mix;
                    if(source_mix < 0)
                        0 => source_mix;
                    <<<source_mix>>>;
                }
                else if(msg.which >= 30 && msg.which <= 37)
                {
                    60 => int midiNote;
                    <<<"which",msg.which>>>;
                    if(msg.which == 31) 62 => midiNote;
                    if(msg.which == 32) 64 => midiNote;
                    if(msg.which == 33) 65 => midiNote;
                    if(msg.which == 34) 67 => midiNote;
                    if(msg.which == 35) 69 => midiNote;
                    if(msg.which == 36) 71 => midiNote;
                    if(msg.which == 37) 72 => midiNote;
                    <<<"midi",midiNote>>>;
                        
                    (Std.mtof(midiNote) $ float) / (Std.mtof(60) $ float) => float ratio;
                    <<<"ratio",ratio>>>;
                    ratio => base_pitch_1;
                    
                }
                //Further keyboard controls go here
                
            }
            else //Key up events
            {
                
            }
        }
    }
} //End keyboard handling function

fun void advanceSource2()
{
    while(true)
    {
        1000 +=> position_2;
        if(position_2 > buf2.samples())
            0 => position_2;
        1000::samp => now;
    }
}

//Launch input handling functions in separate shreds
spork ~ handleMouse();
spork ~ handleKeyboard();
spork ~ advanceSource2();

//Function to play a grain
fun void grain(SndBuf buf, Envelope e, float duration, int position, float pitch, int randompos, float randpitch)
{ 
    Math.random2f(pitch-randpitch,pitch+randpitch) => buf.rate;
    Math.random2(position-randompos,position+randompos) => buf.pos;
    0.4 => buf.gain;
    
    e.keyOn();
    duration*0.6::ms => now;
    e.keyOff();
    duration*0.4::ms => now;
}

//Main loop
while(true)
{
    Math.randomf() => float sourceChoice;
    if(sourceChoice > source_mix)
    {
        //Play grain from source 1
        grain(buf1, e1, grain_duration_1, position_1, base_pitch_1, rand_position_1, rand_pitch_1);
    }
    else
    {
        //Play grain from source 2
        grain(buf2, e2, grain_duration_2, position_2, base_pitch_2, rand_position_2, rand_pitch_2);
    }
}