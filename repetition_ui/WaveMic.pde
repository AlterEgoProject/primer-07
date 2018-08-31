import ddf.minim.ugens.*;

public class WaveMic {
  
  AudioInput in;
  AudioRecorder recorder;
  
  public WaveMic(Minim minim, int buffersize, float samplerate){
    in = minim.getLineIn(Minim.STEREO,buffersize,samplerate);
  }
  
  void start(String tempFileName){ 
    recorder = minim.createRecorder(in, tempFileName);
    recorder.beginRecord();
  }
  void end(){ 
    recorder.endRecord();
    recorder.save();
  }
}
