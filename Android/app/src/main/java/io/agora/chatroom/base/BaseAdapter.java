package io.agora.chatroom.base;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.Size;
import androidx.databinding.DataBindingUtil;
import androidx.databinding.ViewDataBinding;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.List;

public abstract class BaseAdapter<T, VH extends BaseAdapter.BaseViewHolder> extends RecyclerView.Adapter<VH> {

    protected final Context context;
    private List<T> datas;

    private OnItemClickListener<T> mlistener;

    public BaseAdapter(Context context) {
        this.context = context;
        this.datas = new ArrayList<>();

        if (context instanceof OnItemClickListener) {
            this.mlistener = (OnItemClickListener<T>) context;
        }
    }

    public BaseAdapter(Context context, List<T> datas) {
        this.context = context;
        this.datas = datas;

        if (context instanceof OnItemClickListener) {
            this.mlistener = (OnItemClickListener<T>) context;
        }
    }

    public void setOnItemClickListener(OnItemClickListener<T> mlistener) {
        this.mlistener = mlistener;
    }

    public abstract VH createHolder(View view, int viewType);

    public abstract int getLayoutId();

    @NonNull
    @Override
    public VH onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(context).inflate(getLayoutId(), parent, false);
        VH mHolder = createHolder(view, viewType);
        mHolder.mlistener = new BaseViewHolder.OnTempItemClickListener() {
            @Override
            public void onItemClick(View view, int position, long id) {
                if (BaseAdapter.this.mlistener != null) {
                    BaseAdapter.this.mlistener.onItemClick(getItemData(position), view, position, id);
                }
            }
        };
        return mHolder;
    }

    @Override
    public void onBindViewHolder(@NonNull VH holder, int position) {

    }

    public boolean contains(@NonNull T data) {
        if (datas == null) {
            return false;
        }
        return datas.contains(data);
    }

    public int indexOf(@NonNull T data) {
        if (datas == null) {
            return -1;
        }
        return datas.indexOf(data);
    }

    public void setDatas(@NonNull List<T> datas) {
        this.datas = datas;
        notifyDataSetChanged();
    }

    public void addItem(@NonNull T data) {
        if (datas == null) {
            datas = new ArrayList<>();
        }

        int index = datas.indexOf(data);
        if (index < 0) {
            datas.add(data);
            notifyItemInserted(datas.size() - 1);
        } else {
            datas.set(index, data);
            notifyItemChanged(index);
        }
    }

    public void addItem(@NonNull T data, int index) {
        if (datas == null) {
            datas = new ArrayList<>();
        }

        int indexTemp = datas.indexOf(data);
        if (indexTemp < 0) {
            datas.add(index, data);
            notifyItemRangeChanged(index, datas.size() - index);
        } else {
            datas.set(index, data);
            notifyItemChanged(index);
        }
    }

    public void update(int index, @NonNull T data) {
        if (datas == null) {
            datas = new ArrayList<>();
        }

        datas.set(index, data);
        notifyItemChanged(index);
    }

    public void clear() {
        if (datas == null || datas.isEmpty()) {
            return;
        }

        datas.clear();
        notifyDataSetChanged();
    }

    public void deleteItem(@Size(min = 0) int posion) {
        if (datas == null || datas.isEmpty()) {
            return;
        }

        if (0 <= posion && posion < datas.size()) {
            datas.remove(posion);
            notifyItemRemoved(posion);
        }
    }

    public void deleteItem(@NonNull T data) {
        if (datas == null || datas.isEmpty()) {
            return;
        }

        int index = datas.indexOf(data);
        if (0 <= index && index < datas.size()) {
            datas.remove(data);
            notifyItemRemoved(index);
        }
    }

    @Override
    public int getItemCount() {
        if (datas == null) return 0;
        return datas.size();
    }

    @Nullable
    public T getItemData(int position) {
        if (datas == null) {
            return null;
        }

        if (position < 0 || datas.size() <= position) {
            return null;
        }

        return datas.get(position);
    }

    public static abstract class BaseViewHolder<V extends ViewDataBinding> extends RecyclerView.ViewHolder {
        public OnTempItemClickListener mlistener;
        public V mDataBinding;

        public BaseViewHolder(View view) {
            super(view);
            mDataBinding = DataBindingUtil.bind(view);

            view.setOnClickListener(this::onItemClick);
        }

        protected void onItemClick(View view) {
            if (mlistener != null) {
                final int position = getAdapterPosition();
                mlistener.onItemClick(view, position, getItemId());
            }
        }

        interface OnTempItemClickListener {
            void onItemClick(View view, int position, long id);
        }
    }
}
