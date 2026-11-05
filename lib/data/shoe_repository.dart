import 'package:drift/drift.dart';

import 'database.dart';

/// A pair of shoes with its km (start km + every run worn on).
class ShoeKm {
  const ShoeKm(this.shoe, this.km);

  final Shoe shoe;
  final double km;

  bool get wornOut => km >= shoe.limitKm;

  /// 0–1 of the replacement km.
  double get used => shoe.limitKm <= 0 ? 0 : (km / shoe.limitKm).clamp(0.0, 1.0);
}

class ShoeRepository {
  ShoeRepository(this.db);

  final AppDatabase db;

  /// Every pair with its km; active ones first, the default first of all.
  /// Updates when shoes or runs change (only emits real changes).
  Stream<List<ShoeKm>> watchAll() =>
      db.customSelect('SELECT 1', readsFrom: {db.shoes, db.runs}).watch().asyncMap((_) => _withKm()).distinct(_same);

  static bool _same(List<ShoeKm> a, List<ShoeKm> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].shoe != b[i].shoe || a[i].km != b[i].km) return false;
    }
    return true;
  }

  Future<List<ShoeKm>> _withKm() async {
    final shoes = await db.select(db.shoes).get();
    final km = <String, double>{};
    for (final r in await (db.select(db.runs)..where((r) => r.shoeId.isNotNull() & r.endedAt.isNotNull())).get()) {
      km[r.shoeId!] = (km[r.shoeId!] ?? 0) + r.distanceM / 1000;
    }
    final list = [for (final s in shoes) ShoeKm(s, s.startKm + (km[s.id] ?? 0))];
    list.sort((a, b) {
      if (a.shoe.retired != b.shoe.retired) return a.shoe.retired ? 1 : -1;
      if (a.shoe.isDefault != b.shoe.isDefault) return a.shoe.isDefault ? -1 : 1;
      return a.shoe.name.toLowerCase().compareTo(b.shoe.name.toLowerCase());
    });
    return list;
  }

  Future<List<ShoeKm>> all() => _withKm();

  Future<ShoeKm?> byId(String? id) async =>
      id == null ? null : (await _withKm()).where((s) => s.shoe.id == id).firstOrNull;

  /// The pair picked automatically for new runs.
  Future<Shoe?> defaultShoe() =>
      (db.select(db.shoes)..where((s) => s.isDefault.equals(true) & s.retired.equals(false))).getSingleOrNull();

  Future<String> save({
    String? id,
    required String name,
    double startKm = 0,
    double limitKm = 700,
    bool? isDefault,
  }) async {
    final shoeId = id ?? newId();
    await db.transaction(() async {
      final first = (await db.select(db.shoes).get()).isEmpty;
      final makeDefault = isDefault ?? (id == null && first);
      if (makeDefault) await db.update(db.shoes).write(const ShoesCompanion(isDefault: Value(false)));
      await db
          .into(db.shoes)
          .insertOnConflictUpdate(
            ShoesCompanion.insert(
              id: Value(shoeId),
              name: name,
              startKm: Value(startKm),
              limitKm: Value(limitKm),
              isDefault: makeDefault ? const Value(true) : (id == null ? const Value(false) : const Value.absent()),
              updatedAt: Value(DateTime.now()),
            ),
          );
    });
    return shoeId;
  }

  Future<void> setDefault(String id) => db.transaction(() async {
    await db.update(db.shoes).write(const ShoesCompanion(isDefault: Value(false)));
    await (db.update(db.shoes)..where((s) => s.id.equals(id))).write(const ShoesCompanion(isDefault: Value(true)));
  });

  /// Retired shoes keep their runs but aren't offered any more.
  Future<void> setRetired(String id, bool retired) => (db.update(db.shoes)..where((s) => s.id.equals(id))).write(
    ShoesCompanion(retired: Value(retired), isDefault: retired ? const Value(false) : const Value.absent()),
  );

  /// Removes the pair; its runs keep their km but no longer name a shoe.
  Future<void> delete(String id) => db.transaction(() async {
    await (db.update(db.runs)..where((r) => r.shoeId.equals(id))).write(const RunsCompanion(shoeId: Value(null)));
    await (db.delete(db.shoes)..where((s) => s.id.equals(id))).go();
  });

  /// Which shoes a run was worn in.
  Future<void> setRunShoe(String runId, String? shoeId) =>
      (db.update(db.runs)..where((r) => r.id.equals(runId))).write(RunsCompanion(shoeId: Value(shoeId)));
}
