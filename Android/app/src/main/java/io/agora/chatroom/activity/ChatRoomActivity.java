package io.agora.chatroom.activity;

import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.recyclerview.widget.GridLayoutManager;

import com.bumptech.glide.Glide;

import java.util.List;

import io.agora.chatroom.R;
import io.agora.chatroom.adapter.ChatRoomListsnerAdapter;
import io.agora.chatroom.adapter.ChatRoomSeatUserAdapter;
import io.agora.chatroom.base.DataBindBaseActivity;
import io.agora.chatroom.base.OnItemClickListener;
import io.agora.chatroom.data.DataRepositroy;
import io.agora.chatroom.databinding.ActivityChatRoomBinding;
import io.agora.chatroom.manager.RoomManager;
import io.agora.chatroom.manager.RtcManager;
import io.agora.chatroom.manager.UserManager;
import io.agora.chatroom.model.Action;
import io.agora.chatroom.model.Member;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.model.User;
import io.agora.chatroom.service.model.BaseError;
import io.agora.chatroom.service.model.DataCompletableObserver;
import io.agora.chatroom.service.model.DataMaybeObserver;
import io.agora.chatroom.service.model.DataObserver;
import io.agora.chatroom.util.ToastUtile;
import io.agora.chatroom.widget.HandUpDialog;
import io.agora.chatroom.widget.InviteMenuDialog;
import io.agora.chatroom.widget.InvitedMenuDialog;
import io.agora.chatroom.widget.UserSeatMenuDialog;
import io.agora.rtc.IRtcEngineEventHandler;
import io.reactivex.android.schedulers.AndroidSchedulers;

/**
 * 聊天室
 * 1. 查询Room表，房间是否存在，不存在就退出。
 * 2. 查询Member表
 * 2.1. 不存在就创建用户，并且用0加入到RTC，利用RTC分配一个唯一的uid，并且修改member的streamId值，这里注意，rtc分配的uid是int类型，需要进行（& 0xffffffffL）转换成long类型。
 * 2.2. 存在就返回member对象，利用streamId加入到RTC。
 *
 * @author chenhengfei@agora.io
 */
public class ChatRoomActivity extends DataBindBaseActivity<ActivityChatRoomBinding> implements View.OnClickListener, RoomManager.RoomDataCallback {

    private static final String TAG = ChatRoomActivity.class.getSimpleName();

    private static final String TAG_ROOM = "room";

    private ChatRoomSeatUserAdapter mSpeakerAdapter;
    private ChatRoomListsnerAdapter mListenerAdapter;

    private OnItemClickListener<Member> onitemSpeaker = new OnItemClickListener<Member>() {
        @Override
        public void onItemClick(@NonNull Member data, View view, int position, long id) {
            if (!isAnchor()) {
                return;
            }


            if (isMine(data)) {
                return;
            }

            showUserMenuDialog(data);
        }
    };

    private OnItemClickListener<Member> onitemListener = new OnItemClickListener<Member>() {
        @Override
        public void onItemClick(@NonNull Member data, View view, int position, long id) {
            if (!isAnchor()) {
                return;
            }

            showUserInviteDialog(data);
        }
    };

    public static Intent newIntent(Context context, Room mRoom) {
        Intent intent = new Intent(context, ChatRoomActivity.class);
        intent.putExtra(TAG_ROOM, mRoom);
        return intent;
    }

    private final IRtcEngineEventHandler mIRtcEngineEventHandler = new IRtcEngineEventHandler() {
        @Override
        public void onError(int err) {
            super.onError(err);
        }

        @Override
        public void onJoinChannelSuccess(String channel, int uid, int elapsed) {
            super.onJoinChannelSuccess(channel, uid, elapsed);
            if (RoomManager.isLeaving) {
                return;
            }

            Member member = RoomManager.Instance(ChatRoomActivity.this).getMember();
            if (member == null) {
                return;
            }

            long streamId = uid & 0xffffffffL;
            member.setStreamId(streamId);
            onRTCRoomJoined();
        }
    };

    @Override
    protected void iniBundle(@NonNull Bundle bundle) {

    }

    @Override
    protected int getLayoutId() {
        return R.layout.activity_chat_room;
    }

    @Override
    protected void iniView() {
        mSpeakerAdapter = new ChatRoomSeatUserAdapter(this);
        mListenerAdapter = new ChatRoomListsnerAdapter(this);
        mSpeakerAdapter.setOnItemClickListener(onitemSpeaker);
        mListenerAdapter.setOnItemClickListener(onitemListener);
        mDataBinding.rvSpeakers.setLayoutManager(new GridLayoutManager(this, 3));
        mDataBinding.rvListeners.setLayoutManager(new GridLayoutManager(this, 2));
        mDataBinding.rvSpeakers.setAdapter(mSpeakerAdapter);
        mDataBinding.rvListeners.setAdapter(mListenerAdapter);
    }

