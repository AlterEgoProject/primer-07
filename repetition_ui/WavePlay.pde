

public class WavePlay {
  int buffersize;
  int playersize;
  float samplerate;
  
  AudioPlayer player;
  
  public WavePlay(Minim minim, String file_name){
    player = minim.loadFile(file_name);
    buffersize = player.bufferSize();
    playersize = player.length();
    samplerate = player.sampleRate();
  }
  
  void play(){ player.play(); }
}
