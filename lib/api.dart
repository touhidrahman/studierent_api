import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';
import 'package:rpc/rpc.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dartson/dartson.dart';
import 'entities.dart';

const DB_URI = "mongodb://localhost:27017/studierent";
final dson = new Dartson.JSON();

/**
 * Uses refection (mirrors) to produce a Map (array) from an object's
 * variables. Making the variable name the key, and it's value the
 * value.
 */
Map objectToMap(Object object)
{
  // Mirror the particular instance (rather than the class itself)
  InstanceMirror instanceMirror = reflect(object);
  Map dataMapped = new Map();

  // Mirror the instance's class (type) to get the declarations
  for (var declaration in instanceMirror.type.declarations.values)
  {
    // If declaration is a type of variable, map variable name and value
    if (declaration is VariableMirror)
    {
      String variableName = MirrorSystem.getName(declaration.simpleName);
      String variableValue = instanceMirror.getField(declaration.simpleName).reflectee;

      dataMapped[variableName] = variableValue;
    }
  }

  return dataMapped;
}


@ApiClass(version: 'v1')
class Api {
  Api();

  @ApiResource()
  UsersResource usersResource = new UsersResource();

}


class UsersResource{
  @ApiMethod(path: 'users')
  Future<List<User>> getUsers() async {

    Db db = new Db(DB_URI);
    await db.open();
    var collection = db.collection('user');
    List result = [];
    await collection.find().forEach((user) {
      result.add(dson.map(user, new User()));
    });
    await db.close();
    return result;
  }


  @ApiMethod(path: 'users', method: 'POST')
  Future<User> addUser(User request) async {

    Db db = new Db(DB_URI);
    await db.open();
    var collection = db.collection('user');
    await collection.insert(objectToMap(request));
    await db.close();
    return request;
  }


  @ApiMethod(path: 'users/{email}', method: 'DELETE')
  Future<VoidMessage> deleteUser(String email) async
  {
    Db db = new Db(DB_URI);
    await db.open();
    var collection = db.collection('user');
    await collection.remove(where.eq("email", email));
    await db.close();
  }


  @ApiMethod(path: 'users/{email}', method: 'PUT')
  Future<VoidMessage> updateUser(String email, User request) async {
    Db db = new Db(DB_URI);
    await db.open();
    var collection = db.collection('user');
    var res = await collection.findOne({"email":email});
    res["name"] ??= request.name;
    res["contactNo"] ??= request.contactNo;
    res["address"] ??= request.address;
    res["city"] ??= request.city;
    res["country"] ??= request.country;
    res["gender"] ??= request.gender;
    res["resetKey"] ??= request.resetKey;
    await collection.save(res);
    await db.close();
  }

}

