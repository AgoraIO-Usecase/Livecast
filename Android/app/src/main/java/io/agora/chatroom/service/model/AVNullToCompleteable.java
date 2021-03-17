package io.agora.chatroom.service.model;

import org.jetbrains.annotations.NotNull;

import cn.leancloud.types.AVNull;
import io.reactivex.Completable;
import io.reactivex.functions.Function;

public class AVNullToCompleteable implements Function<AVNull, Completable> {

    public AVNullToCompleteable() {
    }

    @Override
    public Completable apply(@NotNull AVNull respone) throws Exception {
        return Completable.complete();
    }
}
