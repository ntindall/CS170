import oscP5.*;
import de.looksgood.ani.*;

// osc
OscP5 oscP5;

// data
Colors colors = new Colors();
static int N_PLAYERS = 2;

// geometry
Blob[] blobs = new Blob[N_PLAYERS];

void setup() {
  size(1920, 1080, P2D);
  smooth(8);
  noStroke();
  noCursor();
  // fullScreen(2);
  frameRate(30);

  Ani.init(this);
  
  oscP5 = new OscP5(this, 4242);

  initWorld();
  
  /* osc plug service
   * osc messages with a specific address pattern can be automatically
   * forwarded to a specific method of an object. in this example 
   * a message with address pattern /test will be forwarded to a method
   * test(). below the method test takes 2 arguments - 2 ints. therefore each
   * message with address pattern /test and typetag ii will be forwarded to
   * the method test(int theA, int theB)
   */
  oscP5.plug(this, "updatePlayer", "/nameless/graphics/position");
}

void draw() {
  background(0);

  for (int i = 0; i < N_PLAYERS; i++) {
    Blob blob = blobs[i];
    if (blob != null)
      blob.draw();
  }
}

void initWorld() {
  for (int id = 0; id < N_PLAYERS; ++id) {
    blobs[id] = new Blob(id);
    blobs[id].show();
  }
}

void updatePlayer(int id, int x, int y) {
  blobs[id].setX(x);
  blobs[id].setY(y);
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage oscMsg) {
  /* with theOscMessage.isPlugged() you check if the osc message has already been
   * forwarded to a plugged method. if theOscMessage.isPlugged()==true, it has already 
   * been forwared to another method in your sketch. theOscMessage.isPlugged() can 
   * be used for double posting but is not required.
  */  
  if (oscMsg.isPlugged() == false) {
    /* print the address pattern and the typetag of the received OscMessage */
    println("### received an osc message.");
    println("### addrpattern\t" + oscMsg.addrPattern());
    println("### typetag\t"+ oscMsg.typetag());
  }
}