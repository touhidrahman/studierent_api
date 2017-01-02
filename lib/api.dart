library studierent_api;

import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';
import 'package:rpc/rpc.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dartson/dartson.dart';
import 'entities.dart';
import 'model.dart';

const DB_URI = "mongodb://localhost:27017/studierent";
final dson = new Dartson.JSON();



/// API Class, Handles all request routing
@ApiClass(version: 'v1')
class Api {
  Api();

  @ApiResource()
  UsersResource usersResource = new UsersResource();

}

/// User routes group
class UsersResource{

  Model model = new Model("studierent", "mongodb://localhost:27017/", 10);

  @ApiMethod(path: 'users')
  Future<List<User>> getUsers() async {
    return model.readCollectionByType(User);
  }
//  Future<List<User>> getUsers() async {
//
//    Db db = new Db(DB_URI);
//    await db.open();
//    var collection = db.collection('user');
//    List result = [];
//    await collection.find().forEach((user) {
//      result.add(dson.map(user, new User()));
//    });
//    await db.close();
//    return result;
//  }


  @ApiMethod(path: 'users', method: 'POST')
  Future<VoidMessage> addUser(User request) async {

    Db db = new Db(DB_URI);
    await db.open();
    var collection = db.collection('user');
    collection.insert(objectToMap(request));
  }
}



