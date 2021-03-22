package io.agora.chatroom;

import android.app.Application;

import cn.leancloud.AVLogger;
import cn.leancloud.AVOSCloud;
import io.agora.chatroom.manager.RtcManager;

public class ChatRoomApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        RtcManager.Instance(this).init();

        if (BuildConfig.DEBUG) {
            AVOSCloud.setLogLevel(AVLogger.Level.DEBUG);
        } else {
            AVOSCloud.setLogLevel(AVLogger.Level.ERROR);
        }
        AVOSCloud.initialize(this, getString(R.string.leancloud_app_id),
                getString(R.string.leancloud_app_key),
                getString(R.string.leancloud_server_url));
    }
}
