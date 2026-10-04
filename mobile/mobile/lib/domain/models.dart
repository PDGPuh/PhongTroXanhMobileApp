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
