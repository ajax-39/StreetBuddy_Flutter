class VendorModel {
  String? id;
  String? name;
  String? phoneNumber;
  String? email;
  String? address;
  List<OpeningHours>? openingHours;
  String? city;
  String? state;
  String? category;
  List<String>? photoUrl;
  String? userId;
  List<Placedata>? placedata;
  String? businessDescription;
  String? website;
  String? instagram;
  String? facebook;
  String? twitter;

  VendorModel({
    this.id,
    this.name,
    this.phoneNumber,
    this.email,
    this.address,
    this.openingHours,
    this.city,
    this.state,
    this.category,
    this.photoUrl,
    this.userId,
    this.placedata,
    this.businessDescription,
    this.website,
    this.instagram,
    this.facebook,
    this.twitter,
  });

  VendorModel.fromJson(String id, Map<String, dynamic> json) {
    this.id = id;
    name = json['name'];
    phoneNumber = json['phoneNumber'];
    email = json['email'];
    address = json['address'];
    if (json['openingHours'] != null) {
      openingHours = <OpeningHours>[];
      json['openingHours'].forEach((v) {
        openingHours!.add(new OpeningHours.fromJson(v));
      });
    }
    city = json['city'];
    state = json['state'];
    category = json['category'];
    photoUrl = List<String>.from(json['photoUrl'] ?? []);
    userId = json['userId'];
    if (json['placedata'] != null) {
      placedata = <Placedata>[];
      json['placedata'].forEach((v) {
        placedata!.add(new Placedata.fromJson(v));
      });
    }
    businessDescription = json['businessDescription'];
    website = json['website'];
    instagram = json['instagram'];
    facebook = json['facebook'];
    twitter = json['twitter'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    data['phoneNumber'] = this.phoneNumber;
    data['email'] = this.email;
    data['userId'] = this.userId;
    data['address'] = this.address;
    if (this.openingHours != null) {
      data['openingHours'] = this.openingHours!.map((v) => v.toJson()).toList();
    }
    data['city'] = this.city;
    data['state'] = this.state;
    data['category'] = this.category;
    data['photoUrl'] = this.photoUrl;
    if (this.placedata != null) {
      data['placedata'] = this.placedata!.map((v) => v.toJson()).toList();
    }
    data['businessDescription'] = this.businessDescription;
    data['website'] = this.website;
    data['instagram'] = this.instagram;
    data['facebook'] = this.facebook;
    data['twitter'] = this.twitter;
    return data;
  }
}

class OpeningHours {
  String? day;
  String? opensat;
  String? closesat;

  OpeningHours({this.day, this.opensat, this.closesat});

  OpeningHours.fromJson(Map<String, dynamic> json) {
    day = json['day'];
    opensat = json['opensat'];
    closesat = json['closesat'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['day'] = this.day;
    data['opensat'] = this.opensat;
    data['closesat'] = this.closesat;
    return data;
  }
}

class Placedata {
  String? ques;
  String? ans;

  Placedata({this.ques, this.ans});

  Placedata.fromJson(Map<String, dynamic> json) {
    ques = json['ques'];
    ans = json['ans'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['ques'] = this.ques;
    data['ans'] = this.ans;
    return data;
  }
}
