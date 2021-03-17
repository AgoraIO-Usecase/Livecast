package io.agora.chatroom.adapter;

import android.content.Context;
import android.view.View;

import androidx.annotation.NonNull;

import com.bumptech.glide.Glide;

import io.agora.chatroom.R;
import io.agora.chatroom.base.BaseAdapter;
import io.agora.chatroom.databinding.ItemHandsupListBinding;
import io.agora.chatroom.model.Action;

/**
 * 举手列表
 *
 * @author chenhengfei@agora.io
 */
public class HandsUpListAdapter extends BaseAdapter<Action, HandsUpListAdapter.ViewHolder> {

    public HandsUpListAdapter(Context context) {
        super(context);
    }

    @Override
    public ViewHolder createHolder(View view, int viewType) {
        return new ViewHolder(view);
    }

    @Override
    public int getLayoutId() {
        return R.layout.item_handsup_list;
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Action item = getItemData(position);
        if (item == null) {
            return;
        }

        Glide.with(context)
                .load(item.getMemberId().getUserId().getAvatarRes())
                .placeholder(R.mipmap.default_head)
                .error(R.mipmap.default_head)
                .circleCrop()
                .into(holder.mDataBinding.ivUser);
        holder.mDataBinding.tvName.setText(item.getMemberId().getUserId().getName());
    }

    static class ViewHolder extends BaseAdapter.BaseViewHolder<ItemHandsupListBinding> {

        ViewHolder(View view) {
            super(view);

            mDataBinding.btRefuse.setOnClickListener(this::onItemClick);
            mDataBinding.btAgree.setOnClickListener(this::onItemClick);
        }
    }
}
