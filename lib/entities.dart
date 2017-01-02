library app_entities;

import 'package:dartson/dartson.dart';

class BaseEntity{
  String id;
  String collectionKey;
}


@Entity()
class User extends BaseEntity{
  String collectionKey = "user";
  String name;
//  String email;
//  String password;
//  String gender;
//  String address;
//  String city;
//  String country;
//  String contactNo;
//  String resetKey;
//  bool status;
}