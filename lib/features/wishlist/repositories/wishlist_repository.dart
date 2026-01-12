import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist_item.dart';

class WishlistRepository {
  final SupabaseClient _supabase;

  WishlistRepository(this._supabase);

  Future<List<WishlistItem>> fetchItems() async {
    final response = await _supabase
        .from('wishlist')
        .select()
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    return data
        .map((e) => WishlistItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<WishlistItem>> streamItems() {
    return _supabase
        .from('wishlist')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => WishlistItem.fromJson(e)).toList());
  }

  Future<WishlistItem> addItem(String title, double price) async {
    final response = await _supabase
        .from('wishlist')
        .insert({'title': title, 'price': price, 'is_completed': false})
        .select()
        .single();

    return WishlistItem.fromJson(response);
  }

  Future<void> deleteItem(String id) async {
    await _supabase.from('wishlist').delete().eq('id', id);
  }

  Future<void> deleteItems(List<String> ids) async {
    await _supabase.from('wishlist').delete().filter('id', 'in', ids);
  }

  Future<void> toggleComplete(String id, bool currentValue) async {
    final newValue = !currentValue;
    await _supabase
        .from('wishlist')
        .update({
          'is_completed': newValue,
          'completed_at': newValue ? DateTime.now().toIso8601String() : null,
        })
        .eq('id', id);
  }

  Future<void> updateComment(String id, String comment) async {
    await _supabase.from('wishlist').update({'comment': comment}).eq('id', id);
  }
}
