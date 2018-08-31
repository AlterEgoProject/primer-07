// http://marumo.hatenablog.com/entry/2014/12/31/200156
import java.io.*;
import javax.sound.sampled.*; 

public class WavFileWriter extends Thread {
    private AudioInputStream audioInputStream;
    private File outputFile;

    private BufferedOutputStream bufOutput = null;
    private BufferedInputStream bufInput = null;

    private int MAX_VALUE;
    private int MIN_VALUE;

    private ByteBuffer bb;

    private int byteOffset;
    private int sampleSizeInByte;

    private static final int INT_BYTE_LENGTH = 4;

    private int n;// write values

    public WavFileWriter(File output, AudioFormat format, long frameLenght) {
        
        this.outputFile = output;

        try {
            PipedOutputStream outputStream = new PipedOutputStream();
            PipedInputStream inputStream = new PipedInputStream();
            outputStream.connect(inputStream);
            bufOutput = new BufferedOutputStream(outputStream);
            bufInput = new BufferedInputStream(inputStream);

            int sampleSizeInBit = format.getSampleSizeInBits();
            this.sampleSizeInByte = sampleSizeInBit / 4;

            this.bb = ByteBuffer.allocate(INT_BYTE_LENGTH);
            if (format.isBigEndian()) {
                this.bb.order(ByteOrder.BIG_ENDIAN);
                this.byteOffset = INT_BYTE_LENGTH - sampleSizeInByte;
            } else {
                this.bb.order(ByteOrder.LITTLE_ENDIAN);
                this.byteOffset = 0;
            }

            MAX_VALUE = (int) (Math.pow(2, sampleSizeInBit) - 1);
            MIN_VALUE = (int) (-Math.pow(2, sampleSizeInBit));
            
            audioInputStream = new AudioInputStream(bufInput, format, frameLenght);
            //println(format.toString());
            this.start();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void close() {
        try {
            bufOutput.flush();
            bufOutput.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void putFrame(int[] values) throws IOException {
        for (int ch = 0; ch < values.length; ch++) {
            n = Math.min(MAX_VALUE, values[ch]);
            n = Math.max(MIN_VALUE, n);
            short short_n = (short)n;
            this.bb.putShort(0, short_n);
            this.bb.putShort(2, short_n);
            bufOutput.write(bb.array(), byteOffset, sampleSizeInByte);
        }
    }

    public void run() {
        try {
            AudioSystem.write(audioInputStream, AudioFileFormat.Type.WAVE, outputFile);
            audioInputStream.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

}
