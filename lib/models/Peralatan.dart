class Peralatan {
  final String id;
  final String nama;
  final String kategori;
  final int harga;
  final int kapasitas;
  final int stok;
  final String lokasi;
  final String deskripsi;
  final String image;
  final int tahunDibeli;

  Peralatan({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.harga,
    required this.kapasitas,
    required this.stok,
    required this.lokasi,
    required this.deskripsi,
    required this.image,
    required this.tahunDibeli,
  });

  factory Peralatan.fromJson(Map<String, dynamic> json) {
    return Peralatan(
      id: json['id'] as String,
      nama: json['nama'] as String,
      kategori: json['kategori'] as String,
      harga: json['harga'] is int
          ? json['harga'] as int
          : int.tryParse(json['harga'].toString()) ?? 0,
      kapasitas: json['kapasitas'] is int
          ? json['kapasitas'] as int
          : int.tryParse(json['kapasitas'].toString()) ?? 0,
      stok: json['stok'] is int
          ? json['stok'] as int
          : int.tryParse(json['stok'].toString()) ?? 0,
      lokasi: json['lokasi'] as String,
      deskripsi: json['deskripsi'] as String,
      image: json['image'] as String,
      tahunDibeli: json['tahun_dibeli'] is int
          ? json['tahun_dibeli'] as int
          : int.tryParse(json['tahun_dibeli'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'kategori': kategori,
      'harga': harga,
      'kapasitas': kapasitas,
      'stok': stok,
      'lokasi': lokasi,
      'deskripsi': deskripsi,
      'image': image,
      'tahun_dibeli': tahunDibeli,
    };
  }

  @override
  String toString() {
    return 'Peralatan(id: \$id, nama: \$nama, kategori: \$kategori, tahunDibeli: \$tahunDibeli)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Peralatan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