    @Override
    protected void iniListener() {
        RtcManager.Instance(this).addHandler(mIRtcEngineEventHandler);
        RoomManager.Instance(this).addRoomDataCallback(this);
        mDataBinding.ivMin.setOnClickListener(this);
        mDataBinding.ivExit.setOnClickListener(this);
        mDataBinding.llExit.setOnClickListener(this);
        mDataBinding.ivNews.setOnClickListener(this);
        mDataBinding.ivAudio.setOnClickListener(this);
        mDataBinding.ivHandUp.setOnClickListener(this);
    }

    @Override
    protected void iniData() {
        User mUser = UserManager.Instance(this).getUserLiveData().getValue();
        if (mUser == null) {
            ToastUtile.toastShort(this, "please login in");
            finish();
            return;
        }

        Room mRoom = (Room) getIntent().getExtras().getSerializable(TAG_ROOM);

        Member mMember = new Member(mUser);
        mMember.setRoomId(mRoom);
        RoomManager.Instance(this).onJoinRoom(mRoom, mMember);

        if (isAnchor()) {
            mMember.setIsSpeaker(1);
            mDataBinding.ivExit.setVisibility(View.VISIBLE);
        } else {
            mMember.setIsSpeaker(0);
            mDataBinding.ivExit.setVisibility(View.INVISIBLE);
        }

        setUserBaseInfo();
        UserManager.Instance(this).getUserLiveData().observe(this, tempUser -> {
            if (tempUser == null) {
                return;
            }

            Member temp = RoomManager.Instance(ChatRoomActivity.this).getMember();
            if (temp == null) {
                return;
            }

            temp.setUser(tempUser);
            setUserBaseInfo();
        });

        if (isAnchor()) {
            mDataBinding.ivNews.setVisibility(View.VISIBLE);
        } else {
            mDataBinding.ivNews.setVisibility(View.GONE);
        }

        preJoinRoom(mRoom);
    }

    private void setUserBaseInfo() {
        Member member = RoomManager.Instance(ChatRoomActivity.this).getMember();
        if (member == null) {
            return;
        }

        Glide.with(this)
                .load(member.getUserId().getAvatarRes())
                .placeholder(R.mipmap.default_head)
                .error(R.mipmap.default_head)
                .circleCrop()
                .into(mDataBinding.ivUser);
    }

    private void refreshVoiceView() {
        Member member = RoomManager.Instance(ChatRoomActivity.this).getMember();
        if (member == null) {
            return;
        }

        if (isAnchor()) {
            mDataBinding.ivAudio.setVisibility(View.VISIBLE);
            if (member.getIsMuted() == 1) {
                mDataBinding.ivAudio.setImageResource(R.mipmap.icon_microphoneoff);
            } else if (member.getIsSelfMuted() == 1) {
                mDataBinding.ivAudio.setImageResource(R.mipmap.icon_microphoneoff);
            } else {
                mDataBinding.ivAudio.setImageResource(R.mipmap.icon_microphoneon);
            }
        } else {
            if (member.getIsSpeaker() == 0) {
                mDataBinding.ivAudio.setVisibility(View.GONE);
            } else {
                mDataBinding.ivAudio.setVisibility(View.VISIBLE);
                if (member.getIsMuted() == 1) {
                    mDataBinding.ivAudio.setImageResource(R.mipmap.icon_microphoneoff);
                } else if (member.getIsSelfMuted() == 1) {
                    mDataBinding.ivAudio.setImageResource(R.mipmap.icon_microphoneoff);
                } else {
                    mDataBinding.ivAudio.setImageResource(R.mipmap.icon_microphoneon);
                }
            }
        }
    }

    private void preJoinRoom(Room room) {
        onLoadRoom(room);

        RoomManager.Instance(this)
                .getRoom(room)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataMaybeObserver<Room>(this) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        if (RoomManager.isLeaving) {
                            return;
                        }

                        ToastUtile.toastShort(ChatRoomActivity.this, R.string.error_room_not_exsit);
                        RoomManager.Instance(ChatRoomActivity.this).leaveRoom();
                        finish();
                    }

