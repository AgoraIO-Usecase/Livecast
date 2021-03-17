package io.agora.chatroom.widget;

import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentManager;

import io.agora.chatroom.R;
import io.agora.chatroom.base.DataBindBaseDialog;
import io.agora.chatroom.databinding.DialogUserInvitedBinding;
import io.agora.chatroom.manager.RoomManager;
import io.agora.chatroom.manager.RtcManager;
import io.agora.chatroom.model.Action;
import io.agora.chatroom.model.User;
import io.agora.chatroom.service.model.BaseError;
import io.agora.chatroom.service.model.DataCompletableObserver;
import io.agora.chatroom.util.ToastUtile;
import io.reactivex.android.schedulers.AndroidSchedulers;

/**
 * 被邀请菜单
 *
 * @author chenhengfei@agora.io
 */
public class InvitedMenuDialog extends DataBindBaseDialog<DialogUserInvitedBinding> implements View.OnClickListener {
    private static final String TAG = InvitedMenuDialog.class.getSimpleName();

    private static final String TAG_OWNER = "owner";
    private static final String TAG_ACTION = "action";

    private User owner;
    private Action action;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        Window win = getDialog().getWindow();
        WindowManager.LayoutParams params = win.getAttributes();
        params.gravity = Gravity.TOP;
        params.width = ViewGroup.LayoutParams.MATCH_PARENT;
        params.height = ViewGroup.LayoutParams.WRAP_CONTENT;
        win.setAttributes(params);
        return super.onCreateView(inflater, container, savedInstanceState);
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setStyle(STYLE_NORMAL, R.style.Dialog_Top);
    }

    @Override
    public void iniBundle(@NonNull Bundle bundle) {
        owner = (User) bundle.getSerializable(TAG_OWNER);
        action = (Action) bundle.getSerializable(TAG_ACTION);
    }

    @Override
    public int getLayoutId() {
        return R.layout.dialog_user_invited;
    }

    @Override
    public void iniView() {

    }

    @Override
    public void iniListener() {
        mDataBinding.btRefuse.setOnClickListener(this);
        mDataBinding.btAgree.setOnClickListener(this);
    }

    @Override
    public void iniData() {
        mDataBinding.tvText.setText(getString(R.string.room_dialog_invited, owner.getName()));
    }

    public void show(@NonNull FragmentManager manager, User owner, Action action) {
        Bundle intent = new Bundle();
        intent.putSerializable(TAG_OWNER, owner);
        intent.putSerializable(TAG_ACTION, action);
        setArguments(intent);
        super.show(manager, TAG);
    }

    @Override
    public void onClick(View v) {
        if (v.getId() == R.id.btRefuse) {
            doRefuse();
        } else if (v.getId() == R.id.btAgree) {
            doAgree();
        }
    }

    private void doAgree() {
        mDataBinding.btAgree.setEnabled(false);
        RoomManager.Instance(requireContext())
                .agreeInvite(action)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataCompletableObserver(requireContext()) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        mDataBinding.btAgree.setEnabled(true);
                        ToastUtile.toastShort(requireContext(), e.getMessage());
                    }

                    @Override
                    public void handleSuccess() {
                        mDataBinding.btAgree.setEnabled(true);
                        RtcManager.Instance(requireContext()).startAudio();
                        dismiss();
                    }
                });
    }

    private void doRefuse() {
        mDataBinding.btRefuse.setEnabled(false);
        RoomManager.Instance(requireContext())
                .refuseInvite(action)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataCompletableObserver(requireContext()) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        mDataBinding.btRefuse.setEnabled(true);
                        ToastUtile.toastShort(requireContext(), e.getMessage());
                    }

                    @Override
                    public void handleSuccess() {
                        mDataBinding.btRefuse.setEnabled(true);
                        dismiss();
                    }
                });
    }
}
