import 'dart:async';
import 'dart:math' as math;

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

  const PropertiesFieldWithLabel({
    super.key,
    required this.label,
    required this.tracked,
    required this.property,
  });

  @override
  Widget build(BuildContext context) {
    final value = property.get();
    final field = switch (value) {
      Vector3 _ => Row(
        children: [
          Expanded(
            child: CustomPropertiesField(
              type: double,
              tracked: tracked,
              property: property,
              boxValue: (c, unboxed) => Vector3(box(double, unboxed) ?? c.x, c.y, c.z),
              unboxValue: (boxed) => unbox(boxed.x),
            ),
          ),
          SizedBox(width: 4.0),
          Expanded(
            child: CustomPropertiesField(
              type: double,
              tracked: tracked,
              property: property,
              boxValue: (c, unboxed) => Vector3(c.x, box(double, unboxed) ?? c.y, c.z),
              unboxValue: (boxed) => unbox(boxed.y),
            ),
          ),
          SizedBox(width: 4.0),
          Expanded(
            child: CustomPropertiesField(
              type: double,
              tracked: tracked,
              property: property,
              boxValue: (c, unboxed) => (c.x, c.y, box(double, unboxed) ?? c.z),
              unboxValue: (boxed) => unbox(boxed.z),
            ),
          ),
        ],
      ),
      Quaternion _ => QuaternionPropertyField(tracked: tracked, property: property),
      dynamic v => CustomPropertiesField(
        type: v.runtimeType,
        tracked: tracked,
        property: property,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 4.0),
        field,
      ],
    );
  }
}

class CustomPropertiesField extends StatefulWidget {
  final Type type;
  final StateTracked tracked;
  final TrackedProperty property;
  final dynamic Function(dynamic current, String unboxed)? boxValue;
  final String Function(dynamic boxed)? unboxValue;

  const CustomPropertiesField({
    super.key,
    required this.type,
    required this.tracked,
    required this.property,
    this.boxValue,
    this.unboxValue,
  });

  @override
  State<CustomPropertiesField> createState() => _CustomPropertiesFieldState();
}

class _CustomPropertiesFieldState extends State<CustomPropertiesField> {
  late final FocusNode _focusNode;
  late final TextEditingController _textEditingController;
  late final StreamSubscription _onChangedSubscription;

  String getValueTypeName() {
    return widget.type.toString();
  }

  String getValue() {
    final boxedValue = widget.property.get();
    final value = widget.unboxValue?.call(boxedValue) ?? unbox(boxedValue);
    return value;
  }

  void setValue(String value) {
    final boxedValue = widget.boxValue?.call(widget.property.get(), value) ?? box(widget.type, value);
    if (boxedValue == null) return;
    widget.tracked.modifyLocal((builder) {
      widget.property.set(widget.tracked, builder, boxedValue);
    });
  }

  @override
  void initState() {
    _focusNode = FocusNode();
    _textEditingController = TextEditingController(text: getValue());
    _onChangedSubscription = widget.property.onChanged.listen(_onChanged);
    super.initState();
  }

  @override
  void dispose() {
    _onChangedSubscription.cancel();
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  const QuaternionPropertyField({super.key, required this.tracked, required this.property});

  @override
  State<QuaternionPropertyField> createState() => _QuaternionPropertyFieldState();
}

class _QuaternionPropertyFieldState extends State<QuaternionPropertyField> {
  late final FocusNode _focusNode;
  late final List<TextEditingController> _textEditingControllers;
  late final StreamSubscription _onChangedSubscription;

  Vector3? _current;

  String getValueTypeName() {
    return 'double';
  }

  @override
  void initState() {
    _focusNode = FocusNode();
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
    _focusNode.dispose();
    super.dispose();
  }

  void _init() {
    final rotationMatrix = (widget.property.get() as Quaternion).asRotationMatrix();
    final pitch = degrees(math.atan2(rotationMatrix[5], rotationMatrix[8]));
    final yaw = degrees(-math.asin(rotationMatrix[2]));
    final roll = degrees(math.atan2(rotationMatrix[1], rotationMatrix[0]));
    _textEditingControllers = [
      TextEditingController(text: pitch.toString()),
      TextEditingController(text: yaw.toString()),
      TextEditingController(text: roll.toString()),
    ];
    _current = Vector3(pitch, yaw, roll);
  }

  void _onChanged(dynamic value) {
    if (_focusNode.hasFocus) return;
    value = value as Quaternion;
    final rotationMatrix = value.asRotationMatrix();
    final pitch = degrees(math.atan2(rotationMatrix[5], rotationMatrix[8]));
    final yaw = degrees(-math.asin(rotationMatrix[2]));
    final roll = degrees(math.atan2(rotationMatrix[1], rotationMatrix[0]));
    _textEditingControllers[0].text = pitch.toString();
    _textEditingControllers[1].text = yaw.toString();
    _textEditingControllers[2].text = roll.toString();
    _current = Vector3(pitch, yaw, roll);
  }

  void _editingComplete() {
    final pitch = radians(double.tryParse(_textEditingControllers[1].text) ?? _current?.y ?? 0.0);
    final yaw = radians(double.tryParse(_textEditingControllers[0].text) ?? _current?.x ?? 0.0);
    final roll = radians(double.tryParse(_textEditingControllers[2].text) ?? _current?.z ?? 0.0);
    final value = Quaternion.euler(pitch, yaw, roll);
    widget.tracked.modifyLocal((builder) {
      widget.property.set(widget.tracked, builder, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      child: Row(
        children: [
          Expanded(
            child: ShadInput(
              controller: _textEditingControllers[0],
              onEditingComplete: _editingComplete,
              placeholder: Text(getValueTypeName()),
            ),
          ),
          SizedBox(width: 4.0),
          Expanded(
            child: ShadInput(
              controller: _textEditingControllers[1],
              onEditingComplete: _editingComplete,
              placeholder: Text(getValueTypeName()),
            ),
          ),
          SizedBox(width: 4.0),
          Expanded(
            child: ShadInput(
              controller: _textEditingControllers[2],
              onEditingComplete: _editingComplete,
              placeholder: Text(getValueTypeName()),
            ),
          ),
        ],
      ),
    );
  }
}