                    @Override
                    public void handleSuccess(@Nullable Room room) {
                        if (RoomManager.isLeaving) {
                            return;
                        }

                        if (room == null) {
                            ToastUtile.toastShort(ChatRoomActivity.this, R.string.error_room_not_exsit);
                            RoomManager.Instance(ChatRoomActivity.this).leaveRoom();
                            finish();
                            return;
                        }

                        RoomManager.Instance(ChatRoomActivity.this)
                                .getMine()
                                .observeOn(AndroidSchedulers.mainThread())
                                .compose(mLifecycleProvider.bindToLifecycle())
                                .subscribe(new DataMaybeObserver<Member>(ChatRoomActivity.this) {
                                    @Override
                                    public void handleError(@NonNull BaseError e) {
                                        if (RoomManager.isLeaving) {
                                            return;
                                        }

                                        ToastUtile.toastShort(ChatRoomActivity.this, R.string.error_room_not_exsit);
                                        finish();
                                    }

                                    @Override
                                    public void handleSuccess(@Nullable Member member) {
                                        if (RoomManager.isLeaving) {
                                            return;
                                        }

                                        if (member != null) {
                                            onMemberUpdated(member);
                                        }

                                        joinRTCRoom();
                                    }
                                });
                    }
                });
    }

    private void getMembers() {
        Room room = RoomManager.Instance(this).getRoom();
        DataRepositroy.Instance(this)
                .getMembers(room)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataObserver<List<Member>>(this) {
                    @Override
                    public void handleError(@NonNull BaseError e) {

                    }

                    @Override
                    public void handleSuccess(@NonNull List<Member> members) {
                        if (RoomManager.isLeaving) {
                            return;
                        }

                        onLoadRoomMembers(members);
                    }
                });
    }

    private void onLoadRoom(Room room) {
        mDataBinding.tvName.setText(room.getChannelName());
    }

    private void onLoadRoomMembers(@NonNull List<Member> members) {
        RoomManager.Instance(this).onLoadRoomMembers(members);

        for (Member member : members) {
            if (member.getIsSpeaker() == 0) {
                mListenerAdapter.addItem(member);
            } else {
                mSpeakerAdapter.addItem(member);
            }
        }

        RoomManager.Instance(this).register();
    }

    private InvitedMenuDialog inviteDialog;

    private void showInviteDialog(Action action) {
        if (inviteDialog != null && inviteDialog.isShowing()) {
            return;
        }

        Room room = RoomManager.Instance(this).getRoom();
        if (room == null) {
            return;
        }
        inviteDialog = new InvitedMenuDialog();
        inviteDialog.show(getSupportFragmentManager(), room.getAnchorId(), action);
    }

    private void closeInviteDialog() {
        if (inviteDialog != null && inviteDialog.isShowing()) {
            inviteDialog.dismiss();
        }
    }

    private void joinRTCRoom() {
        Room room = RoomManager.Instance(this).getRoom();
        if (room == null) {
            return;
        }

        Member member = RoomManager.Instance(this).getMember();
        if (member == null) {
            return;
        }

        int userId = 0;
        if (member.getStreamId() != null) {
            userId = member.getStreamId().intValue();
        }
        RtcManager.Instance(this).joinChannel(room.getObjectId(), userId);
    }

    private void onRTCRoomJoined() {
        joinRoom();
    }

    private void joinRoom() {
        RoomManager.Instance(this)
                .joinRoom()
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataObserver<Member>(this) {
                    @Override
                    public void handleError(@NonNull BaseError e) {

                    }

                    @Override
                    public void handleSuccess(@NonNull Member member) {
                        if (RoomManager.isLeaving) {
                            return;
                        }

                        getMembers();
                    }
                });
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.ivMin:
                exitRoom(false);
                break;
            case R.id.ivExit:
                if (isAnchor()) {
                    showCloseRoomDialog();
                } else {
                    exitRoom(true);
                }
                break;
            case R.id.llExit:
                if (isAnchor()) {
                    showCloseRoomDialog();
                } else {
                    exitRoom(true);
                }
                break;
            case R.id.ivNews:
                gotoHandsUpList();
                break;
            case R.id.ivAudio:
                toggleAudio();
                break;
            case R.id.ivHandUp:
                toggleHandUp();
                break;
        }
    }

    private void showCloseRoomDialog() {
        new AlertDialog.Builder(this)
                .setTitle(R.string.room_dialog_close_title)
                .setMessage(R.string.room_dialog_close_message)
                .setPositiveButton(R.string.confirm, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        exitRoom(true);
                    }
                })
                .setNegativeButton(R.string.cancel, null)
                .show();
    }

    private void exitRoom(boolean leaveRoom) {
        if (leaveRoom) {
            RoomManager.Instance(this).leaveRoom();
        } else {
            RoomManager.Instance(this).onEnterMin();
        }

        finish();
        if (!leaveRoom) {
            overridePendingTransition(R.anim.chat_room_in, R.anim.chat_room_out);
        }
    }

    private void gotoHandsUpList() {
        Room mRoom = RoomManager.Instance(this).getRoom();
        if (mRoom == null) {
            return;
        }

        new HandUpDialog().show(getSupportFragmentManager(), mRoom);
    }

    private void toggleAudio() {
        if (!RoomManager.Instance(this).isAnchor()) {
            Member member = RoomManager.Instance(this).getMember();
            if (member == null) {
                return;
            }

            if (member.getIsMuted() == 1) {
                ToastUtile.toastShort(this, R.string.error_owner_muted);
                return;
            }
        }

        mDataBinding.ivAudio.setEnabled(false);
        RoomManager.Instance(this)
                .toggleAudio()
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataObserver<Member>(this) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        ToastUtile.toastShort(ChatRoomActivity.this, e.getMessage());
                        mDataBinding.ivAudio.setEnabled(true);
                    }

                    @Override
                    public void handleSuccess(@NonNull Member member) {
                        mDataBinding.ivAudio.setEnabled(true);
                        refreshVoiceView();
                    }
                });
    }

    private void refreshHandUpView() {
        if (RoomManager.Instance(this).isAnchor()) {
            mDataBinding.ivHandUp.setVisibility(View.GONE);
        } else {
            mDataBinding.ivHandUp.setImageResource(R.mipmap.icon_un_handup);

            Member member = RoomManager.Instance(this).getMember();
            if (member == null) {
                return;
            }
            mDataBinding.ivHandUp.setVisibility(member.getIsSpeaker() == 0 ? View.VISIBLE : View.GONE);
        }
    }

    private void toggleHandUp() {
        mDataBinding.ivHandUp.setEnabled(false);
        RoomManager.Instance(this)
                .toggleHandUp()
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataCompletableObserver(this) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        ToastUtile.toastShort(ChatRoomActivity.this, e.getMessage());
                        mDataBinding.ivHandUp.setEnabled(true);
                    }

                    @Override
                    public void handleSuccess() {
                        refreshHandUpView();
                        mDataBinding.ivHandUp.setEnabled(true);
                        ToastUtile.toastShort(ChatRoomActivity.this, R.string.request_handup_success);
                    }
                });
    }

    private void showUserMenuDialog(Member data) {
        new UserSeatMenuDialog().show(getSupportFragmentManager(), data);
    }

    private void showUserInviteDialog(Member data) {
        new InviteMenuDialog().show(getSupportFragmentManager(), data);
    }

    @Override
    public void onMemberJoin(Member member) {
        if (member.getIsSpeaker() == 0) {
            mSpeakerAdapter.deleteItem(member);
            mListenerAdapter.addItem(member);
        } else {
            mSpeakerAdapter.addItem(member);
            mListenerAdapter.deleteItem(member);
        }
    }

    @Override
    public void onMemberLeave(Member member) {
        mSpeakerAdapter.deleteItem(member);
        mListenerAdapter.deleteItem(member);

        if (isAnchor(member)) {
            finish();
        }
    }

    @Override
    public void onMemberUpdated(Member member) {
        if (member.getIsSpeaker() == 0) {
            mSpeakerAdapter.deleteItem(member);
            mListenerAdapter.addItem(member);
        } else {
            mSpeakerAdapter.addItem(member);
            mListenerAdapter.deleteItem(member);
        }

        refreshVoiceView();
        refreshHandUpView();
    }

    @Override
    public void onReceivedHandUp() {
        mDataBinding.ivNews.setCount(RoomManager.Instance(this).getHandUpCount());
    }

    @Override
    public void onHandUpAgree(Member member) {
        refreshHandUpView();
        mDataBinding.ivNews.setCount(RoomManager.Instance(this).getHandUpCount());
    }

    @Override
    public void onHandUpRefuse(Member member) {
        refreshHandUpView();
        mDataBinding.ivNews.setCount(RoomManager.Instance(this).getHandUpCount());
    }

    @Override
    public void onReceivedInvite(Action item) {
        showInviteDialog(item);
    }

    @Override
    public void onMemberInviteAgree(Member member) {
    }

    @Override
    public void onMemberInviteRefuse(Member member) {
        if (!RoomManager.Instance(this).isMine(member)) {
            ToastUtile.toastShort(this, getString(R.string.invite_refuse, member.getUserId().getName()));
        }
    }

    @Override
    public void onEnterMin() {

    }

    private boolean isMine(Member member) {
        return RoomManager.Instance(this).isMine(member);
    }

    private boolean isAnchor() {
        return RoomManager.Instance(this).isAnchor();
    }

    private boolean isAnchor(Member member) {
        return RoomManager.Instance(this).isAnchor(member);
    }

    @Override
    protected void onDestroy() {
        RoomManager.Instance(this).removeRoomDataCallback(this);
        RtcManager.Instance(this).removeHandler(mIRtcEngineEventHandler);
        closeInviteDialog();
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {

    }
}
