import ddf.minim.analysis.*;
import ddf.minim.*;

WavePlay wp;
WaveMic wm;
WaveHandler wh;
WaveHandler wh_mic;

Minim minim;

//サンプル音源のファイル名
String sampleFile = "data/voice_collection.wav";

String tempSampleName = "data/temp/sample.wav";
String tempMicName = "data/temp/mic.wav";

final int FRAME_RATE = 60;
final int CAL_CHUNK = 1024;

int counter=0;
float bar = 0;
int sample_length = 10000;
int array_num = 0;

boolean isRecording;
boolean isRecorded;
boolean canPlay;

FFT fft;

int specsize;

void setup(){
  size(1000,600);
  frameRate(FRAME_RATE);
  
  // voiceSample を集めてくる
  wh = new WaveHandler(sampleFile);
  array_num = wh.sampleArray.size();
  
  minim = new Minim(this);
  
  wp = new WavePlay(minim, sampleFile);
  wm = new WaveMic(minim, wp.buffersize, wp.samplerate);
  //fft = new FFT( wp.buffersize, wp.samplerate );
  //specsize = fft.specSize();
  initRecord();
}

void draw(){
  stroke(255);
   if ( canPlay ) {
   wh.play_sample(counter);
   canPlay = false;
 }
 
  if ( isRecording ){
    drawRecord();
    
    bar += width / (sample_length/wp.samplerate) / FRAME_RATE;
    if(bar >= width){
      // 録音停止
      stopRecord();
      bar = 0;
      calError();
      isRecorded = true;
    }
 }

}

ArrayList<Integer> best_record;
float best_error;

void initRecord(){
  isRecording = false;
  isRecorded = false;
  drawSample();
  wh.Integer2wav(wh.sampleArray.get(counter),tempSampleName);
  canPlay = true;
  best_record = new ArrayList<Integer>();
  best_error = (float)Math.pow(10,5);
  println("--- initRecord "+counter+" ---");
}

void keyPressed() {
  if (key == CODED) {      // コード化されているキーが押された
    if (keyCode == UP) {    // キーコードを判定
      if( isRecorded ){ saveWav(); }
    } else if (keyCode == DOWN) {
       startRecord();
    } else if (keyCode == RIGHT) {
       counter++;
       if (counter > array_num-1) counter = 0;
       initRecord();
    } else if (keyCode == LEFT) {
       counter--;
       if (counter < 0) counter = array_num-1;
       initRecord();
    }
  }
}

void drawSample(){
  background(255);
  stroke(0);
  ArrayList<Integer> data = wh.sampleArray.get(counter);
  sample_length = data.size();
  for( int i = 0; i < sample_length - 1; i++ ){
    float x1  =  map( i, 0, sample_length, 0, width );
    float x2  =  map( i+1, 0, sample_length, 0, width );
    line( x1, (1 - data.get(i)/32767.) * height/2, x2, (1 - data.get(i+1)/32767.)*height/2);
  }
}

void drawRecord(){
  //line( bar, 0, bar, height);
  stroke(255,0,0);
  for(int i = 0; i < wp.buffersize-1; i++){
    float x1  =  map( i, 0, wp.buffersize, 0, 1 );
    float x2  =  map( i+1, 0, wp.buffersize, 0, 1 );
    line( bar-x1, (1-wm.in.mix.get(i)) * height/2, bar-x2, (1 - wm.in.mix.get(i+1)) * height/2);
  } 
}

// 録音スタート
void startRecord(){
  isRecording = true;
  wm.start(tempMicName);
}
void stopRecord(){
  isRecording = false;
  wm.end();
}

