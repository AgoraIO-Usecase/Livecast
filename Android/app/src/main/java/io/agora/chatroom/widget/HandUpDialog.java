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
import io.agora.chatroom.adapter.HandsUpListAdapter;
import io.agora.chatroom.base.DataBindBaseDialog;
import io.agora.chatroom.base.OnItemClickListener;
import io.agora.chatroom.databinding.DialogHandUpBinding;
import io.agora.chatroom.manager.RoomManager;
import io.agora.chatroom.model.Action;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.data.BaseError;
import io.agora.chatroom.data.DataCompletableObserver;
import io.agora.chatroom.util.ToastUtile;
import io.reactivex.android.schedulers.AndroidSchedulers;

/**
 * 举手列表
 *
 * @author chenhengfei@agora.io
 */
public class HandUpDialog extends DataBindBaseDialog<DialogHandUpBinding> implements OnItemClickListener<Action> {
    private static final String TAG = HandUpDialog.class.getSimpleName();

    private HandsUpListAdapter mAdapter;

    private static final String TAG_ROOM = "room";

    private Room room;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        Window win = getDialog().getWindow();
        WindowManager.LayoutParams params = win.getAttributes();
        params.gravity = Gravity.BOTTOM;
        params.width = ViewGroup.LayoutParams.MATCH_PARENT;
        params.height = ViewGroup.LayoutParams.WRAP_CONTENT;
        win.setAttributes(params);
        return super.onCreateView(inflater, container, savedInstanceState);
    }

    @Override
    public void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setStyle(STYLE_NORMAL, R.style.Dialog_Bottom);
    }

    @Override
    public void iniBundle(@NonNull Bundle bundle) {
        room = (Room) bundle.getSerializable(TAG_ROOM);
    }

    @Override
    public int getLayoutId() {
        return R.layout.dialog_hand_up;
    }

    @Override
    public void iniView() {

    }

    @Override
    public void iniListener() {

    }

    @Override
    public void iniData() {
        mAdapter = new HandsUpListAdapter(requireContext());
        mAdapter.setOnItemClickListener(this);
        mDataBinding.rvList.setAdapter(mAdapter);

        loadData();
    }

    public void loadData() {
        mAdapter.setDatas(RoomManager.Instance(requireContext()).getHandUpList());
    }

    public void show(@NonNull FragmentManager manager, @NonNull Room room) {
        Bundle intent = new Bundle();
        intent.putSerializable(TAG_ROOM, room);
        setArguments(intent);
        super.show(manager, TAG);
    }

    @Override
    public void onItemClick(@NonNull Action data, View view, int position, long id) {
        if (view.getId() == R.id.btRefuse) {
            clickRefuse(position, data);
        } else if (view.getId() == R.id.btAgree) {
            clickAgree(position, data);
        }
    }

    private void clickRefuse(int index, Action data) {
        RoomManager.Instance(requireContext())
                .refuseHandsUp(data)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataCompletableObserver(requireContext()) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        ToastUtile.toastShort(requireContext(), e.getMessage());
                    }

                    @Override
                    public void handleSuccess() {
                        mAdapter.deleteItem(index);
                    }
                });
    }

    private void clickAgree(int index, Action data) {
        RoomManager.Instance(requireContext())
                .agreeHandsUp(data)
                .observeOn(AndroidSchedulers.mainThread())
                .compose(mLifecycleProvider.bindToLifecycle())
                .subscribe(new DataCompletableObserver(requireContext()) {
                    @Override
                    public void handleError(@NonNull BaseError e) {
                        ToastUtile.toastShort(requireContext(), e.getMessage());
                    }

                    @Override
                    public void handleSuccess() {
                        mAdapter.deleteItem(index);
                    }
                });
    }
}
