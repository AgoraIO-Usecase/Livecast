package io.agora.chatroom.manager;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.util.ObjectsCompat;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import cn.leancloud.AVObject;
import cn.leancloud.AVQuery;
import io.agora.chatroom.data.DataRepositroy;
import io.agora.chatroom.model.Member;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.service.ActionService;
import io.agora.chatroom.service.MemberService;
import io.agora.chatroom.service.RoomService;
import io.agora.chatroom.service.model.BaseError;
import io.agora.chatroom.service.model.DataCompletableObserver;
import io.agora.chatroom.service.model.DataMaybeObserver;
import io.agora.rtc.IRtcEngineEventHandler;
import io.reactivex.Completable;
import io.reactivex.Maybe;
import io.reactivex.Observable;
import io.reactivex.functions.Action;
import io.reactivex.functions.Consumer;

/**
 * 负责房间内数据的管理
 */
public final class RoomManager {

    private static final int ERROR_REGISTER_ANCHOR_ACTION_STATUS = 100;
    private static final int ERROR_REGISTER_MEMBER_ACTION_STATUS = ERROR_REGISTER_ANCHOR_ACTION_STATUS + 1;
    private static final int ERROR_REGISTER_MEMBER_CHANGED = ERROR_REGISTER_MEMBER_ACTION_STATUS + 1;

    private final String TAG = RoomManager.class.getSimpleName();

    private static RoomManager instance;

    private Context mContext;

    private RoomManager(Context context) {
        mContext = context.getApplicationContext();
    }

    private final IRtcEngineEventHandler mIRtcEngineEventHandler = new IRtcEngineEventHandler() {
        @Override
        public void onError(int err) {
            super.onError(err);
        }

        @Override
        public void onJoinChannelSuccess(String channel, int uid, int elapsed) {
            super.onJoinChannelSuccess(channel, uid, elapsed);
            if (isLeaving) {
                return;
            }
        }

        @Override
        public void onLeaveChannel(RtcStats stats) {
            super.onLeaveChannel(stats);
            if (isLeaving) {
                return;
            }
        }

        @Override
        public void onUserJoined(int uid, int elapsed) {
            super.onUserJoined(uid, elapsed);
            if (isLeaving) {
                return;
            }

            long streamId = uid & 0xffffffffL;
            if (streamIdMap.containsKey(streamId)) {
                return;
            }

//            DataRepositroy.Instance(mContext)
//                    .getMember(uid)
//                    .subscribe(new DataMaybeObserver<Member>(mContext) {
//                        @Override
//                        public void handleError(@NonNull BaseError e) {
//
//                        }
//
//                        @Override
//                        public void handleSuccess(@Nullable Member member) {
//                            if (isLeaving) {
//                                return;
//                            }
//
//                            if (member == null) {
//                                return;
//                            }
//
//                            long streamId = uid & 0xffffffffL;
//                            if (streamIdMap.containsKey(streamId)) {
//                                return;
//                            }
//
//                            onMemberJoin(member);
//                        }
//                    });
        }

        @Override
        public void onUserOffline(int uid, int reason) {
            super.onUserOffline(uid, reason);
            if (isLeaving) {
                return;
            }

            long streamId = uid & 0xffffffffL;
            if (!streamIdMap.containsKey(streamId)) {
                return;
            }

//            DataRepositroy.Instance(mContext)
//                    .getMember(uid)
//                    .subscribe(new DataMaybeObserver<Member>(mContext) {
//                        @Override
//                        public void handleError(@NonNull BaseError e) {
//                            if (isLeaving) {
//                                return;
//                            }
//                        }
//
//                        @Override
//                        public void handleSuccess(@Nullable Member member) {
//                            if (isLeaving) {
//                                return;
//                            }
//
//                            if (member == null) {
//                                return;
//                            }
//
//                            if (!streamIdMap.containsKey(streamId)) {
//                                return;
//                            }
//
//                            onMemberLeave(false, member);
//                        }
//                    });
        }

        @Override
        public void onRemoteAudioStateChanged(int uid, int state, int reason, int elapsed) {
            super.onRemoteAudioStateChanged(uid, state, reason, elapsed);
            if (isLeaving) {
                return;
            }
        }
    };

    public static RoomManager Instance(Context context) {
        if (instance == null) {
            synchronized (RoomManager.class) {
                if (instance == null)
                    instance = new RoomManager(context);
            }
        }
        return instance;
    }

    /**
     * 正在退出房间，防止回调处理。
     */
    public volatile static boolean isLeaving = false;

