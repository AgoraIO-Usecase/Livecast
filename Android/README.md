# 前提条件
开始前，请确保你的开发环境满足如下条件：
- Android Studio 4.0.0 或以上版本。
- Android 4.1 或以上版本的设备。部分模拟机可能无法支持本项目的全部功能，所以推荐使用真机。

# 操作步骤
#### 获取示例项目
前往 GitHub 下载或克隆 [InteractivePodcast](https://github.com/AgoraIO-Usecase/InteractivePodcast) 示例项目。

#### 注册Agora
前往 [Agora官网](https://console.agora.io/) 注册项目，生产appId，然后替换工程**data**中 **strings_config.xml** 中 **app_id**。

#### 注册Leanclould
前往 [Leancloud官网](https://www.leancloud.cn/) 注册项目，生产 appId、appKey、server_url，然后替换工程**data**中  **strings_config.xml** 中 **leancloud_app_id**、**leancloud_app_key**、**leancloud_server_url**。

#### 注册Firebase
前往 [Firebase官网](https://firebase.google.com/) 注册项目，生产文件 **google-services.json**，然后放到app工程下面。

#### 运行示例项目
1. 开启 Android 设备的开发者选项，通过 USB 连接线将 Android 设备接入电脑。
2. 在 Android Studio 中，点击 Sync Project with Gradle Files 按钮，同步项目。
3. 在 Android Studio 左下角侧边栏中，点击 Build Variants 选择对应的平台。
4. 点击 Run app 按钮。运行一段时间后，应用就安装到 Android 设备上了。
5. 打开应用，即可使用。

![房间列表](./pic/1.png)
![房间](./pic/2.png)
![最小化](./pic/3.png)