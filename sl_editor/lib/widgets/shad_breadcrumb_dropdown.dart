import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// {@template MyShadBreadcrumbDropdown}
/// A dropdown breadcrumb item that displays a menu when clicked.
///
/// This widget is used to show collapsed breadcrumb items in a dropdown menu,
/// typically represented by an ellipsis. It follows the shadcn/ui pattern of
/// using a popover to show hidden navigation levels.
/// {@endtemplate}
class MyShadDropdown extends StatefulWidget {
  /// {@macro MyShadBreadcrumbDropdown}
  const MyShadDropdown({
    super.key,
    required this.child,
    required this.items,
    this.backgroundColor,
    this.padding,
    this.anchor,
    this.arrowGap,
    this.normalTextColor,
    this.hoverTextColor,
    this.showDropdownArrow,
  });

  /// The widget that triggers the dropdown.
  final Widget child;

  /// The list of dropdown menu items to display.
  final List<Widget> items;

  /// {@template ShadBreadcrumb.dropdownMenuBackgroundColor}
  /// The color for dropdown menu. defaults to
  /// [ShadTheme.of(context).colorScheme.popover]
  /// {@endtemplate}
  final Color? backgroundColor;

  /// {@template ShadBreadcrumb.dropdownMenuPadding}
  /// The padding value for dropdown menu. defaults to
  /// [EdgeInsets.all(4)]
  /// {@endtemplate}
  final EdgeInsetsGeometry? padding;

  /// {@template ShadBreadcrumb.dropdownMenuAnchor}
  /// The anchor configuration for the dropdown popover.
  /// Defaults to
  /// ```dart
  /// ShadAnchorAuto(
  ///   offset: Offset(0, 4),
  ///   targetAnchor: Alignment.bottomLeft,
  ///   followerAnchor: Alignment.bottomRight,
  /// ),
  /// ```
  /// {@endtemplate}
  final ShadAnchorBase? anchor;

  /// {@template ShadBreadcrumb.dropdownArrowGap}
  /// The gap between the child and dropdown icon.
  /// defaults to 4
  /// {@endtemplate}
  final double? arrowGap;

  /// {@template ShadBreadcrumb.linkNormalTextColor}
  /// The color for the breadcrumb link text when not hovered.
  /// defaults to [ShadTheme.of(context).colorScheme.mutedForeground]
  /// {@endtemplate}
  final Color? normalTextColor;

  /// {@template ShadBreadcrumb.linkHoverTextColor}
  /// The color for the breadcrumb link text when hovered.
  /// defaults to [ShadTheme.of(context).colorScheme.foreground]
  /// {@endtemplate}
  final Color? hoverTextColor;

  /// {@template ShadBreadcrumb.showDropdownArrow}
  /// Whether to show the dropdown arrow icon.
  /// Defaults to true.
  /// {@endtemplate}
  final bool? showDropdownArrow;

  @override
  State<MyShadDropdown> createState() => _ShadBreadcrumbDropdownState();
}

class _ShadBreadcrumbDropdownState extends State<MyShadDropdown> {
  final controller = ShadPopoverController();
  bool isHovered = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    final effectiveDropdownMenuBackgroundColor =
        widget.backgroundColor ?? theme.breadcrumbTheme.dropdownMenuBackgroundColor ?? theme.colorScheme.popover;

    final effectiveDropdownMenuPadding =
        widget.padding ?? theme.breadcrumbTheme.dropdownMenuPadding ?? const EdgeInsets.all(4);

    final effectiveAnchor =
        widget.anchor ??
        theme.breadcrumbTheme.dropdownMenuAnchor ??
        const ShadAnchorAuto(
          offset: Offset(0, 4),
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.bottomRight,
        );

    final effectiveArrowGap = widget.arrowGap ?? theme.breadcrumbTheme.dropdownArrowGap ?? 4;

    final effectiveNormalTextColor =
        widget.normalTextColor ?? theme.breadcrumbTheme.linkNormalTextColor ?? theme.colorScheme.mutedForeground;

    final effectiveHoverTextColor =
        widget.hoverTextColor ?? theme.breadcrumbTheme.linkHoverTextColor ?? theme.colorScheme.foreground;

    final effectiveTextColor = isHovered || controller.isOpen ? effectiveHoverTextColor : effectiveNormalTextColor;

    final effectiveShowDropdownArrow = widget.showDropdownArrow ?? theme.breadcrumbTheme.showDropdownArrow ?? true;

    return ShadPopover(
      anchor: effectiveAnchor,
      decoration: ShadDecoration(
        color: effectiveDropdownMenuBackgroundColor,
      ),
      controller: controller,
      padding: effectiveDropdownMenuPadding,
      popover: (context) => IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.items,
        ),
      ),
      child: ShadBreadcrumbLink(
        normalColor: effectiveTextColor,
        onHoverChange: (isHovered) => setState(() => this.isHovered = isHovered),
        onPressed: controller.toggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: effectiveArrowGap,
          children: [
            widget.child,
            if (effectiveShowDropdownArrow)
              AnimatedRotation(
                turns: controller.isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: theme.breadcrumbTheme.separatorSize ?? 14,
                  color: effectiveTextColor,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
