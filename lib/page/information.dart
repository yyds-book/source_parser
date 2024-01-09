import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:source_parser/provider/book.dart';
import 'package:source_parser/provider/setting.dart';
import 'package:source_parser/provider/source.dart';
import 'package:source_parser/router/router.dart';
import 'package:source_parser/schema/book.dart';
import 'package:source_parser/schema/setting.dart';
import 'package:source_parser/util/message.dart';
import 'package:source_parser/widget/book_cover.dart';
import 'package:source_parser/widget/loading.dart';

class InformationPage extends ConsumerStatefulWidget {
  const InformationPage({super.key});

  @override
  ConsumerState<InformationPage> createState() {
    return _BookInformationState();
  }
}

class _BookInformationState extends ConsumerState<InformationPage> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
    getInformation(ref);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final provider = ref.watch(settingNotifierProvider);
      final setting = switch (provider) {
        AsyncData(:final value) => value,
        _ => Setting(),
      };
      final book = ref.watch(bookNotifierProvider);
      final eInkMode = setting.eInkMode;
      final sourceProvider = ref.watch(currentSourceProvider);
      final source = switch (sourceProvider) {
        AsyncData(:final value) => value,
        _ => null,
      };
      return RefreshIndicator(
        onRefresh: () => getInformation(ref),
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      _BackgroundImage(url: book.cover),
                      const _ColorFilter(),
                      _Information(book: book),
                    ],
                  ),
                  collapseMode: CollapseMode.pin,
                ),
                pinned: true,
                stretch: true,
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  _Introduction(book: book),
                  const SizedBox(height: 8),
                  _Catalogue(book: book, eInkMode: eInkMode, loading: loading),
                  const SizedBox(height: 8),
                  _Source(
                    currentSource: source?.name,
                    sources: book.sources,
                  ),
                  const SizedBox(height: 8),
                  const _Archive(),
                ]),
              )
            ],
          ),
          bottomNavigationBar: const _BottomBar(),
        ),
      );
    });
  }

  Future<void> getInformation(WidgetRef ref) async {
    final message = Message.of(context);
    setState(() {
      loading = true;
    });
    try {
      final notifier = ref.read(bookNotifierProvider.notifier);
      await notifier.refreshInformation();
      setState(() {
        loading = false;
      });
    } catch (error) {
      message.show(error.toString());
      setState(() {
        loading = false;
      });
    }
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: BookCover(
        height: double.infinity,
        url: url,
        width: double.infinity,
      ),
    );
  }
}

class _ColorFilter extends StatelessWidget {
  const _ColorFilter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    return Container(color: primary.withOpacity(0.25));
  }
}

class _Information extends StatelessWidget {
  const _Information({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => handleLongPress(context),
            child: BookCover(height: 120, url: book.cover, width: 90),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white, height: 1.6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => searchSameAuthor(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(book.author),
                        const Icon(
                          Icons.arrow_forward_ios_outlined,
                          color: Colors.white,
                          size: 14,
                        )
                      ],
                    ),
                  ),
                  Text(
                    _buildSpan(book),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  void handleLongPress(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return _CoverSelector(book: book);
      },
    );
  }

  void searchSameAuthor(BuildContext context) {
    SearchPageRoute(credential: book.author).push(context);
  }

  String _buildSpan(Book book) {
    final spans = <String>[];
    if (book.category.isNotEmpty) {
      spans.add(book.category);
    }
    if (book.status.isNotEmpty) {
      spans.add(book.status);
    }
    return spans.join(' · ');
  }
}

class _Introduction extends StatefulWidget {
  const _Introduction({required this.book});

  final Book book;

  @override
  State<_Introduction> createState() => _IntroductionState();
}

class _IntroductionState extends State<_Introduction> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTint = colorScheme.surfaceTint;
    var introduction = widget.book.introduction;
    introduction = introduction
        .replaceAll(' ', '')
        .replaceAll(RegExp(r'\u2003'), '')
        .replaceAll(RegExp(r'\n+'), '\n\u2003\u2003')
        .trim();
    introduction = '\u2003\u2003$introduction';
    return Card(
      color: surfaceTint.withOpacity(0.05),
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  children: [
                    if (widget.book.words.isNotEmpty)
                      _Tag(text: widget.book.words),
                    if (widget.book.status.isNotEmpty)
                      _Tag(text: widget.book.status),
                  ],
                ),
                if (widget.book.words.isNotEmpty ||
                    widget.book.status.isNotEmpty)
                  const SizedBox(height: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: handleTap,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      introduction,
                      maxLines: expanded ? null : 4,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            if (!expanded)
              Positioned(
                bottom: 8,
                right: 0,
                child: Container(
                  decoration: ShapeDecoration(
                    color: surfaceTint.withOpacity(0.1),
                    shape: const StadiumBorder(),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: surfaceTint,
                    size: 12,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }

  void handleTap() {
    setState(() {
      expanded = !expanded;
    });
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTint = colorScheme.surfaceTint;
    final textTheme = theme.textTheme;
    final labelMedium = textTheme.labelMedium;
    return Container(
      decoration: ShapeDecoration(
        color: surfaceTint.withOpacity(0.1),
        shape: const StadiumBorder(),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      child: Text(text, style: labelMedium),
    );
  }
}

class _Catalogue extends StatelessWidget {
  const _Catalogue({
    required this.book,
    this.eInkMode = false,
    this.loading = false,
  });

  final Book book;
  final bool eInkMode;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    const boldTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return GestureDetector(
      onTap: () => handleTap(context),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.05),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Text('目录', style: boldTextStyle),
              const Spacer(),
              if (loading && book.chapters.isEmpty)
                SizedBox(
                  height: 24,
                  width: eInkMode ? null : 24,
                  child: const LoadingIndicator(),
                ),
              if (!loading || book.chapters.isNotEmpty) ...[
                Text(
                  '共${book.chapters.length}章',
                  textAlign: TextAlign.right,
                ),
                const Icon(Icons.chevron_right_outlined)
              ]
            ],
          ),
        ),
      ),
    );
  }

  void handleTap(BuildContext context) {
    if (loading) return;
    const BookCataloguePageRoute().push(context);
  }
}

