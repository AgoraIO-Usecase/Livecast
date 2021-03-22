package io.agora.chatroom.adapter;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.List;

import io.agora.chatroom.R;
import io.agora.chatroom.base.BaseAdapter;
import io.agora.chatroom.data.DataRepositroy;
import io.agora.chatroom.databinding.ItemRoomsBinding;
import io.agora.chatroom.model.Member;
import io.agora.chatroom.model.Room;
import io.agora.chatroom.data.BaseError;
import io.agora.chatroom.data.DataMaybeObserver;
import io.agora.chatroom.data.DataObserver;
import io.reactivex.android.schedulers.AndroidSchedulers;
import io.reactivex.schedulers.Schedulers;

/**
 * 房间列表
 *
 * @author chenhengfei@agora.io
 */
public class RoomListAdapter extends BaseAdapter<Room, RoomListAdapter.ViewHolder> {

    public RoomListAdapter(Context context) {
        super(context);
    }

    @Override
    public int getLayoutId() {
        return R.layout.item_rooms;
    }

    @Override
    public RoomListAdapter.ViewHolder createHolder(View view, int viewType) {
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull RoomListAdapter.ViewHolder holder, int position) {
        Room item = getItemData(position);
        if (item == null) {
            return;
        }

        holder.mDataBinding.tvName.setText(item.getChannelName());

        List<Member> speakers = item.getSpeakers();
        holder.mDataBinding.members.setMemebrs(speakers);
        holder.mDataBinding.tvNumbers.setText(String.format("%s/%s", item.getMembers(), speakers == null ? 0 : speakers.size()));

        DataRepositroy.Instance(context)
                .getRoomListInfo(item)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(new DataObserver<Room>(context) {
                    @Override
                    public void handleError(@NonNull BaseError e) {

                    }

                    @Override
                    public void handleSuccess(@NonNull Room room) {
                        List<Member> speakers = room.getSpeakers();
                        holder.mDataBinding.tvNumbers.setText(String.format("%s/%s", room.getMembers(), speakers == null ? 0 : speakers.size()));
                    }
                });

        DataRepositroy.Instance(context)
                .getRoomListInfo2(item)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe(new DataMaybeObserver<Room>(context) {
                    @Override
                    public void handleError(@NonNull BaseError e) {

                    }

                    @Override
                    public void handleSuccess(@Nullable Room room) {
                        if (room != null) {
                            holder.mDataBinding.members.setMemebrs(room.getSpeakers());
                        }
                    }
                });
    }

    class ViewHolder extends BaseAdapter.BaseViewHolder<ItemRoomsBinding> {

        public ViewHolder(View view) {
            super(view);
        }
    }
}
