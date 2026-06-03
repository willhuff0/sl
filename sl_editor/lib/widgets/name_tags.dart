import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/client.dart';
import 'package:sl_engine/editor/avatars.dart';
import 'package:sl_engine/editor/sl_editor.dart';
import 'package:vector_math/vector_math.dart';

final _nameTagMinDistance = 0.75;
final _nameTagFadeStart = 2.0;
final _nameTagOffset = Vector3(0.0, 0.6, 0.0);
final _nameTagFontHeight = 0.125;
final _nameTagBorderRadius = 0.0375;
final _nameTagPadding = Vector2(0.03, 0.0);

class NameTagsWidget extends StatefulWidget {
  final Widget? child;

  const NameTagsWidget({super.key, this.child});

  @override
  State<NameTagsWidget> createState() => NameTagsWidgetState();
}

class NameTagsWidgetState extends State<NameTagsWidget> {
  late final StreamSubscription _onAvatarsMovedSubscription;

  var _nameTagPoints = <int, Vector3>{};

  @override
  void initState() {
    _onAvatarsMovedSubscription = Avatars.onAvatarsMoved.listen(_onAvatarsMoved);
    super.initState();
  }

  @override
  void dispose() {
    _onAvatarsMovedSubscription.cancel();
    super.dispose();
  }

  void _onAvatarsMoved(_) {
    setState(() {
      _nameTagPoints = Avatars.getCurrentRemoteAvatarPositions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientStates = Client.get().getClientStates();

    final cameraState = SLEditor.camera?.getState();
    if (cameraState == null) return Container();

    final viewPosition = SLEditor.camera?.getViewPosition();
    if (viewPosition == null) return Container();

    final cameraPosition = viewPosition.$1;
    final Matrix4 viewProjMat = cameraState.$3 * cameraState.$2;

    final screenHeight = MediaQuery.of(context).size.height;
    final fov = radians(viewPosition.$3);
    final fovScaler = 2.0 * tan(fov / 2.0);
    final fontHeightFactor = (_nameTagFontHeight * screenHeight) / fovScaler;
    final borderRadiusFactor = (_nameTagBorderRadius * screenHeight) / fovScaler;
    final paddingFactor = (_nameTagPadding * screenHeight) / fovScaler;

    final nameTags = _nameTagPoints.entries
        .map((entry) {
          final clientId = entry.key;
          final position = entry.value + _nameTagOffset;

          final name = clientStates[clientId]?.name;
          if (name == null) return null;

          final clipPoint = viewProjMat.transform(Vector4(position.x, position.y, position.z, 1.0));
          final ndcPoint = clipPoint.xyz / clipPoint.w;

          if (ndcPoint.z < -1.0 || ndcPoint.z > 1.0) return null;

          final cameraDistance = position.distanceTo(cameraPosition);
          if (cameraDistance < _nameTagMinDistance) return null;

          final opacity = clampDouble(
            (cameraDistance - _nameTagMinDistance) / (_nameTagFadeStart - _nameTagMinDistance),
            0.0,
            1.0,
          );

          final fontSize = fontHeightFactor / cameraDistance;
          final borderRadius = borderRadiusFactor / cameraDistance;
          final padding = paddingFactor / cameraDistance;

          return (
            Vector2((ndcPoint.x + 1.0) * 0.5, (ndcPoint.y + 1.0) * 0.5),
            FractionalTranslation(
              translation: Offset(-0.5, 0.0),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: padding.x, vertical: padding.y),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    color: ShadTheme.of(context).colorScheme.border.withValues(alpha: 0.1),
                    border: BoxBorder.all(
                      color: ShadTheme.of(context).colorScheme.border.withValues(alpha: 0.1),
                      width: 2.0,
                    ),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(fontSize: fontSize),
                  ),
                ),
              ),
            ),
          );
        })
        .nonNulls
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: nameTags.map((nameTag) {
            return Positioned(
              left: nameTag.$1.x * constraints.maxWidth,
              bottom: nameTag.$1.y * constraints.maxHeight,
              child: nameTag.$2,
            );
          }).toList(),
        );
      },
    );
  }
}
