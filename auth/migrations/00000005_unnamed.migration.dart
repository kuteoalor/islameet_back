import 'dart:async';
import 'package:conduit_core/conduit_core.dart';


class Migration5 extends Migration { 
  @override
  Future upgrade() async {
   		database.alterColumn("_ChatRoom", "lastMessage", (c) {c.isNullable = true;});
  }
  
  @override
  Future downgrade() async {}
  
  @override
  Future seed() async {}
}
    