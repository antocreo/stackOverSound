// ring Obj

public class Ring {

  //Serial properties
  String serialMsgIndex;

  //Audio properties
  AudioPlayer ringPlayer;

  int msgCount;

  //interaction properties
  boolean isInPlace;
  boolean isSliding;
  boolean hasPlayed;
  String direction;

  //visual properties
  float xPos, yPos, w, h;
  color ringColor;

  //constructor
  Ring(float rW, float rH, color rColor) {
    msgCount = 0;
    w = rW;
    h = rH;
    ringColor = rColor;
    isInPlace = false;
    hasPlayed = false;
  };


  //////FUNCTIONS//////


  boolean setRingInPlace(boolean val) {
    isInPlace = val;
    return isInPlace;
  }

  boolean setRingSliding(boolean val) {
    isSliding = val;
    return isSliding;
  }

  void display(float x, float y) {
    xPos = x;
    yPos = y;

    pushStyle();
    noStroke();
    //main ring
    fill(ringColor);
    rect(x, y, w, h, 10);
    popStyle();
  }

  //this defines the status of the ring once has been triggered.
  void triggered() {
  }

  ////GETTERS & SETTERS///

  void setSize(float rW, float rH) {

    w = rW;
    h = rH;
  }


  float getH() {

    return  h ;
  }


  String getDirection() {

    if (isSliding) {
      if (isInPlace) {
        direction = "up";
      } else if (!isInPlace) {
        direction = "down";
      }
    }
    return direction;
  }
} //end of class