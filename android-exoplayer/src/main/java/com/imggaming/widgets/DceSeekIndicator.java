package com.imggaming.widgets;

import android.content.Context;
import android.support.annotation.Nullable;
import android.support.v7.widget.AppCompatTextView;
import android.util.AttributeSet;

public class DceSeekIndicator extends AppCompatTextView {

    private Runnable runnable;

    public DceSeekIndicator(Context context) {
        super(context);
    }

    public DceSeekIndicator(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
    }

    public DceSeekIndicator(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    public void show(boolean isRew, String label) {
        show(isRew, label, 0, null);
    }

    public void show(boolean isRew, String label, int timeout, Runnable hideRunnable) {
        setLabel(label);
        removeCallbacks(runnable);
        runnable = hideRunnable;
        if (timeout > 0) {
            postDelayed(runnable, timeout);
        }
    }

    public void setLabel(String label) {
        setText(label);
    }

}
