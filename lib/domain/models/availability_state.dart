import 'package:freezed_annotation/freezed_annotation.dart';

part 'availability_state.freezed.dart';
part 'availability_state.g.dart';

enum AvailabilityStatus {
  available,
  scheduled,
  unavailable,
  regionRestricted,
  subscriptionRequired,
}

@freezed
class AvailabilityState with _$AvailabilityState {
  const factory AvailabilityState({
    @Default(AvailabilityStatus.available) AvailabilityStatus status,
    DateTime? availableFrom,
    DateTime? expiresAt,
    String? reason,
  }) = _AvailabilityState;

  factory AvailabilityState.fromJson(Map<String, dynamic> json) =>
      _$AvailabilityStateFromJson(json);
}
