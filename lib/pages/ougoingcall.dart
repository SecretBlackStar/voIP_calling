import 'package:caller/pages/call.dart';
import 'package:flutter/material.dart';
import 'package:caller/services/socket.services.dart';
import 'package:caller/services/auth.services.dart';
import 'package:caller/services/contact.services.dart';
import 'package:caller/utils/types.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class OutgoingCallPage extends StatefulWidget {
  final String calleeId;

  const OutgoingCallPage({
    Key? key,
    required this.calleeId,
  }) : super(key: key);

  @override
  State<OutgoingCallPage> createState() => _OutgoingCallPageState();
}

class _OutgoingCallPageState extends State<OutgoingCallPage> {
  final socket = SignallingService.instance.socket;
  String contactName = '';
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String ongoingCallSound = "sounds/calling1.mp3";
  final String calleeNotFoundSound = "sounds/calleeNotFound.wav";
  User? currentUser;
  Timer? timer;

  // WebRTC variables
  RTCPeerConnection? _rtcPeerConnection;
  MediaStream? _localStream;
  List<RTCIceCandidate> rtcIceCadidates = [];
  bool isAudioOn = true;

  @override
  void initState() {
    super.initState();
    _initializeCurrentUser();
    _fetchContactName();
    _playOngoingCallSound();
    _listenForCallAnswered();
    _listenForCalleeNotFound();
    _startCallTimeout();
    _listenForLeaveCall();
    _makeCall();
  }

  void _startCallTimeout() {
    timer = Timer(const Duration(seconds: 30), () {
      _leaveCall(false);
    });
  }

  void _listenForCalleeNotFound() {
    socket?.on("calleeNotFound", (data) {
      _playCalleeNotFoundSound();
    });
  }

  void _listenForLeaveCall() {
    socket?.on("leftCall", (data) {
      _leaveCall(false);
    });
  }

  void _playCalleeNotFoundSound() async {
    await _audioPlayer.setSource(AssetSource(calleeNotFoundSound));
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.resume();
  }

  void _listenForCallAnswered() {
    socket?.on("callAnswered", (data) {
      _audioPlayer.stop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
              appId: data['appId'],
              channelId: data['channelId'],
              token: data['token'],
              callerId: currentUser?.callerId ?? "123",
              calleeId: data['calleeId']),
        ),
      );
    });
  }

  Future<void> _initializeCurrentUser() async {
    currentUser = await authService.getCurrentUser();
  }

  Future<void> _fetchContactName() async {
    var contact = await contactService.getAllContacts().then((contacts) {
      return contacts.firstWhere(
        (contact) => contact.phoneNumber == widget.calleeId,
        orElse: () => Contact(
            name: widget.calleeId,
            phoneNumber: widget.calleeId,
            owner: currentUser!.uid),
      );
    });

    setState(() {
      contactName = contact.name;
    });
  }

  void _playOngoingCallSound() async {
    await _audioPlayer.setSource(AssetSource(ongoingCallSound));
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.resume();

    // Restart the sound when it ends
    _audioPlayer.onPlayerComplete.listen((event) {
      _audioPlayer.setSource(AssetSource(ongoingCallSound));
      _audioPlayer.resume();
    });
  }

  void _leaveCall(bool emit) {
    if (emit) {
      socket?.emit("leaveCall", {
        "to": widget.calleeId,
      });
    }
    _audioPlayer.stop();
    timer?.cancel();
    Navigator.pop(context);
  }

  void _makeCall() async {
    socket!.emit('makeCall', {
      "calleeId": widget.calleeId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Calling...",
                  style: TextStyle(fontSize: 28, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Text(
                  "Dialing: $contactName",
                  style: const TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 40),
                IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red, size: 40),
                  onPressed: () {
                    _leaveCall(true);
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket?.off("callAnswered");
    socket?.off("calleeNotFound");
    _audioPlayer.stop();
    timer?.cancel();
    _rtcPeerConnection?.close();
    super.dispose();
  }
}
