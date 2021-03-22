package io.agora.chatroom.activity;

import android.Manifest;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.core.util.ObjectsCompat;
import androidx.lifecycle.Lifecycle;
import androidx.recyclerview.widget.StaggeredGridLayoutManager;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;

import com.bumptech.glide.Glide;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.agora.chatroom.R;
import io.agora.chatroom.adapter.RoomListAdapter;
import io.agora.chatroom.base.DataBindBaseActivity;
import io.agora.chatroom.base.OnItemClickListener;
import io.agora.chatroom.data.DataRepositroy;
import io.agora.chatroom.databinding.ActivityRoomListBinding;
import io.agora.chatroom.manager.RoomManager;
import io.agora.chatroom.manager.UserManager;
import io.agora.chatroom.model.Action;
import io.agora.chatroom.model.Member;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.model.User;
import io.agora.chatroom.service.model.BaseError;
import io.agora.chatroom.service.model.DataCompletableObserver;
import io.agora.chatroom.service.model.DataObserver;
import io.agora.chatroom.util.ToastUtile;
import io.agora.chatroom.widget.CreateRoomDialog;
import io.agora.chatroom.widget.HandUpDialog;
import io.agora.chatroom.widget.SpaceItemDecoration;
import io.reactivex.android.schedulers.AndroidSchedulers;
import pub.devrel.easypermissions.EasyPermissions;

/**
 * 房间列表
 *
 * @author chenhengfei@agora.io
 */
