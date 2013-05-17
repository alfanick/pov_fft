import ddf.minim.analysis.*;
import ddf.minim.*;

import processing.serial.*;

Minim minim;  
AudioPlayer music;
FFT fftLog;

Serial pov;

float height3, height23;
float spectrumScale = 2;

byte[][] colors = new byte[40][3];
byte[] buffer = new byte[185];

class FFTThread extends Thread {
  fftLog = new FFT(music.bufferSize(), music.sampleRate());
  fftLog.logAverages(22, 8);
  
  PApplet context;  
  FFT fftLogarithm;
  AudioPlayer musicHandler;
  
  boolean isRunning;
  String musicFile;


  FFTThread(PApplet context, String musicFile, ) {
    this.isRunning = false;
    this.context = context;
    this.musicFile = musicFile;
  }
  
  void start() {
    minim = new Minim(context);
    music = minim.loadFile(musicFile, 2048);
    musicHandler.loop();
    musicHandler.mute();
    
    fftLogarithm =new FFT(musicHandler.bufferSize(), musicHandler.sampleRate());
    fftLogarithm.logAverages(22, 8);


    isRunning = true;
    super.start();    
  }
  
  void run() {
    while(isRunning) {
       
    }
  }
  
  void quit() {
    isRunning = false;
    interrupt();
  }
}

class SenderThread extends Thread {
  
  PApplet context; 
  Serial BTSerial;
  byte[] buffer;
  boolean withTransmissionInitSeq;
  boolean isRunning;
  
  SenderThread(PApplet context, boolean withTransmissionInitSeq) {
    
    this.withTransmissionInitSeq = withTransmissionInitSeq;
    this.isRunning = false;
    this.context = context;
    
    if ( this.withTransmissionInitSeq)
      this.buffer = new byte[185];
    else 
      this.buffer = new byte[180];
      
  }
  
  void start() {
    try {
      BTSerial = new Serial(context, "/dev/tty.POVINF2011-SPP", 115200);
    } 
    catch (Exception e) {
      print("Could not open serial port");
      interrupt();
    }
    
    isRunning = true;
    super.start();
  }
  
  void run() {
    while(isRunning) {
    
    }
  }
  
  void sendWithTransmissionInit(){
    int buffer_position = 0;
    boolean mode = true;
    
    byte to_send = 0;
    int tmp;
    
    for (int i=0; i<5; i++){
      buffer[i] = byte(255);
    }
    
    for (int i = 0; i < 40; i++) {
      for (int j = 0; j < 3; j++) {
        tmp = (colors[i][j] * 4095) / 255;
        // wysylka prawych 8 bitow
        if (mode) {
            buffer[5+buffer_position++] = byte(tmp >> 4);
            
            to_send = byte((tmp << 12) >> 8);
        } else {
            to_send |= (tmp >> 8);

            buffer[5+buffer_position++] = byte(to_send);

            buffer[5+buffer_position++] = byte((tmp << 8) >> 8);
        }

        mode = !mode;
      }
    }
   
    BTSerial.write(buffer);
  }
  
   
  void sendWithoutInit(){
    
    int buffer_position = 0;
    boolean mode = true;
    
    byte to_send = 0;
    int tmp;
    
    for (int i = 0; i < 40; i++) {
      for (int j = 0; j < 3; j++) {
        tmp = (colors[i][j] * 4095) / 255;
        // wysylka prawych 8 bitow
        if (mode) {
            buffer[buffer_position++] = byte(tmp >> 4);
            
            to_send = byte((tmp << 12) >> 8);
        } else {
            to_send |= (tmp >> 8);

            buffer[buffer_position++] = byte(to_send);

            buffer[buffer_position++] = byte((tmp << 8) >> 8);
        }

        mode = !mode;
      }
    }
   
    BTSerial.write(buffer);
  }
  
  void quit() {
      isRunning = false;
      BTSerial.stop();
      interrupt();
  }
}




void send_translate() {
    int buffer_position = 0;
    boolean mode = true;
    
    byte to_send = 0;
    int tmp;
    
    for (int i=0; i<5; i++){
      buffer[i] = byte(255);
    }
    
    for (int i = 0; i < 40; i++) {
      for (int j = 0; j < 3; j++) {
        tmp = (colors[i][j] * 4095) / 255;
        // wysylka prawych 8 bitow
        if (mode) {
            buffer[5+buffer_position++] = byte(tmp >> 4);
            
            to_send = byte((tmp << 12) >> 8);
        } else {
            to_send |= (tmp >> 8);

            buffer[5+buffer_position++] = byte(to_send);

            buffer[5+buffer_position++] = byte((tmp << 8) >> 8);
        }

        mode = !mode;
      }
    }
   
    pov.write(buffer);
}  


void setup() {
  size(1000, 800, P3D);
  rectMode(CORNERS);

  height3 = height/3;
  height23 = 2*height/3;
  
  minim = new Minim(this);
  music = minim.loadFile("music.mp3", 2048);
  music.loop();
  
  fftLog = new FFT(music.bufferSize(), music.sampleRate());
  fftLog.logAverages(22, 8);
  
  try {
    pov = new Serial(this, "/dev/tty.POVINF2011-SPP", 115200);
  } 
  catch (Exception e) {
  }
}

void draw() {
  background(0);
  // perform a forward FFT on the samples in jingle's mix buffer
  // note that if jingle were a MONO file, this would be the same as using jingle.left or jingle.right
  stroke(255);
  
  noStroke();
  fill(255);
  
  // draw the linear averages
  // draw the logarithmic averages
  fftLog.forward(music.mix);
  int w = int(width/fftLog.avgSize()*2);
  float v = 0;
  for(int i = 0; i < fftLog.avgSize()/2; i++)
  {
    v = fftLog.getAvg(i);
    // draw a rectangle for each average, multiply the value by spectrumScale so we can see it better
    
    fill(255);
    rect(i*w, height-50, i*w + w, height - v*spectrumScale - 50);
    
    colors[i][1] = byte(min(v, 255));
    
    if (v > 255) {
      v -= 255;
      colors[i][0] = byte(min(v, 255));
    }
    
    fill(colors[i][0], colors[i][1], 0);
    rect(i*w, height, i*w+w, height-50);

    fill(255);
    text(int(v), i*w,height-25);

  }
  
  send_translate();
}

void stop()
{
  music.close();
  minim.stop();
  pov.stop();
  super.stop(); 
}
