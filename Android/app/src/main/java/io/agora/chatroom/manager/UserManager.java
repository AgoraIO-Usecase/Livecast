package io.agora.chatroom.manager;

import android.content.Context;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.lifecycle.MutableLiveData;
import androidx.preference.PreferenceManager;

import com.google.gson.Gson;

import java.util.Random;

import io.agora.chatroom.data.DataRepositroy;
import io.agora.chatroom.model.User;
import io.agora.chatroom.service.model.BaseError;
import io.agora.chatroom.service.model.DataObserver;

public final class UserManager {
    private static final String TAG = UserManager.class.getSimpleName();

    private static final String TAG_USER = "user";

    private Context mContext;
    private volatile static UserManager instance;

    private MutableLiveData<User> mUserLiveData = new MutableLiveData<>();

    private UserManager(Context context) {
        mContext = context.getApplicationContext();
    }

    public static UserManager Instance(Context context) {
        if (instance == null) {
            synchronized (UserManager.class) {
                if (instance == null)
                    instance = new UserManager(context);
            }
        }
        return instance;
    }

    public MutableLiveData<User> getUserLiveData() {
        return mUserLiveData;
    }

    public void loginIn() {
        if (UserManager.Instance(mContext).getUserLiveData().getValue() == null) {
            String userValue = PreferenceManager.getDefaultSharedPreferences(mContext)
                    .getString(TAG_USER, null);
            User mUser = null;
            if (TextUtils.isEmpty(userValue)) {
                mUser = new User();
                mUser.setName(radomName());
                mUser.setAvatar(radomAvatar());
            } else {
                mUser = new Gson().fromJson(userValue, User.class);
            }

            DataRepositroy.Instance(mContext)
                    .login(mUser)
                    .subscribe(new DataObserver<User>(mContext) {
                        @Override
                        public void handleError(@NonNull BaseError e) {
                            Log.e(TAG, "loginIn error: " + e.getMessage());
                        }

                        @Override
                        public void handleSuccess(@NonNull User user) {
                            Log.i(TAG, "loginIn " + user);
                            onLoginIn(user);
                        }
                    });
        }
    }

    public void onLoginIn(User mUser) {
        mUserLiveData.postValue(mUser);

        PreferenceManager.getDefaultSharedPreferences(mContext)
                .edit()
                .putString(TAG_USER, new Gson().toJson(mUser))
                .apply();
    }

    public void onLoginOut(User mUser) {
        mUserLiveData.postValue(null);

        PreferenceManager.getDefaultSharedPreferences(mContext)
                .edit()
                .remove(TAG_USER)
                .apply();
    }

    public void update(User mUser) {
        mUserLiveData.postValue(mUser);

        PreferenceManager.getDefaultSharedPreferences(mContext)
                .edit()
                .putString(TAG_USER, new Gson().toJson(mUser))
                .apply();
    }

    public static String radomAvatar() {
        return String.valueOf(new Random().nextInt(13) + 1);
    }

    public static String radomName() {
        return "User " + String.valueOf(new Random().nextInt(999999));
    }
}