    private List<RoomDataCallback> callbacks = new ArrayList<>();

    private Room mRoom;
    private Member mMember;

    /**
     * Member表中objectId和Member的键值对
     */
    public Map<String, Member> membersMap = new ConcurrentHashMap<>();

    /**
     * RTC的UID和Member的键值对
     */
    private Map<Long, Member> streamIdMap = new ConcurrentHashMap<>();

    /**
     * 举手memberId和Action对应表
     */
    private Map<String, io.agora.chatroom.model.Action> requestHandUpMap = new ConcurrentHashMap<>();

    @Nullable
    public Room getRoom() {
        return mRoom;
    }

    @Nullable
    public Member getMember() {
        return mMember;
    }

    public Completable toggleHandUp() {
        return DataRepositroy.Instance(mContext)
                .requestHandsUp(mMember);
    }

    public Observable<Member> toggleAudio() {
        int newValue = mMember.getIsSelfMuted() == 0 ? 1 : 0;
        return DataRepositroy.Instance(mContext)
                .muteSelfVoice(mMember, newValue)
                .doOnComplete(new Action() {
                    @Override
                    public void run() throws Exception {
                        mMember.setIsSelfMuted(newValue);
                        if (newValue == 0) {
                            RtcManager.Instance(mContext).muteLocalAudioStream(false);
                        } else {
                            RtcManager.Instance(mContext).muteLocalAudioStream(true);
                        }
                    }
                });
    }

    public void addRoomDataCallback(@NonNull RoomDataCallback callback) {
        this.callbacks.add(callback);
    }

    public void removeRoomDataCallback(@NonNull RoomDataCallback callback) {
        this.callbacks.remove(callback);
    }

    public Observable<Member> joinRoom() {
        return DataRepositroy.Instance(mContext)
                .joinRoom(mMember)
                .doOnNext(new Consumer<Member>() {
                    @Override
                    public void accept(Member member) throws Exception {
                        onMemberUpdated(mMember, member);
                        mMember = member;
                    }
                });
    }

    public void onJoinRoom(Room room, Member member) {
        this.mRoom = room;
        this.mMember = member;
        isLeaving = false;

        RtcManager.Instance(mContext).addHandler(mIRtcEngineEventHandler);
    }

    public void register() {
        registerMemberChanged();

        if (isAnchor()) {
            registerAnchorActionStatus();
        } else {
            registerMemberActionStatus();
        }
    }

