package com.brentvatne.exoplayer;

import android.animation.LayoutTransition;
import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.media.AudioManager;
import android.net.Uri;
import android.os.Handler;
import android.os.Message;
import android.support.annotation.IntegerRes;
import android.support.annotation.Nullable;
import android.support.v4.view.GestureDetectorCompat;
import android.text.TextUtils;
import android.util.Log;
import android.view.GestureDetector;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.widget.ImageButton;
import android.widget.ProgressBar;
import android.widget.RelativeLayout;
import android.widget.TextView;

import com.brentvatne.react.R;
import com.brentvatne.receiver.AudioBecomingNoisyReceiver;
import com.brentvatne.receiver.BecomingNoisyListener;
import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.uimanager.ThemedReactContext;
import com.google.android.exoplayer2.C;
import com.google.android.exoplayer2.DefaultLoadControl;
import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.Format;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.Timeline;
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory;
import com.google.android.exoplayer2.mediacodec.MediaCodecRenderer;
import com.google.android.exoplayer2.mediacodec.MediaCodecUtil;
import com.google.android.exoplayer2.metadata.Metadata;
import com.google.android.exoplayer2.metadata.MetadataRenderer;
import com.google.android.exoplayer2.source.BehindLiveWindowException;
import com.google.android.exoplayer2.source.ExtractorMediaSource;
import com.google.android.exoplayer2.source.LoopingMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.source.dash.DashMediaSource;
import com.google.android.exoplayer2.source.dash.DefaultDashChunkSource;
import com.google.android.exoplayer2.source.hls.HlsMediaSource;
import com.google.android.exoplayer2.source.smoothstreaming.DefaultSsChunkSource;
import com.google.android.exoplayer2.source.smoothstreaming.SsMediaSource;
import com.google.android.exoplayer2.trackselection.AdaptiveTrackSelection;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.MappingTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelection;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter;
import com.google.android.exoplayer2.util.Util;
import com.previewseekbar.PreviewSeekBarLayout;
import com.previewseekbar.base.PreviewLoader;
import com.previewseekbar.base.PreviewView;

import java.net.CookieHandler;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.util.Locale;

