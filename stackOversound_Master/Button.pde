//button obj

public class Button {

  PFont font;

  String btnString;    //index

  //visual properties
  float xPos, yPos, btnSize;
  float strokeW;
  color btnColor, txtColor;
  float alpha = 50;
  float fontSize;

  boolean isMouseOver;
  boolean active;

  //constructor
  Button(float bSize, color bColor) {
    btnSize = bSize;
    btnColor = bColor;
    txtColor = btnColor;
    fontSize = bSize/2;
    font = loadFont("FuturaBT-Heavy-48.vlw");
    textFont(font, fontSize);
    active = true;
  };


  void display(float x, float y, String string) {
    xPos = x;
    yPos = y;
    btnString = string;
    textFont(font, fontSize);

    pushStyle();
    ellipseMode(CORNER);      //the default is CENTRE on ellipse!

    noStroke();
    //noFill();
    //strokeWeight(strokeW);
    //main ring
    //stroke(btnColor);
    fill(btnColor, alpha);
    ellipse(x, y, btnSize, btnSize);

    fill(txtColor);
    textAlign(CENTER);
    text(string, x + btnSize/2, y +btnSize/2 + textAscent()/2);
    popStyle();
  }

  void isMouseOver() {

    if (mouseX > xPos && mouseX < xPos + btnSize && mouseY > yPos && mouseY < yPos + btnSize) {
      clicked(true);
    } else {
      clicked(false);
    }
  }

  void clicked (boolean bState) {

    if (bState) {
      isMouseOver = true;
      alpha =  255; 
      txtColor = bgColor;
    } else {
      alpha = 50;
      txtColor = btnColor;
      isMouseOver = false;
    }
  }
  void setFontSize(float fs) {

    fontSize = fs;
  }
}