class CartaoModel {
  final String codigo;
  final int timestamp;
  final String tipo;  
  final String? nome;
  final bool? autorizado;

  CartaoModel({
    required this.codigo,
    required this.timestamp,
    required this.tipo,
    this.nome,
    this.autorizado,
  });

   
  factory CartaoModel.fromJson(Map<String, dynamic> json) {
    return CartaoModel(
      codigo: json['codigo'],
      timestamp: json['timestamp'],      
      tipo: json['tipo'] ?? 'entrada',
      nome: json['nome'],
      autorizado: json['autorizado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'timestamp': timestamp,
      'tipo': tipo,
      if (nome != null) 'nome': nome,
      if (autorizado != null) 'autorizado': autorizado,
    };
  }
}