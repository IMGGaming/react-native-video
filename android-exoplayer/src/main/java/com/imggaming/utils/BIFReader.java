package com.imggaming.utils;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.AsyncTask;
import android.support.annotation.NonNull;
import android.support.v4.util.LruCache;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;
import okio.Buffer;
import okio.BufferedSink;
import okio.BufferedSource;
import okio.Okio;

public class BIFReader {

    private static final String TAG = BIFReader.class.getSimpleName();

    private boolean initialised = false;
    private File file;

    private int noOfImages;
    private int multiplier;
    private List<Integer> timeStamps;
    private List<Integer> offsets;

    private final LruCache<Integer, Bitmap> cache = new BitmapLruCache();

    public BIFReader(String url) {
        init(url);
    }

    private void init(final String url) {
        AsyncTask.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    file = File.createTempFile("previews", ".bif");
                    file.deleteOnExit();
                    download(url, file);
                    Log.d(TAG, "init() file downloaded: " + file.getAbsolutePath());
                    doInit(url, file);
                    initialised = true;
                } catch (IOException e) {
                    Log.e(TAG, "init() error ", e);
                    initialised = false;
                }
            }
        });
    }

    private void doInit(String url, File file) throws IOException {
        byte[] data = new byte[4];

        FileInputStream fis = new FileInputStream(file);

        try {
            fis.skip(12);
            if (fis.read(data) != 4) {
                return;
            }
            noOfImages = java.nio.ByteBuffer.wrap(data).order(java.nio.ByteOrder.LITTLE_ENDIAN).getInt();

            if (fis.read(data) != 4) {
                return;
            }
            multiplier = java.nio.ByteBuffer.wrap(data).order(java.nio.ByteOrder.LITTLE_ENDIAN).getInt();
            if (multiplier == 0) {
                multiplier = 1000;
            }

            fis.skip(44); // bytes reserved for future

            int tableCapacity = (noOfImages  + 1) * 2;

            timeStamps = new ArrayList<>();
            offsets = new ArrayList<>();

            for (int i = 0; i < tableCapacity; i+=2) {
                if (fis.read(data) != 4) {
                    return;
                }
                int timestamp = java.nio.ByteBuffer.wrap(data).order(java.nio.ByteOrder.LITTLE_ENDIAN).getInt();
                timeStamps.add(timestamp);

                if (fis.read(data) != 4) {
                    return;
                }
                int offset = java.nio.ByteBuffer.wrap(data).order(java.nio.ByteOrder.LITTLE_ENDIAN).getInt();
                offsets.add(offset);
            }

            Log.d(TAG, "doInit() noOfImages: " + noOfImages + " multiplier: " + multiplier);
        } finally {
            fis.close();
        }
    }

    private void download(@NonNull String url, @NonNull File destFile) throws IOException {
        Request request = new Request.Builder().url(url)
                .addHeader("Content-Type", "application/json")
                .build();
        OkHttpClient client = new OkHttpClient();

        Response response = null;
        BufferedSink sink = null;
        BufferedSource source = null;

        try {
            response = client.newCall(request).execute();
            ResponseBody body = response.body();
            source = body.source();

            sink = Okio.buffer(Okio.sink(destFile));
            Buffer sinkBuffer = sink.buffer();

            long totalBytesRead = 0;
            int bufferSize = 8 * 1024;
            for (long bytesRead; (bytesRead = source.read(sinkBuffer, bufferSize)) != -1; ) {
                sink.emit();
                totalBytesRead += bytesRead;
            }

        } finally {
            if (response != null) {
                response.close();
            }
            if (sink != null) {
                sink.flush();
                sink.close();
            }
            if (source != null) {
                source.close();
            }
        }
    }

    // ToDO: Make it run on background thread
    public Bitmap getImage(long time) {
        Log.d(TAG, "getImage() time = " + time);

        if (!initialised) {
            Log.d(TAG, "getImage() not initialised");
            return null;
        }

        if (file == null || !file.exists()) {
            Log.e(TAG, "getImage() file error");
            return null;
        }

        int offset = 0;

        for (int i = 0; i < noOfImages; i++) {
            long current = timeStamps.get(i) * multiplier;
            if (current < time) {
                offset = i;
            } else {
                break;
            }
        }

        Bitmap bMap = cache.get(offset);
        if (bMap != null) {
            Log.d(TAG, "getImage() image in cache offset = " + offset);
            return bMap;
        }

        Log.d(TAG, "getImage() image offset = " + offset);

        bMap = getReadBitmap(offset);
        return bMap;
    }

    private Bitmap getReadBitmap(int offset) {
        FileInputStream fis = null;
        Bitmap bMap = null;
        int start = offsets.get(offset);
        int end = offsets.get(offset + 1) - 1;

        try {
            fis = new FileInputStream(file);

            byte[] data = new byte[end - start];

            fis.skip(start);

            fis.read(data);

            bMap = BitmapFactory.decodeByteArray(data, 0, data.length);

            cache.put(offset, bMap);

            Log.d(TAG, "getReadBitmap() read offset = " + offset);

        } catch (FileNotFoundException e) {
            Log.e(TAG, "getReadBitmap() error ", e);
        } catch (IOException e) {
            Log.e(TAG, "getReadBitmap() error ", e);
        } finally {
            if (fis != null) {
                try {
                    fis.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return bMap;
    }

    public void close() {
        cache.evictAll();
        if (file != null && file.exists()) {
            file.delete();
        }
    }

    @Override
    protected void finalize() throws Throwable {
        close();
        super.finalize();
    }

    private static class BitmapLruCache extends LruCache<Integer, Bitmap> {

        private static final int MAX = 10 * 1024 * 1024; // 10MB

        public BitmapLruCache() {
            super(MAX);
        }

        @Override
        protected int sizeOf(final Integer key, final Bitmap value) {
            return value.getByteCount();
        }

        @Override
        protected void entryRemoved(final boolean evicted, final Integer key, final Bitmap oldValue, final Bitmap newValue) {
            super.entryRemoved(evicted, key, oldValue, newValue);

            if (oldValue != null && oldValue != newValue) {
                Log.d(TAG, "entryRemoved() recycling bitmap key = " + key);
                oldValue.recycle();
            }
        }
    }
}
