import 'dart:async';

import 'package:flutter/material.dart' show Scrollbar, SelectableText;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/smooth_scroll_controller.dart';
import 'package:sl_editor/widgets/shad_breadcrumb_dropdown.dart';
import 'package:sl_engine/logger.dart';

class ConsolePanel extends StatelessWidget {
  const ConsolePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ShadCard(
          border: ShadBorder(
            bottom: ShadBorderSide(
              color: ShadTheme.of(context).colorScheme.border,
              width: 2.0,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          padding: EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(width: 8.0),
              Text('Console'),
              Expanded(child: Container()),
              MyShadDropdown(
                items: [
                  ShadBreadcrumbDropMenuItem(
                    child: Text('Clear'),
                    onPressed: () {
                      Logger.clear();
                    },
                  ),
                  ShadSeparator.horizontal(
                    margin: EdgeInsets.symmetric(vertical: 4.0),
                  ),
                  _ToggleCollapseButton(),
                ],
                showDropdownArrow: false,
                anchor: ShadAnchor(
                  childAlignment: Alignment.topRight,
                  overlayAlignment: Alignment.bottomRight,
                ),
                child: Icon(
                  LucideIcons.ellipsis,
                  color: ShadTheme.of(context).colorScheme.foreground,
                  size: 24.0,
                ),
              ),
              SizedBox(width: 8.0),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: _LogsWidget(),
          ),
        ),
      ],
    );
  }
}

class _LogsWidget extends StatefulWidget {
  const _LogsWidget({super.key});

  @override
  State<_LogsWidget> createState() => _LogsWidgetState();
}

class _LogsWidgetState extends State<_LogsWidget> {
  late final SmoothScrollController _scrollController;
  late final StreamSubscription<Log?> _subscription;
  Log? _expanded;

  @override
  void initState() {
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log(
      "test debug message test debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug message",
    );
    Logger.log(
      "test debug message test debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug messagetest debug message",
    );
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test debug message");
    Logger.log("test info message", .info);
    Logger.log("test warning message", .warning);
    Logger.log("test error message", .error);
    _scrollController = SmoothScrollController();
    _subscription = Logger.getStream().listen(_onLog);
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _subscription.cancel();
    super.dispose();
  }

  void _onLog(Log? log) {
    if (!mounted) return;
    setState(() {});
  }

  void _onExpand(Log log) {
    if (_expanded == log) {
      setState(() => _expanded = null);
    } else {
      setState(() => _expanded = log);
    }
  }

  @override
  Widget build(BuildContext context) {
    final logs = Logger.getLogs();
    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.separated(
        controller: _scrollController,
        reverse: true,
        padding: EdgeInsets.only(top: 8.0, bottom: 8.0, right: 14.0),
        itemBuilder: (context, index) {
          final log = logs[index];
          return _LogWidget(
            key: ValueKey(log),
            log: log,
            expanded: log == _expanded,
            onExpand: () => _onExpand(log),
          );
        },
        separatorBuilder: (context, index) {
          return ShadSeparator.horizontal(
            margin: EdgeInsets.zero,
          );
        },
        itemCount: logs.length,
      ),
    );
  }
}

class _LogWidget extends StatelessWidget {
  final Log log;
  final bool expanded;
  final void Function() onExpand;

  const _LogWidget({
    super.key,
    required this.log,
    required this.expanded,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = ShadTheme.of(context).colorScheme;
    final color = switch (log.severity) {
      .debug => colorScheme.foreground.withValues(alpha: 0.6),
      .info => colorScheme.foreground.withValues(alpha: 0.6),
      .warning => const Color(0xfffacc15),
      .error => colorScheme.destructive,
    };
    final backgroundColor = switch (log.severity) {
      .debug => colorScheme.foreground.withValues(alpha: 0.05),
      .info => colorScheme.foreground.withValues(alpha: 0.05),
      .warning => const Color(0xfffacc15).withValues(alpha: 0.1),
      .error => colorScheme.destructive.withValues(alpha: 0.1),
    };
    final expandedBackgroundColor = switch (log.severity) {
      .debug => colorScheme.foreground.withValues(alpha: 0.1),
      .info => colorScheme.foreground.withValues(alpha: 0.1),
      .warning => const Color(0xfffacc15).withValues(alpha: 0.15),
      .error => colorScheme.destructive.withValues(alpha: 0.15),
    };

    return GestureDetector(
      onTap: onExpand,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            Icon(
              switch (log.severity) {
                .debug => LucideIcons.code,
                .info => LucideIcons.info,
                .warning => LucideIcons.triangleAlert,
                .error => LucideIcons.octagonAlert,
              },
              color: color,
              size: 24.0,
            ),
            SizedBox(width: 6.0),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                decoration: expanded || log.severity != .debug
                    ? BoxDecoration(
                        color: expanded ? expandedBackgroundColor : backgroundColor,
                        borderRadius: BorderRadius.circular(4.0),
                      )
                    : null,
                child: expanded
                    ? SelectableText(
                        log.message,
                        scrollPhysics: NeverScrollableScrollPhysics(),
                      )
                    : Text(
                        log.message,
                        maxLines: 3,
                        softWrap: true,
                        overflow: .fade,
                      ),
              ),
            ),
            SizedBox(width: 8.0),
            if (log.count > 1) ...[
              Container(
                margin: EdgeInsets.zero,
                padding: EdgeInsets.all(5.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24.0),
                  color: colorScheme.muted.withValues(alpha: 0.5),
                ),
                constraints: BoxConstraints(
                  minWidth: 24.0,
                  minHeight: 24.0,
                ),
                alignment: Alignment.center,
                child: Text(
                  log.count.toString(),
                  style: TextStyle(
                    color: colorScheme.foreground.withValues(alpha: 0.5),
                    fontSize: 12.0,
                  ),
                ),
              ),
              SizedBox(width: 8.0),
            ],
            Text(
              DateFormat('HH:mm:ss.SSS').format(log.timestamp),
              style: TextStyle(
                color: colorScheme.foreground.withValues(alpha: 0.5),
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleCollapseButton extends StatefulWidget {
  const _ToggleCollapseButton({super.key});

  @override
  State<_ToggleCollapseButton> createState() => _ToggleCollapseButtonState();
}

class _ToggleCollapseButtonState extends State<_ToggleCollapseButton> {
  @override
  Widget build(BuildContext context) {
    return ShadBreadcrumbDropMenuItem(
      child: Row(
        children: [
          Text('Collapse'),
          SizedBox(width: 8.0),
          SizedBox(
            width: 24.0,
            height: 14.0,
            child: Logger.isCollapse() ? Icon(LucideIcons.check) : null,
          ),
        ],
      ),
      onPressed: () {
        setState(() => Logger.setCollapse(!Logger.isCollapse()));
      },
    );
  }
}