class _Source extends StatelessWidget {
  const _Source({this.currentSource, required this.sources});

  final String? currentSource;
  final List<AvailableSource> sources;

  @override
  Widget build(BuildContext context) {
    const boldTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    var name = '';
    if (currentSource != null && currentSource!.isNotEmpty) {
      name = '$currentSource · ';
    }
    return GestureDetector(
      onTap: () => handleTap(context),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.05),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('书源', style: boldTextStyle),
                  Expanded(
                    child: Text(
                      '$name可用${sources.length}个',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const Icon(Icons.chevron_right_outlined)
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void handleTap(BuildContext context) {
    const BookSourceListPageRoute().push(context);
  }
}

class _Archive extends StatelessWidget {
  const _Archive();

  @override
  Widget build(BuildContext context) {
    const boldTextStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    return Consumer(builder: (context, ref, child) {
      final book = ref.watch(bookNotifierProvider);
      return GestureDetector(
        onTap: () => handleTap(context, ref),
        child: Card(
          color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.05),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: const RoundedRectangleBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('归档', style: boldTextStyle),
                    const Spacer(),
                    Switch(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      value: book.archive,
                      onChanged: (value) => handleTap(context, ref),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void handleTap(BuildContext context, WidgetRef ref) async {
    final message = Message.of(context);
    final notifier = ref.read(bookNotifierProvider.notifier);
    await notifier.toggleArchive();
    final book = ref.read(bookNotifierProvider);
    if (book.archive) {
      message.show('归档后，书架不再更新');
    }
  }
}

class _BottomBar extends ConsumerStatefulWidget {
  const _BottomBar();

  @override
  ConsumerState<_BottomBar> createState() => __BottomBarState();
}

class __BottomBarState extends ConsumerState<_BottomBar> {
  bool inShelf = false;
  @override
  void initState() {
    super.initState();
    initInShelf();
  }

  void initInShelf() async {
    final notifier = ref.read(bookNotifierProvider.notifier);
    inShelf = await notifier.inShelf();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final icon = Icon(
      inShelf ? Icons.check_outlined : Icons.library_add_outlined,
    );
    final text = Text(inShelf ? '已在书架' : '加入书架');
    return Container(
      color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.05),
      padding: EdgeInsets.fromLTRB(16, 8, 16, padding.bottom + 8),
      child: Row(
        children: [
          TextButton(
            onPressed: () => toggleShelf(ref),
            child: Row(
              children: [icon, text],
            ),
            // child: FutureBuilder(
            //   future: future,
            //   builder: (context, snapshot) {
            //     if (snapshot.hasData && snapshot.data == true) {
            //       print(snapshot.data);
            //       return const Row(
            //         children: [Icon(Icons.check_outlined), Text('已在书架')],
            //       );
            //     } else {
            //       return const Row(
            //         children: [Icon(Icons.library_add_outlined), Text('加入书架')],
            //       );
            //     }
            //   },
            // ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              onPressed: () => startReader(context),
              child: Consumer(builder: (context, ref, child) {
                final book = ref.watch(bookNotifierProvider);
                final hasProgress = book.cursor != 0 || book.index != 0;
                String text = hasProgress ? '继续阅读' : '立即阅读';
                return Text(text);
              }),
            ),
          ),
        ],
      ),
    );
  }

  void toggleShelf(WidgetRef ref) async {
    final notifier = ref.read(bookNotifierProvider.notifier);
    inShelf = await notifier.toggleShelf();
    setState(() {});
  }

  void startReader(BuildContext context) async {
    const BookReaderPageRoute().push(context);
  }
}

class _CoverSelector extends ConsumerStatefulWidget {
  const _CoverSelector({required this.book});

  final Book book;

  @override
  ConsumerState<_CoverSelector> createState() => __CoverSelectorState();
}

class __CoverSelectorState extends ConsumerState<_CoverSelector> {
  bool loading = true;
  List<String> covers = [];

  @override
  void initState() {
    super.initState();
    getCovers(ref);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: LoadingIndicator());
    }
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        childAspectRatio: 3 / 4,
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        return Consumer(builder: (context, ref, child) {
          return GestureDetector(
            onTap: () => handleTap(ref, covers[index]),
            child: BookCover(height: 120, url: covers[index], width: 90),
          );
        });
      },
      itemCount: covers.length,
      padding: const EdgeInsets.all(16),
    );
  }

  void getCovers(WidgetRef ref) async {
    setState(() {
      loading = true;
    });
    final notifier = ref.read(bookNotifierProvider.notifier);
    final covers = await notifier.getCovers();
    setState(() {
      this.covers = covers;
      loading = false;
    });
  }

  void handleTap(WidgetRef ref, String cover) async {
    final notifier = ref.read(bookNotifierProvider.notifier);
    notifier.refreshCover(cover);
    Navigator.of(context).pop();
  }
}
