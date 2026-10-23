import '../core/reference_photo.dart';
import '../core/device_media.dart';

enum UserRole { tenant, landlord, admin }

enum RoomStatus { available, rented, hidden, pending }

enum RentalStatus { active, expired, terminated, pending }

extension RentalStatusLabel on RentalStatus {
  String get label => switch (this) {
    RentalStatus.active => 'Đang hiệu lực',
    RentalStatus.expired => 'Đã hết hạn',
    RentalStatus.terminated => 'Đã kết thúc',
    RentalStatus.pending => 'Chờ xác nhận',
  };
}

enum ResourceKind {
  room,
  person,
  conversation,
  rental,
  swap,
  kyc,
  report,
  order,
}

class ResourceRef {
  final ResourceKind kind;
  final String id;
  const ResourceRef(this.kind, this.id);
}

class AppNotification {
  final String id, title, description;
  final ResourceRef? target;
  final bool verification;
  bool read;
  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    this.target,
    this.verification = false,
    this.read = false,
  });
}

extension RoomStatusLabel on RoomStatus {
  String get label => switch (this) {
    RoomStatus.available => 'Đang hiển thị',
    RoomStatus.rented => 'Đã cho thuê',
    RoomStatus.hidden => 'Đã ẩn',
    RoomStatus.pending => 'Chờ duyệt',
  };
}

class Room {
  final String id,
      title,
      district,
      type,
      address,
      description,
      electricity,
      water,
      otherFees;
  final int price, area, floor, match;
  final List<String> amenities;
  final String landlordId, landlordName;
  final RoomStatus status;
  final List<PhotoKind> images;
  final List<LocalPhoto> localPhotos;
  int get imageCount => images.length + localPhotos.length;
  final double? latitude, longitude;
  const Room({
    required this.id,
    required this.title,
    required this.district,
    required this.price,
    this.area = 20,
    this.floor = 3,
    this.match = 92,
    this.type = 'Studio',
    this.address = '123 Nguyễn Tri Phương',
    this.description = 'Studio xanh, thoáng mát, gần Bách Khoa. Phòng full nội thất mới, có ban công đón nắng, khu vực an ninh, yên tĩnh, thuận tiện di chuyển sang các quận trung tâm. Phù hợp cho sinh viên và người đi làm yêu thích không gian sống xanh, sạch, gọn gàng.',
    this.electricity = '3.500đ/kWh',
    this.water = '100.000đ/người',
    this.otherFees = 'Wifi, giữ xe miễn phí. Đặt cọc 1 tháng tiền phòng.',
    this.landlordId = 'owner-a',
    this.landlordName = 'Cô Hồng',
    this.status = RoomStatus.available,
    this.images = const [PhotoKind.room],
    this.localPhotos = const [],
    this.latitude = 10.7626,
    this.longitude = 106.6697,
    this.amenities = const [
      'Có nội thất',
      'Wifi riêng',
      'Máy lạnh',
      'Bếp riêng',
    ],
  });
  String get priceLabel => '${_money(price)}đ/tháng';
  Room copyWith({
    RoomStatus? status,
    String? landlordId,
    String? landlordName,
  }) => Room(
    id: id,
    title: title,
    district: district,
    price: price,
    area: area,
    floor: floor,
    match: match,
    type: type,
    address: address,
    description: description,
    electricity: electricity,
    water: water,
    otherFees: otherFees,
    amenities: amenities,
    images: images,
    localPhotos: localPhotos,
    latitude: latitude,
    longitude: longitude,
    status: status ?? this.status,
    landlordId: landlordId ?? this.landlordId,
    landlordName: landlordName ?? this.landlordName,
  );
}

String _money(int amount) => amount.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}.',
);

class Person {
  final String id, name, school, bio, gender, district;
  final int budget;
  final List<String> habits;
  final int age, match;
  final PhotoKind photo;
  final List<String> interests;
  const Person({
    required this.id,
    required this.name,
    required this.school,
    required this.bio,
    this.gender = 'Nữ',
    this.district = 'Quận 10',
    this.budget = 2500000,
    this.habits = const ['Gọn gàng', 'Không hút thuốc', 'Ngủ sớm'],
    this.age = 21,
    this.match = 91,
    this.photo = PhotoKind.woman,
    this.interests = const ['Nấu ăn', 'Đọc sách', 'Du lịch'],
  });
}

