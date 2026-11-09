class RobotState {
  const RobotState({
    this.status = 'Offline',
    this.emotion = 'CALM',
    this.action = 'idle_wait',
    this.energy = 0,
    this.tracking = false,
  });

  final String status;
  final String emotion;
  final String action;
  final int energy;
  final bool tracking;

  factory RobotState.fromJson(Map<String, dynamic> json) {
    return RobotState(
      status: json['status']?.toString() ?? 'Online',
      emotion: json['emotion']?.toString().toUpperCase() ?? 'CALM',
      action: json['action']?.toString() ?? 'idle_wait',
      energy: (json['energy'] as num?)?.round() ?? 0,
      tracking: json['tracking'] == true,
    );
  }

  RobotState copyWith({String? status}) => RobotState(
    status: status ?? this.status,
    emotion: emotion,
    action: action,
    energy: energy,
    tracking: tracking,
  );
}
