import 'package:flutter/material.dart';
import 'package:caller/services/auth.services.dart';
import 'package:caller/services/history.services.dart';

class CallHistoryItem {
  final String id;
  final String? contact;
  final String phoneNumber;
  final String from;
  final String to;
  final DateTime time;

  CallHistoryItem({
    required this.id,
    this.contact,
    required this.phoneNumber,
    required this.from,
    required this.to,
    required this.time,
  });
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int airtimeInSeconds = 0;
  List<CallHistoryItem> callHistory = [];
  final Color mainColor = Color(0xFF6C63FF);
  String? currentUserCallerID;

  @override
  void initState() {
    super.initState();
    fetchAirtime();
    fetchCurrentUserCallerID();
    fetchCallHistory();
  }

  Future<void> fetchAirtime() async {
    final user = await authService.getCurrentUser();
    setState(() {
      airtimeInSeconds = user?.airtime ?? 0;
    });
  }

  Future<void> fetchCurrentUserCallerID() async {
    final user = await authService.getCurrentUser();
    setState(() {
      currentUserCallerID = user?.callerId;
    });
  }

  Future<void> fetchCallHistory() async {
    List<Map<String, dynamic>> historyData = await historyService.getCallHistory();
    setState(() {
      callHistory = historyData.map((data) {
        return CallHistoryItem(
          id: data['id'],
          contact: data['from'],
          phoneNumber: data['to'],
          from: data['from'],
          to: data['to'],
          time: DateTime.parse(data['timestamp']),
        );
      }).toList();
    });
  }

  Map<String, List<CallHistoryItem>> groupByDate(List<CallHistoryItem> calls) {
    final Map<String, List<CallHistoryItem>> groupedCalls = {};
    final DateTime today = DateTime.now();
    final DateTime yesterday = today.subtract(Duration(days: 1));

    String getDateTitle(DateTime date) {
      if (date.year == today.year && date.month == today.month && date.day == today.day) {
        return 'Today';
      } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
        return 'Yesterday';
      } else if (date.month == today.month && date.year == today.year) {
        return '${date.day} ${_getMonthName(date.month)}';
      } else {
        return '${_getMonthName(date.month)} ${date.year}';
      }
    }

    for (var call in calls) {
      String title = getDateTitle(call.time);
      if (!groupedCalls.containsKey(title)) {
        groupedCalls[title] = [];
      }
      groupedCalls[title]!.add(call);
    }
    return groupedCalls;
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  String formatAirtime(int seconds) {
    final hours = (seconds / 3600).floor();
    final minutes = ((seconds % 3600) / 60).floor();
    final secs = seconds % 60;
    return '${hours}h ${minutes}m ${secs}s';
  }

  @override
  Widget build(BuildContext context) {
    final formattedAirtime = formatAirtime(airtimeInSeconds);
    final groupedCalls = groupByDate(callHistory);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Airtime Section
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedAirtime,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Current Airtime',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/allairtimes");
                      },
                      backgroundColor: mainColor,
                      child: const Icon(Icons.shopping_cart, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Recent Calls Section
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              // Call History List
              Expanded(
                child: callHistory.isNotEmpty
                    ? ListView(
                        children: groupedCalls.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              ...entry.value.map((item) {
                                bool isOutgoing =
                                    item.from == currentUserCallerID;
                                return ListTile(
                                  leading: const Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Color(0xFF6C63FF),
                                  ),
                                  title: Text(
                                    isOutgoing ? item.to:item.from,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.time.toLocal().toString().split(' ')[1].substring(0, 5),
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                  trailing: Icon(
                                    isOutgoing
                                        ? Icons.call_made
                                        : Icons.call_received,
                                    color: isOutgoing
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                );
                              }).toList(),
                              const Divider(),
                            ],
                          );
                        }).toList(),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.history, size: 60, color: Colors.grey),
                            SizedBox(height: 10),
                            Text('No recent calls', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
