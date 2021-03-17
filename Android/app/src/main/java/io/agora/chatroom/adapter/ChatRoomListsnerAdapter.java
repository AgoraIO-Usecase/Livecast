package io.agora.chatroom.adapter;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;

import com.bumptech.glide.Glide;

import io.agora.chatroom.R;
import io.agora.chatroom.base.BaseAdapter;
import io.agora.chatroom.databinding.ItemRoomListenerBinding;
import io.agora.chatroom.model.Member;

/**
 * 房间上坐用户
 *
 * @author chenhengfei@agora.io
 */
public class ChatRoomListsnerAdapter extends BaseAdapter<Member, ChatRoomListsnerAdapter.ViewHolder> {

    public ChatRoomListsnerAdapter(Context context) {
        super(context);
    }

    @Override
    public ViewHolder createHolder(View view, int viewType) {
        return new ViewHolder(view);
    }

    @Override
    public int getLayoutId() {
        return R.layout.item_room_listener;
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Member item = getItemData(position);
        if (item == null) {
            return;
        }

        Glide.with(context)
                .load(item.getUserId().getAvatarRes())
                .placeholder(R.mipmap.default_head)
                .error(R.mipmap.default_head)
                .circleCrop()
                .into(holder.mDataBinding.ivUser);
        holder.mDataBinding.tvName.setText(item.getUserId().getName());
    }

    class ViewHolder extends BaseAdapter.BaseViewHolder<ItemRoomListenerBinding> {

        public ViewHolder(View view) {
            super(view);
        }
    }
}
