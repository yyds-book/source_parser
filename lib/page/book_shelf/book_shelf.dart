import 'package:creator/creator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:source_parser/state/book.dart';

import '../../model/book.dart';
import '../../widget/bottom_bar.dart';
import '../../widget/shelf_item.dart';

class BookShelf extends StatelessWidget {
  const BookShelf({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () => goSearch(context),
              icon: const Icon(Icons.search)),
          IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.ellipsis_vertical),
          ),
        ],
      ),
      body: Watcher(
        (context, ref, _) {
          final books = ref.watch(shelfBooksEmitter.asyncData).data;
          if (books != null && books.isNotEmpty) {
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3),
              itemBuilder: (context, index) => ShelfItem(book: books[index]),
              itemCount: books.length,
            );
          } else {
            return const Center(child: Text('空空如也'));
          }
        },
      ),
      bottomNavigationBar: const BottomBar(),
    );
  }

  void goSearch(BuildContext context) {
    context.push('/search');
  }
}