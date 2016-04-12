Machine.add("./gametrak.ck");
// spork control
spork ~ gametrak();
// print
spork ~ print();

Machine.add("./frankenstein.ck");
spork ~ watchGametrak();