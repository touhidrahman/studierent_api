library studierent_model;

import 'dart:async';
import 'dart:mirrors';
import 'package:mongo_dart/mongo_dart.dart';
import 'db_pool.dart';
import 'package:s_api_v2/entities.dart';
import 'package:connection_pool/connection_pool.dart';

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

class Model
{
  DbPool _dbPool;

  Model(String _dbName, String _dbUrl, int _dbPoolSize)
  {
    _dbPool = new DbPool(_dbUrl + _dbName, _dbPoolSize);
  }


  dynamic mapToEntity(cleanObject, Map document)
  {
    var reflection = reflect(cleanObject);
    document['id'] = document['id'].toString();
    document.remove('id');
    document.forEach((k, v) {
      reflection.setField(new Symbol(k), v);
    });
    return cleanObject;
  }

  Map entityToMap(Object object)
  {
    var reflection = reflect(object);
    Map target = new Map();
    var type = reflection.type;
    while(type != null)
    {
      type.declarations.values.forEach((item){
        if (item is VariableMirror){
          VariableMirror value = item;
          if (!value.isFinal){
            target[MirrorSystem.getName(value.simpleName)]
            = reflection.getField(value.simpleName).reflectee;
          }
        }
      });
      type = type.superclass;
    }
    return target;
  }

  Map entityToMongo(object)
  {
    Map item = entityToMap(object);
    // convert only on write to mongo
    item['_id'] = item['id']; // mongo to dart
    item.remove('id');
    return item;
  }

  dynamic getInstance(Type t)
  {
    MirrorSystem mirrors = currentMirrorSystem();
    LibraryMirror lm = mirrors.libraries.values.firstWhere(
            (LibraryMirror lm) => lm.qualifiedName == new Symbol('app_entities')
    );
    ClassMirror cm = lm.declarations[new Symbol(t.toString())];
    InstanceMirror im = cm.newInstance(new Symbol(''), []);
    return im.reflectee;
  }

  // create
  Future<BaseEntity> createByItem(BaseEntity item)
  {
    assert(item.id == null);
    item.id = new ObjectId().toString();
    return _dbPool.getConnection().then((ManagedConnection mc){
      Db db = mc.conn;
      DbCollection coll = db.collection(item.collectionKey);
      Map aMap = entityToMongo(item);
      return coll.insert(aMap).then((status){
        _dbPool.releaseConnection(mc);
        return (status['ok'] == 1) ? item : null;
      });
    });
  }

  // update
  Future<BaseEntity> updateItem(BaseEntity item) async
  {
    assert(item.id != null);
    item.id = new ObjectId().toString();
    return _dbPool.getConnection().then((ManagedConnection mc){
      Db db = mc.conn;
      DbCollection coll = db.collection(item.collectionKey);
      Map selector = {'_id':item.id};
      Map newItem = entityToMongo(item);
      return coll.update(selector, newItem).then((status){
        _dbPool.releaseConnection(mc);
        return status;
      });
    });
  }

  // Delete
  Future<Map> deleteByItem(BaseEntity item) async
  {
    assert(item.id != null);
    return _dbPool.getConnection().then((ManagedConnection mc){
      Db db = mc.conn;
      DbCollection coll = db.collection(item.collectionKey);
      Map aMap = entityToMongo(item);
      return coll.remove(aMap).then((status){
        _dbPool.releaseConnection(mc);
        return status;
      });
    });
  }

  // Read
  Future<List> _getCollection(String collName, [Map query = null]) {
    return _dbPool.getConnection().then((ManagedConnection mc) async {
      DbCollection coll = new DbCollection(mc.conn, collName);
      return coll.find(query).toList().then((List<Map> maps){
        _dbPool.releaseConnection(mc);
        return maps;
      });
    });
  }

  // Read Where
  Future<List> _getCollectionWhere(String collName, fieldName, values) {
    return _dbPool.getConnection().then((ManagedConnection mc) async {
      DbCollection coll = new DbCollection(mc.conn, collName);
      SelectorBuilder builder = where.oneFrom(fieldName, values);
      return coll.find(builder).toList().then((map){
        _dbPool.releaseConnection(mc);
        return map;
      });
    });
  }

  // refresh an item from db
  Future<BaseEntity> readItemByItem(BaseEntity matcher) async {
    assert(matcher.id != null);
    Map query = {'_id': matcher.id};
    BaseEntity bDto;
    return _getCollection(matcher.collectionKey, query).then((items){
      bDto = mapToEntity(getInstance(matcher.runtimeType), items.first);
      return bDto;
    });
  }

  // get a collection by type and field values
  Future<List> readCollectionByTypeWhere(t, fieldName, values) async {
    List list = new List();
    BaseEntity freshInstance = getInstance(t);
    return _getCollectionWhere(freshInstance.collectionKey, fieldName, values)
        .then((items) {
      items.forEach((item){
        list.add(mapToEntity(getInstance(t), item));
      });
      return list;
    });
  }

  // get a collection based off a type and optional query
//  Future<List> readCollectionByType() async {
//    List list = new List();
//    return _getCollection(new User().collectionKey)
//        .then((items) {
//      items.forEach((item){
//        list.add(mapToEntity(User, item));
//      });
//      return list;
//    });
//  }
  Future<List> readCollectionByType(t, [Map query = null]) async {
    List list = new List();
    BaseEntity freshInstance = getInstance(t);
    return _getCollection(freshInstance.collectionKey, query)
        .then((items) {
      items.forEach((item){
        list.add(mapToEntity(getInstance(t), item));
      });
      return list;
    });
  }

  // Drop
  Future<Map> dropDatabase() async {
    var connection = await _dbPool.getConnection();
    var db = connection.conn;
    Map status = await db.drop();
    return status;
  }
}