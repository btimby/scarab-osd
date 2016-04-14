// Minimal STK500 implementation
// Protocol document:
// http://www.atmel.com/Images/doc2525.pdf
// Example source code:
// https://github.com/robokoding/STK500

int DELAY = 50;

void update_OSD(String port, File firmware){
  println("updating");
  int c, i;
  Serial serial = new Serial(this, port, 57600); //<>//
  println("serial open");
  
  for (i = 0; i < 25; i++){
    serial.write(0x30);
    serial.write(0x20);
    try{
      Thread.sleep(DELAY);
    } catch (InterruptedException e) {}
  }
  
  // CONFIRM ACK
  // TODO: DISPLAY MESSAGES TO USER.
  c = serial.read();
  if (c != 0x14){
    println("ACK Failed");
    return;
  }
  c = serial.read();
  if (c != 0x10){
    println("ACK Failed");
    return;
  }

  println("entered programming mode");

  FileInputStream fs;
  long buffSize, start, end, fileSize = firmware.length();
  int laddress, haddress, address = 0;
  byte[] buffer = new byte[128];
  
  try {
    fs = new FileInputStream(firmware);
  } catch (FileNotFoundException e) {
    // TODO: inform user
    println("File not found");
    return;
  }

  println("writing data: " + fileSize);

  for (i = 0; i < fileSize; i += 128){
    // find start and end of our chunk. If chunk extends past EOF shrink chunk to EOF.
    start = i;
    end = i + 127;
    if (end > fileSize){
      end = fileSize - 1;
    }
    buffSize = end - start + 1;

    println("writing " + start + " to " + end);

    // read our buffer
    try {
      fs.read(buffer, 0, (int)buffSize);
    } catch(IOException e) {
      // TODO: inform user
      println("read failed");
      return;
    }
    
    // TODO: we can use our file size and s,e values to calculate progress.
    
    // prepare to write to region of memory
    laddress = address % 256;
    haddress = address / 256;
    address += 64;
    serial.write(0x55);
    serial.write(laddress);
    serial.write(haddress);
    serial.write(0x20);
    try{
      Thread.sleep(DELAY);
    } catch (InterruptedException e) {}
    
    // CONFIRM ACK
    // TODO: DISPLAY MESSAGES TO USER.
    c = serial.read();
    if (c != 0x14){
      println("ACK Failed");
      return;
    }
    c = serial.read();
    if (c != 0x10){
      println("ACK Failed");
      return;
    }

    serial.write(0x64);
    serial.write(0x00);
    serial.write((byte)buffSize);
    serial.write(0x46);
    for (int ii = 0; ii < buffSize; ii++){
      serial.write(buffer[ii]);
    }
    serial.write(0x20);
    try{
      Thread.sleep(DELAY);
    } catch (InterruptedException e) {}
    
    // CONFIRM ACK
    // TODO: DISPLAY MESSAGES TO USER.
    c = serial.read();
    if (c != 0x14){
      println("ACK Failed");
      return;
    }
    c = serial.read();
    if (c != 0x10){
      println("ACK Failed");
      return;
    }
  }

  println("done writing");

  serial.write(0x51);
  serial.write(0x20);
  try{
    Thread.sleep(DELAY);
  } catch (InterruptedException e) {}
  
  // CONFIRM ACK
  // TODO: DISPLAY MESSAGES TO USER.
  c = serial.read();
  if (c != 0x14){
    println("ACK Failed");
    return;
  }
  c = serial.read();
  if (c != 0x10){
    println("ACK Failed");
    return;
  }

  println("Success");

  //success.
  serial.clear();
  serial.stop();
}
