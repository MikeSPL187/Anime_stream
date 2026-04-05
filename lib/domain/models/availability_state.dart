enum AvailabilityStatus {
  available,
  scheduled,
  unavailable,
  regionRestricted,
  subscriptionRequired,
}

class AvailabilityState {
  const AvailabilityState({
    required this.status,
    this.availableFrom,
    this.expiresAt,
    this.reason,
  });

  const AvailabilityState.available()
      : status = AvailabilityStatus.available,
        availableFrom = null,
        expiresAt = null,
        reason = null;

  final AvailabilityStatus status;
  final DateTime? availableFrom;
  final DateTime? expiresAt;
  final String? reason;
}
