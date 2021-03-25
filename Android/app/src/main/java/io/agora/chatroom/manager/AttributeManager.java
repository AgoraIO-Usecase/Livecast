package io.agora.chatroom.manager;

import android.os.Handler;
import android.util.Log;

import com.google.gson.Gson;

import java.util.List;

import cn.leancloud.AVException;
import cn.leancloud.AVObject;
import cn.leancloud.AVQuery;
import cn.leancloud.livequery.AVLiveQuery;
import cn.leancloud.livequery.AVLiveQueryEventHandler;
import cn.leancloud.livequery.AVLiveQuerySubscribeCallback;

public abstract class AttributeManager<T> {

    public static final String TAG = AttributeManager.class.getSimpleName();

    public static final String TAG_OBJECTID = "objectId";
    public static final String TAG_CREATEDAT = "createdAt";

    private AVLiveQuery avLiveQuery;

    protected abstract String getObjectName();

    protected Gson mGson = new Gson();

    public interface AttributeListener<T> {
        void onCreated(T item);

        void onUpdated(T item);

        void onDeleted(String objectId);

        void onSubscribeError();
    }

    private Handler mHandler = new Handler();

    public void registerObserve(AVQuery<AVObject> query, AttributeListener<T> callback) {
        Log.i(TAG, String.format("%s registerObserve", getObjectName()));
        final AVLiveQuery avLiveQuery = AVLiveQuery.initWithQuery(query);
        avLiveQuery.setEventHandler(new AVLiveQueryEventHandler() {

            @Override
            public void onObjectCreated(AVObject avObject) {
                super.onObjectCreated(avObject);
                Log.d(TAG, String.format("%s onObjectCreated: %s", getObjectName(), avObject));
                callback.onCreated(convertObject(avObject));
            }

            @Override
            public void onObjectUpdated(AVObject avObject, List<String> updatedKeys) {
                super.onObjectUpdated(avObject, updatedKeys);
                Log.d(TAG, String.format("%s onObjectUpdated: %s", getObjectName(), avObject));
                callback.onUpdated(convertObject(avObject));
            }

            @Override
            public void onObjectDeleted(String objectId) {
                super.onObjectDeleted(objectId);
                Log.d(TAG, String.format("%s onObjectDeleted: %s", getObjectName(), objectId));
                callback.onDeleted(objectId);
            }
        });

        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                Log.e(TAG, String.format("%s subscribe error: timeout", getObjectName()));
                callback.onSubscribeError();
            }
        };
        mHandler.postDelayed(runnable, 5000L);
        avLiveQuery.subscribeInBackground(new AVLiveQuerySubscribeCallback() {
            @Override
            public void done(AVException e) {
                if (null != e) {
                    Log.e(TAG, String.format("%s subscribe error: %s", getObjectName(), e.getMessage()));
                    AttributeManager.this.avLiveQuery = null;
                    callback.onSubscribeError();
                } else {
                    Log.i(TAG, String.format("%s subscribe success", getObjectName()));
                    AttributeManager.this.avLiveQuery = avLiveQuery;
                }
                mHandler.removeCallbacks(runnable);
            }
        });
    }

    public void unregisterObserve() {
        Log.i(TAG, String.format("%s unregisterObserve", getObjectName()));

        if (avLiveQuery != null) {
            avLiveQuery.unsubscribeInBackground(new AVLiveQuerySubscribeCallback() {
                @Override
                public void done(AVException e) {
                    if (null != e) {
                        Log.e(TAG, String.format("%s unsubscribe error: %s", getObjectName(), e.getMessage()));
                    } else {
                        Log.i(TAG, String.format("%s unsubscribe success", getObjectName()));
                    }
                }
            });
            avLiveQuery = null;
        }
    }

    protected abstract T convertObject(AVObject object);
}
