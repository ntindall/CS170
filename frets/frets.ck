class PanicHit
{
    me.sourceDir() + "/panic-hit.wav" => string filename_hit;
    SndBuf hit_buffer;
    filename_hit => hit_buffer.read;
    0.5 => hit_buffer.gain; // give it all, baby
    1.0 => hit_buffer.rate; // inital note is low E
    41.203445 => float hit_buffer_freq; //Hz
    hit_buffer => dac; // ready to rock

    SinOsc s => JCRev r => dac;
    SinOsc so1 => JCRev ro1 => dac;
    // initialize
    0.5 => s.gain;
    0.5 => so1.gain;
    0.05 => r.mix;
    0.05 => ro1.mix;
    // 100.0::ms => dur envelopeDuration => e.duration;

    fun void playFrequency( float frequency)
    {
        frequency / hit_buffer_freq => hit_buffer.rate;
        frequency * 1.0 => s.freq;
        frequency * 2 => so1.freq;
        0 => s.phase;
        0 => so1.phase;
        0 => hit_buffer.pos;
        // e.keyOn();
    }

    fun void setRate( float rate )
    {
        rate => hit_buffer.rate;
    }

}

PanicHit panicHit;


// base and register
12 => int base;
1 => int register;
0 => int reg_change;

Hid kb;
// Hid mouse;
HidMsg msg;
// 0 => int mouse_dev;
// if( !mouse.openMouse( mouse_dev ) ) me.exit();
// <<< "* mouse ready...", "" >>>;
//
//
//
// while( true )
// {
//     // wait
//     mouse => now;
//     // loop over messages

// }



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
0 => int stop;
0 => int twiceTheSpeed;

[ 0, 4, 7, 9, 10, 9, 7, 4 ] @=> int scale[];
0 => int scaleIndex;

// infinite event loop
while( true )
{
    // wait for event
    // kb => now;

    // get message
    while( kb.recv( msg ) )
    {
        // which
        <<< msg.which >>>;
        if (msg.which == 30) 0 => twiceTheSpeed; // 1
        if (msg.which == 31) 1 => twiceTheSpeed; // 2
        if (msg.which == 44) 1 => stop; // [space]
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
            key[msg.which] + 12 => base;
            0 => scaleIndex;
            // panicHit.playFrequency(freq);
            // <<< freq, "" >>>;
            // fire!
            // 1 => bar.noteOn;
            // 0 => hit_buffer.pos;
            // 427::ms => now;
        }
    }

    if (stop == 1) {
        base + register * 12 => Std.mtof => freq;
        panicHit.playFrequency(freq);
        1::second => now;
        break;
    }
    else {
        base + register * 12 + scale[scaleIndex] => Std.mtof => freq;
        panicHit.playFrequency(freq);
        if (twiceTheSpeed) 213.5::ms => now;
        else 427::ms => now;
        if (scaleIndex < 7) scaleIndex++;
        else 0 => scaleIndex;
    }


    // while( mouse.recv( msg ) )
    // {
    //     if( msg.isMouseMotion() )
    //     {
    //         // <<< msg.members >>>;
    //     }
    // }
}
