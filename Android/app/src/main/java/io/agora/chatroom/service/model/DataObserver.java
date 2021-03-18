package io.agora.chatroom.service.model;

import android.content.Context;

import androidx.annotation.NonNull;

import org.jetbrains.annotations.NotNull;

import io.reactivex.Observer;
import io.reactivex.disposables.Disposable;

/**
 * 网络回调基类，主要负责异常封装，以及数据序列化。
 *
 * @author Aslan
 * @date 2019/9/23
 */
public abstract class DataObserver<T> implements Observer<T> {

    private Context context;

    public DataObserver(Context context) {
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

    }

    @Override
    public void onSubscribe(@NotNull Disposable d) {

    }

    @Override
    public void onNext(@NonNull T t) {
        handleSuccess(t);
    }

    public abstract void handleError(@NonNull BaseError e);

    public abstract void handleSuccess(@NonNull T t);
}