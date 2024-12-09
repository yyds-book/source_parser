import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:source_parser/model/reader_theme.dart';
import 'package:source_parser/provider/reader.dart';

class ReaderView extends ConsumerWidget {
  final Widget Function()? builder;
  final bool eInkMode;
  final TextSpan textSpan;
  final int pageIndex;
  final String title;

  const ReaderView({
    super.key,
    this.builder,
    required this.eInkMode,
    required this.textSpan,
    required this.pageIndex,
    required this.title,
  });

  const ReaderView.builder({
    super.key,
    required this.builder,
    required this.eInkMode,
    required this.pageIndex,
    required this.title,
  }) : textSpan = const TextSpan();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var state = ref.watch(readerThemeNotifierProvider).valueOrNull;
    var theme = state ?? ReaderTheme();
    var header = _Header(
      padding: theme.headerPadding,
      style: theme.headerStyle,
      title: title,
    );
    Widget content = _Content(
      padding: theme.pagePadding,
      style: theme.pageStyle,
      textSpan: textSpan,
    );
    if (builder != null) content = builder!.call();
    var footer = _Footer(
      cursor: pageIndex,
      length: 10,
      padding: theme.footerPadding,
      progress: 0.8326,
      style: theme.footerStyle,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [header, Expanded(child: content), footer],
    );
  }
}

class _Content extends StatelessWidget {
  final EdgeInsets padding;
  final TextStyle style;
  final TextSpan textSpan;
  const _Content({
    required this.padding,
    required this.style,
    required this.textSpan,
  });

  @override
  Widget build(BuildContext context) {
    var text = RichText(text: textSpan);
    return Padding(padding: padding, child: text);
  }
}

class _Footer extends StatefulWidget {
  final int cursor;
  final int length;
  final EdgeInsets padding;
  final double progress;
  final TextStyle style;

  const _Footer({
    required this.cursor,
    required this.length,
    required this.padding,
    required this.progress,
    required this.style,
  });

  @override
  State<_Footer> createState() => _FooterState();
}

class _FooterState extends State<_Footer> {
  int battery = 100;

  @override
  Widget build(BuildContext context) {
    const spacer = SizedBox(width: 4);
    var pageIndicator = _buildPage();
    var progressIndicator = _buildProgress();
    var left = Row(children: [pageIndicator, spacer, progressIndicator]);
    var timeIndicator = _buildTime();
    var batteryIndicator = _buildBattery();
    var right = Row(children: [timeIndicator, spacer, batteryIndicator]);
    var row = Row(children: [left, const Spacer(), right]);
    return Padding(padding: widget.padding, child: row);
  }

  @override
  void initState() {
    super.initState();
    _calculateBattery();
  }

  Widget _buildBattery() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final onBackground = colorScheme.outline;
    var outerDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      color: onBackground.withOpacity(0.25),
    );
    var innerDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      color: primary.withOpacity(0.5),
    );
    var container = Container(
      decoration: innerDecoration,
      height: 8,
      width: 16 * (battery / 100),
    );
    var body = Container(
      alignment: Alignment.centerLeft,
      decoration: outerDecoration,
      height: 8,
      width: 16,
      child: container,
    );
    const borderRadius = BorderRadius.only(
      topRight: Radius.circular(1),
      bottomRight: Radius.circular(1),
    );
    var capDecoration = BoxDecoration(
      borderRadius: borderRadius,
      color: onBackground.withOpacity(0.25),
    );
    var cap = Container(decoration: capDecoration, height: 4, width: 1);
    return Row(children: [body, cap]);
  }

  Widget _buildPage() {
    var text = '${(widget.cursor + 1)}/${widget.length}';
    return Text(text, style: widget.style);
  }

  Widget _buildProgress() {
    var progress = (widget.progress * 100).toStringAsFixed(2);
    return Text('$progress%', style: widget.style);
  }

  Widget _buildTime() {
    var time = DateTime.now().toString().substring(11, 16);
    return Text(time, style: widget.style);
  }

  Future<void> _calculateBattery() async {
    var level = await Battery().batteryLevel;
    setState(() {
      battery = level;
    });
  }
}

class _Header extends StatelessWidget {
  final EdgeInsets padding;
  final TextStyle style;
  final String title;

  const _Header({
    required this.padding,
    required this.style,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    var text = Text(title, style: style, textAlign: TextAlign.start);
    return Padding(padding: padding, child: text);
  }
}