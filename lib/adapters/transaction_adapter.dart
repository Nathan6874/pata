import 'package:hive/hive.dart';
import '../models/transaction.dart';

class TransactionAdapter extends TypeAdapter<Transaction> {
  @override
  final int typeId = 0;

  @override
  Transaction read(BinaryReader reader) {
    return Transaction(
      id: reader.readString(),
      montant: reader.readInt(),
      motif: reader.readString(),
      categorie: reader.readString(),
      type: TransactionType.values[reader.readInt()],
      date: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      synced: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Transaction obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.montant);
    writer.writeString(obj.motif);
    writer.writeString(obj.categorie);
    writer.writeInt(obj.type.index);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeBool(obj.synced);
  }
}