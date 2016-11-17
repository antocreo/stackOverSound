/*
 //================================================================================================================================================//
 //==================================================== S T A C K   O V E R S O U N D ============================================================//
 //===============================================================================================================================================//
 
 //Author: Antonio Daniele
 //PROTOTYPE FOR A MEMORY PUZZLE FOR KIDS
 //PROJECT 01 FOR CRUFT FEST 2016
 //ECS742 Interactive Digital Media Techniques - PhD MAT Programme QMUL
 
 //STACK OVERSOUND
 //is a prototype for an interactive memory puzzle for kids.
 //It can be used with songs, sounds, separate tracks, storytelling and everything that can be splitted and shuffled.
 
 //================================================================================================================================================//
 //================================================================================================================================================//
 //================================================================================================================================================//
 
 //NOTE: TO PLAY WITH THE PHYSICA OBJECT YOU NEED TO UNCOMMENT LINE 94 AND 96 (OPEN THE SERIAL PORT)
 
 */

// importing packages and libraries
import ddf.minim.*;
import processing.serial.*; 
import java.io.*; 
import java.util.Arrays;
import processing.video.*;

PFont font;
float fontSize1, fontSize2, fontSize3;
String levelString = "SELECT DIFFICULTY";
String pleaseRemoveRings = "remove all the rings from the pin &";

int arraySize = 6;              //constant array size
int levelSize = 4;
int selectedLevel = 1;

Serial serialPort;            // The serial port
String incomingMsg = null;

int startMillis = millis();    //get the time

//create a minim obj
Minim minim;
//create a player obj array
AudioPlayer[] player = new AudioPlayer[arraySize];         //contains all the chunks
AudioPlayer totalPlayer;                                   //contains the full track

//create movei obj
Movie winMovie;

int playerIndex = 0;                                      //is the chunk that plays                  
int lastPlayerIndex = 0;                                  //keeps track of the last track played
int lastTotalPlayer = 0;    

boolean win = false;
boolean levelActive = false;
int page;

String selectedFolder; //stores the value of the random song (contained in its folder)
int randomChunk; //stores the value of the random chink of the song

StringList shuffledChunks = new StringList();            //StringList (so that I can use shuffle method) of shuffled indeces
StringList resultArray = new StringList();               //StringList that stores the result
StringList ringPosition = new StringList();              //stores the position of the ring when they activate  
String[] fromSerial = new String[arraySize];             //stores the messages taken from serial
String[] lastFromSerial = new String[arraySize];         //stores the messages taken from serial last position


Ring[] rings = new Ring[arraySize];                     // array with rings graphic
Button[] buttons = new Button[arraySize];               // array with buttons for chosing the level
Button back;

boolean startSeqOn = false;
boolean shuffled = false;
boolean stopTotal = false;

