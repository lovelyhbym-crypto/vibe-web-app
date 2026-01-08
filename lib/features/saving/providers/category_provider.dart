import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../domain/category_model.dart';

part 'category_provider.g.dart';

@Riverpod(keepAlive: true)
class CategoryNotifier extends _$CategoryNotifier {
  @override
  FutureOr<List<CategoryModel>> build() {
    // Initial default categories
    return [
      const CategoryModel(id: '1', name: '야식', isCustom: false),
      const CategoryModel(id: '2', name: '술', isCustom: false),
      const CategoryModel(id: '3', name: '커피', isCustom: false),
      const CategoryModel(id: '4', name: '택시', isCustom: false),
    ];
  }

  Future<void> addCategory(String name) async {
    final stateList = state.value ?? [];
    // Check for duplicates
    if (stateList.any((c) => c.name == name)) return;

    final newCategory = CategoryModel(
      id: const Uuid().v4(),
      name: name,
      isCustom: true,
    );

    state = AsyncValue.data([...stateList, newCategory]);
  }

  Future<void> deleteCategory(String id) async {
    final stateList = state.value ?? [];
    final updatedList = stateList.where((c) => c.id != id).toList();
    state = AsyncValue.data(updatedList);
  }

  Future<void> editCategory(String id, String newName) async {
    final stateList = state.value ?? [];
    final updatedList = stateList.map((c) {
      if (c.id == id) {
        return c.copyWith(name: newName);
      }
      return c;
    }).toList();
    state = AsyncValue.data(updatedList);
  }
}

final categoryProvider = categoryNotifierProvider;
