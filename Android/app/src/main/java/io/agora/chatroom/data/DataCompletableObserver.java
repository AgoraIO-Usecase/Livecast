package io.agora.chatroom.data;

import android.content.Context;

import androidx.annotation.NonNull;

import org.jetbrains.annotations.NotNull;

import io.reactivex.CompletableObserver;
import io.reactivex.disposables.Disposable;

/**
 * 网络回调基类，主要负责异常封装，以及数据序列化。
 *
 * @author Aslan
 * @date 2019/9/23
 */
public abstract class DataCompletableObserver implements CompletableObserver {

    private Context context;

    public DataCompletableObserver(Context context) {
        this.context = context;
    }

    @Override
    public void onError(@NotNull Throwable e) {
        if (e instanceof BaseError) {
            handleError((BaseError) e);
        } else {
            handleError(new BaseError(-100, e.getMessage()));
        }
    }

    @Override
    public void onComplete() {
        handleSuccess();
    }

    @Override
    public void onSubscribe(@NotNull Disposable d) {

    }

    public abstract void handleError(@NonNull BaseError e);

    public abstract void handleSuccess();
}