color bgColor = #FFFCE5;
color[] ringsColor = {#FAD812, #036A02, #0210F7, #12BAFA, #208904, #F28D3B};    //colors of the rings

////------------------------------------------------ SETUP-------------------------------------------////


void setup() {
  //fullScreen();
  size(800, 600, P3D);
  smooth(100);

  //set the initial page
  page = 1;

  //load all the rings on stage
  loadRings();
  //load buttons
  loadBtns();
  //load back button
  back = new Button(60, color(100, 0, 0));

  //list all the ports and begin serial
  //printArray(Serial.list());  
  //serialPort = new Serial(this, Serial.list()[5], 115200);                              //UNCOMMENT THIS TO PLAY WITH THE PHYSICAL OBJECT              
  //let's clear all the old messages
  //serialPort.clear();                                                                   //UNCOMMENT THIS TO PLAY WITH THE PHYSICAL OBJECT

  // we pass this to Minim so that it can load files from the data directory
  minim = new Minim(this);

  //run the main setup
  mainSetup();

  //setup and load the win movie
  winMovie = new Movie(this, "win.mp4");
  winMovie.loop();


  //load fonts
  font = loadFont("FuturaBT-Heavy-48.vlw");
}

////------------------------------------------------ DRAW -------------------------------------------////


void draw() {

  background(bgColor);

  //PAGE 1
  if (page == 1) {
    //display buttons
    displayBtns(width/2, height/2);
  } 
  //PAGE 2
  if (page==2) {

    //check if all the rings are on the pin/ then check if I win 
    if (ringPosition.size() == arraySize) {
      checkWin();
    } 

    //if not win draw all this
    if (!win && page == 2) {
      checkSliding();
      //draw the oscilloscope only if the player is on
      drawScope();
      //draw the base of the rings - it's just graphic no interaction.
      drawBase();
      //draw the rings
      displayRings();
      //draw back button
      backButton(50, 50);

      //just plays the full track activated with spacebar (if you get stuck and whant to listen again)
      totalPlayerControl();

      if (millis() - startMillis >10000 && !isAnyonePlaying()) {
        //let's clear all the old messages
        serialPort.clear();
      }
    }
  }//end if page 2


  //PAGE 3
  if (page == 3) {

    //draw movie etc.
    winMovie(); //play movie

    //draw back button
    backButton(50, 50);
  }
}



//==========================================    F  U  N  C  T  I  O  N   S    ========================================////


////------------------------------------------------ SERIAL EVENT -------------------------------------------////

//this function controls almost everything that happens between the physical interface and the software.

//check every incoming message from the serial port
void serialEvent(Serial mySerialPort) {

  //read the message until next line
  incomingMsg = mySerialPort.readStringUntil('\n');
  //if the message is not null and is not the start game message
  if (incomingMsg != null) {  
    incomingMsg = trim(incomingMsg);                   //trim all the white spaces
    String fromSerial[] = split(incomingMsg, ',');    //split the array coming from Ardu to individual values and store them into this array
    //println(fromSerial);

    //page 1 option
    if (page == 1) {
      if (incomingMsg.matches("r")==false && int(incomingMsg) > 0 && int(incomingMsg) <=levelSize ) {

        selectedLevel = int(incomingMsg);
        activateLevel(selectedLevel);
      }

      //if press starting sequence button...trigger the booleanz! (setup for a physical button)
    } else if (page == 2) {
      if (incomingMsg.matches("r")) {
        startSeqOn = true;
      } else {
        startSeqOn = false;
      }

      //if there is a difference in status from the previous check (I am saying to see if there are variations in the array)
      if ( !Arrays.equals(lastFromSerial, fromSerial)) {

        //iterate the rings
        for (int i=0; i<arraySize; i++) {

          //if there is a 1 message contact is HIGH, the ring is in place
          if ( fromSerial[i].equals( "1") ) {
            rings[i].isInPlace = true;

            //if the size is less than arraySize and the ring is not already in position, //put the ring in the arrayList 
            if (ringPosition.size()<arraySize && !ringPosition.hasValue(str(i))) {
              ringPosition.append(str(i));
              //we store the last position of the array
              lastPlayerIndex = int(ringPosition.get(ringPosition.size()-1));
            }
          } 
          //check also if the ring has been moved
          //iterates through the rings: if the serial msg will be 0 = LOW: the ring is not there anymore
          else if ( fromSerial[i].equals("0") ) {
            rings[i].isInPlace = false;

            //take the last ring away from the arrayList if the size is less than arraySize and there is at least one ring
            if (ringPosition.size()>0 && ringPosition.hasValue(str(i))) {
              ringPosition.remove(ringPosition.size()-1);
              //ringPosition.remove((i));

              //println("removed");
              win =false;      //I need this because if I remove a ring, win cannot be false
            }
            //if we are in a win situation it means all the 6 rings are on so we can just remove the last one and rewind and reset
            if (win) {
              //ringPosition.remove((i));
              ringPosition.remove(ringPosition.size()-1);
              if (ringPosition.size()<arraySize) {
                //reset();
              }
            }
          }
          //make the lastArray = to the former to check change of variation
          lastFromSerial[i] =  fromSerial[i];
        } //end for

        //print("msg from Serial "); 
        //println(fromSerial);
        //println("my Sequence", ringPosition);
        //println("ring n", playerIndex, "in Place", rings[playerIndex].isInPlace );
      } //end if



      //let's make the player playing just the last ring on the stack
      if (ringPosition.size()>0) {
        playerIndex = int(ringPosition.get(ringPosition.size()-1)); // just a holder for the incoming serial as a int. it says that the chunk to be played is the last ring put in place
        //println(" I passed playerINdex", playerIndex);
      }
    }
  }
}

////------------------------------------------------ CHECK SLIDING -------------------------------------------////


void checkSliding() {
  //check: if the ring is not in Place
  if (!rings[lastPlayerIndex].isInPlace) {

    player[lastPlayerIndex].pause();
    player[lastPlayerIndex].rewind();
    rings[lastPlayerIndex].hasPlayed = false;

    //otherwise if the ring is in Place && the chunk has not been played yet
  } 
  if (rings[playerIndex].isInPlace && !rings[playerIndex].hasPlayed) {

    //now you can play the relative chunk
    playChunk(player[lastPlayerIndex]);                         //play the sample if no other is playing
  }

  startMillis = millis();    //starts the counter every 1 sec
}

////------------------------------------------------ CHECK WIN -------------------------------------------////


void checkWin() {
  //check three things: all the players have stopped, all the rings are in place, the arrays ring Position and result are equal
  if (!isAnyonePlaying() && ringPosition.size() == resultArray.size() ) {
    boolean hasWon = true;
    for (int i=0; i<resultArray.size(); i++) {
      if (!ringPosition.get(i).equals(resultArray.get(i))) {
        hasWon = false;
        break;
      }
    }  
    if ( hasWon ) {
      //set it as true and go to page 3
      win = true;
      lastTotalPlayer = 0;
      page = 3;
    }
  }
}

////------------------------------------------------ WINMOVIE -------------------------------------------////


void winMovie() {
  //if win then
  if (win) {
    if (winMovie.available() == true) {
      winMovie.read();
    }
    image(winMovie, 0, 0, width, height);
    //if (totalPlayer.position()<totalPlayer.length()) {
    playChunk(totalPlayer);  
    //}
  } else {
    //stop and rewind the movie
    winMovie.jump(0);
    winMovie.pause();
  }
}

////------------------------------------------------ LOAD RANDOM CHUNKS -------------------------------------------////


//let's load the chunks
void loadRandomChunks() {
  //choose a random folder from 0-levelsize+1
  selectedFolder  = str(int(random(1, levelSize+1)));
  //load the shuffled chunks in the players  
  for (int i=0; i<arraySize; i++) {
    player[i] = minim.loadFile(selectedFolder + "/" + shuffledChunks.get(i) + ".aif");
    //println(player[i].length());
  }
}

////------------------------------------------------ LOAD CHUNKS -------------------------------------------////


//let's load the chunks
void loadChunks() {
  //choose the folder 
  selectedFolder  = str(selectedLevel);
  totalPlayer = minim.loadFile(selectedFolder + "/" + "total.aif");   //let's load the full track
  //load the shuffled chunks in the players  
  for (int i=0; i<arraySize; i++) {
    player[i] = minim.loadFile(selectedFolder + "/" + shuffledChunks.get(i) + ".aif");
    //println(player[i].length());
  }
}

////------------------------------------------------ SHUFFLE CHUNKS -------------------------------------------////


//this will shuffle the elements in the array shuffled
void shuffleChunks() {
  //fill the array

  //otherwise fill the array
  for (int i=0; i<arraySize; i++) {
    shuffledChunks.append(str(i));  //because indeces have to go from 1 to 6
  }

  //shuffle the elements in the list
  shuffledChunks.shuffle();
  shuffled  =true;
  //println("shuffled", shuffledChunks);
}

////------------------------------------------------ FILL RESULT ARRAY -------------------------------------------////


void fillResultArray() {

  //find the lower value and get me the index
  for (int i = 0; i<shuffledChunks.size(); i++) {
    //get the value of shuffled and fill the result with the index as a string
    //what is doing here is basically inverting the index and the element to get the result sequence
    int last = int(shuffledChunks.get(i)); //stores the initial value
    resultArray.set(last, str(i));
  }
  //println("result", resultArray);
}

////------------------------------------------------ PLAY CHUNK -------------------------------------------////

//manage the chunk playing
void playChunk(AudioPlayer p) {
  //if there's nothing playing
  if (!isAnyonePlaying()) {
    p.play();
    rings[playerIndex].hasPlayed = true;
    //println("has played?", rings[playerIndex].hasPlayed);
  }
  //check if the chunk has played all
  if (p.position() == p.length() ) {
    p.pause();
    p.rewind();
    rings[playerIndex].hasPlayed = false;
    //println("END!", rings[playerIndex].hasPlayed);
  }
}

////------------------------------------------------ IS ANYONE PLAYING? -------------------------------------------////

//tell me if any player is playing
boolean isAnyonePlaying() {

  boolean[] value = new boolean [arraySize];

  for (int i=0; i<arraySize; i++) {
    value[i] = player[i].isPlaying();
    if (value[i]) {
      return true;
    }
  }
  return false;
}


////------------------------------------------------ STARTING SEQUENCE -------------------------------------------////

/*
        //when the game starts play the sequence
 void startingSequence() {
 if (startSeqOn) {
 println("starting sequence");
 //let's clear all the old messages
 //serialPort.clear();
 playChunk(totalPlayer);
 
 println("end of starting sequence");
 }
 }
 */

////------------------------------------------------ LOAD RINGS -------------------------------------------////


void loadRings() {
  //loading all the rings
  float startSize = width/2;
  float ringH = 50;
  float perc = 15;
  for (int i=0; i<arraySize; i++) {
    rings[i] = new Ring(startSize - percentage(startSize, perc)*i, ringH, ringsColor[i]);
    //we set them out of the wood pin and not sliding
    rings[i].isInPlace = false;
    rings[i].isSliding = false;
    //println(rings[i].isInPlace + " " + rings[i].isSliding);
  }
}

////------------------------------------------------ DISPLAY RINGS -------------------------------------------////


void displayRings() {
  //just displaying the rings
  pushStyle();
  rectMode(CENTER);
  float xOffset = width/2;
  float increment = 0;
  float fromBottom = 50;
  float interSpace = 1;

  //stable version 
  //for (int i=0; i<arraySize; i++) {
  //rings[i].display(xOffset, height - fromBottom - (rings[i].h/2  +  increment));
  //increment += rings[i].h + interSpace;
  //}

  //this one is fancier but less stable
  if (ringPosition.size()>0) {
    for (int i=0; i<ringPosition.size(); i++) {
      //float increment = ringPosition.size() * rings[0].h - rings[0].h;

      rings[int(ringPosition.get(i))].display(xOffset, height - fromBottom - (rings[int(ringPosition.get(i))].h/2  +  increment));
      increment += rings[int(ringPosition.get(i))].h + interSpace;
    }
  }
  popStyle();
}

////------------------------------------------------ LOAD BUTTONS -------------------------------------------////


void loadBtns() {
  //loading all the rings
  float ringSize = 80;

  for (int i=0; i<levelSize; i++) {
    color btnCol = color (90*i, 255/(i+1), 171, 255);
    buttons[i] = new Button(ringSize, btnCol);
  }
}

////------------------------------------------------ DISPLAY BUTTONS -------------------------------------------////


void displayBtns(float x, float y) {
  //line(width/2, 0, width/2, height);  //middle line debug 

  //some coordinates variables
  float fromTop = y;
  float interSpace = 20;
  float ringBlockWidth  = (buttons[0].btnSize + interSpace ) * levelSize - interSpace;    // there are arraySize - 1 interspace so we need to take one out
  float xOffset = x - ringBlockWidth/2;    //centering the rings

  //display level text
  pushStyle();
  fill(60);
  noStroke();
  textFont(font, 40);
  text(levelString, x - textWidth(levelString)/2, fromTop - 40);
  textFont(font, 30);
  text(pleaseRemoveRings, x - textWidth(pleaseRemoveRings)/2, fromTop - 100 );

  popStyle();

  //just displaying the rings 
  pushStyle();
  for (int i=0; i<levelSize; i++) {
    //float x, float y, string val
    buttons[i].display(xOffset + (buttons[i].btnSize +interSpace) * i, fromTop, str(i+1));
  }
  popStyle();
}

////------------------------------------------------ BACK BUTTON -------------------------------------------////

//display the back button
void backButton(float x, float y) {
  back.display(x, y, "back");
  back.setFontSize(20);
}

////------------------------------------------------ DRAW BASE PIN -------------------------------------------////

void drawBase() {
  //draw the base pin
  pushStyle();
  noStroke();
  //wood pin
  rectMode(CORNER);
  fill(#F0EABD);
  rect(width/2 - 10, 200, 20, height-200, 10);
  //base ring
  rectMode(CENTER);
  fill(#C16C04);
  rect(width/2, height - 25, width/2 +30, 50, 10);
  popStyle();
}

////------------------------------------------------ DRAW SCOPE -------------------------------------------////


void drawScope() {
  if (isAnyonePlaying()) {
    // draw the waveforms
    pushStyle();
    noStroke();
    if (ringPosition.size()>0) {
      for (int i = 0; i < player[playerIndex].bufferSize() - 1; i++)
      {
        //mapping the buffer size to the width so to get the x position variation 
        float x = map( i, 0, player[playerIndex].bufferSize(), 0, width );
        //mapping the alpha from 100 to 0 according to the player position
        float alpha = map(player[playerIndex].position(), 0, player[playerIndex].length(), 100, 0 );
        fill(ringsColor[playerIndex], alpha);
        ellipse( x*2, rings[playerIndex].yPos + player[playerIndex].left.get(i)*50, 5, rings[playerIndex].getH()/2 );
        ellipse( x*2, 10 + rings[playerIndex].yPos + player[playerIndex].right.get(i)*50, 5, rings[playerIndex].getH()/2 );
      }
    }
    popStyle();
  }
}

////------------------------------------------------ MAIN SETUP -------------------------------------------////

//just wrapping the loading settings
void mainSetup() {
  //setup audio and arrays
  shuffleChunks();        //shuffle the pieces of the song
  if (shuffled) {
    fillResultArray();    //copy and sort shuffled array to store the result
    loadChunks();        //let's load all the chunks in the memory

    //make the lastArray = to the former
    for (int i=0; i<arraySize; i++) {
      fromSerial[i] = "0";
      lastFromSerial[i] = "0";
      //println(lastFromSerial);
    }
  }
}

////------------------------------------------------ RESET -------------------------------------------////


void reset() {
  //println("reset");
  win = false;
  shuffled = false;
  //println("win", win, "shuffled", shuffled); 

  //cleat all the arrays
  shuffledChunks.clear();            
  resultArray.clear();                 
  ringPosition.clear();              

  page = 1;
  playerIndex = 0;
  lastPlayerIndex = 0;

  startSeqOn = false;

  //reset the total player
  totalPlayer.pause();
  totalPlayer.rewind();

  //pause and rewind all the players, just in case
  for (int i=0; i<arraySize; i++) {

    player[i].pause();
    player[i].rewind();
    //reset the message from serial
    //lastFromSerial[i] =  fromSerial[i];
  }
}

////------------------------------------------------ MOUSE AND KEYBOARDS -------------------------------------------////

//some key commands to select levels and to go back 
void mousePressed() {

  //check if mouse is over buttons
  for (int i=0; i<levelSize; i++) {
    buttons[i].isMouseOver();
    if (buttons[i].isMouseOver && page == 1) {
      if (ringPosition.size()<arraySize) {
        activateLevel( i+1 );
      }
    }
  }
  back.isMouseOver();
  if (back.isMouseOver) {
    page = 1;
    reset();
  }
}

void keyReleased() {
  //reset counter
  if (key == 'r') {
    stopTotalPlayer();
  }

  if (key == ' ') {
    stopTotal =! stopTotal; //toggle total Player
    //println(stopTotal);
  }

  //print result
  if (key == 's') {

    //println("result is", resultArray);
  }
  activateLevel( key );
}

////------------------------------------------------ ACTIVATE LEVEL -------------------------------------------////
void activateLevel( int level ) {

  //activate keyboard interface with buttons
  for (int i=0; i<levelSize; i++) {
    if (level>=1 && level <= 4 || level>= '1' && level <='4') {
      //sett all the other buttons false
      buttons[levelSize-1-i].clicked(false);
      //set our button true
      buttons[(level-1)%levelSize].clicked(true);
    }
  }
  //chose level
  if (level>=1 && level <=4 || level>= '1' && level <='4') {
    selectedLevel = ((level-1)%levelSize) + 1;
    reset();
    mainSetup();    
    //println("selected level", selectedLevel);
    page = 2;
    //startSeqOn = true;
    //uncomment 
    //play the total song;
    if (totalPlayer.position()<totalPlayer.length()) {
      playChunk(totalPlayer);
    } else {
      stopTotalPlayer();
    }
  }
}

////------------------------------------------------ TOTAL PLAYER CONTROL -------------------------------------------////

//controls the player of the full track
void totalPlayerControl() {

  if (totalPlayer.position()<totalPlayer.length() && !stopTotal) {
    playChunk(totalPlayer);
  } else {
    stopTotalPlayer();
  }
}

////------------------------------------------------ STOP TOTAL PLAYER -------------------------------------------////


void stopTotalPlayer() {  
  totalPlayer.pause();
  totalPlayer.rewind();
}

////------------------------------------------------ PERCENTAGE -------------------------------------------////


float percentage(float whole, float percAmount) {

  return whole*percAmount/100;
}