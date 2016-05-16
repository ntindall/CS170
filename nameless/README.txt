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