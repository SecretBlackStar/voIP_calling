import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:caller/services/contact.services.dart';
import 'package:caller/services/auth.services.dart';
import 'package:caller/services/history.services.dart';
import 'package:caller/utils/types.dart';
import 'package:caller/services/socket.services.dart';

class CallScreen extends StatefulWidget {
  final String appId;
  final String channelId;
  final String token;
  final String callerId;
  final String calleeId;

  const CallScreen({
    Key? key,
    required this.appId,
    required this.channelId,
    required this.token,
    required this.callerId,
    required this.calleeId,
  }) : super(key: key);

  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late RtcEngine _engine;
  bool _localUserJoined = false;
  final socket = SignallingService.instance.socket;
  int? _remoteUid;
  late Timer _timer;
  Duration _callDuration = Duration.zero;
  String contactName = '';
  User? currentUser;

  @override
  void initState() {
    super.initState();
    _initializeAgora();
    _initializeCurrentUser();
    _startCallTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    _addCallHistory().then((_) {
      _endCall(false);
      super.dispose();
    });
  }

  Future<void> _initializeCurrentUser() async {
    currentUser = await authService.getCurrentUser();
    _fetchContactName();
  }

  Future<void> _fetchContactName() async {
    var contact = await contactService.getAllContacts().then((contacts) {
      return contacts.firstWhere(
        (contact) => contact.phoneNumber == widget.callerId,
        orElse: () => Contact(
            name: widget.callerId,
            phoneNumber: widget.callerId,
            owner: currentUser!.uid),
      );
    });

    setState(() {
      contactName = contact.name;
    });
  }

  Future<void> _addCallHistory() async {
    await historyService.createCallHistory(
      widget.callerId,
      widget.calleeId,
      _callDuration.inSeconds,
    );
  }

  void _startCallTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration += Duration(seconds: 1);
      });

      if (currentUser != null && widget.callerId == currentUser!.callerId) {
        if (_callDuration.inSeconds % 5 == 0) {
          authService.updateUser({'airtime': currentUser!.airtime - 5});
        }
      }
    });
  }

  void _listenForLeaveCall() {
    socket?.on("leftCall", (data) {
      _endCall(false);
    });
  }

  Future<void> _initializeAgora() async {
    print(
        'App ID: ${widget.appId}, Token: ${widget.token}, Channel ID: ${widget.channelId}');
    _engine = await createAgoraRtcEngine();

    await _engine.initialize(RtcEngineContext(
      appId: widget.appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelId,
      options: ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0, // 0 for dynamic UID generation
    );

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          setState(() {
            _remoteUid = null;
          });
        },
      ),
    );
  }

  void _endCall(bool emit) async {
    if (emit) {
      socket?.emit("leaveCall", {
        "to": widget.calleeId,
      });
    }
    await _engine.leaveChannel();
    await _engine.release();
    Navigator.pushNamed(context, "/home");
  }

  String _formatCallDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(duration.inMinutes)}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person, size: 100, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  contactName.isEmpty ? widget.callerId : contactName,
                  style: TextStyle(color: Colors.white, fontSize: 22),
                ),
                const SizedBox(height: 20),
                Text(
                  "In Call",
                  style: TextStyle(color: Colors.white, fontSize: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  _formatCallDuration(_callDuration),
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 40),
                IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red, size: 50),
                  onPressed: () {
                    _endCall(true);
                  },
                  tooltip: 'End Call',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
