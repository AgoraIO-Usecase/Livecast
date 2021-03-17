package io.agora.chatroom.widget;

import android.content.Intent;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.Display;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentManager;

import java.util.Random;

import io.agora.chatroom.R;
import io.agora.chatroom.activity.ChatRoomActivity;
import io.agora.chatroom.base.DataBindBaseDialog;
import io.agora.chatroom.data.DataRepositroy;
import io.agora.chatroom.databinding.DialogCreateRoomBinding;
import io.agora.chatroom.manager.UserManager;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.model.User;
import io.agora.chatroom.service.model.BaseError;
import io.agora.chatroom.service.model.DataObserver;
import io.agora.chatroom.util.ToastUtile;
import io.reactivex.android.schedulers.AndroidSchedulers;

/**
 * 创建房间
 *
 * @author chenhengfei@agora.io
 */
public class CreateRoomDialog extends DataBindBaseDialog<DialogCreateRoomBinding> implements View.OnClickListener {
    private static final String TAG = CreateRoomDialog.class.getSimpleName();

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        Window win = getDialog().getWindow();
        WindowManager windowManager = win.getWindowManager();
        Display display = windowManager.getDefaultDisplay();
        WindowManager.LayoutParams params = win.getAttributes();
        params.width = display.getWidth() * 4 / 5;
        params.height = ViewGroup.LayoutParams.WRAP_CONTENT;
        win.setAttributes(params);
        return super.onCreateView(inflater, container, savedInstanceState);
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setStyle(STYLE_NORMAL, R.style.Dialog_Nomal);
    }

    @Override
    public void iniBundle(@NonNull Bundle bundle) {

    }

    @Override
    public int getLayoutId() {
        return R.layout.dialog_create_room;
    }

    @Override
    public void iniView() {

    }

    @Override
    public void iniListener() {
        mDataBinding.btCancel.setOnClickListener(this);
        mDataBinding.ivRefresh.setOnClickListener(this);
        mDataBinding.btCreate.setOnClickListener(this);
    }

    @Override
    public void iniData() {
        refreshName();
    }

    public void show(@NonNull FragmentManager manager) {
        super.show(manager, TAG);
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.btCancel:
                dismiss();
                break;
            case R.id.ivRefresh:
                refreshName();
                break;
            case R.id.btCreate:
                create();
                break;
        }
    }

    public static String radomName() {
        return "Room " + String.valueOf(new Random().nextInt(999999));
    }

    private void refreshName() {
        mDataBinding.etInput.setText(radomName());
    }

    private void create() {
        String roomName = mDataBinding.etInput.getText().toString();
        if (TextUtils.isEmpty(roomName)) {
            return;
        }

        User user = UserManager.Instance(requireContext()).getUserLiveData().getValue();
        if (user == null) {
            return;
        }

        Room mRoom = new Room();
        mRoom.setAnchorId(user);
        mRoom.setChannelName(roomName);

        mDataBinding.btCreate.setEnabled(false);
        DataRepositroy.Instance(requireContext())
                .creatRoom(mRoom)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataObserver<Room>(requireContext()) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        mDataBinding.btCreate.setEnabled(true);
                        ToastUtile.toastShort(requireContext(), e.getMessage());
                    }

                    @Override
                    public void handleSuccess(@NonNull Room room) {
                        mDataBinding.btCreate.setEnabled(true);
                        room.setAnchorId(user);
                        Intent intent = ChatRoomActivity.newIntent(requireContext(), room);
                        startActivity(intent);

                        dismiss();
                    }
                });
    }
}
