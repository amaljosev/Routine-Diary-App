class Habit {
  final String? id;
  final String? habitName;
  final String? note;
  final String? habitIconId;
  final String? category;
  final String? habitStartAt;
  final String? habitTime;
  final String? habitEndAt;
  final String? habitRepeatValue;
  final String? repeatDays;
  final String? habitRemindTime;
  final String? habitColorId;
  final String? isCompleteToday;
  final String? goalValue;
  final String? goalCount;
  final String? goalCompletedCount;

  Habit({
    this.id,
    this.habitName,
    this.note,
    this.category,
    this.habitIconId,
    this.habitStartAt,
    this.habitTime,
    this.habitEndAt,
    this.habitRepeatValue,
    this.repeatDays,
    this.habitRemindTime,
    this.habitColorId,
    this.isCompleteToday,
    this.goalValue,
    this.goalCount,
    this.goalCompletedCount,
  });

  Habit copyWith({
    String? id,
    String? habitName,
    String? note,
    String? category,
    String? habitIconId,
    String? habitStartAt,
    String? habitTime,
    String? habitEndAt,
    String? habitRepeatValue,
    String? habitRemindTime,
    String? habitColorId,
    String? repeatDays,
    String? isCompleteToday,
    String? goalValue,
    String? goalCount,
    String? goalCompletedCount,
  }) {
    return Habit(
      id: id ?? this.id,
      habitName: habitName ?? this.habitName,
      note: note ?? this.note,
      category: category ?? this.category,
      habitIconId: habitIconId ?? this.habitIconId,
      habitStartAt: habitStartAt ?? this.habitStartAt,
      habitTime: habitTime ?? this.habitTime,
      habitEndAt: habitEndAt ?? this.habitEndAt,
      habitRemindTime: habitRemindTime ?? this.habitRemindTime,
      habitColorId: habitColorId ?? this.habitColorId,
      habitRepeatValue: habitRepeatValue ?? this.habitRepeatValue,
      repeatDays: repeatDays ?? this.repeatDays,
      isCompleteToday: isCompleteToday ?? this.isCompleteToday,
      goalValue: goalValue ?? this.goalValue,
      goalCount: goalCount ?? this.goalCount,
      goalCompletedCount: goalCompletedCount ?? this.goalCompletedCount,
    );
  }

  // Convert Habit → Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitName': habitName,
      'note': note,
      'category': category,
      'habitIconId': habitIconId,
      'habitStartAt': habitStartAt,
      'habitTime': habitTime,
      'habitEndAt': habitEndAt,
      'habitRepeatValue': habitRepeatValue,
      'repeatDays': repeatDays,
      'habitRemindTime': habitRemindTime,
      'habitColorId': habitColorId,
      'isCompleteToday': isCompleteToday,
      'goalValue': goalValue,
      'goalCount': goalCount,
      'goalCompletedCount': goalCompletedCount,
    };
  }

  // Convert Map → Habit
  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'],
      habitName: map['habitName'],
      note: map['note'],
      category: map['category'],
      habitIconId: map['habitIconId'],
      habitStartAt: map['habitStartAt'],
      habitTime: map['habitTime'],
      habitEndAt: map['habitEndAt'],
      habitRepeatValue: map['habitRepeatValue'],
      repeatDays: map['repeatDays'],
      habitRemindTime: map['habitRemindTime'],
      habitColorId: map['habitColorId'],
      isCompleteToday: map['isCompleteToday'],
      goalValue: map['goalValue'],
      goalCount: map['goalCount'],
      goalCompletedCount: map['goalCompletedCount'],
    );
  }
}
