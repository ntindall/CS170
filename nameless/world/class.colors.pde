class Colors {
  static final int N_COLORS = 4;
  color[] colors = {
    color(255, 45, 85),
    color(246, 178, 34),
    color(21, 158, 239),
    color(169, 208, 5)
  };

  Colors() {
  }

  color getById(int id) {
    if (id < N_COLORS)
      return colors[id];
    else 
      return colors[0];
  }
}