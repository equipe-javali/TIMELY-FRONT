class CartaoModel {
  final String codigo;
  final int timestamp;
  final String? nome;
  final bool? autorizado;

  CartaoModel({
    required this.codigo,
    required this.timestamp,
    this.nome,
    this.autorizado,
  });

  factory CartaoModel.fromJson(Map<String, dynamic> json) {
    return CartaoModel(
      codigo: json['codigo'],
      timestamp: json['timestamp'],
      nome: json['nome'],
      autorizado: json['autorizado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'timestamp': timestamp,
      if (nome != null) 'nome': nome,
      if (autorizado != null) 'autorizado': autorizado,
    };
  }
}