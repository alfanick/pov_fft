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
byte[] buffer = new byte[180];

void send_translate() {
    int buffer_position = 0;
    boolean mode = true;
    
    byte to_send = 0;
    int tmp;
  /*  
    pov.write(255);
    pov.write(255);
    pov.write(255);
    pov.write(255);
    pov.write(255);
    */
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
    
    pov.write(buffer);
}  


void setup() {
  size(640, 480, P3D);
  //rectMode(CORNERS);

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
  println("abc:");
  for(int i = 0; i < fftLog.avgSize()/2; i++)
  {
    v = fftLog.getAvg(i);
    // draw a rectangle for each average, multiply the value by spectrumScale so we can see it better
    rect(i*w, height-50, i*w + w, height - v*spectrumScale );
    
    colors[i][1] = byte(min(v, 255));
    
    if (v > 255) {
      v -= 255;
      colors[i][0] = byte(min(v, 255));
    }
      

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