// 横にスライド、縦にスケールさせて最小となる誤差を算出
void calError(){
  wh_mic = new WaveHandler(tempMicName);
  ArrayList<Integer> sample_wave = wh.sampleArray.get(counter);
  //println(sample_wave.size(), record_wave.size());
  if(wh_mic.sampleArray.size() != 1){
    println("--- sample_wave.size() != 1 ---");
    return; 
  }
  ArrayList<Integer> record_wave = wh_mic.sampleArray.get(0);
  if(sample_wave.size() > record_wave.size() ){
    println("--- sample_wave.size() > record_wave.size() ---");
    return;
  }
  // 最大値でスケーリング
  record_wave = max_scaling(sample_wave,record_wave);
  // 横にスライドして誤差が最小の場所 slide_length を探す 
  record_wave = slideError(sample_wave,record_wave);
  // 縦にスケーリングして誤差と誤差が最小の値 scaling_value を探す
  float[] wd = waveDifference(sample_wave,record_wave);
  float scaling_value = wd[0];
  float score = 100/(wd[1]/(sample_wave.size()/44100));
  
  // 誤差をウィンドウに表示
  fill(255);
  rect(5,5,60,30);
  fill(255,0,0);
  textSize(24);
  text((int)(score), 20, 30);
  if(wd[1] < best_error) {
    //println(wd[1]);
    best_error= wd[1];
    record_wave = arrayProcessing(record_wave,scaling_value);
    best_record = record_wave;
  }
}

ArrayList<Integer> max_scaling(ArrayList<Integer> wave1, ArrayList<Integer> wave2){
  float max1 = max_array(wave1);
  float max2 = max_array(wave2);
  return arrayProcessing(wave2,max1/max2*100);
}


int max_array(ArrayList<Integer> array){
  int max = 0;
  for(int val : array){ if(val > max){ max = val; } }
  return max;
}

ArrayList<Integer> arrayProcessing(ArrayList<Integer> array,float scaling_value){
  ArrayList<Integer> new_array = new ArrayList<Integer>();
  for(int i=0; i<array.size();i++) {
    int temp = (int)(array.get(i)*scaling_value/100.);
    if(temp>=32767){temp=32766;}
    if(temp<=-32768){temp=-32767;}
    new_array.add(new Integer(temp));
  }
  return new_array;
}

float[] waveDifference(ArrayList<Integer> wave1, ArrayList<Integer> wave2){
  float min_ss = (float)Math.pow(10,5);
  float best_scale=0;
  
  for(float scale=0 ;scale<200; scale++){
    float ss = 0;
    for(int i=0; i<wave1.size()-CAL_CHUNK; i+=CAL_CHUNK){
      int max1 = max_array(new ArrayList<Integer>(wave1.subList(i,i+CAL_CHUNK)));
      int max2 = max_array(new ArrayList<Integer>(wave2.subList(i,i+CAL_CHUNK)));
      ss += Math.pow(max1/32767. - max2/32767.*scale/100.,2);
    }
    if(ss < min_ss){ min_ss = ss; best_scale = scale; }
  }
  
  float[] results = new float[2];
  results[0] = best_scale;
  results[1] = (float)Math.sqrt(min_ss);
  return results;
}

ArrayList<Integer> slideError(ArrayList<Integer> wave1, ArrayList<Integer> wave2){
  int slide_diff = 0;
  float min_ss = (float)Math.pow(10,5);
  int array_len = Math.min(wave1.size(), wave2.size());
  for(int i=0; i< wave2.size() - array_len + 1; i++){
    ArrayList<Integer> seg_wave = new ArrayList<Integer>(wave2.subList(i,i+array_len));
    float ss = waveError(wave1,seg_wave);
    //println(ss);
    if(ss < min_ss){ min_ss = ss; slide_diff = i; }
  }
  return new ArrayList<Integer>(wave2.subList(slide_diff,slide_diff+array_len));
}

float waveError(ArrayList<Integer> wave1, ArrayList<Integer> wave2){
  float ss=0;
  for(int i=0; i<wave1.size()-CAL_CHUNK; i+=CAL_CHUNK){
    int max1 = max_array(new ArrayList<Integer>(wave1.subList(i,i+CAL_CHUNK)));
    int max2 = max_array(new ArrayList<Integer>(wave2.subList(i,i+CAL_CHUNK)));
    ss += Math.pow(max1/32767.-max2/32767.,2);
  }
  return ss;
}

// voiceSample と voice_record の wav を保存
void saveWav(){
  // ファイル名のために data/input内のファイル数を取得
  FilenameFilter filter = new FileFilter();
  File[] waveFiles = new File(dataPath(sketchPath("data/input"))).listFiles(filter);
  String out_file;
  out_file = "data/input/"+waveFiles.length+".wav";
  wh.Integer2wav(best_record,out_file);
  out_file = "data/output/"+waveFiles.length+".wav";
  wh.Integer2wav(wh.sampleArray.get(counter),out_file);
  println("--- saveWav "+waveFiles.length+"--- ");
}