    public void leaveRoom() {
        isLeaving = true;

        RtcManager.Instance(mContext).stopAudio();

        RtcManager.Instance(mContext).leaveChannel();
        DataRepositroy.Instance(mContext)
                .leanRoom(mMember)
                .subscribe(new DataCompletableObserver(mContext) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                    }

                    @Override
                    public void handleSuccess() {
                    }
                });
        onMemberLeave(true, mMember);
        onLeaveRoom();
    }

    private void onLeaveRoom() {
        RtcManager.Instance(mContext).removeHandler(mIRtcEngineEventHandler);
        unregisterMemberChanged();
        unregisterMemberActionStatus();
        unregisterAnchorActionStatus();

        this.mRoom = null;
        this.mMember = null;
        this.requestHandUpMap.clear();
        this.membersMap.clear();
        this.streamIdMap.clear();
    }

    public int getHandUpCount() {
        return requestHandUpMap.size();
    }

    public List<io.agora.chatroom.model.Action> getHandUpList() {
        return new ArrayList<>(requestHandUpMap.values());
    }

    public void onRoomUpdated(Room room) {
        this.mRoom = room;
    }

    void onMemberUpdated(Member oldMember, Member newMember) {
        if (isMine(oldMember)) {
            if (oldMember.getIsSpeaker() == 0 && newMember.getIsSpeaker() == 1) {
                RtcManager.Instance(mContext).startAudio();
            } else if (oldMember.getIsSpeaker() == 1 && newMember.getIsSpeaker() == 0) {
                RtcManager.Instance(mContext).stopAudio();
            }
        }
        membersMap.put(newMember.getObjectId(), newMember);
        if (newMember.getStreamId() != null) {
            streamIdMap.put(newMember.getStreamId(), newMember);
        }

        for (RoomDataCallback callback : callbacks) {
            callback.onMemberUpdated(oldMember, newMember);
        }
    }

    public void onLoadRoomMembers(@NonNull List<Member> members) {
        for (int i = 0; i < members.size(); i++) {
            Member member = members.get(i);
            if (isMine(member)) {
                member = mMember;
                members.set(i, mMember);
            }

            member.setRoomId(mRoom);
            membersMap.put(member.getObjectId(), member);
            if (member.getStreamId() != null) {
                streamIdMap.put(member.getStreamId(), member);
            }
        }
    }

    void onMemberJoin(Member member) {
        Log.d(TAG, "onMemberJoin() called with: member = [" + member + "]");

        if (!TextUtils.isEmpty(member.getObjectId())) {
            membersMap.put(member.getObjectId(), member);
        }

        if (member.getStreamId() != null) {
            streamIdMap.put(member.getStreamId(), member);
        }

        for (RoomDataCallback callback : callbacks) {
            callback.onMemberJoin(member);
        }
    }

    void onMemberLeave(boolean isManual, String memberId) {
        Log.d(TAG, "onMemberLeave() called with: memberId = [" + memberId + "]");
        Member member = membersMap.get(memberId);
        if (member != null) {
            onMemberLeave(isManual, member);
        }
    }

    void onMemberLeave(boolean isManual, Member member) {
        Log.d(TAG, "onMemberLeave() called with: member = [" + member + "]");

        if (!TextUtils.isEmpty(member.getObjectId())) {
            membersMap.remove(member.getObjectId());
        }

        if (member.getStreamId() != null) {
            streamIdMap.remove(member.getStreamId());
        }

        for (RoomDataCallback callback : callbacks) {
            callback.onMemberLeave(member);
        }

        if (ObjectsCompat.equals(member.getUserId(), getRoom().getAnchorId())) {
            if (!isManual) {
                leaveRoom();
            }
        }
    }

    public boolean isAnchor(Member member) {
        return ObjectsCompat.equals(member.getUserId(), mRoom.getAnchorId());
    }

    public boolean isAnchor() {
        return isAnchor(mMember);
    }

    public boolean isAnchor(String userId) {
        return ObjectsCompat.equals(userId, mRoom.getAnchorId().getObjectId());
    }

    public boolean isMine(Member member) {
        return ObjectsCompat.equals(member, mMember);
    }

    public Maybe<Room> getRoom(Room room) {
        return DataRepositroy.Instance(mContext)
                .getRoom(room)
                .doOnSuccess(new Consumer<Room>() {
                    @Override
                    public void accept(Room room) throws Exception {
                        onRoomUpdated(room);
                    }
                });
    }

    public Maybe<Member> getMine() {
        return getMember(mMember.getUserId().getObjectId())
                .doOnSuccess(new Consumer<Member>() {
                    @Override
                    public void accept(Member member) throws Exception {
                        mMember = member;
                        mMember.setRoomId(mRoom);
                    }
                });
    }

    public Maybe<Member> getMember(String userId) {
        return DataRepositroy.Instance(mContext)
                .getMember(mRoom.getObjectId(), userId)
                .doOnSuccess(new Consumer<Member>() {
                    @Override
                    public void accept(Member member) throws Exception {
                        member.setRoomId(mRoom);
                    }
                });
    }

    public Completable agreeInvite(io.agora.chatroom.model.Action data) {
        return DataRepositroy.Instance(mContext)
                .agreeInvite(data)
                .doOnComplete(new Action() {
                    @Override
                    public void run() throws Exception {
                        Member member = data.getMemberId();
                        member = getMemberById(member.getObjectId());
                        onMemberInviteAgree(member);
                    }
                });
    }

    public Completable refuseInvite(io.agora.chatroom.model.Action data) {
        return DataRepositroy.Instance(mContext)
                .refuseInvite(data)
                .doOnComplete(new Action() {
                    @Override
                    public void run() throws Exception {
                        Member member = data.getMemberId();
                        member = getMemberById(member.getObjectId());
                        onMemberInviteRefuse(member);
                    }
                });
    }

    public Completable agreeHandsUp(io.agora.chatroom.model.Action data) {
        return DataRepositroy.Instance(mContext)
                .agreeHandsUp(data)
                .doOnComplete(new Action() {
                    @Override
                    public void run() throws Exception {
                        Member member = data.getMemberId();
                        requestHandUpMap.remove(member.getObjectId());

                        member = getMemberById(member.getObjectId());
                        onHandUpAgree(member);
                    }
                });
    }

    public Completable refuseHandsUp(io.agora.chatroom.model.Action data) {
        return DataRepositroy.Instance(mContext)
                .refuseHandsUp(data)
                .doOnComplete(new Action() {
                    @Override
                    public void run() throws Exception {
                        Member member = data.getMemberId();
                        requestHandUpMap.remove(member.getObjectId());

                        member = getMemberById(member.getObjectId());
                        onHandUpRefuse(member);
                    }
                });
    }

    public Member getMemberById(String memberId) {
        return membersMap.get(memberId);
    }

    public Member getMemberByStramId(long streamId) {
        return streamIdMap.get(streamId);
    }

    /**
     * 作为房主，需要监听房间中Action变化。
     */
    private void registerAnchorActionStatus() {
        Room room = getRoom();
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, room.getObjectId());

        AVQuery<AVObject> query = AVQuery.getQuery(ActionService.OBJECT_KEY);
        query.whereEqualTo(ActionService.TAG_ROOMID, roomAVObject);
        Log.i(AttributeManager.TAG, String.format("%s registerObserve roomId= %s", ActionService.OBJECT_KEY, room.getObjectId()));
        ActionService.Instance().registerObserve(query, new AttributeManager.AttributeListener<io.agora.chatroom.model.Action>() {
            @Override
            public void onCreated(io.agora.chatroom.model.Action item) {
                if (item.getAction() == ActionService.ACTION.HandsUp.getValue()) {
                    if (item.getStatus() == ActionService.ACTION_STATUS.Ing.getValue()) {
                        Member member = item.getMemberId();
                        member = getMemberById(member.getObjectId());
                        if (requestHandUpMap.containsKey(member.getObjectId())) {
                            return;
                        }

                        item.setMemberId(member);
                        requestHandUpMap.put(member.getObjectId(), item);
                        onReceivedHandUp();
                    }
                } else if (item.getAction() == ActionService.ACTION.Invite.getValue()) {
                    if (item.getStatus() == ActionService.ACTION_STATUS.Agree.getValue()) {
                        Member member = item.getMemberId();
                        member = getMemberById(member.getObjectId());
                        onMemberInviteAgree(member);
                    } else if (item.getStatus() == ActionService.ACTION_STATUS.Refuse.getValue()) {
                        Member member = item.getMemberId();
                        member = getMemberById(member.getObjectId());
                        onMemberInviteRefuse(member);
                    }
                }
            }

            @Override
            public void onUpdated(io.agora.chatroom.model.Action item) {

            }

            @Override
            public void onDeleted(String objectId) {

            }

            @Override
            public void onSubscribeError() {
                onRoomError(ERROR_REGISTER_ANCHOR_ACTION_STATUS);
            }
        });
    }

    private void unregisterAnchorActionStatus() {
        ActionService.Instance().unregisterObserve();
    }

    /**
     * 作为观众，需要监听自己的Action变化。
     */
    private void registerMemberActionStatus() {
        Member member = getMember();
        AVObject memberAVObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, member.getObjectId());

        AVQuery<AVObject> query = AVQuery.getQuery(ActionService.OBJECT_KEY);
        query.whereEqualTo(ActionService.TAG_MEMBERID, memberAVObject);
        Log.i(AttributeManager.TAG, String.format("%s registerObserve memberId= %s", ActionService.OBJECT_KEY, member.getObjectId()));
        ActionService.Instance().registerObserve(query, new AttributeManager.AttributeListener<io.agora.chatroom.model.Action>() {
            @Override
            public void onCreated(io.agora.chatroom.model.Action item) {
                if (item.getAction() == ActionService.ACTION.HandsUp.getValue()) {
                    if (item.getStatus() == ActionService.ACTION_STATUS.Agree.getValue()) {
                        onHandUpAgree(member);
                    } else if (item.getStatus() == ActionService.ACTION_STATUS.Refuse.getValue()) {
                        onHandUpRefuse(member);
                    }
                } else if (item.getAction() == ActionService.ACTION.Invite.getValue()) {
                    if (item.getStatus() == ActionService.ACTION_STATUS.Ing.getValue()) {
                        onReceivedInvite(item);
                    }
                }
            }

            @Override
            public void onUpdated(io.agora.chatroom.model.Action item) {

            }

            @Override
            public void onDeleted(String objectId) {

            }

            @Override
            public void onSubscribeError() {
                onRoomError(ERROR_REGISTER_MEMBER_ACTION_STATUS);
            }
        });
    }

    private void unregisterMemberActionStatus() {
        ActionService.Instance().unregisterObserve();
    }

    /**
     * 监听房间内部成员信息变化
     */
    private void registerMemberChanged() {
        Room room = getRoom();
        Member member = getMember();
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, room.getObjectId());

        AVQuery<AVObject> query = AVQuery.getQuery(MemberService.OBJECT_KEY);
        query.whereEqualTo(MemberService.TAG_ROOMID, roomAVObject);
        Log.i(AttributeManager.TAG, String.format("%s registerObserve roomId= %s", MemberService.OBJECT_KEY, room.getObjectId()));
        MemberService.Instance().registerObserve(query, new AttributeManager.AttributeListener<Member>() {
            @Override
            public void onCreated(Member member) {
                if (isLeaving) {
                    return;
                }

                if (membersMap.containsKey(member.getObjectId())) {
                    return;
                }

                getMember(member.getUserId().getObjectId())
                        .subscribe(new DataMaybeObserver<Member>(mContext) {
                            @Override
                            public void handleError(@NonNull BaseError e) {

                            }

                            @Override
                            public void handleSuccess(@Nullable Member member) {
                                if (member == null) {
                                    return;
                                }

                                if (isLeaving) {
                                    return;
                                }

                                if (membersMap.containsKey(member.getObjectId())) {
                                    return;
                                }

                                onMemberJoin(member);
                            }
                        });
            }

            @Override
            public void onUpdated(Member member) {
                if (isLeaving) {
                    return;
                }

                getMember(member.getUserId().getObjectId())
                        .subscribe(new DataMaybeObserver<Member>(mContext) {
                            @Override
                            public void handleError(@NonNull BaseError e) {

                            }

                            @Override
                            public void handleSuccess(@Nullable Member member) {
                                if (member == null) {
                                    return;
                                }

                                if (isLeaving) {
                                    return;
                                }

                                if (membersMap.containsKey(member.getObjectId())) {
                                    Member old = membersMap.get(member.getObjectId());
                                    onMemberUpdated(old, member);
                                } else {
                                    onMemberJoin(member);
                                }
                            }
                        });
            }

            @Override
            public void onDeleted(String objectId) {
                if (isLeaving) {
                    return;
                }

                if (!membersMap.containsKey(objectId)) {
                    return;
                }

                onMemberLeave(false, objectId);
            }

            @Override
            public void onSubscribeError() {
                onRoomError(ERROR_REGISTER_MEMBER_CHANGED);
            }
        });
    }

    private void unregisterMemberChanged() {
        MemberService.Instance().unregisterObserve();
    }

    void onReceivedHandUp() {
        Log.d(TAG, "onReceivedHandUp() called");
        for (RoomDataCallback callback : callbacks) {
            callback.onReceivedHandUp();
        }
    }

    void onHandUpAgree(Member member) {
        Log.d(TAG, "onHandUpAgree() called with: member = [" + member + "]");
        for (RoomDataCallback callback : callbacks) {
            callback.onHandUpAgree(member);
        }
    }

    void onHandUpRefuse(Member member) {
        Log.d(TAG, "onHandUpRefuse() called with: member = [" + member + "]");
        for (RoomDataCallback callback : callbacks) {
            callback.onHandUpRefuse(member);
        }
    }

    void onReceivedInvite(io.agora.chatroom.model.Action item) {
        Log.d(TAG, "onReceivedInvite() called with: item = [" + item + "]");
        for (RoomDataCallback callback : callbacks) {
            callback.onReceivedInvite(item);
        }
    }

    void onMemberInviteAgree(Member member) {
        Log.d(TAG, "onMemberInviteAgree() called with: member = [" + member + "]");
        for (RoomDataCallback callback : callbacks) {
            callback.onMemberInviteAgree(member);
        }
    }

    void onMemberInviteRefuse(Member member) {
        Log.d(TAG, "onMemberInviteRefuse() called with: member = [" + member + "]");
        for (RoomDataCallback callback : callbacks) {
            callback.onMemberInviteRefuse(member);
        }
    }

    void onRoomError(int error) {
        Log.d(TAG, "onRoomError() called with: error = [" + error + "]");
        for (RoomDataCallback callback : callbacks) {
            callback.onRoomError(error);
        }
    }

    public void onEnterMin() {
        Log.d(TAG, "onEnterMin() called");
        for (RoomDataCallback callback : callbacks) {
            callback.onEnterMin();
        }
    }

    @MainThread
    public interface RoomDataCallback {
        void onMemberJoin(Member member);

        void onMemberLeave(Member member);

        void onMemberUpdated(Member oldMember, Member newMember);

        void onReceivedHandUp();

        void onHandUpAgree(Member member);

        void onHandUpRefuse(Member member);

        void onReceivedInvite(io.agora.chatroom.model.Action item);

        void onMemberInviteAgree(Member member);

        void onMemberInviteRefuse(Member member);

        void onEnterMin();

        void onRoomError(int error);
    }
}