public class RoomListActivity extends DataBindBaseActivity<ActivityRoomListBinding> implements View.OnClickListener,
        OnItemClickListener<Room>, EasyPermissions.PermissionCallbacks, SwipeRefreshLayout.OnRefreshListener, RoomManager.RoomDataCallback {

    private static final int TAG_PERMISSTION_REQUESTCODE = 1000;
    private static final String[] PERMISSTION = new String[]{
            Manifest.permission.READ_EXTERNAL_STORAGE,
            Manifest.permission.WRITE_EXTERNAL_STORAGE,
            Manifest.permission.RECORD_AUDIO};

    private RoomListAdapter mAdapter;

    @Override
    protected void iniBundle(@NonNull Bundle bundle) {

    }

    @Override
    protected int getLayoutId() {
        return R.layout.activity_room_list;
    }

    @Override
    protected void iniView() {
        mAdapter = new RoomListAdapter(this);
        mDataBinding.list.setLayoutManager(new StaggeredGridLayoutManager(2, StaggeredGridLayoutManager.VERTICAL));
        mDataBinding.list.setAdapter(mAdapter);
        mDataBinding.list.addItemDecoration(new SpaceItemDecoration(this));
    }

    @Override
    protected void iniListener() {
        RoomManager.Instance(this).addRoomDataCallback(this);
        mDataBinding.swipeRefreshLayout.setOnRefreshListener(this);
        mDataBinding.ivHead.setOnClickListener(this);
        mDataBinding.btCrateRoom.setOnClickListener(this);

        mDataBinding.ivExit.setOnClickListener(this);
        mDataBinding.ivNews.setOnClickListener(this);
        mDataBinding.ivAudio.setOnClickListener(this);
        mDataBinding.ivHandUp.setOnClickListener(this);
        mDataBinding.llMin.setOnClickListener(this);
    }

    @Override
    protected void iniData() {
        mDataBinding.btCrateRoom.setVisibility(View.VISIBLE);
        mDataBinding.llMin.setVisibility(View.GONE);

        User user = UserManager.Instance(this).getUserLiveData().getValue();
        if (user != null) {
            setUser(user);
        }

        UserManager.Instance(this).getUserLiveData().observe(this, mUser -> {
            if (mUser == null) {
                return;
            }
            setUser(mUser);
        });

        mDataBinding.tvEmpty.setVisibility(mAdapter.getItemCount() <= 0 ? View.VISIBLE : View.GONE);
        loadRooms();
    }

    private void setUser(@NonNull User user) {
        Glide.with(RoomListActivity.this)
                .load(user.getAvatarRes())
                .placeholder(R.mipmap.default_head)
                .circleCrop()
                .error(R.mipmap.default_head)
                .into(mDataBinding.ivHead);
    }

    private void loadRooms() {
        DataRepositroy.Instance(this)
                .getRooms()
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataObserver<List<Room>>(this) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        mDataBinding.swipeRefreshLayout.setRefreshing(false);
                        ToastUtile.toastShort(RoomListActivity.this, e.getMessage());
                    }

                    @Override
                    public void handleSuccess(@NonNull List<Room> rooms) {
                        mDataBinding.swipeRefreshLayout.setRefreshing(false);
                        mAdapter.setDatas(rooms);
                        mDataBinding.tvEmpty.setVisibility(mAdapter.getItemCount() <= 0 ? View.VISIBLE : View.GONE);
                    }
                });
    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.btCrateRoom) {
            gotoCreateRoom();
        } else if (v.getId() == R.id.ivHead) {
            Intent intent = UserInfoActivity.newIntent(this);
            startActivity(intent);
        } else if (v.getId() == R.id.ivExit) {
            exitRoom();
        } else if (v.getId() == R.id.ivNews) {
            gotoHandUpListDialog();
        } else if (v.getId() == R.id.ivAudio) {
            toggleAudio();
        } else if (v.getId() == R.id.ivHandUp) {
            toggleHandUp();
        } else if (v.getId() == R.id.llMin) {
            rebackRoom();
        }
    }

    private void rebackRoom() {
        Room room = RoomManager.Instance(this).getRoom();
        if (room == null) {
            mDataBinding.btCrateRoom.setVisibility(View.VISIBLE);
            mDataBinding.llMin.setVisibility(View.GONE);
            return;
        }

        Intent intent = ChatRoomActivity.newIntent(this, room);
        startActivity(intent);
        overridePendingTransition(R.anim.chat_room_in, R.anim.chat_room_out);
    }

    private void exitRoom() {
        RoomManager.Instance(this).leaveRoom();

        mDataBinding.btCrateRoom.setVisibility(View.VISIBLE);
        mDataBinding.llMin.setVisibility(View.GONE);
    }

    private void gotoHandUpListDialog() {
        new HandUpDialog().show(getSupportFragmentManager(), RoomManager.Instance(this).getRoom());
    }

    private void refreshVoiceView() {
        Member member = RoomManager.Instance(this).getMember();
        if (RoomManager.Instance(this).isAnchor()) {
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

    private void toggleAudio() {
        if (!RoomManager.Instance(this).isAnchor()) {
            if (RoomManager.Instance(this).getMember().getIsMuted() == 1) {
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
                        mDataBinding.ivAudio.setEnabled(true);
                        ToastUtile.toastShort(RoomListActivity.this, e.getMessage());
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
            if (member != null) {
                mDataBinding.ivHandUp.setVisibility(member.getIsSpeaker() == 0 ? View.VISIBLE : View.GONE);
            }
        }
    }

    private void toggleHandUp() {
        mDataBinding.ivHandUp.setEnabled(false);
        RoomManager.Instance(this).
                toggleHandUp()
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataCompletableObserver(this) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        ToastUtile.toastShort(RoomListActivity.this, e.getMessage());
                        mDataBinding.ivHandUp.setEnabled(true);
                    }

                    @Override
                    public void handleSuccess() {
                        refreshHandUpView();
                        mDataBinding.ivHandUp.setEnabled(true);

                        ToastUtile.toastShort(RoomListActivity.this, R.string.request_handup_success);
                    }
                });
    }

    private void gotoCreateRoom() {
        if (EasyPermissions.hasPermissions(this, PERMISSTION)) {
            new CreateRoomDialog().show(getSupportFragmentManager());
        } else {
            EasyPermissions.requestPermissions(this, getString(R.string.error_permisstion),
                    TAG_PERMISSTION_REQUESTCODE, PERMISSTION);
        }
    }

    @Override
    public void onPermissionsGranted(int requestCode, @NonNull List<String> perms) {

    }

    @Override
    public void onPermissionsDenied(int requestCode, @NonNull List<String> perms) {

    }

    @Override
    public void onItemClick(@NonNull Room data, View view, int position, long id) {
        if (!EasyPermissions.hasPermissions(this, PERMISSTION)) {
            EasyPermissions.requestPermissions(this, getString(R.string.error_permisstion),
                    TAG_PERMISSTION_REQUESTCODE, PERMISSTION);
            return;
        }

        Room roomCur = RoomManager.Instance(this).getRoom();
        if (roomCur != null) {
            if (!ObjectsCompat.equals(roomCur, data)) {
                ToastUtile.toastShort(this, "您已经加入了一个房间，请先退出");
                return;
            }
        }

        Intent intent = ChatRoomActivity.newIntent(this, data);
        startActivity(intent);
    }

    @Override
    public void onBackPressed() {
        moveTaskToBack(false);
    }

    @Override
    protected void onDestroy() {
        RoomManager.Instance(this).removeRoomDataCallback(this);
        super.onDestroy();
    }

    @Override
    public void onRefresh() {
        loadRooms();
    }

    @Override
    public void onMemberJoin(Member member) {
        updateMinRoomInfo();
    }

    @Override
    public void onMemberLeave(Member member) {
        if (RoomManager.Instance(this).isAnchor(member) || RoomManager.Instance(this).isMine(member)) {
            mDataBinding.btCrateRoom.setVisibility(View.VISIBLE);
            mDataBinding.llMin.setVisibility(View.GONE);

            if (RoomManager.Instance(this).isAnchor(member)) {
                mAdapter.deleteItem(member.getRoomId());
                mDataBinding.tvEmpty.setVisibility(mAdapter.getItemCount() <= 0 ? View.VISIBLE : View.GONE);
            }

            if (RoomManager.Instance(this).isAnchor(member)) {
                ToastUtile.toastShort(this, R.string.room_closed);
            }
        } else {
            updateMinRoomInfo();
        }
    }

    @Override
    public void onMemberUpdated(Member oldMember, Member newMember) {
        if (this.getLifecycle().getCurrentState().isAtLeast(Lifecycle.State.RESUMED) == false) {
            return;
        }

        if (oldMember.getIsSpeaker() == 0 && newMember.getIsSpeaker() == 1) {
        } else if (oldMember.getIsSpeaker() == 1 && newMember.getIsSpeaker() == 0) {
            ToastUtile.toastShort(this, R.string.member_speaker_to_listener);
        }

        if (oldMember.getIsMuted() == 0 && newMember.getIsMuted() == 1) {
            ToastUtile.toastShort(this, R.string.member_muted);
        }

        refreshVoiceView();
        refreshHandUpView();
        updateMinRoomInfo();
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

    }

    @Override
    public void onMemberInviteAgree(Member member) {
    }

    @Override
    public void onMemberInviteRefuse(Member member) {
        if (this.getLifecycle().getCurrentState().isAtLeast(Lifecycle.State.RESUMED) == false) {
            return;
        }

        if (!RoomManager.Instance(this).isMine(member)) {
            ToastUtile.toastShort(this, getString(R.string.invite_refuse, member.getUserId().getName()));
        }
    }

    @Override
    public void onEnterMin() {
        mDataBinding.btCrateRoom.setVisibility(View.GONE);
        mDataBinding.llMin.setVisibility(View.VISIBLE);

        if (RoomManager.Instance(this).isAnchor()) {
            mDataBinding.ivNews.setVisibility(View.VISIBLE);
        } else {
            mDataBinding.ivNews.setVisibility(View.GONE);
        }

        refreshVoiceView();
        refreshHandUpView();
        updateMinRoomInfo();
    }

    private void updateMinRoomInfo() {
        Room room = RoomManager.Instance(this).getRoom();
        if (room == null) {
            return;
        }

        List<Member> speakers = new ArrayList<>();
        int members = 0;
        Map<String, Member> membersMap = RoomManager.Instance(this).membersMap;
        for (HashMap.Entry<String, Member> item : membersMap.entrySet()) {
            Member member = item.getValue();
            if (member.getIsSpeaker() == 1) {
                speakers.add(member);
            }
            members++;
        }
        room.setSpeakers(speakers);
        room.setMembers(members);

        mDataBinding.members.setMemebrs(speakers);
        mDataBinding.tvNumbers.setText(String.format("%s/%s", room.getMembers(), speakers.size()));
    }
}
