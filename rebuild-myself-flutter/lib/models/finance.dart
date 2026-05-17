class FinanceMentalLog {
  final int? id;
  final int? userId;
  final int? moneyPressure;
  final double? gapAmount;
  final String? incomeRecord;
  final int? escapeState;
  final int? actionMinutes;
  final String? recordDate;
  final String? createTime;

  FinanceMentalLog({
    this.id,
    this.userId,
    this.moneyPressure,
    this.gapAmount,
    this.incomeRecord,
    this.escapeState,
    this.actionMinutes,
    this.recordDate,
    this.createTime,
  });

  factory FinanceMentalLog.fromJson(Map<String, dynamic> json) =>
      FinanceMentalLog(
        id: json['id'],
        userId: json['userId'] ?? json['user_id'],
        moneyPressure: json['moneyPressure'] ?? json['money_pressure'] ?? json['pressure'],
        gapAmount: (json['gapAmount'] ?? json['gap_amount'] ?? 0).toDouble(),
        incomeRecord: json['incomeRecord'] ?? json['income_record'] ?? json['income']?.toString(),
        escapeState: json['escapeState'] ?? json['escape_state'] ?? json['isEscaping'] ?? (json['is_escaping'] == true ? 1 : 0),
        actionMinutes: json['actionMinutes'] ?? json['action_minutes'],
        recordDate: json['recordDate'] ?? json['record_date'] ?? json['date'],
        createTime: json['createTime'] ?? json['create_time'],
      );

  Map<String, dynamic> toJson() => {
        if (moneyPressure != null) 'pressure': moneyPressure,
        if (gapAmount != null) 'gapAmount': gapAmount,
        if (incomeRecord != null) 'income': incomeRecord,
        if (escapeState != null) 'isEscaping': escapeState == 1,
        if (actionMinutes != null) 'actionMinutes': actionMinutes,
        if (recordDate != null) 'date': recordDate,
      };

  bool get isEscaping => escapeState == 1;
}
