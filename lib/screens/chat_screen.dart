import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flash_chat/constants.dart';

final _firestore = FirebaseFirestore.instance;
User _loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _messageTextController = TextEditingController();

  String _messageText;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    try {
      final user = _auth.currentUser;

      print('user $user');

      if (user != null) {
        setState(() {
          _loggedInUser = user;
        });
      }
      print(_loggedInUser.email);
    } catch (e) {
      print(e);
    }
  }

  // void _getMessages() async {
  //   try {
  //     final messages = await _firestore.collection('messages').get();
  //
  //     messages.docs.forEach((element) {
  //       print('element ${element.data()}');
  //     });
  //   } catch (e) {
  //     print(e);
  //   }
  // }

  // void _getMessagesStream() async {
  //   //firestore snapshots return a Stream(observable) of QuerySnapshot instead of a Future
  //   await for (var snapshot in _firestore.collection('messages').snapshots()) {
  //     for (var message in snapshot.docs) {
  //       print(message.data());
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        // title: Text('⚡️Chat'),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'logo',
              child: Container(
                child: Image.asset('images/logo.png'),
                height: 25.0,
              ),
            ),
            Text('️Chat'),
          ],
        ),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _messageTextController,
                      onChanged: (value) {
                        _messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // if (_loggedInUser != null) {
                      try {
                        print('_messageText $_messageText');
                        print('_loggedInUser.email ${_loggedInUser}');

                        _firestore.collection('messages').add({
                          'text': _messageText,
                          'sender': _loggedInUser.email,
                        });

                        _messageTextController.clear();
                      } catch (e) {
                        print(e);
                      }
                      // }
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Set the StreamBuilder type to the Stream returned by firestore.snapshots() method,
    // which is a Stream of QuerySnapshot
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      // snapshot parameter down below is an async snapshot
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blueAccent,
            ),
          );
        }

        List<MessageBubble> messageBubbles = [];
        // reverse the order of list display to last-in-display-first
        final messages = snapshot.data.docs.reversed;

        for (var message in messages) {
          final messageText = message.data()['text'];
          final messageSender = message.data()['sender'];
          final currentUser = _loggedInUser.email;

          final messageBubble = MessageBubble(
            text: messageText,
            sender: messageSender,
            isMe: (currentUser == messageSender),
          );
          messageBubbles.add(messageBubble);
        }

        // Tip: Use Expanded to use only available space on the screen and not stretch beyond it
        return Expanded(
          child: ListView(
            reverse: true, // show the bottom of the list view showing
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble(
      {@required this.text, @required this.sender, @required this.isMe});

  final String text;
  final String sender;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            sender,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12.0,
            ),
          ),
          Material(
            borderRadius: BorderRadius.only(
              topLeft: isMe ? Radius.circular(25.0) : Radius.circular(0),
              topRight: isMe ? Radius.circular(0) : Radius.circular(25.0),
              bottomLeft: Radius.circular(25.0),
              bottomRight: Radius.circular(25.0),
            ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                '$text',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
