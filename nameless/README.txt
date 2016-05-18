To run server:

chuck run-nameless-server.ck:(local)
processing-java --sketch=`pwd`/world --run

dependencies: oscP5 and Ani (move folders to processing's sketchbook)
if local is not specified, initializes clients as listed in the source.

--------------------------------------------------------------------------------

To run local:

chuck run-nameless-go.ck:(name of server)

if name of server is not specified, assumed to be localhost.

--------------------------------------------------------------------------------

To do:
- server ability to change color of client
- client needs to have a color map
  - more sound sources
- nathan slew color on server

CLIENT KEYMAP
 - <SPACE>             to begin / enter world
 - ^v<> keys           to navigate world
 - d                   to rearticulate drone (on your current position)
 - 1-0                 to 'tinkle' (clocked by server)
 - j                   to 'jump' (clocked by server)

SERVER KEYMAP
 - g                   to slew to random g
 - b                   to slew to random b
 - r                   to slew to random r
 - y                   <not implemented>
 - p                   to use pentatonic scale
 - h                   to use hirajoshi scale
 - a                   to use aminor
 - d                   to use dminor
 - zxcv                to set ADSR presets on all clients