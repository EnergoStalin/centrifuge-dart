import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:centrifuge/centrifuge.dart' as centrifuge;

void main() async {
  final url = 'ws://localhost:8000/connection/websocket?format=protobuf';
  final channel = 'chat:index';

  final onEvent = (dynamic event) {
    print('$channel> $event');
  };

  try {
    final client = centrifuge.createClient(url);

    client.connectStream.listen(onEvent);
    client.errorStream.listen(onEvent);
    client.disconnectStream.listen(onEvent);

    await client.connect();

    final subscription = client.subscribe(channel);

    subscription.publishStream.map((e) => utf8.decode(e.data)).listen(onEvent);
    subscription.joinStream.listen(onEvent);
    subscription.leaveStream.listen(onEvent);

    subscription.subscribeSuccessStream.listen(onEvent);
    subscription.subscribeErrorStream.listen(onEvent);
    subscription.unsubscribeStream.listen(onEvent);

    final handler = _handleUserInput(client, subscription);
//    Future<void>.delayed(Duration(seconds: 1)).then((_) => exit(0));

    await for (List<int> codeUnit in stdin) {
      final message = utf8.decode(codeUnit).trim();
      handler(message);
    }
  } catch (ex) {
    print(ex);
  }
}

Function(String) _handleUserInput(
    centrifuge.Client centrifuge, centrifuge.Subscription subscription) {
  return (String message) async {
    switch (message) {
      case '#subscribe':
        await subscription.subscribe();
        break;
      case '#unsubscribe':
        await subscription.unsubscribe();
        break;
      case '#disconnect':
        await centrifuge.disconnect();
        Future<void>.delayed(Duration(seconds: 1)).then((_) => exit(0));
        break;
      default:
        final output = jsonEncode({'input': message});
        final data = utf8.encode(output);
        await subscription.publish(data);
        break;
    }
    return;
  };
}