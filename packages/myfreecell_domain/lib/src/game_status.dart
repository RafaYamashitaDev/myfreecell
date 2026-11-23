/// Derived status of a stable snapshot (GD-STATE-01 item 4, GD-CMP-01).
///
/// [inProgress] means the foundations are not complete. [completed] means
/// every foundation is at level 13. There is no other lifecycle state.
///
/// There is no persisted numeric or string representation. The enum index and
/// the name are not compatibility contracts. A stable snapshot derives this
/// from its board. It is not stored independently.
enum GameStatus {
  /// The foundations do not yet hold every card.
  inProgress,

  /// Every foundation is at level 13.
  completed,
}
