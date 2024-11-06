import 'package:flutter/material.dart';
import 'package:caller/services/auth.services.dart';
import 'package:caller/services/history.services.dart';

class Call {
  final String id;
  final String? contact;
  final String phoneNumber;
  final String from;
  final String to;
  final DateTime time;

  Call({
    required this.id,
    this.contact,
    required this.phoneNumber,
    required this.from,
    required this.to,
    required this.time,
  });
}

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final Color mainColor = Color(0xFFB05AAD);
  List<Call> callHistory = [];
  String searchTerm = '';
  String? currentUserCallerID;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserCallerID();
    _loadCallHistory();
  }

  Future<void> _loadCurrentUserCallerID() async {
    final user = await authService.getCurrentUser();
    setState(() {
      currentUserCallerID = user?.callerId;
    });
  }

  Future<void> _loadCallHistory() async {
    List<Map<String, dynamic>> historyData = await historyService.getCallHistory();
    setState(() {
      callHistory = historyData.map((data) {
        return Call(
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

  Map<String, List<Call>> groupByDate(List<Call> calls) {
    final Map<String, List<Call>> groupedCalls = {};
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

  @override
  Widget build(BuildContext context) {
    final filteredCalls = callHistory.where((call) {
      return call.contact?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false;
    }).toList();

    final groupedCalls = groupByDate(filteredCalls);

    return Scaffold(
      appBar: AppBar(
        title: Text('History', style: TextStyle(color: mainColor)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: groupedCalls.isNotEmpty
                  ? ListView(
                      children: groupedCalls.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                entry.key,
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            ...entry.value.map((item) {
                              bool isOutgoing = item.from == currentUserCallerID;
                              return ListTile(
                                leading: Icon(Icons.person, size: 40, color: Color(0xFF6C63FF)),
                                title: Text(
                                  isOutgoing ? item.to:item.from,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  item.time.toLocal().toString().split(' ')[1].substring(0, 5),
                                  style: TextStyle(color: Colors.grey),
                                ),
                                trailing: Icon(
                                  isOutgoing ? Icons.call_made : Icons.call_received,
                                  color: isOutgoing ? Colors.green : Colors.blue,
                                ),
                                onTap: () {
                                  // Add call action here if necessary
                                },
                              );
                            }).toList(),
                            Divider(),
                          ],
                        );
                      }).toList(),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
    );
  }
}
