import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nee_construction_app/providers/product_provider.dart';

void main() {
  test('Latest search wins when requests finish out of order', () async {
    final requests = <String?, Completer<Map<String, dynamic>>>{};
    final provider = ProductProvider(
      loadPage: ({category, search, required page}) {
        final response = Completer<Map<String, dynamic>>();
        requests[search] = response;
        return response.future;
      },
    );
    addTearDown(provider.dispose);
    provider.setSearch('cement');
    provider.setSearch('steel');
    expect(requests.keys, ['cement', 'steel']);
    requests['steel']!.complete({'data': [], 'next_page_url': null});
    await Future<void>.delayed(Duration.zero);
    expect(provider.loading, isFalse);
    expect(provider.hasMore, isFalse);
    requests['cement']!.complete({'data': [], 'next_page_url': '/page/2'});
    await Future<void>.delayed(Duration.zero);
    expect(provider.search, 'steel');
    expect(provider.hasMore, isFalse);
    expect(provider.error, isNull);
  });

  test(
    'An obsolete failure cannot replace a newer successful search',
    () async {
      final requests = <Completer<Map<String, dynamic>>>[];
      final provider = ProductProvider(
        loadPage: ({category, search, required page}) {
          final response = Completer<Map<String, dynamic>>();
          requests.add(response);
          return response.future;
        },
      );
      addTearDown(provider.dispose);
      provider.setCategory('Cement');
      provider.setCategory('Steel');
      requests.last.complete({'data': [], 'next_page_url': null});
      await Future<void>.delayed(Duration.zero);
      requests.first.completeError(Exception('offline'));
      await Future<void>.delayed(Duration.zero);
      expect(provider.category, 'Steel');
      expect(provider.error, isNull);
      expect(provider.loading, isFalse);
    },
  );
}
