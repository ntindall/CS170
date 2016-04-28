Our instrument takes in input from both the keyboard and a GameTrak controller
in order to control properties of the way that a sound file is granularized.

The instrument has notions of "registers," which control the rate at which the
playback is played (default is 1). Pressing 1 changes register to .1, 2 to .2,
etc. This pattern follows up until 8 (to .8), after which pressing 9 on the
keyboard will shift to register (1.6). We have experimented with different
combinations of the registers (for multiple instruments), and have mainly
been working with powers of '2' (.2, .4, .8, 1.6, etc.). When shifting
registers, the rate is interpolated between start and end.

The instrument has 4 basic volume settings controller by 'Q','W', 'E', 'R' and
increasing from left to right. When switching volume, the rate is interpolated
from beginning to end.

Finally, the (left) GameTrack controller changes the sound as follows:

Z position => position in the file
X position => rate of granularization
Y position => divided into four segments which represent octaves. Shifting 
              Y position up and down while holding the other values constant
              will cause 3 subsequent octave jumps (from bottom most segment
              to upper most segment).

There is keyboard output to give real time feedback to the performer to aid them
in their control of the instrument.

