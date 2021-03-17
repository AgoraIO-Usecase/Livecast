package io.agora.chatroom.data.remote;

import android.text.TextUtils;

import androidx.core.util.ObjectsCompat;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.util.ArrayList;
import java.util.List;

import cn.leancloud.AVObject;
import cn.leancloud.AVQuery;
import cn.leancloud.types.AVNull;
import io.agora.chatroom.data.DataSource;
import io.agora.chatroom.model.Action;
import io.agora.chatroom.model.Member;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.model.User;
import io.agora.chatroom.service.ActionService;
import io.agora.chatroom.service.MemberService;
import io.agora.chatroom.service.RoomService;
import io.agora.chatroom.service.UserService;
import io.agora.chatroom.service.model.AVObjectToObservable;
import io.reactivex.Completable;
import io.reactivex.CompletableSource;
import io.reactivex.Maybe;
import io.reactivex.MaybeSource;
import io.reactivex.Observable;
import io.reactivex.ObservableSource;
import io.reactivex.annotations.NonNull;
import io.reactivex.functions.BiFunction;
import io.reactivex.functions.Function;
import io.reactivex.schedulers.Schedulers;

public class RemoteDataSource implements DataSource {

    private Gson mGson = new Gson();

    @Override
    public Observable<User> login(User user) {
        if (TextUtils.isEmpty(user.getObjectId())) {
            AVObject avObject = new AVObject(UserService.OBJECT_KEY);
            avObject.put(UserService.TAG_NAME, user.getName());
            avObject.put(UserService.TAG_AVATAR, user.getAvatar());
            return avObject.saveInBackground()
                    .subscribeOn(Schedulers.io())
                    .concatMap(new Function<AVObject, ObservableSource<? extends User>>() {
                        @Override
                        public ObservableSource<? extends User> apply(@NonNull AVObject avObject) throws Exception {
                            User user = mGson.fromJson(avObject.toJSONObject().toJSONString(), User.class);
                            return Observable.just(user);
                        }
                    });
        } else {
            AVQuery<AVObject> query = AVQuery.getQuery(UserService.OBJECT_KEY);
            query.whereEqualTo(UserService.TAG_OBJECTID, user.getObjectId());
            return query.countInBackground()
                    .subscribeOn(Schedulers.io())
                    .concatMap(new Function<Integer, Observable<User>>() {
                        @Override
                        public Observable<User> apply(@NonNull Integer integer) throws Exception {
                            if (integer <= 0) {
                                AVObject avObject = new AVObject(UserService.OBJECT_KEY);
                                avObject.put(UserService.TAG_NAME, user.getName());
                                avObject.put(UserService.TAG_AVATAR, user.getAvatar());
                                return avObject.saveInBackground()
                                        .concatMap(new AVObjectToObservable<>(new TypeToken<User>() {
                                        }.getType()));
                            } else {
                                return query.getFirstInBackground()
                                        .concatMap(new Function<AVObject, ObservableSource<? extends User>>() {
                                            @Override
                                            public ObservableSource<? extends User> apply(@NonNull AVObject avObject) throws Exception {
                                                User user = mGson.fromJson(avObject.toJSONObject().toJSONString(), User.class);
                                                return Observable.just(user);
                                            }
                                        });
                            }
                        }
                    });
        }
    }

    @Override
    public Observable<User> update(User user) {
        AVObject avObject = AVObject.createWithoutData(UserService.OBJECT_KEY, user.getObjectId());
        avObject.put(UserService.TAG_NAME, user.getName());
        avObject.put(UserService.TAG_AVATAR, user.getAvatar());
        return avObject.saveInBackground()
                .subscribeOn(Schedulers.io())
                .concatMap(new AVObjectToObservable<>(new TypeToken<User>() {
                }.getType()));
    }

    @Override
    public Observable<List<Room>> getRooms() {
        AVQuery<AVObject> query = AVQuery.getQuery(RoomService.OBJECT_KEY);
        query.include(RoomService.ANCHOR_ID_KEY);
        query.limit(10);
        query.orderByDescending(RoomService.TAG_CREATEDAT);
        return query.findInBackground()
                .subscribeOn(Schedulers.io())
                .concatMap(avObjects -> {
                    List<Room> rooms = new ArrayList<>();
                    for (AVObject object : avObjects) {
                        AVObject userObject = object.getAVObject(RoomService.ANCHOR_ID_KEY);
                        User user = mGson.fromJson(userObject.toJSONObject().toJSONString(), User.class);

                        Room room = mGson.fromJson(object.toJSONObject().toJSONString(), Room.class);
                        room.setAnchorId(user);
                        rooms.add(room);
                    }
                    return Observable.just(rooms);
                });
    }

