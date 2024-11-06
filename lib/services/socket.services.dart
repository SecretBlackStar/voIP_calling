import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart';

class SignallingService {
  Socket? socket;
  SignallingService._();
  static final instance = SignallingService._();

  void init({required String websocketUrl, required String selfCallerID}) {
    socket = io(websocketUrl, {
      "transports": ['websocket'],
      "query": {"callerId": selfCallerID},
      "timeout": 300000, // Set timeout to 30 seconds (30000 milliseconds)
      "connectTimeout": 300000, // Optional: also set connectTimeout
    });

    socket!.onConnect((data) {
      log("Socket connected !!");
    });

    socket!.onConnectError((data) {
      log(data.toString());
      log("Connect Error $data");
    });

    socket!.connect();
  }
}
