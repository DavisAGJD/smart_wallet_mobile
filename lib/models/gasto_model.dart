class Gasto {
  final String descripcion;
  final double monto;

  Gasto({required this.descripcion, required this.monto});

  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      descripcion: json['descripcion'],
      monto: json['monto'].toDouble(),
    );
  }
}