    @Override
    public Observable<Room> getRoomListInfo(Room room) {
        String roomId = room.getObjectId();
        AVObject roomObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, roomId);

        //查询成员数量
        AVQuery<AVObject> queryMember1 = AVQuery.getQuery(MemberService.OBJECT_KEY);
        queryMember1.whereEqualTo(MemberService.TAG_ROOMID, roomObject);

        //查询演讲者数量
        AVQuery<AVObject> queryMember2 = AVQuery.getQuery(MemberService.OBJECT_KEY);
        queryMember2.whereEqualTo(MemberService.TAG_ROOMID, roomObject);
        queryMember2.whereEqualTo(MemberService.TAG_IS_SPEAKER, 1);

        return Observable.zip(queryMember1.countInBackground(), queryMember2.countInBackground(), new BiFunction<Integer, Integer, Room>() {
            @NonNull
            @Override
            public Room apply(@NonNull Integer integer, @NonNull Integer integer2) throws Exception {
                room.setMembers(integer);
                return room;
            }
        }).subscribeOn(Schedulers.io());
    }

    @Override
    public Maybe<Room> getRoomListInfo2(Room room) {
        String roomId = room.getObjectId();
        AVObject roomObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, roomId);

        //查询3个用户成员
        AVQuery<AVObject> queryMember3 = AVQuery.getQuery(MemberService.OBJECT_KEY);
        queryMember3.whereEqualTo(MemberService.TAG_ROOMID, roomObject);
        queryMember3.limit(3);
        queryMember3.include(MemberService.TAG_USERID);

        return queryMember3.findInBackground()
                .subscribeOn(Schedulers.io())
                .firstElement()
                .concatMap(new Function<List<AVObject>, MaybeSource<? extends Room>>() {
                    @Override
                    public MaybeSource<? extends Room> apply(@NonNull List<AVObject> avObjects) throws Exception {
                        List<Member> speakers = new ArrayList<>();
                        for (AVObject item : avObjects) {
                            AVObject userObject = item.getAVObject(MemberService.TAG_USERID);
                            User user = mGson.fromJson(userObject.toJSONObject().toJSONString(), User.class);

                            Member member = mGson.fromJson(item.toJSONObject().toJSONString(), Member.class);
                            member.setUserId(user);

                            if (member.getIsSpeaker() == 1) {
                                speakers.add(member);
                            }
                        }
                        room.setSpeakers(speakers);
                        return Maybe.just(room);
                    }
                });
    }

    @Override
    public Observable<Room> creatRoom(Room room) {
        AVObject userAVObject = AVObject.createWithoutData(UserService.OBJECT_KEY, room.getAnchorId().getObjectId());
        AVObject avObject = new AVObject(RoomService.OBJECT_KEY);
        avObject.put(RoomService.ANCHOR_ID_KEY, userAVObject);
        avObject.put(RoomService.CHANNEL_NAME_KEY, room.getChannelName());
        return avObject.saveInBackground()
                .subscribeOn(Schedulers.io())
                .concatMap(new AVObjectToObservable<>(new TypeToken<Room>() {
                }.getType()));
    }

    @Override
    public Maybe<Room> getRoom(Room room) {
        AVQuery<AVObject> query = AVQuery.getQuery(RoomService.OBJECT_KEY);
        query.include(RoomService.ANCHOR_ID_KEY);
        return query.getInBackground(room.getObjectId())
                .subscribeOn(Schedulers.io())
                .firstElement()
                .concatMap(new Function<AVObject, MaybeSource<? extends Room>>() {
                    @Override
                    public MaybeSource<? extends Room> apply(@NonNull AVObject avObject) throws Exception {
                        AVObject userObject = avObject.getAVObject(RoomService.ANCHOR_ID_KEY);
                        User user = mGson.fromJson(userObject.toJSONObject().toJSONString(), User.class);

                        Room roomNew = mGson.fromJson(avObject.toJSONObject().toJSONString(), Room.class);
                        roomNew.setAnchorId(user);
                        return Maybe.just(roomNew);
                    }
                });
    }

    @Override
    public Observable<List<Member>> getMembers(Room room) {
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, room.getObjectId());

        AVQuery<AVObject> query = AVQuery.getQuery(MemberService.OBJECT_KEY);
        query.include(MemberService.TAG_USERID);
        query.include(MemberService.TAG_ROOMID);
        query.include(MemberService.TAG_ROOMID + "." + RoomService.ANCHOR_ID_KEY);
        query.whereEqualTo(MemberService.TAG_ROOMID, roomAVObject);
        return query.findInBackground()
                .subscribeOn(Schedulers.io())
                .concatMap(avObjects -> {
                    List<Member> list = new ArrayList<>();
                    for (AVObject object : avObjects) {
                        AVObject userObject = object.getAVObject(MemberService.TAG_USERID);
                        AVObject roomObject = object.getAVObject(MemberService.TAG_ROOMID);
                        AVObject ancherObject = roomObject.getAVObject(RoomService.ANCHOR_ID_KEY);

                        User user = mGson.fromJson(userObject.toJSONObject().toJSONString(), User.class);
                        Room roomTemp = mGson.fromJson(roomObject.toJSONObject().toJSONString(), Room.class);
                        User ancher = mGson.fromJson(ancherObject.toJSONObject().toJSONString(), User.class);
                        room.setAnchorId(ancher);

                        Member member = mGson.fromJson(object.toJSONObject().toJSONString(), Member.class);
                        member.setUserId(user);
                        member.setRoomId(roomTemp);
                        list.add(member);
                    }
                    return Observable.just(list);
                });
    }

    @Override
    public Maybe<Member> getMember(String roomId, String userId) {
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, roomId);
        AVObject userAVObject = AVObject.createWithoutData(UserService.OBJECT_KEY, userId);
        AVQuery<AVObject> avQuery = AVQuery.getQuery(MemberService.OBJECT_KEY);
        avQuery.whereEqualTo(MemberService.TAG_USERID, userAVObject);
        avQuery.whereEqualTo(MemberService.TAG_ROOMID, roomAVObject);
        avQuery.include(MemberService.TAG_ROOMID);
        avQuery.include(MemberService.TAG_ROOMID + "." + RoomService.ANCHOR_ID_KEY);
        avQuery.include(MemberService.TAG_USERID);
        return avQuery.getFirstInBackground()
                .subscribeOn(Schedulers.io()).firstElement()
                .concatMap(new Function<AVObject, MaybeSource<? extends Member>>() {
                    @Override
                    public MaybeSource<? extends Member> apply(@NonNull AVObject avObject) throws Exception {
                        AVObject userObject = avObject.getAVObject(MemberService.TAG_USERID);
                        AVObject roomObject = avObject.getAVObject(MemberService.TAG_ROOMID);
                        AVObject ancherObject = roomObject.getAVObject(RoomService.ANCHOR_ID_KEY);

                        User user = mGson.fromJson(userObject.toJSONObject().toJSONString(), User.class);
                        Room room = mGson.fromJson(roomObject.toJSONObject().toJSONString(), Room.class);
                        User ancher = mGson.fromJson(ancherObject.toJSONObject().toJSONString(), User.class);
                        room.setAnchorId(ancher);

                        Member memberTemp = mGson.fromJson(avObject.toJSONObject().toJSONString(), Member.class);
                        memberTemp.setUserId(user);
                        memberTemp.setRoomId(room);
                        return Maybe.just(memberTemp);
                    }
                });
    }

    @Override
    public Maybe<Member> getMember(int uid) {
        AVQuery<AVObject> avQuery = AVQuery.getQuery(MemberService.OBJECT_KEY);
        avQuery.whereEqualTo(MemberService.TAG_STREAMID, uid);
        avQuery.include(MemberService.TAG_ROOMID);
        avQuery.include(MemberService.TAG_ROOMID + "." + RoomService.ANCHOR_ID_KEY);
        avQuery.include(MemberService.TAG_USERID);
        return avQuery.getFirstInBackground()
                .subscribeOn(Schedulers.io())
                .firstElement()
                .concatMap(new Function<AVObject, MaybeSource<? extends Member>>() {
                    @Override
                    public MaybeSource<? extends Member> apply(@NonNull AVObject avObject) throws Exception {
                        AVObject userObject = avObject.getAVObject(MemberService.TAG_USERID);
                        AVObject roomObject = avObject.getAVObject(MemberService.TAG_ROOMID);
                        AVObject ancherObject = roomObject.getAVObject(RoomService.ANCHOR_ID_KEY);

                        User user = mGson.fromJson(userObject.toJSONObject().toJSONString(), User.class);
                        Room room = mGson.fromJson(roomObject.toJSONObject().toJSONString(), Room.class);
                        User ancher = mGson.fromJson(ancherObject.toJSONObject().toJSONString(), User.class);
                        room.setAnchorId(ancher);

                        Member memberTemp = mGson.fromJson(avObject.toJSONObject().toJSONString(), Member.class);
                        memberTemp.setUserId(user);
                        memberTemp.setRoomId(room);
                        return Maybe.just(memberTemp);
                    }
                });
    }

    @Override
    public Observable<Member> joinRoom(Member member) {
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, member.getRoomId().getObjectId());
        AVObject userAVObject = AVObject.createWithoutData(UserService.OBJECT_KEY, member.getUserId().getObjectId());

        AVQuery<AVObject> avQuery = AVQuery.getQuery(MemberService.OBJECT_KEY)
                .whereEqualTo(MemberService.TAG_USERID, userAVObject)
                .whereEqualTo(MemberService.TAG_ROOMID, roomAVObject);

        return avQuery.countInBackground()
                .subscribeOn(Schedulers.io())
                .concatMap(new Function<Integer, ObservableSource<Member>>() {
                    @Override
                    public ObservableSource<Member> apply(@NonNull Integer integer) throws Exception {
                        if (integer <= 0) {
                            AVObject avObject = new AVObject(MemberService.OBJECT_KEY);
                            avObject.put(MemberService.TAG_ROOMID, roomAVObject);
                            avObject.put(MemberService.TAG_USERID, userAVObject);

                            avObject.put(MemberService.TAG_STREAMID, member.getStreamId());
                            avObject.put(MemberService.TAG_IS_SPEAKER, member.getIsSpeaker());
                            avObject.put(MemberService.TAG_ISMUTED, member.getIsMuted());
                            avObject.put(MemberService.TAG_ISSELFMUTED, member.getIsSelfMuted());
                            return avObject.saveInBackground()
                                    .flatMap(new Function<AVObject, ObservableSource<Member>>() {
                                        @Override
                                        public ObservableSource<Member> apply(@NonNull AVObject avObject) throws Exception {
                                            Member memberTemp = mGson.fromJson(avObject.toJSONObject().toJSONString(), Member.class);
                                            memberTemp.setUserId(member.getUserId());
                                            memberTemp.setRoomId(member.getRoomId());
                                            return Observable.just(memberTemp);
                                        }
                                    });
                        } else {
                            avQuery.include(MemberService.TAG_ROOMID);
                            avQuery.include(MemberService.TAG_ROOMID + "." + RoomService.ANCHOR_ID_KEY);
                            avQuery.include(MemberService.TAG_USERID);
                            return avQuery.getFirstInBackground()
                                    .flatMap(new Function<AVObject, ObservableSource<Member>>() {
                                        @Override
                                        public ObservableSource<Member> apply(@NonNull AVObject avObject) throws Exception {
                                            AVObject userObject = avObject.getAVObject(MemberService.TAG_USERID);
                                            AVObject roomObject = avObject.getAVObject(MemberService.TAG_ROOMID);
                                            AVObject ancherObject = roomObject.getAVObject(RoomService.ANCHOR_ID_KEY);

                                            User user = mGson.fromJson(userObject.toJSONObject().toJSONString(), User.class);
                                            Room room = mGson.fromJson(roomObject.toJSONObject().toJSONString(), Room.class);
                                            User ancher = mGson.fromJson(ancherObject.toJSONObject().toJSONString(), User.class);
                                            room.setAnchorId(ancher);

                                            Member memberTemp = mGson.fromJson(avObject.toJSONObject().toJSONString(), Member.class);
                                            memberTemp.setUserId(user);
                                            memberTemp.setRoomId(room);
                                            return Observable.just(memberTemp);
                                        }
                                    });
                        }
                    }
                });
    }

    @Override
    public Completable leanRoom(Member member) {
        if (ObjectsCompat.equals(member.getUserId(), member.getRoomId().getAnchorId())) {
            AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, member.getRoomId().getObjectId());

            //删除Member。
            AVQuery<AVObject> avQueryMember = AVQuery.getQuery(MemberService.OBJECT_KEY)
                    .whereEqualTo(MemberService.TAG_ROOMID, roomAVObject);

            //删除Action
            AVQuery<AVObject> avQueryAction = AVQuery.getQuery(ActionService.OBJECT_KEY)
                    .whereEqualTo(ActionService.TAG_ROOMID, roomAVObject);

            //删除房间
            AVObject avObjectRoom = AVObject.createWithoutData(RoomService.OBJECT_KEY, member.getRoomId().getObjectId());

            return Observable.concat(avQueryMember.deleteAllInBackground(), avQueryAction.deleteAllInBackground(), avObjectRoom.deleteInBackground()).concatMapCompletable(new Function<AVNull, CompletableSource>() {
                @Override
                public CompletableSource apply(@NonNull AVNull avNull) throws Exception {
                    return Completable.complete();
                }
            }).subscribeOn(Schedulers.io());
        } else {
            AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, member.getRoomId().getObjectId());
            AVObject memberAVObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, member.getObjectId());

            //删除Action
            AVQuery<AVObject> avQueryAction = AVQuery.getQuery(ActionService.OBJECT_KEY)
                    .whereEqualTo(ActionService.TAG_ROOMID, roomAVObject)
                    .whereEqualTo(ActionService.TAG_MEMBERID, memberAVObject);

            //删除Member
            AVObject avObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, member.getObjectId());

            return avQueryAction.deleteAllInBackground()
                    .concatWith(avObject.deleteInBackground()).concatMapCompletable(new Function<AVNull, CompletableSource>() {
                        @Override
                        public CompletableSource apply(@NonNull AVNull avNull) throws Exception {
                            return Completable.complete();
                        }
                    }).subscribeOn(Schedulers.io());
        }
    }

    @Override
    public Observable<Member> muteVoice(Member member, int muted) {
        AVObject avObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, member.getObjectId());
        avObject.put(MemberService.TAG_ISMUTED, muted);
        return avObject.saveInBackground()
                .subscribeOn(Schedulers.io())
                .concatMap(new AVObjectToObservable<>(new TypeToken<Member>() {
                }.getType()));
    }

    @Override
    public Observable<Member> muteSelfVoice(Member member, int muted) {
        AVObject avObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, member.getObjectId());
        avObject.put(MemberService.TAG_ISSELFMUTED, muted);
        return avObject.saveInBackground()
                .subscribeOn(Schedulers.io())
                .concatMap(new AVObjectToObservable<>(new TypeToken<Member>() {
                }.getType()));
    }

    @Override
    public Completable requestHandsUp(Member member) {
        AVObject memberAVObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, member.getObjectId());
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, member.getRoomId().getObjectId());

        AVObject avObject = new AVObject(ActionService.OBJECT_KEY);
        avObject.put(ActionService.TAG_MEMBERID, memberAVObject);
        avObject.put(ActionService.TAG_ROOMID, roomAVObject);
        avObject.put(ActionService.TAG_ACTION, ActionService.ACTION.HandsUp.getValue());
        avObject.put(ActionService.TAG_STATUS, ActionService.ACTION_STATUS.Ing.getValue());
        return avObject.saveInBackground()
                .concatMapCompletable(new Function<AVObject, CompletableSource>() {
                    @Override
                    public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                        return Completable.complete();
                    }
                });
    }

    @Override
    public Completable agreeHandsUp(Action action) {
        AVObject memberObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, action.getMemberId().getObjectId());
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, action.getRoomId().getObjectId());

        //更新Member表
        memberObject.put(MemberService.TAG_IS_SPEAKER, 1);

        //更新Action表
        AVObject actionObject = AVObject.createWithoutData(ActionService.OBJECT_KEY, action.getObjectId());
        actionObject.put(ActionService.TAG_MEMBERID, memberObject);
        actionObject.put(ActionService.TAG_ROOMID, roomAVObject);
        actionObject.put(ActionService.TAG_ACTION, ActionService.ACTION.HandsUp.getValue());
        actionObject.put(ActionService.TAG_STATUS, ActionService.ACTION_STATUS.Agree.getValue());

        return Completable.concatArray(memberObject.saveInBackground().concatMapCompletable(new Function<AVObject, CompletableSource>() {
            @Override
            public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                return Completable.complete();
            }
        }), actionObject.saveInBackground().concatMapCompletable(new Function<AVObject, CompletableSource>() {
            @Override
            public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                return Completable.complete();
            }
        })).subscribeOn(Schedulers.io());
    }

    @Override
    public Completable refuseHandsUp(Action action) {
        AVObject memberAVObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, action.getMemberId().getObjectId());
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, action.getRoomId().getObjectId());

        //更新Action表
        AVObject actionObject = new AVObject(ActionService.OBJECT_KEY);
        actionObject.put(ActionService.TAG_MEMBERID, memberAVObject);
        actionObject.put(ActionService.TAG_ROOMID, roomAVObject);
        actionObject.put(ActionService.TAG_ACTION, ActionService.ACTION.HandsUp.getValue());
        actionObject.put(ActionService.TAG_STATUS, ActionService.ACTION_STATUS.Refuse.getValue());

        return actionObject.saveInBackground().concatMapCompletable(new Function<AVObject, CompletableSource>() {
            @Override
            public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                return Completable.complete();
            }
        }).subscribeOn(Schedulers.io());
    }

    @Override
    public Completable inviteSeat(Member member) {
        AVObject memberAVObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, member.getObjectId());
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, member.getRoomId().getObjectId());

        AVObject avObject = new AVObject(ActionService.OBJECT_KEY);
        avObject.put(ActionService.TAG_MEMBERID, memberAVObject);
        avObject.put(ActionService.TAG_ROOMID, roomAVObject);
        avObject.put(ActionService.TAG_ACTION, ActionService.ACTION.Invite.getValue());
        avObject.put(ActionService.TAG_STATUS, ActionService.ACTION_STATUS.Ing.getValue());

        return avObject.saveInBackground().concatMapCompletable(new Function<AVObject, CompletableSource>() {
            @Override
            public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                return Completable.complete();
            }
        });
    }

    @Override
    public Completable agreeInvite(Action action) {
        AVObject memberAVObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, action.getMemberId().getObjectId());
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, action.getRoomId().getObjectId());

        //更新Member表
        memberAVObject.put(MemberService.TAG_IS_SPEAKER, 1);

        //更新Action表
        AVObject actionObject = new AVObject(ActionService.OBJECT_KEY);
        actionObject.put(ActionService.TAG_MEMBERID, memberAVObject);
        actionObject.put(ActionService.TAG_ROOMID, roomAVObject);
        actionObject.put(ActionService.TAG_ACTION, ActionService.ACTION.Invite.getValue());
        actionObject.put(ActionService.TAG_STATUS, ActionService.ACTION_STATUS.Agree.getValue());

        return Completable.concatArray(memberAVObject.saveInBackground().concatMapCompletable(new Function<AVObject, CompletableSource>() {
            @Override
            public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                return Completable.complete();
            }
        }), actionObject.saveInBackground().concatMapCompletable(new Function<AVObject, CompletableSource>() {
            @Override
            public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                return Completable.complete();
            }
        })).subscribeOn(Schedulers.io());
    }

    @Override
    public Completable refuseInvite(Action action) {
        AVObject memberAVObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, action.getMemberId().getObjectId());
        AVObject roomAVObject = AVObject.createWithoutData(RoomService.OBJECT_KEY, action.getRoomId().getObjectId());

        //更新Action表
        AVObject actionObject = new AVObject(ActionService.OBJECT_KEY);
        actionObject.put(ActionService.TAG_MEMBERID, memberAVObject);
        actionObject.put(ActionService.TAG_ROOMID, roomAVObject);
        actionObject.put(ActionService.TAG_ACTION, ActionService.ACTION.Invite.getValue());
        actionObject.put(ActionService.TAG_STATUS, ActionService.ACTION_STATUS.Refuse.getValue());

        return actionObject.saveInBackground().concatMapCompletable(new Function<AVObject, CompletableSource>() {
            @Override
            public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                return Completable.complete();
            }
        }).subscribeOn(Schedulers.io());
    }

    @Override
    public Completable seatOff(Member member) {
        AVObject memberObject = AVObject.createWithoutData(MemberService.OBJECT_KEY, member.getObjectId());
        memberObject.put(MemberService.TAG_IS_SPEAKER, 0);
        return memberObject.saveInBackground()
                .subscribeOn(Schedulers.io())
                .concatMapCompletable(new Function<AVObject, CompletableSource>() {
                    @Override
                    public CompletableSource apply(@NonNull AVObject avObject) throws Exception {
                        return Completable.complete();
                    }
                });
    }
}
