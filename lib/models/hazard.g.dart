// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hazard.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HazardAdapter extends TypeAdapter<Hazard> {
  @override
  final int typeId = 0;

  @override
  Hazard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hazard(
      response: fields[0] as String,
      date: fields[1] as DateTime,
      objectsDetected: (fields[2] as List).cast<String>(),
      threatLevel: fields[3] as int,
      synced: fields[4] as bool,
      localRecordingPath: fields[5] as String?,
      cloudRecordingUrl: fields[6] as String?,
      description: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Hazard obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.response)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.objectsDetected)
      ..writeByte(3)
      ..write(obj.threatLevel)
      ..writeByte(4)
      ..write(obj.synced)
      ..writeByte(5)
      ..write(obj.localRecordingPath)
      ..writeByte(6)
      ..write(obj.cloudRecordingUrl)
      ..writeByte(7)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HazardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
