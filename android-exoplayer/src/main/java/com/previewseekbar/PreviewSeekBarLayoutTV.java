package com.previewseekbar;

import android.content.Context;
import android.util.AttributeSet;

public class PreviewSeekBarLayoutTV extends  PreviewSeekBarLayout {
    public PreviewSeekBarLayoutTV(Context context) {
        super(context);
    }

    public PreviewSeekBarLayoutTV(Context context, AttributeSet attrs) {
        super(context, attrs);
    }

    public PreviewSeekBarLayoutTV(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    public void showPreview() {
        getMorphView().setVisibility(GONE);
        getFrameView().setVisibility(GONE);
        super.showPreview();
    }

    @Override
    public void hidePreview() {
        getMorphView().setVisibility(GONE);
        getFrameView().setVisibility(GONE);
        super.hidePreview();
    }
}
