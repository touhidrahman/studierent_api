import 'package:connection_pool/connection_pool.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'dart:async';


class DbPool extends ConnectionPool<Db>
{
  String uri;

  DbPool(String this.uri, int poolSize) : super(poolSize);

  // override methods in connection pool
  void closeConnection(Db conn)
  {
    conn.close();
  }

  Future<Db> openNewConnection()
  {
    var conn = new Db(uri);
    return conn.open().then((_) => conn);
  }
}