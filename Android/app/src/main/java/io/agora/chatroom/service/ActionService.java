package io.agora.chatroom.service;

import cn.leancloud.AVObject;
import io.agora.chatroom.manager.AttributeManager;
import io.agora.chatroom.model.Action;

public class ActionService extends AttributeManager<Action> {

    private volatile static ActionService instance;

    public static final String OBJECT_KEY = "ACTION";

    public enum ACTION {
        HandsUp(1), Invite(2);

        private int value;

        ACTION(int value) {
            this.value = value;
        }

        public int getValue() {
            return value;
        }
    }

    public enum ACTION_STATUS {
        Ing(1), Agree(2), Refuse(3);

        private int value;

        ACTION_STATUS(int value) {
            this.value = value;
        }

        public int getValue() {
            return value;
        }
    }

    public static final String TAG_ROOMID = "roomId";
    public static final String TAG_MEMBERID = "memberId";
    public static final String TAG_ACTION = "action";
    public static final String TAG_STATUS = "status";

    private ActionService() {
        super();
    }

    public synchronized static ActionService Instance() {
        if (instance == null) {
            synchronized (ActionService.class) {
                if (instance == null) {
                    instance = new ActionService();
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
    protected Action convertObject(AVObject object) {
        return mGson.fromJson(object.toJSONObject().toJSONString(), Action.class);
    }
}
