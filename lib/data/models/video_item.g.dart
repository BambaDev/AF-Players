// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VideoItemAdapter extends TypeAdapter<VideoItem> {
  @override
  final int typeId = 1;

  @override
  VideoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoItem(
      id: fields[0] as String,
      title: fields[1] as String,
      videoPath: fields[2] as String,
      subtitlePath: fields[3] as String?,
      sourceType: fields[4] as VideoSourceType,
      addedAt: fields[5] as DateTime,
      lastPositionMs: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, VideoItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.videoPath)
      ..writeByte(3)
      ..write(obj.subtitlePath)
      ..writeByte(4)
      ..write(obj.sourceType)
      ..writeByte(5)
      ..write(obj.addedAt)
      ..writeByte(6)
      ..write(obj.lastPositionMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VideoSourceTypeAdapter extends TypeAdapter<VideoSourceType> {
  @override
  final int typeId = 0;

  @override
  VideoSourceType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VideoSourceType.local;
      case 1:
        return VideoSourceType.remote;
      default:
        return VideoSourceType.local;
    }
  }

  @override
  void write(BinaryWriter writer, VideoSourceType obj) {
    switch (obj) {
      case VideoSourceType.local:
        writer.writeByte(0);
        break;
      case VideoSourceType.remote:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoSourceTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
