// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reflection.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReflectionAdapter extends TypeAdapter<Reflection> {
  @override
  final int typeId = 1;

  @override
  Reflection read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reflection(
      text: fields[0] as String,
      date: fields[1] as DateTime,
      synced: fields[2] as bool,
      localAudioPath: fields[3] as String?,
      cloudAudioUrl: fields[4] as String?,
      tags: (fields[5] as List).cast<String>(),
      transcript: fields[6] as String?,
      approved: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Reflection obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.text)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.synced)
      ..writeByte(3)
      ..write(obj.localAudioPath)
      ..writeByte(4)
      ..write(obj.cloudAudioUrl)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.transcript)
      ..writeByte(7)
      ..write(obj.approved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReflectionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
