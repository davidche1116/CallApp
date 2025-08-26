class CallRecord {
  final String phone;
  final DateTime time;

  final int id;
  final String name;
  final String photo;

  CallRecord(
    this.phone,
    this.time, {
    this.id = 0,
    this.name = '',
    this.photo = '',
  });

  // Convert into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {'PHONE': phone, 'TIME': time.toString().substring(0, 19)};
  }

  // Implement toString to make it easier to see information about
  // each when using the print statement.
  @override
  String toString() {
    return 'CALL_RECORD{ID: $id, PHONE: $phone, TIME: $time, NAME: $name, PHOTO: $photo}';
  }
}
