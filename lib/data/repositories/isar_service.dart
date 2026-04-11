import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/store_model.dart';
import '../models/shopping_list_model.dart';

class IsarService {
  static IsarService? _instance;
  static Isar? _isar;

  IsarService._();

  static IsarService get instance {
    _instance ??= IsarService._();
    return _instance!;
  }

  Isar get db {
    if (_isar == null) throw StateError('Isar not initialized. Call init() first.');
    return _isar!;
  }

  Future<void> init() async {
    if (_isar != null && _isar!.isOpen) return;

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [StoreModelSchema, ShoppingListModelSchema],
      directory: dir.path,
      name: 'nearcart_db',
    );
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
