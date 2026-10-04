import 'package:flutter/foundation.dart';

import '../../core/async_resource.dart';
import '../../demo/demo_store.dart';
import '../../demo/models.dart';

abstract interface class RoomRepository {
  Future<List<Room>> discover();
  Future<Room?> find(String id);
}

class DemoRoomRepository implements RoomRepository {
  final DemoStore store;
  final DemoTransport transport;
  DemoRoomRepository(this.store, this.transport);
  @override
  Future<List<Room>> discover() => transport.run(
    () => store.rooms.where((r) => r.status == RoomStatus.available).toList(),
  );
  @override
  Future<Room?> find(String id) =>
      transport.run(() => store.rooms.where((r) => r.id == id).firstOrNull);
}

class RoomController extends ChangeNotifier {
  final DemoStore store;
  final RoomRepository repository;
  final feed = AsyncResource<List<Room>>();
  String district = 'Quận 10', type = 'Studio', query = '', sort = 'newest';
  double minPrice = 0, maxPrice = 3000000;
  final Set<String> amenities = {};
  RoomController(this.store, this.repository) {
    feed.addListener(notifyListeners);
  }
  Future<void> load() =>
      feed.load(repository.discover, isEmpty: (list) => list.isEmpty);
  List<Room> get filtered {
    if (feed.phase == ResourcePhase.error ||
        feed.phase == ResourcePhase.loading) {
      return [];
    }
    final list =
        (feed.phase == ResourcePhase.ready || feed.phase == ResourcePhase.empty
                ? feed.data ?? <Room>[]
                : store.rooms)
            .where(
              (r) =>
                  r.status == RoomStatus.available &&
                  (district == 'Tất cả' || r.district == district) &&
                  (type == 'Tất cả' || r.type == type) &&
                  r.price >= minPrice &&
                  r.price <= maxPrice &&
                  amenities.every(r.amenities.contains) &&
                  '${r.title} ${r.address}'.toLowerCase().contains(
                    query.trim().toLowerCase(),
                  ),
            )
            .toList();
    if (sort == 'price_asc') list.sort((a, b) => a.price.compareTo(b.price));
    if (sort == 'price_desc') list.sort((a, b) => b.price.compareTo(a.price));
    return list;
  }

  void resetFilters() {
    district = 'Quận 10';
    type = 'Studio';
    query = '';
    sort = 'newest';
    minPrice = 0;
    maxPrice = 3000000;
    amenities.clear();
  }

  @override
  void dispose() {
    feed.removeListener(notifyListeners);
    feed.dispose();
    super.dispose();
  }
}