enum MessageDelivery { sent, sending, failed }

class ChatMessage {
  final String id;
  final MessageDelivery delivery;
  final String text, time;
  final bool mine, room;
  final String? roomId;
  const ChatMessage(
    this.text, {
    this.mine = false,
    this.time = '10:21',
    this.room = false,
    this.roomId,
    this.id = '',
    this.delivery = MessageDelivery.sent,
  });
  ChatMessage withDelivery(MessageDelivery value) => ChatMessage(
    text,
    id: id,
    delivery: value,
    mine: mine,
    time: time,
    room: room,
    roomId: roomId,
  );
}

class Conversation {
  final String id, name, time, subtitle;
  final String participantId, participantName;
  final String? roomId;
  final PhotoKind photo;
  final bool host;
  int unread;
  final List<ChatMessage> messages;
  Conversation({
    required this.id,
    required this.name,
    required this.subtitle,
    this.time = '09:22',
    this.participantId = '',
    this.participantName = '',
    this.roomId,
    this.photo = PhotoKind.man,
    this.host = false,
    this.unread = 0,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];
}

class Rental {
  final Room room;
  String code;
  final String id, tenantId, landlordId;
  final RentalStatus status;
  DateTime? codeExpiresAt;
  bool checkedIn;
  Rental(
    this.room,
    this.code, {
    String? id,
    this.tenantId = 'tenant-a',
    String? landlordId,
    this.status = RentalStatus.active,
    this.checkedIn = true,
    this.codeExpiresAt,
  }) : id = id ?? 'rental-${room.id}',
       landlordId = landlordId ?? room.landlordId;
}

class SwapRequest {
  final String roomId, reason;
  final String id, tenantId;
  final bool leaseholder;
  String status;
  final String targetDistrict, targetType, movingDate;
  final int budgetMax;
  final List<String> habits;
  String decisionNote = '';
  SwapRequest({
    required this.roomId,
    required this.reason,
    required this.leaseholder,
    this.status = 'Chờ duyệt',
    this.id = '',
    this.tenantId = 'tenant-a',
    this.targetDistrict = 'Quận 10',
    this.targetType = 'Studio',
    this.budgetMax = 4000000,
    this.movingDate = '',
    this.habits = const [],
  });
}

abstract final class DemoRepository {
  static const rooms = [
    Room(
      id: 'r1',
      title: 'Studio xanh gần Bách Khoa',
      district: 'Quận 10',
      price: 2800000,
    ),
    Room(
      id: 'r2',
      status: RoomStatus.pending,
      title: 'Phòng full nội thất, ban công lớn',
      district: 'Quận 3',
      price: 3200000,
      area: 25,
      floor: 2,
      match: 89,
    ),
    Room(
      id: 'r3',
      status: RoomStatus.rented,
      title: 'Phòng riêng gần ĐH Kinh tế',
      district: 'Quận 10',
      price: 2500000,
      area: 22,
      floor: 1,
      match: 87,
      type: 'Phòng trọ',
    ),
    Room(
      id: 'r4',
      landlordId: 'owner-b',
      landlordName: 'Nguyễn Văn Hùng',
      title: 'Căn hộ mini Thảo Điền',
      district: 'Thủ Đức',
      address: 'Khu vực Thảo Điền (địa chỉ minh họa)',
      description: 'Căn hộ mini tại Thảo Điền, có nội thất, bếp riêng và không gian sáng thoáng. Diện tích 30 m², ở tầng 4, phù hợp người đi làm hoặc hai người ở chung. Liên hệ Nguyễn Văn Hùng để hẹn xem phòng và xác nhận địa chỉ cụ thể.',
      price: 4500000,
      area: 30,
      floor: 4,
      match: 85,
      type: 'Căn hộ mini',
    ),
  ];
  static const people = [
    Person(
      id: 'p1',
      name: 'Nguyễn Hoài An',
      school: 'ĐH Kinh tế TP.HCM',
      bio: 'Thích sống gọn gàng, sạch sẽ, mê đồ ăn ngon và những chuyến đi khám phá. Mong tìm được bạn ở vui vẻ, tôn trọng không gian riêng và cùng nhau tạo nên một căn nhà thật chill!',
    ),
    Person(
      id: 'p2',
      name: 'Trần Minh',
      gender: 'Nam',
      district: 'Quận 3',
      school: 'ĐH Bách Khoa TP.HCM',
      age: 22,
      match: 89,
      photo: PhotoKind.man,
      bio: 'Hòa đồng, yêu cây xanh và thích đọc sách. Tìm bạn ở cùng gọn gàng, tôn trọng không gian riêng.',
    ),
    Person(
      id: 'p3',
      name: 'Lê Thu Hà',
      school: 'ĐH Kinh tế TP.HCM',
      match: 87,
      bio: 'Thích nấu ăn và tìm một không gian yên tĩnh để học tập.',
    ),
  ];
  static List<Conversation> conversations() => [
    Conversation(
      id: 'c1',
      participantName: 'Cô Hồng',
      participantId: 'owner-a',
      roomId: 'r1',
      name: 'Cô Hồng',
      subtitle: 'Dạ được bạn. Chiều thứ Bảy khoảng 14h thì cô ở nhà, bạn qua xem nhé.',
      photo: PhotoKind.host,
      host: true,
      unread: 2,
      messages: [
        const ChatMessage(
          'Chào bạn! Mình thấy bạn quan tâm đến studio này đúng không ạ?',
          time: '10:12',
        ),
        const ChatMessage(
          'Dạ đúng rồi ạ. Phòng này hiện còn trống không ạ?',
          mine: true,
          time: '10:14',
        ),
        const ChatMessage(
          'Dạ phòng vẫn còn trống nhé! Bạn có thể xem thêm thông tin phòng ở đây ạ:',
          time: '10:16',
          room: true,
          roomId: 'r1',
        ),
        const ChatMessage(
          'Phòng trông rất đẹp ạ! Mình có thể đến xem trực tiếp vào chiều thứ Bảy được không?',
          mine: true,
          time: '10:18',
        ),
        const ChatMessage(
          'Dạ được bạn ạ. Chiều thứ Bảy mình rảnh từ 14h, bạn qua xem thoải mái nhé. Mình sẽ đợi bạn ở dưới sảnh chung cư.',
          time: '10:20',
        ),
        const ChatMessage(
          'Dạ vâng, mình sẽ qua lúc 14h nhé. Cảm ơn bạn nhiều!',
          mine: true,
        ),
        const ChatMessage('Không có gì ạ! Hẹn gặp bạn nhé 😊'),
      ],
    ),
    Conversation(
      id: 'c2',
      participantId: 'p1',
      name: 'Nguyễn Hoài An',
      subtitle: 'Dạ vâng ạ, mình cảm ơn cô!',
      time: '09:15',
      photo: PhotoKind.woman,
      unread: 1,
    ),
    Conversation(
      id: 'c3',
      participantName: 'Cô Hồng',
      participantId: 'owner-a',
      roomId: 'r1',
      name: 'Studio xanh gần Bách Khoa',
      subtitle: 'Bạn: Dạ, mình có thể xem vào chiều thứ Bảy được không ạ?',
      time: 'Hôm qua',
      photo: PhotoKind.room,
    ),
    Conversation(
      id: 'c4',
      participantId: 'p2',
      name: 'Trần Minh',
      subtitle: 'Bạn có muốn tìm phòng ghép ở khu Bách Khoa không?',
      time: 'Hôm qua',
    ),
    Conversation(
      id: 'c5',
      participantName: 'Cô Hồng',
      participantId: 'owner-a',
      roomId: 'r3',
      name: 'Phòng trọ Quận 10',
      subtitle: 'Chủ trọ: Vâng, phòng này vẫn còn trống bạn nhé.',
      time: '2 ngày trước',
      photo: PhotoKind.room,
    ),
    Conversation(
      id: 'c6',
      participantId: 'p3',
      name: 'Lê Thu Hà',
      subtitle: 'Cuối tuần này mình đi xem phòng cùng nhau nhé?',
      time: '3 ngày trước',
      photo: PhotoKind.woman,
    ),
    Conversation(
      id: 'c7',
      participantName: 'Nguyễn Văn Hùng',
      participantId: 'owner-b',
      roomId: 'r4',
      name: 'Căn hộ mini Thảo Điền',
      subtitle: 'Bạn: Cảm ơn, mình sẽ cân nhắc thêm.',
      time: '5 ngày trước',
      photo: PhotoKind.room,
    ),
  ];
}
