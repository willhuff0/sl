import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/client/state_tracker.dart';
import 'package:sl_editor/client/tracked_property.dart';
import 'package:sl_editor/field_boxer.dart';
import 'package:vector_math/vector_math.dart';

class PropertiesFieldWithLabel extends StatelessWidget {
  final String label;
  final StateTracked tracked;
  final TrackedProperty property;
  final void Function()? onChanged;

  const PropertiesFieldWithLabel({
    super.key,
    required this.label,
    required this.tracked,
    required this.property,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = property.value;
    final field = switch (value) {
      Vector3 _ => Row(
        children: [
          Expanded(
            child: CustomPropertiesField(
              type: double,
              typeName: 'float',
              tracked: tracked,
              property: property,
              boxValue: (c, unboxed) => Vector3(box(double, unboxed) ?? c.x, c.y, c.z),
              unboxValue: (boxed) => unboxFloat32(boxed.x),
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 4.0),
          Expanded(
            child: CustomPropertiesField(
              type: double,
              typeName: 'float',
              tracked: tracked,
              property: property,
              boxValue: (c, unboxed) => Vector3(c.x, box(double, unboxed) ?? c.y, c.z),
              unboxValue: (boxed) => unboxFloat32(boxed.y),
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 4.0),
          Expanded(
            child: CustomPropertiesField(
              type: double,
              typeName: 'float',
              tracked: tracked,
              property: property,
              boxValue: (c, unboxed) => Vector3(c.x, c.y, box(double, unboxed) ?? c.z),
              unboxValue: (boxed) => unboxFloat32(boxed.z),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
      Quaternion _ => QuaternionPropertyField(
        tracked: tracked,
        property: property,
        onChanged: onChanged,
      ),
      dynamic v => CustomPropertiesField(
        type: v.runtimeType,
        tracked: tracked,
        property: property,
        onChanged: onChanged,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 4.0),
        Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyW): DoNothingAndStopPropagationIntent(),
            SingleActivator(LogicalKeyboardKey.keyE): DoNothingAndStopPropagationIntent(),
            SingleActivator(LogicalKeyboardKey.keyR): DoNothingAndStopPropagationIntent(),
          },
          child: field,
        ),
      ],
    );
  }
}

class CustomPropertiesField extends StatefulWidget {
  final Type type;
  final String typeName;
  final StateTracked tracked;
  final TrackedProperty property;
  final dynamic Function(dynamic current, String unboxed)? boxValue;
  final String Function(dynamic boxed)? unboxValue;
  final void Function()? onChanged;

  CustomPropertiesField({
    super.key,
    required this.type,
    String? typeName,
    required this.tracked,
    required this.property,
    this.boxValue,
    this.unboxValue,
    this.onChanged,
  }) : typeName = typeName ?? type.toString();

  @override
  State<CustomPropertiesField> createState() => _CustomPropertiesFieldState();
}

class _CustomPropertiesFieldState extends State<CustomPropertiesField> {
  late final FocusNode _focusNode;
  late final TextEditingController _textEditingController;
  late final StreamSubscription _onChangedSubscription;

  String getValueTypeName() {
    return widget.typeName;
  }

  String getValue() {
    final boxedValue = widget.property.value;
    final value = widget.unboxValue?.call(boxedValue) ?? unbox(boxedValue);
    return value;
  }

  void setValue(String value) {
    final boxedValue = widget.boxValue?.call(widget.property.value, value) ?? box(widget.type, value);
    if (boxedValue == null) return;
    widget.tracked.modifyLocal((builder) {
      widget.property.stage(builder, boxedValue);
    });
    widget.onChanged?.call();
  }

  @override
  void initState() {
    _focusNode = FocusNode()..addListener(_onFocusChanged);
    _textEditingController = TextEditingController(text: getValue());
    _onChangedSubscription = widget.property.onChanged.listen(_onChanged);
    super.initState();
  }

  @override
  void dispose() {
    _onChangedSubscription.cancel();
    _textEditingController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _editingComplete();
    }
  }

  void _onChanged(dynamic value) {
    if (_focusNode.hasFocus) return;
    _textEditingController.text = getValue();
  }

  void _editingComplete() {
    final text = _textEditingController.text.trim();
    if (text.isNotEmpty) {
      setValue(text);
    }
    _textEditingController.text = getValue();
  }

  @override
  Widget build(BuildContext context) {
    return ShadInput(
      controller: _textEditingController,
      focusNode: _focusNode,
      onEditingComplete: _editingComplete,
      placeholder: Text(getValueTypeName()),
    );
  }
}

class QuaternionPropertyField extends StatefulWidget {
  final StateTracked tracked;
  final TrackedProperty property;
  final void Function()? onChanged;

  const QuaternionPropertyField({
    super.key,
    required this.tracked,
    required this.property,
    this.onChanged,
  });

  @override
  State<QuaternionPropertyField> createState() => _QuaternionPropertyFieldState();
}

class _QuaternionPropertyFieldState extends State<QuaternionPropertyField> {
  late final List<FocusNode> _focusNodes;
  late final List<VoidCallback> _focusListeners;
  late final List<TextEditingController> _textEditingControllers;
  late final StreamSubscription _onChangedSubscription;

  Vector3? _current;

  String getValueTypeName() {
    return 'float';
  }

  @override
  void initState() {
    _focusListeners = List.generate(3, (index) {
      return () {
        if (!_focusNodes[index].hasFocus) {
          _editingComplete();
        }
      };
    });
    _focusNodes = List.generate(3, (index) => FocusNode()..addListener(_focusListeners[index]));
    _init();
    _onChangedSubscription = widget.property.onChanged.listen(_onChanged);
    super.initState();
  }

  @override
  void dispose() {
    _onChangedSubscription.cancel();
    for (final textEditingController in _textEditingControllers) {
      textEditingController.dispose();
    }
    for (int i = 0; i < 3; i++) {
      _focusNodes[i].removeListener(_focusListeners[i]);
      _focusNodes[i].dispose();
    }
    super.dispose();
  }

  void _init() {
    final rotationMatrix = (widget.property.value as Quaternion).asRotationMatrix();
    final pitch = degrees(math.atan2(rotationMatrix[5], rotationMatrix[8]));
    final yaw = degrees(-math.asin(rotationMatrix[2]));
    final roll = degrees(math.atan2(rotationMatrix[1], rotationMatrix[0]));
    _textEditingControllers = [
      TextEditingController(text: unboxFloat32(pitch)),
      TextEditingController(text: unboxFloat32(yaw)),
      TextEditingController(text: unboxFloat32(roll)),
    ];
    _current = Vector3(pitch, yaw, roll);
  }

  void _onChanged(dynamic value) {
    if (_focusNodes.any((n) => n.hasFocus)) return;
    value = value as Quaternion;
    final rotationMatrix = value.asRotationMatrix();
    final pitch = degrees(math.atan2(rotationMatrix[5], rotationMatrix[8]));
    final yaw = degrees(-math.asin(rotationMatrix[2]));
    final roll = degrees(math.atan2(rotationMatrix[1], rotationMatrix[0]));
    _textEditingControllers[0].text = unboxFloat32(pitch);
    _textEditingControllers[1].text = unboxFloat32(yaw);
    _textEditingControllers[2].text = unboxFloat32(roll);
    _current = Vector3(pitch, yaw, roll);
  }

  void _editingComplete() {
    final pitch = radians(double.tryParse(_textEditingControllers[1].text) ?? _current?.y ?? 0.0);
    final yaw = radians(double.tryParse(_textEditingControllers[0].text) ?? _current?.x ?? 0.0);
    final roll = radians(double.tryParse(_textEditingControllers[2].text) ?? _current?.z ?? 0.0);
    final value = Quaternion.euler(pitch, yaw, roll);
    widget.tracked.modifyLocal((builder) {
      widget.property.stage(builder, value);
    });
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ShadInput(
            controller: _textEditingControllers[0],
            focusNode: _focusNodes[0],
            onEditingComplete: _editingComplete,
            placeholder: Text(getValueTypeName()),
          ),
        ),
        SizedBox(width: 4.0),
        Expanded(
          child: ShadInput(
            controller: _textEditingControllers[1],
            focusNode: _focusNodes[1],
            onEditingComplete: _editingComplete,
            placeholder: Text(getValueTypeName()),
          ),
        ),
        SizedBox(width: 4.0),
        Expanded(
          child: ShadInput(
            controller: _textEditingControllers[2],
            focusNode: _focusNodes[2],
            onEditingComplete: _editingComplete,
            placeholder: Text(getValueTypeName()),
          ),
        ),
      ],
    );
  }
}
