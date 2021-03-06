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
byte[] buffer = new byte[45];

void send_translate() {
    int buffer_position = 5;
    boolean mode = true;
    
    byte to_send = 0;
    int tmp;
    
    
    buffer[0] = byte(255);
    buffer[1] = byte(255);
    buffer[2] = byte(255);
    buffer[3] = byte(255);
    buffer[4] = byte(255);
    
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
    for (int i = 0; i < 40; i++) {
      for (int j = 0; j < 3; j++) {
        colors[i][j] = 0;
      }
    }
}  

void send_translate_254() {
    int buffer_position = 5;
    boolean mode = true;
    
    byte to_send = 0;
    int tmp;
    
    
    buffer[0] = byte(254);
    buffer[1] = byte(254);
    buffer[2] = byte(254);
    buffer[3] = byte(254);
    buffer[4] = byte(254);
    
    for (int i = 0; i < 40; i++) {
      buffer[i+5] = byte(abs(map(colors[i][0], 0, 255, 0, 40)));
      print(buffer[i+5]);print(' ');
    }
    print("\n");
    
    pov.write(buffer);
    for (int i = 0; i < 40; i++) {
      for (int j = 0; j < 3; j++) {
        colors[i][j] = 0;
      }
    }
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
    rect(i*w, v+50, w, height - 50);
    
    colors[i][0] = byte(min(v, 255));
    /*
    colors[i][1] = byte(min(v, 64) * 255 / 140);
    
    if (v > 64) {
      v -= 64;
      colors[i][0] = byte(min(v, 192) * 255 / 192);
      if (v > 0) {
        v -= 140;
        colors[i][2] = byte(min(v, 255));
      }
    }
    */
  }
  
  send_translate_254();
} //

void stop()
{
  music.close();
  minim.stop();
  pov.stop();
  super.stop(); 
}
