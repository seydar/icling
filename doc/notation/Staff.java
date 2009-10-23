// FILE:     Staff.java
// PURPOSE:  musical staff.


import java.awt.*;

public class Staff {
    private int x, y;
    private int width;
    private int gap;

    public void
    setNW(int nwx,int nwy) {
        x = nwx;
        y = nwy;
    }

    public void
    setWidth(int swx) {
	width = swx;
    }

    public void
    setSpace(int sdy) {
	gap = sdy;
    }

    public void 
    draw(Graphics g) {
        for (int i=0; i<6; i++) {
            g.drawLine(x, y+i*gap, x+width, y+i*gap); 
        }
    }
}


