import '../features/rooms/room_controller.dart';
import '../domain/models.dart';
import 'demo_store.dart';
import 'transport.dart';

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
