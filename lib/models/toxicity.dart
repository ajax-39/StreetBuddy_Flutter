class Toxicity {
  bool? identityAttack;
  bool? insult;
  bool? obscene;
  bool? severeToxicity;
  bool? sexualExplicit;
  bool? threat;
  bool? toxicity;

  Toxicity(
      {this.identityAttack,
      this.insult,
      this.obscene,
      this.severeToxicity,
      this.sexualExplicit,
      this.threat,
      this.toxicity});

  Toxicity.fromJson(Map<String, dynamic> json) {
    identityAttack = json['identity_attack'];
    insult = json['insult'];
    obscene = json['obscene'];
    severeToxicity = json['severe_toxicity'];
    sexualExplicit = json['sexual_explicit'];
    threat = json['threat'];
    toxicity = json['toxicity'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['identity_attack'] = this.identityAttack;
    data['insult'] = this.insult;
    data['obscene'] = this.obscene;
    data['severe_toxicity'] = this.severeToxicity;
    data['sexual_explicit'] = this.sexualExplicit;
    data['threat'] = this.threat;
    data['toxicity'] = this.toxicity;
    return data;
  }
}
