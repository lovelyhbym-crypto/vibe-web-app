import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/category_model.dart';

part 'category_provider.g.dart';

@Riverpod(keepAlive: true)
class CategoryNotifier extends _$CategoryNotifier {
  @override
  FutureOr<List<CategoryModel>> build() {
    // 욕망의 4대 천왕 + 기타
    return [
      const CategoryModel(
        id: 'delivery',
        name: '배달 & 야식',
        iconPath: 'fastfood',
        color: '0xFFFF3B30', // Neon Red
        isCustom: false,
      ),
      const CategoryModel(
        id: 'alcohol',
        name: '술 & 유흥',
        iconPath: 'local_bar',
        color: '0xFFCCFF00', // Neon Lime
        isCustom: false,
      ),
      const CategoryModel(
        id: 'taxi',
        name: '택시 & 편의',
        iconPath: 'local_taxi',
        color: '0xFF007AFF', // Electric Blue
        isCustom: false,
      ),
      const CategoryModel(
        id: 'shopping',
        name: '쇼핑 & 군것질',
        iconPath: 'shopping_bag',
        color: '0xFFAF52DE', // Purple
        isCustom: false,
      ),
      const CategoryModel(
        id: 'etc',
        name: '기타',
        iconPath: 'more_horiz',
        color: '0xFF8E8E93', // Gray
        isCustom: false,
      ),
      // [Trophy Mode] Hidden Category for System Optimization
      const CategoryModel(
        id: 'system_optimization',
        name: '유혹방어 & 자산지킴',
        iconPath: 'security',
        color: '0xFFD4FF00', // Neon Lime
        isCustom: false,
      ),
    ];
  }

  // Fixed categories, no modification allowed for now
  Future<void> addCategory(String name) async {
    // No-op or implementation if 'Etc' allows sub-categories
  }

  Future<void> deleteCategory(String id) async {
    // No-op
  }

  Future<void> editCategory(String id, String newName) async {
    // No-op
  }
}

final categoryProvider = categoryNotifierProvider;
