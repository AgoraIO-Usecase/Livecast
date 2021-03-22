package io.agora.chatroom.data;

import android.content.Context;

import java.util.List;

import io.agora.chatroom.data.leancloud.RemoteDataSource;
import io.agora.chatroom.model.Action;
import io.agora.chatroom.model.Member;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.model.User;
import io.reactivex.Completable;
import io.reactivex.Maybe;
import io.reactivex.Observable;

public class DataRepositroy implements DataSource {
    private static final String TAG = DataRepositroy.class.getSimpleName();

    private volatile static DataRepositroy instance;

    private Context mContext;

    private RemoteDataSource mRemoteDataSource = new RemoteDataSource();

    private DataRepositroy(Context context) {
        mContext = context.getApplicationContext();
    }

    public static synchronized DataRepositroy Instance(Context context) {
        if (instance == null) {
            synchronized (DataRepositroy.class) {
                if (instance == null)
                    instance = new DataRepositroy(context);
            }
        }
        return instance;
    }

    @Override
    public Observable<User> login(User user) {
        return mRemoteDataSource.login(user);
    }

    @Override
    public Observable<User> update(User user) {
        return mRemoteDataSource.update(user);
    }

    @Override
    public Observable<List<Room>> getRooms() {
        return mRemoteDataSource.getRooms();
    }

    @Override
    public Observable<Room> getRoomListInfo(Room room) {
        return mRemoteDataSource.getRoomListInfo(room);
    }

    @Override
    public Maybe<Room> getRoomListInfo2(Room room) {
        return mRemoteDataSource.getRoomListInfo2(room);
    }

    @Override
    public Observable<Room> creatRoom(Room room) {
        return mRemoteDataSource.creatRoom(room);
    }

    @Override
    public Maybe<Room> getRoom(Room room) {
        return mRemoteDataSource.getRoom(room);
    }

    @Override
    public Observable<List<Member>> getMembers(Room room) {
        return mRemoteDataSource.getMembers(room);
    }

    @Override
    public Maybe<Member> getMember(String roomId, String userId) {
        return mRemoteDataSource.getMember(roomId, userId);
    }

    @Override
    public Maybe<Member> getMember(int uid) {
        return mRemoteDataSource.getMember(uid);
    }

    @Override
    public Observable<Member> joinRoom(Member member) {
        return mRemoteDataSource.joinRoom(member);
    }

    @Override
    public Completable leanRoom(Member member) {
        return mRemoteDataSource.leanRoom(member);
    }

    @Override
    public Observable<Member> muteVoice(Member member, int muted) {
        return mRemoteDataSource.muteVoice(member, muted);
    }

    @Override
    public Observable<Member> muteSelfVoice(Member member, int muted) {
        return mRemoteDataSource.muteSelfVoice(member, muted);
    }

    @Override
    public Completable requestHandsUp(Member member) {
        return mRemoteDataSource.requestHandsUp(member);
    }

    @Override
    public Completable agreeHandsUp(Action action) {
        return mRemoteDataSource.agreeHandsUp(action);
    }

    @Override
    public Completable refuseHandsUp(Action action) {
        return mRemoteDataSource.refuseHandsUp(action);
    }

    @Override
    public Completable inviteSeat(Member member) {
        return mRemoteDataSource.inviteSeat(member);
    }

    @Override
    public Completable agreeInvite(Action action) {
        return mRemoteDataSource.agreeInvite(action);
    }

    @Override
    public Completable refuseInvite(Action action) {
        return mRemoteDataSource.refuseInvite(action);
    }

    @Override
    public Completable seatOff(Member member) {
        return mRemoteDataSource.seatOff(member);
    }
}
