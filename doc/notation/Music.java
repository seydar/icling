// FILE:     Music.java
// PURPOSE:  display musical notation.


import java.awt.*;

public class Music extends java.applet.Applet {

    private int sdx;                              // distance between notes
    private int sdy;                              // distance between line
    
    Staff staff = new Staff();
    Note[] note = new Note[16];
    
    public void 
    init() {
        int nwx = 20;
        int nwy = 20;
        int width = 512;
        
        sdx = 12;
        sdy = 6;
        
        staff.setNW(nwx, nwy);
        staff.setWidth(width-2*nwx);
        staff.setSpace(sdy);
        
        int x = 0;
        for (int i=0; i<8; i++) {
            note[i] = new Note(sdy*2, 4);
        }
        for (int i=8; i<12; i++) {
            note[i] = new Note(sdy*2, 2);
        }
        for (int i=12; i<16; i++) {
            note[i] = new Note(sdy*2, 1);
        }
        for (int i=0; i<4; i++) {
            note[i].setNW(nwx + (x += sdx), nwy+i*sdy);
        }
        for (int i=4; i<8; i++) {
            note[i].setNW(nwx + (x += sdx), nwy+(i-4)*sdy);
        }
        for (int i=8; i<16; i++) {
            note[i].setNW(nwx + (x += sdx), nwy+(i-8)*sdy);
        }
    }
    
    public void
    paint(Graphics g) {
        setBackground(Color.white);
        g.setColor(Color.black);
        staff.draw(g);
        for (int i=0; i<note.length; i++) {
            note[i].draw(g);
        }
    }

}
