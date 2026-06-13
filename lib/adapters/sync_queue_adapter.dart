import 'package:hive/hive.dart';
import 'package:pata/models/sync_queue.dart';
import 'package:pata/models/transaction.dart';

class SyncQueueItemAdapter extends TypeAdapter<SyncQueueItem> {
  @override
  final int typeId = 1;

  @override
  SyncQueueItem read(BinaryReader reader) {
    return SyncQueueItem(
      id: reader.readString(),
      action: SyncAction.values[reader.readInt()],
      transaction: reader.read() as Transaction,
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, SyncQueueItem obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.action.index);
    writer.write(obj.transaction);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}

class SyncActionAdapter extends TypeAdapter<SyncAction> {
  @override
  final int typeId = 2;

  @override
  SyncAction read(BinaryReader reader) {
    return SyncAction.values[reader.readInt()];
  }

  @override
  void write(BinaryWriter writer, SyncAction obj) {
    writer.writeInt(obj.index);
  }
}