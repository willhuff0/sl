import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_shared/sl_shared.dart';

class AvatarsWidget extends StatefulWidget {
  const AvatarsWidget({super.key});

  @override
  State<AvatarsWidget> createState() => _AvatarsWidgetState();
}

class _AvatarsWidgetState extends State<AvatarsWidget> {
  late final StreamSubscription _onClientStatesChangedSubscription;

  @override
  void initState() {
    _onClientStatesChangedSubscription = Client.get().onClientStatesChanged.listen((_) => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _onClientStatesChangedSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: Client.get()
            .getClientStates()
            .values
            .map(
              (clientState) => _AvatarWidget(
                clientState: clientState,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  final ClientState clientState;

  const _AvatarWidget({super.key, required this.clientState});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Color(clientState.color),
          width: 2.0,
        ),
        shape: BoxShape.circle,
      ),
      width: 24.0,
      height: 24.0,
      margin: EdgeInsets.symmetric(horizontal: 2.0),
    );
  }
}
