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
  bool? isApproved;

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
    this.isApproved,
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
    isApproved = json['is_approved'] ?? false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = name;
    data['phoneNumber'] = phoneNumber;
    data['email'] = email;
    data['userId'] = userId;
    data['address'] = address;
    if (openingHours != null) {
      data['openingHours'] = openingHours!.map((v) => v.toJson()).toList();
    }
    data['city'] = city;
    data['state'] = state;
    data['category'] = category;
    data['photoUrl'] = photoUrl;
    if (placedata != null) {
      data['placedata'] = placedata!.map((v) => v.toJson()).toList();
    }
    data['businessDescription'] = businessDescription;
    data['website'] = website;
    data['instagram'] = instagram;
    data['facebook'] = facebook;
    data['twitter'] = twitter;
    data['is_approved'] = isApproved;
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
    data['day'] = day;
    data['opensat'] = opensat;
    data['closesat'] = closesat;
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
    data['ques'] = ques;
    data['ans'] = ans;
    return data;
  }
}
