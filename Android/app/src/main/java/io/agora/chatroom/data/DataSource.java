package io.agora.chatroom.data;

import java.util.List;

import io.agora.chatroom.model.Action;
import io.agora.chatroom.model.Member;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.model.User;
import io.reactivex.Completable;
import io.reactivex.Maybe;
import io.reactivex.Observable;

public interface DataSource {
    Observable<User> login(User user);

    Observable<User> update(User user);

    Observable<List<Room>> getRooms();

    Observable<Room> getRoomListInfo(Room room);

    Maybe<Room> getRoomListInfo2(Room room);

    Observable<Room> creatRoom(Room room);

    Maybe<Room> getRoom(Room room);

    Observable<List<Member>> getMembers(Room room);

    Maybe<Member> getMember(String roomId, String userId);

    Maybe<Member> getMember(int uid);

    Observable<Member> joinRoom(Member member);

    Completable leanRoom(Member member);

    Observable<Member> muteVoice(Member member, int muted);

    Observable<Member> muteSelfVoice(Member member, int muted);

    Completable requestHandsUp(Member member);

    Completable agreeHandsUp(Action action);

    Completable refuseHandsUp(Action action);

    Completable inviteSeat(Member member);

    Completable agreeInvite(Action action);

    Completable refuseInvite(Action action);

    Completable seatOff(Member member);
}
