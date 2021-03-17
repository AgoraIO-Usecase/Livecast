package io.agora.chatroom.base;

import android.view.View;

import androidx.annotation.NonNull;

public interface OnItemClickListener<T> {
    void onItemClick(@NonNull T data, View view, int position, long id);
}
