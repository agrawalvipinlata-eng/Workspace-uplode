class Bus {
  const Bus({
    required this.id,
    required this.busNumber,
    required this.plateNumber,
    this.capacity = 0,
    this.driverId,
    this.routeId,
    this.isActive = true,
  });

  final String id;
  final String busNumber; // e.g. "Bus 3"
  final String plateNumber; // e.g. "UK07 PA 1234"
  final int capacity;
  final String? driverId;
  final String? routeId;
  final bool isActive;

  factory Bus.fromMap(String id, Map<String, dynamic> map) => Bus(
        id: id,
        busNumber: (map['busNumber'] as String?) ?? '',
        plateNumber: (map['plateNumber'] as String?) ?? '',
        capacity: (map['capacity'] as num?)?.toInt() ?? 0,
        driverId: map['driverId'] as String?,
        routeId: map['routeId'] as String?,
        isActive: (map['isActive'] as bool?) ?? true,
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'busNumber': busNumber,
        'plateNumber': plateNumber,
        'capacity': capacity,
        'driverId': driverId,
        'routeId': routeId,
        'isActive': isActive,
      };
}
