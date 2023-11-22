import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:permission_handler/permission_handler.dart';

const appId = '06b417f44ed0470e9249534d3a603920';
const appCertificate = '67b6ab170b4b4d7cb78e48f94991f81d';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agora Audio Call',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CallScreen(),
    );
  }
}

class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine rtcEngin;
  int? _remoteUid;
  bool _localUserJoined = false;
  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    await initializeAgora();
  }

  Future<void> initializeAgora() async {
    await [
      Permission.microphone,
      Permission.audio,
    ].request();

    rtcEngin = createAgoraRtcEngine();
    rtcEngin.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting));

    rtcEngin.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${connection.localUid} joined')));
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${connection.localUid} joined')));
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${connection.localUid} offline')));
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
        onError: (err, msg) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$err error')));
        },
        onConnectionStateChanged: (connection, state, reason) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$state State')));
        },
      ),
    );

    await rtcEngin.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await rtcEngin.enableAudio();
    await rtcEngin.enableLocalAudio(true);
    await rtcEngin.startPreview();
  }

  // @override
  // void dispose() async {
  //   await rtcEngin.leaveChannel();
  //   await rtcEngin.release();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agora Audio Call'),
      ),
      body: Center(
          child: Column(
        children: [
          ElevatedButton(
              onPressed: () async {
                await rtcEngin.joinChannel(
                  token:
                      '007eJxTYEhKmj5XtksqPrj33Q/pzKQj3L27DLdV3H3VM//LIUE9rb8KDBZmZsYpppbGZqmGySbGSQZAaGxuaWppkmJiYWmcZj7zfGxqQyAjw6wiQWZGBggE8VkZEpNSSnMYGABw/R+d',
                  channelId: 'abdul',
                  uid: 12,
                  options: const ChannelMediaOptions(
                      autoSubscribeAudio: true,
                      channelProfile:
                          ChannelProfileType.channelProfileLiveBroadcasting,
                      clientRoleType: ClientRoleType.clientRoleBroadcaster),
                );
              },
              child: const Text('Call')),
          ElevatedButton(
              onPressed: () async {
                await rtcEngin.leaveChannel();
              },
              child: const Text('End')),
          Builder(
            builder: (context) {
              if (_localUserJoined) {
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined call')));
                });
                return const Text('Joined');
              } else {
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('Waiting')));
                });
                return const Text('Waiting');
              }
            },
          ),
          Builder(
            builder: (context) {
              if (_remoteUid == null) {
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User is offline')));
                });
                return const Text('Offline');
              } else {
                SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined call')));
                });
                return const Text('joined');
              }
            },
          ),
          const SizedBox(
            height: 200,
          ),
          Stack(
            children: [
              Center(
                child: _remoteVideo(),
              ),
              Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: Center(
                    child: _localUserJoined
                        ? AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: rtcEngin,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          )
                        : const CircularProgressIndicator(),
                  ),
                ),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: rtcEngin,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: const RtcConnection(channelId: 'abdul'),
        ),
      );
    } else {
      return const Text(
        'Please wait for remote user to join',
        textAlign: TextAlign.center,
      );
    }
  }
}

String generateToken({
  required String appID,
  required String appCertificate,
  required int uid,
  required String channelName,
}) {
  return '$appID$appCertificate$uid$channelName';
}

// 06b417f44ed0470e9249534d3a603920
// 67b6ab170b4b4d7cb78e48f94991f81d