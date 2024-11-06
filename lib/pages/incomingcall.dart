import 'package:flutter/material.dart';
import 'package:caller/services/socket.services.dart';
import 'package:caller/services/auth.services.dart';
import 'package:caller/services/contact.services.dart';
import 'package:caller/utils/types.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class IncomingCallPage extends StatefulWidget {
  final String callerId;
  final String channelId;
  final String appId;
  final String token;

  const IncomingCallPage({
    Key? key,
    required this.callerId,
    required this.channelId,
    required this.appId,
    required this.token,
  }) : super(key: key);

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  final socket = SignallingService.instance.socket;
  String contactName = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String incomingRingtone = "sounds/ringtone1.mp3";
  User? currentUser;
  Timer? timer;
  bool callAnswered = false;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
    _playIncomingRingtone();
    _listenForLeaveCall();
    _startCallTimeout();
  }

  void _startCallTimeout() {
    timer = Timer(const Duration(seconds: 30), () {
      _rejectCall(true);
    });
  }

  void _listenForLeaveCall() {
    socket?.on("leftCall", (data) {
      print("Leaving call");
      _rejectCall(false);
    });
  }

  Future<void> _initializeCurrentUser() async {
    currentUser = await authService.getCurrentUser();
    await _fetchContactName();
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

  void _playIncomingRingtone() async {
    await _audioPlayer.setSource(AssetSource(incomingRingtone));
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.resume();

    _audioPlayer.onPlayerComplete.listen((event) {
      _audioPlayer.setSource(AssetSource(incomingRingtone));
      _audioPlayer.resume();
    });
  }

  void _answerCall() {
    _audioPlayer.stop();
    callAnswered = true;
    timer?.cancel();

    socket?.emit("answerCall", {
      "callerId": widget.callerId,
      "channelId": widget.channelId,
      "appId": widget.appId,
      "token": widget.token,
    });
    Navigator.pushNamed(context, "/call", arguments: {
      "callerId": widget.callerId,
      "calleeId": currentUser?.callerId ?? "1123",
      "channelId": widget.channelId,
      "appId": widget.appId,
      "token": widget.token,
    });
  }

  void _rejectCall(bool emit) {
    _audioPlayer.stop();
    if (emit) {
      socket?.emit("leaveCall", {
        "to": widget.callerId,
      });
    }
    timer?.cancel();
    Navigator.pop(context);
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
                Text(
                  "Incoming Call",
                  style: const TextStyle(fontSize: 28, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  "Caller: $contactName",
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.call, color: Colors.green, size: 50),
                      onPressed: _answerCall,
                      tooltip: 'Accept Call',
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.call_end,
                          color: Colors.red, size: 50),
                      onPressed: () {
                        _rejectCall(true);
                      },
                      tooltip: 'Reject Call',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    timer?.cancel();
    socket?.off("leftCall");
    super.dispose();
  }
}
