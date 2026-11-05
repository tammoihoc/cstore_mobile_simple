import 'dart:async';
import 'dart:convert';
import 'package:cstore_mobile/models/models.dart';
import 'package:cstore_mobile/services/account_api.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
      'photo refresh bypasses active polling and ignores its stale product response',
      () async {
    final oldProducts = Completer<http.Response>();
    var reads = 0;
    Map<String, dynamic> product(String image) => {
          'id': 1,
          'storeId': 2,
          'name': 'Sữa',
          'price': 25000,
          'stock': 5,
          'image': image,
          'category': 'Đồ uống',
          'active': true
        };
    http.Response response(Object data) =>
        http.Response.bytes(utf8.encode(jsonEncode(data)), 200);
    final state = AppState(accountApi: AccountApi(client: MockClient((r) async {
      if (r.method == 'POST') {
        return response(product('/api/images/uploaded.png'));
      }
      if (r.url.path.endsWith('/merchant/products')) {
        reads++;
        if (reads == 1) return oldProducts.future;
        return response([product('/api/images/uploaded.png')]);
      }
      return response([]);
    })))
      ..account = const Account(1, 'store@test.local', 'Store', Role.store, 2);
    final item = Product(1, 2, 'Sữa', 25000, 5, '', 'Đồ uống');
    state.products.add(item);
    final polling = state.reload();
    await Future<void>.delayed(Duration.zero);
    expect(state.loading, isTrue);
    await state.uploadImage(item, [1, 2, 3], 'qa.png');
    expect(state.products.single.asset, '/api/images/uploaded.png');
    oldProducts.complete(response([product('')]));
    await polling;
    expect(state.products.single.asset, '/api/images/uploaded.png');
    expect(reads, 2);
    state.dispose();
  });
}
