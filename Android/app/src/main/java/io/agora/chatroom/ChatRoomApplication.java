package io.agora.chatroom;

import android.app.Application;

import cn.leancloud.AVLogger;
import cn.leancloud.AVOSCloud;
import io.agora.chatroom.manager.RtcManager;

public class ChatRoomApplication extends Application {

    public static Application instance;

    public ChatRoomApplication() {
        instance = this;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        RtcManager.Instance(this).init();

        if (BuildConfig.DEBUG) {
            AVOSCloud.setLogLevel(AVLogger.Level.DEBUG);
        } else {
            AVOSCloud.setLogLevel(AVLogger.Level.ERROR);
        }
        AVOSCloud.initialize(this, instance.getApplicationContext().getString(R.string.leancloud_app_id),
                instance.getApplicationContext().getString(R.string.leancloud_app_key),
                instance.getApplicationContext().getString(R.string.leancloud_server_url));
    }
}
