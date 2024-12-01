import 'dart:async';
import 'package:conduit_core/conduit_core.dart';


class Migration3 extends Migration { 
  @override
  Future upgrade() async {
   		database.addColumn("_User", SchemaColumn("isMale", ManagedPropertyType.boolean, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: false));
		database.addColumn("_User", SchemaColumn("name", ManagedPropertyType.string, isPrimaryKey: false, autoincrement: false, isIndexed: false, isNullable: true, isUnique: false));
		database.deleteColumn("_User", "age");
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    