@SuppressLint("ViewConstructor")
class ReactExoplayerView extends RelativeLayout implements LifecycleEventListener, ExoPlayer.EventListener,
        BecomingNoisyListener, AudioManager.OnAudioFocusChangeListener, MetadataRenderer.Output {

    private static final String TAG = "ReactExoplayerView";

    private static final DefaultBandwidthMeter BANDWIDTH_METER = new DefaultBandwidthMeter();
    private static final CookieManager DEFAULT_COOKIE_MANAGER;
    private static final int SHOW_JS_PROGRESS = 1;
    private static final int SHOW_NATIVE_PROGRESS = 2;

    static {
        DEFAULT_COOKIE_MANAGER = new CookieManager();
        DEFAULT_COOKIE_MANAGER.setCookiePolicy(CookiePolicy.ACCEPT_ORIGINAL_SERVER);
    }

    private final VideoEventEmitter eventEmitter;

    private PreviewSeekBarLayout previewSeekBarLayout;
    private TextView currentTextView;
    private TextView durationTextView;
    private TextView liveTextView;
    private ImageButton playPauseButton;
    private ImageButton fullscreenButton;
    private View rewindContainer;
    private View forwardContainer;
    private View controls;
    private View bottomBarContainer;
    private long controlsVisibleTill = System.currentTimeMillis();
    private long lastControlsVisibilityChange = System.currentTimeMillis();
    private final long CONTROLS_VISIBILITY_DURATION = 3000;
    private GestureDetectorCompat gestureDetector;
    private long startTouchActionDownTime;
    private boolean controlsVisible = false;
    private float eventDownX;
    private float eventDownY;

    // React
    private final ThemedReactContext themedReactContext;
    private final AudioManager audioManager;
    private final AudioBecomingNoisyReceiver audioBecomingNoisyReceiver;
    private Handler mainHandler;
    private ExoPlayerView exoPlayerView;
    private DataSource.Factory mediaDataSourceFactory;
    private SimpleExoPlayer player;
    private MappingTrackSelector trackSelector;
    // Props from React
    private boolean playerNeedsSource;
    private int resumeWindow;
    private long resumePosition;
    private boolean loadVideoStarted;
    private boolean isPaused = true;
    private boolean isBuffering;
    private float rate = 1f;
    private Uri srcUri;
    private String extension;
    private boolean repeat;
    private boolean disableFocus;
    private boolean live = false;
    private boolean forceHideControls = false;
    // End props
    private float mProgressUpdateInterval = 250.0f;
    private final float NATIVE_PROGRESS_UPDATE_INTERVAL = 250.0f;
    @SuppressLint("HandlerLeak")
    private final Handler progressHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case SHOW_JS_PROGRESS:
                    if (player != null && player.getPlaybackState() == ExoPlayer.STATE_READY && player.getPlayWhenReady()) {
                        long currentMillis = player.getCurrentPosition();
                        eventEmitter.progressChanged(currentMillis, player.getBufferedPercentage());
                        progressHandler.removeMessages(SHOW_JS_PROGRESS);
                        msg = obtainMessage(SHOW_JS_PROGRESS);
                        sendMessageDelayed(msg, Math.round(mProgressUpdateInterval));
                    }
                    break;
            }
        }
    };

    @SuppressLint("HandlerLeak")
    private final Handler nativeProgressHandler = new Handler() {
        @Override
        public void handleMessage(Message msg) {
            switch (msg.what) {
                case SHOW_NATIVE_PROGRESS:
                    if (player != null && player.getPlaybackState() == ExoPlayer.STATE_READY && player.getPlayWhenReady()) {
                        long currentMillis = player.getCurrentPosition();
                        progressHandler.removeMessages(SHOW_NATIVE_PROGRESS);
                        msg = obtainMessage(SHOW_NATIVE_PROGRESS);
                        sendMessageDelayed(msg, Math.round(NATIVE_PROGRESS_UPDATE_INTERVAL));

                        updateProgressControl(currentMillis);
                    }
                    break;
            }
        }
    };
    private boolean playInBackground = false;

    public ReactExoplayerView(ThemedReactContext context) {
        super(context);
        createViews();
        this.eventEmitter = new VideoEventEmitter(context);
        this.themedReactContext = context;
        audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        themedReactContext.addLifecycleEventListener(this);
        audioBecomingNoisyReceiver = new AudioBecomingNoisyReceiver(themedReactContext);
        GestureDetector.SimpleOnGestureListener gestureListener = new GestureDetector.SimpleOnGestureListener() {
            @Override
            public boolean onScroll(MotionEvent e1, MotionEvent e2, float distanceX, float distanceY) {
                eventEmitter.touchActionMove(distanceX, distanceY);
                float newTranslationY = bottomBarContainer.getTranslationY() + distanceY;
                if (newTranslationY > 0 && newTranslationY < bottomBarContainer.getHeight()) {
                    bottomBarContainer.setTranslationY(newTranslationY);
                    controls.setAlpha(1 - newTranslationY / bottomBarContainer.getHeight());
                }
                return true;
            }
        };
        gestureDetector = new GestureDetectorCompat(themedReactContext, gestureListener);

        initializePlayer();
    }

    private static boolean isBehindLiveWindow(ExoPlaybackException e) {
        if (e.type != ExoPlaybackException.TYPE_SOURCE) {
            return false;
        }
        Throwable cause = e.getSourceException();
        while (cause != null) {
            if (cause instanceof BehindLiveWindowException) {
                return true;
            }
            cause = cause.getCause();
        }
        return false;
    }

    @Override
    public void setId(int id) {
        super.setId(id);
        eventEmitter.setViewId(id);
    }

    @Override
    protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec);
    }

    @Override
    public boolean onTouchEvent(MotionEvent event) {
        gestureDetector.onTouchEvent(event);
        if (event.getAction() == MotionEvent.ACTION_DOWN) {
            startTouchActionDownTime = System.currentTimeMillis();
            eventDownX = event.getX();
            eventDownY = event.getY();
        }
        if (event.getAction() == MotionEvent.ACTION_UP) {
            long touchDuration = System.currentTimeMillis() - startTouchActionDownTime;
            if (touchDuration < ViewConfiguration.getTapTimeout()) {
                viewControlsFor(CONTROLS_VISIBILITY_DURATION);
            } else {
                if (eventDownY > event.getY()) {
                    animateControls(0, 250);
                } else {
                    viewControlsFor(CONTROLS_VISIBILITY_DURATION);
                }
            }
            eventEmitter.touchActionUp();
        }
        return true;
    }

    private void createViews() {
        addOnLayoutChangeListener(new OnLayoutChangeListener() {
            @Override
            public void onLayoutChange(View v, int left, int top, int right, int bottom, int oldLeft, int oldTop,
                                       int oldRight, int oldBottom) {
                postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        controls.requestLayout();
                    }
                }, 200);
            }
        });
        clearResumePosition();
        mediaDataSourceFactory = buildDataSourceFactory(true);
        mainHandler = new Handler();
        if (CookieHandler.getDefault() != DEFAULT_COOKIE_MANAGER) {
            CookieHandler.setDefault(DEFAULT_COOKIE_MANAGER);
        }

        LayoutInflater inflater = LayoutInflater.from(getContext());

        LayoutParams layoutParams = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        exoPlayerView = new ExoPlayerView(getContext());
        exoPlayerView.setLayoutParams(layoutParams);
        addView(exoPlayerView, 0, layoutParams);
        setLayoutTransition(new LayoutTransition());

        controls = inflater.inflate(R.layout.controls, null);
        LayoutParams controlsParam = new LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT);
        controls.setLayoutParams(controlsParam);
        addView(controls);

        bottomBarContainer = controls.findViewById(R.id.bottomBarContainer);

        rewindContainer = controls.findViewById(R.id.rewindContainer);
        forwardContainer = controls.findViewById(R.id.forwardContainer);
        ImageButton rewindButton = (ImageButton) controls.findViewById(R.id.rewindImageView);
        rewindButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                viewControlsFor(CONTROLS_VISIBILITY_DURATION);
                seekTo(player.getCurrentPosition() - 30000);
            }
        });
        ImageButton forwardButton = (ImageButton) controls.findViewById(R.id.forwardImageView);
        forwardButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                viewControlsFor(CONTROLS_VISIBILITY_DURATION);
                seekTo(player.getCurrentPosition() + 30000);
            }
        });
        playPauseButton = (ImageButton) controls.findViewById(R.id.playPauseImageView);
        playPauseButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                viewControlsFor(CONTROLS_VISIBILITY_DURATION);
                setPausedModifier(!isPaused);
            }
        });
        fullscreenButton = (ImageButton) findViewById(R.id.fullscreenButton);
        fullscreenButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                eventEmitter.fullscreenChange();
            }
        });
        durationTextView = (TextView) controls.findViewById(R.id.durationTextView);
        currentTextView = (TextView) controls.findViewById(R.id.currentTimeTextView);
        liveTextView = (TextView) controls.findViewById(R.id.liveTextView);
        previewSeekBarLayout = (PreviewSeekBarLayout) controls.findViewById(R.id.previewSeekBarLayout);
        previewSeekBarLayout.setPreviewLoader(new PreviewLoader() {
            @Override
            public void loadPreview(long currentPosition, long max) {

            }
        });

        controlsVisible = controls.getVisibility() == VISIBLE;
    }

    @Override
    protected void onAttachedToWindow() {
        super.onAttachedToWindow();
        initializePlayer();
    }

    // LifecycleEventListener implementation

    @Override
    protected void onDetachedFromWindow() {
        super.onDetachedFromWindow();
        stopPlayback();
    }

    @Override
    public void onHostResume() {
        if (playInBackground) {
            return;
        }
        setPlayWhenReady(!isPaused);
    }

    @Override
    public void onHostPause() {
        if (playInBackground) {
            return;
        }
        setPlayWhenReady(false);
    }

    @Override
    public void onHostDestroy() {
        stopPlayback();
    }

    // Internal methods

    public void cleanUpResources() {
        stopPlayback();
    }

    private void initializePlayer() {
        Log.d("initialisePlayer", "--");
        if (player == null) {
            TrackSelection.Factory videoTrackSelectionFactory = new AdaptiveTrackSelection.Factory(BANDWIDTH_METER);
            trackSelector = new DefaultTrackSelector(videoTrackSelectionFactory);
            player = ExoPlayerFactory.newSimpleInstance(getContext(), trackSelector, new DefaultLoadControl());
            player.addListener(this);
            player.setMetadataOutput(this);
            exoPlayerView.setPlayer(player);
            audioBecomingNoisyReceiver.setListener(this);
            setPlayWhenReady(!isPaused);
            playerNeedsSource = true;

            PlaybackParameters params = new PlaybackParameters(rate, 1f);
            player.setPlaybackParameters(params);
        }
        if (playerNeedsSource && srcUri != null) {
            MediaSource mediaSource = buildMediaSource(srcUri, extension);
            mediaSource = repeat ? new LoopingMediaSource(mediaSource) : mediaSource;
            boolean haveResumePosition = resumeWindow != C.INDEX_UNSET;
            if (haveResumePosition) {
                player.seekTo(resumeWindow, resumePosition);
            }
            player.prepare(mediaSource, !haveResumePosition, false);
            playerNeedsSource = false;

            eventEmitter.loadStart();
            loadVideoStarted = true;
        }
    }

    private MediaSource buildMediaSource(Uri uri, String overrideExtension) {
        int type = Util.inferContentType(
                !TextUtils.isEmpty(overrideExtension) ? "." + overrideExtension : uri.getLastPathSegment());
        switch (type) {
            case C.TYPE_SS:
                return new SsMediaSource(uri, buildDataSourceFactory(false),
                        new DefaultSsChunkSource.Factory(mediaDataSourceFactory), mainHandler, null);
            case C.TYPE_DASH:
                return new DashMediaSource(uri, buildDataSourceFactory(false),
                        new DefaultDashChunkSource.Factory(mediaDataSourceFactory), mainHandler, null);
            case C.TYPE_HLS:
                return new HlsMediaSource(uri, mediaDataSourceFactory, mainHandler, null);
            case C.TYPE_OTHER:
                return new ExtractorMediaSource(uri, mediaDataSourceFactory, new DefaultExtractorsFactory(), mainHandler,
                        null);
            default: {
                throw new IllegalStateException("Unsupported type: " + type);
            }
        }
    }

    private void releasePlayer() {
        if (player != null) {
            isPaused = player.getPlayWhenReady();
            updateResumePosition();
            player.release();
            player.setMetadataOutput(null);
            player = null;
            trackSelector = null;
        }
        progressHandler.removeMessages(SHOW_JS_PROGRESS);
        progressHandler.removeMessages(SHOW_NATIVE_PROGRESS);
        themedReactContext.removeLifecycleEventListener(this);
        audioBecomingNoisyReceiver.removeListener();
    }

    private boolean requestAudioFocus() {
        if (disableFocus) {
            return true;
        }
        int result = audioManager.requestAudioFocus(this, AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN);
        return result == AudioManager.AUDIOFOCUS_REQUEST_GRANTED;
    }

    private void setPlayWhenReady(boolean playWhenReady) {
        if (player == null) {
            return;
        }

        if (playWhenReady) {
            boolean hasAudioFocus = requestAudioFocus();
            if (hasAudioFocus) {
                player.setPlayWhenReady(true);
            }
        } else {
            player.setPlayWhenReady(false);
        }
    }

    private void startPlayback() {
        if (player != null) {
            switch (player.getPlaybackState()) {
                case ExoPlayer.STATE_IDLE:
                case ExoPlayer.STATE_ENDED:
                    initializePlayer();
                    break;
                case ExoPlayer.STATE_BUFFERING:
                case ExoPlayer.STATE_READY:
                    if (!player.getPlayWhenReady()) {
                        setPlayWhenReady(true);
                    }
                    break;
                default:
                    break;
            }

        } else {
            initializePlayer();
        }
        if (!disableFocus) {
            setKeepScreenOn(true);
        }
    }

    private void pausePlayback() {
        if (player != null) {
            if (player.getPlayWhenReady()) {
                setPlayWhenReady(false);
            }
        }
        setKeepScreenOn(false);
    }

    private void stopPlayback() {
        onStopPlayback();
        releasePlayer();
    }

    private void onStopPlayback() {
        setKeepScreenOn(false);
        audioManager.abandonAudioFocus(this);
    }

    private void updateResumePosition() {
        resumeWindow = player.getCurrentWindowIndex();
        resumePosition = player.isCurrentWindowSeekable() ? Math.max(0, player.getCurrentPosition()) : C.TIME_UNSET;
    }

    private void clearResumePosition() {
        resumeWindow = C.INDEX_UNSET;
        resumePosition = C.TIME_UNSET;
    }

    // AudioManager.OnAudioFocusChangeListener implementation

    /**
     * Returns a new DataSource factory.
     *
     * @param useBandwidthMeter Whether to set {@link #BANDWIDTH_METER} as a listener to the new
     *                          DataSource factory.
     * @return A new DataSource factory.
     */
    private DataSource.Factory buildDataSourceFactory(boolean useBandwidthMeter) {
        return DataSourceUtil.getDefaultDataSourceFactory(getContext(), useBandwidthMeter ? BANDWIDTH_METER : null);
    }

    // AudioBecomingNoisyListener implementation

    @Override
    public void onAudioFocusChange(int focusChange) {
        switch (focusChange) {
            case AudioManager.AUDIOFOCUS_LOSS:
                eventEmitter.audioFocusChanged(false);
                break;
            case AudioManager.AUDIOFOCUS_GAIN:
                eventEmitter.audioFocusChanged(true);
                break;
            default:
                break;
        }

        if (player != null) {
            if (focusChange == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK) {
                // Lower the volume
                player.setVolume(0.8f);
            } else if (focusChange == AudioManager.AUDIOFOCUS_GAIN) {
                // Raise it back to normal
                player.setVolume(1);
            }
        }
    }

    // ExoPlayer.EventListener implementation

    @Override
    public void onAudioBecomingNoisy() {
        eventEmitter.audioBecomingNoisy();
    }

    @Override
    public void onLoadingChanged(boolean isLoading) {
        // Do nothing.
    }

    @Override
    public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
        String text = "onStateChanged: playWhenReady=" + playWhenReady + ", playbackState=";
        switch (playbackState) {
            case ExoPlayer.STATE_IDLE:
                text += "idle";
                eventEmitter.idle();
                break;
            case ExoPlayer.STATE_BUFFERING:
                text += "buffering";
                // Hide central control buttons when buffering
                updateCentralControls(INVISIBLE);
                onBuffering(true);
                break;
            case ExoPlayer.STATE_READY:
                text += "ready";
                // Show central control buttons when buffering
                updateCentralControls(VISIBLE);
                eventEmitter.ready();
                onBuffering(false);
                startProgressHandler();
                setupProgressBarSeekListener();
                videoLoaded();
                break;
            case ExoPlayer.STATE_ENDED:
                text += "ended";
                eventEmitter.end();
                onStopPlayback();
                break;
            default:
                text += "unknown";
                break;
        }
        Log.d(TAG, text);
    }

    private void startProgressHandler() {
        progressHandler.sendEmptyMessage(SHOW_JS_PROGRESS);
        nativeProgressHandler.sendEmptyMessage(SHOW_NATIVE_PROGRESS);
    }

    private void updateProgressControl(long currentMillis) {
        ProgressBar progressBar = (ProgressBar) previewSeekBarLayout.getPreviewView();
        if (player == null || progressBar == null) {
            return;
        }
        long duration = player.getDuration();

        if (duration != C.TIME_UNSET && durationTextView != null) {
            int secs = (int) (duration / 1000) % 60;
            int mins = (int) ((duration / (1000 * 60)) % 60);
            int hours = (int) ((duration / (1000 * 60 * 60)) % 24);
            String durationString = "";
            if (hours > 0) {
                durationString = String.format(Locale.UK, "%02d:%02d:%02d", hours, mins, secs);
            } else {
                durationString = String.format(Locale.UK, "%02d:%02d", mins, secs);
            }

            durationTextView.setText(durationString);
            progressBar.setMax((int) duration);
        }

        if (currentMillis != C.TIME_UNSET && currentTextView != null) {
            int secs = (int) (currentMillis / 1000) % 60;
            int mins = (int) ((currentMillis / (1000 * 60)) % 60);
            int hours = (int) ((currentMillis / (1000 * 60 * 60)) % 24);
            String currentString = "";
            if (hours > 0) {
                currentString = String.format(Locale.UK, "%02d:%02d:%02d", hours, mins, secs);
            } else {
                currentString = String.format(Locale.UK, "%02d:%02d", mins, secs);
            }
            currentTextView.setText(currentString);
            progressBar.setProgress((int) currentMillis);
        }

    }

    private void setupProgressBarSeekListener() {
        if (previewSeekBarLayout != null && previewSeekBarLayout.getPreviewView() instanceof ProgressBar) {
            previewSeekBarLayout.getPreviewView().addOnPreviewChangeListener(new PreviewView.OnPreviewChangeListener() {
                @Override
                public void onStartPreview(PreviewView previewView) {

                }

                @Override
                public void onStopPreview(PreviewView previewView) {

                }

                @Override
                public void onPreview(PreviewView previewView, int progress, boolean fromUser) {
                    if (fromUser && player != null) {
                        viewControlsFor(CONTROLS_VISIBILITY_DURATION);
                        player.seekTo(progress);
                        updateProgressControl(progress);
                    }
                }
            });
        }
    }

    private void videoLoaded() {
        if (loadVideoStarted) {
            loadVideoStarted = false;
            Format videoFormat = player.getVideoFormat();
            int width = videoFormat != null ? videoFormat.width : 0;
            int height = videoFormat != null ? videoFormat.height : 0;
            eventEmitter.load(player.getDuration(), player.getCurrentPosition(), width, height);
        }
    }

    private void onBuffering(boolean buffering) {
        if (isBuffering == buffering) {
            return;
        }

        isBuffering = buffering;
        if (buffering) {
            eventEmitter.buffering(true);
        } else {
            eventEmitter.buffering(false);
        }
    }

    @Override
    public void onPositionDiscontinuity() {
        if (playerNeedsSource) {
            // This will only occur if the user has performed a seek whilst in the error state. Update the
            // resume position so that if the user then retries, playback will resume from the position to
            // which they seeked.
            updateResumePosition();
        }
    }

    @Override
    public void onTimelineChanged(Timeline timeline, Object manifest) {
        // Do nothing.
    }

    @Override
    public void onTracksChanged(TrackGroupArray trackGroups, TrackSelectionArray trackSelections) {
        // Do Nothing.
    }

    @Override
    public void onPlaybackParametersChanged(PlaybackParameters params) {
        eventEmitter.playbackRateChange(params.speed);
    }

    @Override
    public void onPlayerError(ExoPlaybackException e) {
        String errorString = null;
        Exception ex = e;
        if (e.type == ExoPlaybackException.TYPE_RENDERER) {
            Exception cause = e.getRendererException();
            if (cause instanceof MediaCodecRenderer.DecoderInitializationException) {
                // Special case for decoder initialization failures.
                MediaCodecRenderer.DecoderInitializationException decoderInitializationException = (MediaCodecRenderer.DecoderInitializationException) cause;
                if (decoderInitializationException.decoderName == null) {
                    if (decoderInitializationException.getCause() instanceof MediaCodecUtil.DecoderQueryException) {
                        errorString = getResources().getString(R.string.error_querying_decoders);
                    } else if (decoderInitializationException.secureDecoderRequired) {
                        errorString = getResources().getString(R.string.error_no_secure_decoder,
                                decoderInitializationException.mimeType);
                    } else {
                        errorString = getResources().getString(R.string.error_no_decoder,
                                decoderInitializationException.mimeType);
                    }
                } else {
                    errorString = getResources().getString(R.string.error_instantiating_decoder,
                            decoderInitializationException.decoderName);
                }
            }
        } else if (e.type == ExoPlaybackException.TYPE_SOURCE) {
            ex = e.getSourceException();
            errorString = getResources().getString(R.string.unrecognized_media_format);
        }
        if (errorString != null) {
            eventEmitter.error(errorString, ex);
        }
        playerNeedsSource = true;
        if (isBehindLiveWindow(e)) {
            clearResumePosition();
            initializePlayer();
        } else {
            updateResumePosition();
        }
    }

    @Override
    public void onMetadata(Metadata metadata) {
        eventEmitter.timedMetadata(metadata);
    }

    // ReactExoplayerViewManager public api

    public void setSrc(final Uri uri, final String extension) {
        if (uri != null) {
            boolean isOriginalSourceNull = srcUri == null;
            boolean isSourceEqual = uri.equals(srcUri);

            this.srcUri = uri;
            this.extension = extension;
            this.mediaDataSourceFactory = DataSourceUtil.getDefaultDataSourceFactory(getContext(), BANDWIDTH_METER);

            if (!isOriginalSourceNull && !isSourceEqual) {
                reloadSource();
            }
        }
    }

    public void setProgressUpdateInterval(final float progressUpdateInterval) {
        mProgressUpdateInterval = progressUpdateInterval;
    }

    public void setRawSrc(final Uri uri, final String extension) {
        if (uri != null) {
            boolean isOriginalSourceNull = srcUri == null;
            boolean isSourceEqual = uri.equals(srcUri);

            this.srcUri = uri;
            this.extension = extension;
            this.mediaDataSourceFactory = DataSourceUtil.getRawDataSourceFactory(getContext());

            if (!isOriginalSourceNull && !isSourceEqual) {
                reloadSource();
            }
        }
    }

    private void reloadSource() {
        playerNeedsSource = true;
        initializePlayer();
    }

    public void setResizeModeModifier(@ResizeMode.Mode int resizeMode) {
        exoPlayerView.setResizeMode(resizeMode);
    }

    public void setRepeatModifier(boolean repeat) {
        this.repeat = repeat;
    }

    public void setPausedModifier(boolean paused) {
        isPaused = paused;
        if (player != null) {
            if (!paused) {
                startPlayback();
            } else {
                pausePlayback();
            }
        }
        if (playPauseButton != null) {
            if (isPaused) {
                playPauseButton.setImageResource(R.drawable.ic_play);
            } else {
                playPauseButton.setImageResource(R.drawable.ic_pause);
            }
        }

    }

    public void setMutedModifier(boolean muted) {
        if (player != null) {
            player.setVolume(muted ? 0 : 1);
        }
    }

    public void setVolumeModifier(float volume) {
        if (player != null) {
            player.setVolume(volume);
        }
    }

    public void seekTo(long positionMs) {
        if (player != null) {
            eventEmitter.seek(player.getCurrentPosition(), positionMs);
            player.seekTo(positionMs);
        }
    }

    public void setRateModifier(float newRate) {
        rate = newRate;

        if (player != null) {
            PlaybackParameters params = new PlaybackParameters(rate, 1f);
            player.setPlaybackParameters(params);
        }
    }

    public void setPlayInBackground(boolean playInBackground) {
        this.playInBackground = playInBackground;
    }

    public void setDisableFocus(boolean disableFocus) {
        this.disableFocus = disableFocus;
    }

    public void setColorProgressBar(String color) {
        try {
            previewSeekBarLayout.setTintColor(Color.parseColor(color));
        } catch (IllegalArgumentException e) {
            Log.e(getClass().getSimpleName(), e.getMessage(), e);
        }
    }

    public void setLive(final boolean live) {
        this.live = live;
        if (liveTextView != null && currentTextView != null && previewSeekBarLayout != null && durationTextView != null
                && rewindContainer != null && forwardContainer != null) {
            liveTextView.setVisibility(live ? VISIBLE : GONE);
            @IntegerRes
            int controlsVisibility = live ? INVISIBLE : VISIBLE;
            currentTextView.setVisibility(controlsVisibility);
            previewSeekBarLayout.setVisibility(controlsVisibility);
            durationTextView.setVisibility(controlsVisibility);
            rewindContainer.setVisibility(controlsVisibility);
            forwardContainer.setVisibility(controlsVisibility);
        }
    }

    public void setForceHideControls(final boolean hide) {
        this.forceHideControls = hide;
        if (hide) {
            controls.setVisibility(INVISIBLE);
        }
    }

    public void setControlsOpacity(final float opacity) {
        float newTranslationY = ((1 - opacity) * bottomBarContainer.getHeight() * 0.5f);
        if (newTranslationY < 0) {
            newTranslationY = 0;
        } else if (newTranslationY > bottomBarContainer.getHeight()) {
            newTranslationY = bottomBarContainer.getHeight();
        }
        bottomBarContainer.setTranslationY(newTranslationY);
        controls.setAlpha(opacity);
    }

    public void setIconBottomRight(@Nullable String icon) {
        if (icon != null) {
            switch (icon) {
                case "fullscreenOn":
                    fullscreenButton.setImageResource(R.drawable.ic_fullscreen_on);
                    break;
                case "fullscreenOff":
                    fullscreenButton.setImageResource(R.drawable.ic_fullscreen_off);
                    break;
                default:
                    break;
            }
        }
    }

    private void viewControlsFor(final long duration) {
        if (!forceHideControls) {
            controlsVisibleTill = System.currentTimeMillis() + duration - 50;
            // Don't emit too many events
            if (!controlsVisible || lastControlsVisibilityChange - System.currentTimeMillis() >= 1000) {
                eventEmitter.controlsVisibilityChange(true);
                controlsVisible = true;
                lastControlsVisibilityChange = System.currentTimeMillis();
            }
            controls.setVisibility(VISIBLE);
            animateControls(1, 250);
            postDelayed(new Runnable() {
                @Override
                public void run() {
                    if (controlsVisibleTill <= System.currentTimeMillis() && !isPaused) {
                        // Don't emit too many events
                        if (controlsVisible || lastControlsVisibilityChange - System.currentTimeMillis() >= 1000) {
                            eventEmitter.controlsVisibilityChange(false);
                            animateControls(0, 250);
                            controlsVisible = false;
                            lastControlsVisibilityChange = System.currentTimeMillis();
                        }
                    }
                }
            }, duration);
        }
    }

    private void updateCentralControls(@IntegerRes int visibility) {
        playPauseButton.setVisibility(visibility);
        rewindContainer.setVisibility(live ? INVISIBLE : visibility);
        forwardContainer.setVisibility(live ? INVISIBLE : visibility);
    }

    private void animateControls(final float opacity, final long duration) {
        float newTranslationY = ((1 - opacity) * bottomBarContainer.getHeight() * 0.5f);
        if (newTranslationY < 0) {
            newTranslationY = 0;
        } else if (newTranslationY > bottomBarContainer.getHeight()) {
            newTranslationY = bottomBarContainer.getHeight();
        }

        updateCentralControls(opacity == 0 || isBuffering ? INVISIBLE : VISIBLE);
        bottomBarContainer.animate().translationY(newTranslationY).setDuration(duration).start();
        controls.animate().alpha(opacity).setDuration(duration).start();
    }
}
