// http://krr.blog.shinobi.jp/javafx_praxis/java%E3%81%A7%E5%91%A8%E6%B3%A2%E6%95%B0%E5%88%86%E6%9E%90%E3%82%92%E3%81%97%E3%81%A6%E3%81%BF%E3%82%8B
import java.io.File;
import java.io.ByteArrayInputStream;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;

import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.SourceDataLine;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.AudioFileFormat;

import java.util.Arrays;

import org.apache.commons.lang3.ArrayUtils;

class WaveHandler{
     
    // 取得する音声情報用の変数
    AudioFormat format = null;
    int frameLength;
    ArrayList<ArrayList<Integer>> sampleArray;
    SourceDataLine source;
     
    /**
     * 音声ファイルを読み込み、メタ情報とサンプリング・データを取得
     * @throws Exception
     */
    public WaveHandler(String fileName){
      try{
        __init__(fileName);
      } catch (Exception e){
        println("--- WaveHandler error!!! ---");
        e.printStackTrace(System.err);
        exit();
      }
    }
    
    void __init__(String fileName) throws Exception{
        File file = new File( sketchPath(fileName) );
        AudioInputStream is = AudioSystem.getAudioInputStream( file );
        //println("--- WaveHandler file read ---");
         
        // メタ情報の取得
        format = is.getFormat();
        //println( format.toString() );
        
        frameLength = (int)is.getFrameLength();
        
        // 音声データの取得
        ArrayList<Integer> valuesActual = new ArrayList<Integer>();
        sampleArray = new ArrayList<ArrayList<Integer>>();
        int zero_counter = 0;
        int ZERO_THRESHOLD = 100;
        boolean zero_sequence = true;
        for( int i=0 ; i<frameLength ; i++ ){
            if((i+1)%(44100*10)==0){ 
            println("--- loaded "+(int)(100.*i/frameLength)+"% ("+sampleArray.size()+")--");
          }
            // 1標本分の値を取得
            int size = format.getFrameSize();
            byte[] data = new byte[ size ];
            int readedSize = is.read(data);
             
            // データ終了でループを抜ける
            if( readedSize == -1 ){ break; } 
             
            // 1標本分の値を取得
            switch( format.getSampleSizeInBits() ){
                case 8:
                    valuesActual.add( (int) data[0] );
                    break;
                case 16:
                    int temp_val = byte2int(data);
                    if (!zero_sequence){
                      valuesActual.add( temp_val );
                    }
                    if(temp_val<10 && temp_val>-10) { 
                      zero_counter++;
                      if( zero_counter > ZERO_THRESHOLD ){ zero_sequence = true;}
                    } else {
                      if(zero_sequence){ 
                        if( checkData(valuesActual)){
                          sampleArray.add(valuesActual); 
                          valuesActual = new ArrayList<Integer>();
                          //for(int j=0;j<ZERO_THRESHOLD;j++){valuesActual.add(0);}
                        }
                        zero_sequence = false;
                      }
                      zero_counter = 0;
                    }
                    break;
                default:
            }
        }
        if( checkData(valuesActual)){ sampleArray.add(valuesActual); }
        
        // 音声ストリームを閉じる
        is.close();
        // ソースデータラインを取得
        DataLine.Info info = new DataLine.Info( SourceDataLine.class, format );
        source = (SourceDataLine)AudioSystem.getLine( info );
        
        //println("--- WaveHandler data listed ---");
        
        
        
    }
    
    boolean checkData(ArrayList<Integer> data){
      if(data.size()<44100){return false;}
      int[] int_data = new int[data.size()];
      for(int i=0; i<data.size(); i++){ int_data[i] = data.get(i); }
      if(max(int_data)<10){return false;}
      return true;
    }
    
    public int byte2int(byte[] byte_data){
      return (int) ByteBuffer.wrap( byte_data ).order( ByteOrder.LITTLE_ENDIAN ).getShort();
    }
    
    public byte[] int2byte(int wave){
      byte[] data = ByteBuffer.allocate(4).putInt(wave).array();
      byte[] new_data = {data[3],data[2],data[3],data[2]};
      return new_data;
    }
    
    byte[] create_byteData(ArrayList<Integer> array_data){
      ArrayList<Byte> temp_byte = new ArrayList<Byte>();
      for (int i=0; i<array_data.size();i++){
        byte[] data = ByteBuffer.allocate(4).putInt(array_data.get(i)).array();
        for(int j=0;j<2;j++){
          temp_byte.add(data[3]);
          temp_byte.add(data[2]);
        }
      }
      Byte[] bytes = temp_byte.toArray(new Byte[temp_byte.size()]);
      return ArrayUtils.toPrimitive(bytes);
    }
    
    ArrayList<Integer> create_arrayData(byte[] byte_data){
      ArrayList<Integer> array_data =new ArrayList<Integer>();
      for(int j=0; j<byte_data.length;j+=4){
          int temp_val = byte2int(Arrays.copyOfRange(byte_data,j,j+4));
          array_data.add(temp_val);
        }
      return array_data;
    }
    
    void play_sample(int index){
      play_array(sampleArray.get(index));
    }
    
    void play_array(ArrayList<Integer> array_data){
      byte[] data = create_byteData(array_data);
      // スピーカー出力開始
      try{source.open( format );}
      catch (Exception e) {
        println("--- SourceDataLine error!!! ---");
        return;
      }
      source.start();
      source.write( data, 0, data.length );
      source.drain();
      source.close();
    }
    
    void Integer2wav(ArrayList<Integer> data, String file_name) {
      try{
        File outFile = new File( sketchPath(file_name) );
        WavFileWriter writer = new WavFileWriter(outFile, format, frameLength);
          int sampleLength = data.size();
          Integer[] int_sample = data.toArray(new Integer[sampleLength]);
          for(int j=0; j<sampleLength; j++){
              Integer[] temp_sample = Arrays.copyOfRange(int_sample,j,j+1);
              writer.putFrame(ArrayUtils.toPrimitive(temp_sample));
          }
        writer.close();
      } catch (Exception e){
        println("--- Integer2wav error!!! ---");
        e.printStackTrace(System.err);
        exit();
      }
    }
}
