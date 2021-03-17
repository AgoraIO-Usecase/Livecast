package io.agora.chatroom.adapter;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;

import io.agora.chatroom.R;
import io.agora.chatroom.base.BaseAdapter;
import io.agora.chatroom.databinding.ItemRoomSeatUserBinding;
import io.agora.chatroom.model.Member;

/**
 * 房间上坐用户
 *
 * @author chenhengfei@agora.io
 */
public class ChatRoomSeatUserAdapter extends BaseAdapter<Member, ChatRoomSeatUserAdapter.ViewHolder> {

    public ChatRoomSeatUserAdapter(Context context) {
        super(context);
    }

    @Override
    public ViewHolder createHolder(View view, int viewType) {
        return new ViewHolder(view);
    }

    @Override
    public int getLayoutId() {
        return R.layout.item_room_seat_user;
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Member item = getItemData(position);
        if (item == null) {
            return;
        }
        holder.mDataBinding.viewUser.setUserInfo(item);
    }

    class ViewHolder extends BaseAdapter.BaseViewHolder<ItemRoomSeatUserBinding> {

        public ViewHolder(View view) {
            super(view);
        }
    }
}
