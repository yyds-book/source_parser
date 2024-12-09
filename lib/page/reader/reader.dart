import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:source_parser/model/reader_state.dart';
import 'package:source_parser/model/reader_theme.dart';
import 'package:source_parser/page/reader/component/background.dart';
import 'package:source_parser/page/reader/component/cache.dart';
import 'package:source_parser/page/reader/component/overlay.dart';
import 'package:source_parser/page/reader/component/view.dart';
import 'package:source_parser/provider/book.dart';
import 'package:source_parser/provider/cache.dart';
import 'package:source_parser/provider/reader.dart';
import 'package:source_parser/schema/book.dart';
import 'package:source_parser/util/message.dart';

@RoutePage()
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key});

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _Reader extends StatefulWidget {
  final Book book;
  const _Reader({required this.book});

  @override
  State<_Reader> createState() => _ReaderState();
}

class _ReaderBackground extends ConsumerWidget {
  const _ReaderBackground();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = ref.watch(readerThemeNotifierProvider).valueOrNull;
    return ReaderBackground(theme: theme ?? ReaderTheme());
  }
}

class _ReaderCacheIndicator extends StatelessWidget {
  const _ReaderCacheIndicator();

  @override
  Widget build(BuildContext context) {
    const indicator = Padding(
      padding: EdgeInsets.only(right: 8.0),
      child: ReaderCacheIndicator(),
    );
    return Align(alignment: Alignment.centerRight, child: indicator);
  }
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  bool caching = false;
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(bookNotifierProvider);
    const indicator = Padding(
      padding: EdgeInsets.only(right: 8.0),
      child: ReaderCacheIndicator(),
    );
    const align = Align(alignment: Alignment.centerRight, child: indicator);
    return Stack(children: [_Reader(book: book), if (caching) align]);
  }

  @override
  void deactivate() {
    ref.invalidate(booksProvider);
    super.deactivate();
  }
}

class _ReaderState extends State<_Reader> {
  bool showOverlay = false;
  bool showCache = false;

  @override
  Widget build(BuildContext context) {
    var readerOverlay = ReaderOverlay(
      onCached: handleCached,
      onRemoved: handleRemoved,
      title: widget.book.name,
    );
    var children = [
      _ReaderBackground(),
      _ReaderView(book: widget.book, onTap: handleTap),
      if (showCache) _ReaderCacheIndicator(),
      if (showOverlay) readerOverlay,
    ];
    return Stack(children: children);
  }

  void handleCached(int amount) async {
    setState(() {
      showCache = true;
    });
    var container = ProviderScope.containerOf(context);
    final notifier = container.read(cacheProgressNotifierProvider.notifier);
    await notifier.cacheChapters(amount: amount);
    if (!mounted) return;
    final message = Message.of(context);
    final progress = container.read(cacheProgressNotifierProvider);
    message.show('缓存完毕，${progress.succeed}章成功，${progress.failed}章失败');
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      showCache = false;
    });
  }

  void handleRemoved() {
    setState(() {
      showOverlay = false;
    });
  }

  void handleTap() {
    setState(() {
      showOverlay = true;
    });
  }
}

class _ReaderView extends ConsumerStatefulWidget {
  final Book book;
  final void Function()? onTap;
  const _ReaderView({required this.book, this.onTap});

  @override
  ConsumerState<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends ConsumerState<_ReaderView> {
  final controller = PageController(initialPage: 1);
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    var theme = ref.watch(readerThemeNotifierProvider).valueOrNull;
    var provider = readerStateNotifierProvider(widget.book);
    var state = ref.watch(provider);
    var page = switch (state) {
      AsyncData(:final value) => _buildData(ref, value, theme ?? ReaderTheme()),
      AsyncError(:final error, :final stackTrace) =>
        _buildError(ref, error, stackTrace, theme ?? ReaderTheme()),
      AsyncLoading() => _buildLoading(),
      _ => const SizedBox(),
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: handleTapUp,
      child: page,
    );
  }

  @override
  void dispose() {
    controller.removeListener(_handleScroll);
    controller.dispose();
    super.dispose();
  }

  Future<void> handlePageChanged(WidgetRef ref, int index) async {
    var provider = readerStateNotifierProvider(widget.book);
    final notifier = ref.read(provider.notifier);
    notifier.updatePageIndex(index);
    controller.jumpToPage(1);
  }

  Future<void> handleTapUp(TapUpDetails details) async {
    if (_isAnimating) return;
    // 左中右三部分，中间触发widget.onTap,左右分别翻页
    var position = details.localPosition;
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var index = 0;
    if (position.dx < width / 3) {
      index = 0;
    } else if (position.dx > width / 3 * 2) {
      index = 2;
    } else {
      if (position.dy < height / 4) {
        index = 0;
      } else if (position.dy > height / 4 * 3) {
        index = 2;
      }
      index = 1;
    }
    if (index == 1) return widget.onTap?.call();
    // await handlePageChanged(ref, index);
    controller.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleScroll);
  }

  Widget _buildData(WidgetRef ref, ReaderState state, ReaderTheme theme) {
    if (state.pages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return PageView.builder(
      controller: controller,
      itemBuilder: (_, index) => _itemBuilder(state, theme, index),
      itemCount: state.pages.length,
    );
    // return Container(color: Colors.white);
  }

  Widget _buildError(
    WidgetRef ref,
    Object error,
    StackTrace stackTrace,
    ReaderTheme theme,
  ) {
    var children = [
      Text(error.toString()),
      Text(stackTrace.toString()),
    ];
    var column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
    var padding = Padding(
      padding: const EdgeInsets.all(16.0),
      child: column,
    );
    return ReaderView.builder(
      builder: () => padding,
      eInkMode: false,
      modes: [],
      pageIndex: 0,
      title: '',
      theme: theme,
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  void _handleScroll() {
    if (_isAnimating) return;

    final position = controller.page ?? 1;
    if (position <= 0.0 || position >= 2.0) {
      _isAnimating = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await handlePageChanged(ref, position <= 0.0 ? 0 : 2);
        _isAnimating = false;
      });
    }
  }

  Widget _itemBuilder(ReaderState state, ReaderTheme theme, int index) {
    var book = state.book;
    var chapters = book.chapters;
    var title = book.name;
    if (book.cursor > 0) title = chapters[book.index].name;
    return ReaderView(
      eInkMode: false,
      modes: [],
      textSpan: state.pages[index],
      pageIndex: state.pageIndex,
      title: title,
      theme: theme,
    );
  }
}
