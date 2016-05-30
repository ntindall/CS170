Xmitter xmit;
xmit.init(me.arg(0));

<<< "Killing all clients" >>>;
for (int z; z < xmit.targets(); z++)
{
  // a message is kicked as soon as it is complete 
  <<< "Killing 1" >>>;
  xmit.at(z).startMsg( "/slork/kill");
}
<<< "Done" >>>;
1::second => now;