package io.agora.chatroom.service;

import com.google.gson.Gson;

import cn.leancloud.AVObject;
import io.agora.chatroom.manager.AttributeManager;
import io.agora.chatroom.model.Room;

public class RoomService extends AttributeManager<Room> {

    private volatile static RoomService instance;

    public static final String OBJECT_KEY = "ROOM";

    public static final String CHANNEL_NAME_KEY = "channelName";
    public static final String ANCHOR_ID_KEY = "anchorId";

    private RoomService() {
        super();
    }

    public synchronized static RoomService Instance() {
        if (instance == null) {
            synchronized (RoomService.class) {
                if (instance == null) {
                    instance = new RoomService();
                    instance.init();
                }
            }
        }
        return instance;
    }

    private void init() {
    }

    @Override
    protected String getObjectName() {
        return OBJECT_KEY;
    }

    @Override
    protected Room convertObject(AVObject object) {
        return mGson.fromJson(object.toJSONObject().toJSONString(), Room.class);
    }
}
