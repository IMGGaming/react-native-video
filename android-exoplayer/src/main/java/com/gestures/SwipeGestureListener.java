package com.gestures;

import android.util.Log;
import android.view.GestureDetector;
import android.view.MotionEvent;

public class SwipeGestureListener extends GestureDetector.SimpleOnGestureListener {
    private Listener listener;

    @Override
    public boolean onDown(MotionEvent e) {
        return true;
    }

    @Override
    public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
        if (listener == null)
            return true;

        if (distanceX == 0 && Math.abs(distanceY) > 1) {
            listener.swipeVertical(distanceY);
        }

        if (distanceY == 0 && Math.abs(distanceX) > 1) {
            listener.swipeHorizontal(distanceX);
        }
        return true;
    }

    public void setListener(Listener listener) {
        this.listener = listener;
    }

    public interface Listener {
        void swipeHorizontal(float dx);

        void swipeVertical(float dy);
    }
}