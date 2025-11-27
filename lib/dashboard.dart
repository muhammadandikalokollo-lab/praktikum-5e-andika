import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'main.dart';

// ================= MODEL =================
class Item {
  final int id;
  final String nama;
  final double harga;

  Item({
    required this.id,
    required this.nama,
    required this.harga,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json["id"],
      nama: json["nama"],
      harga: double.parse(json["harga"].toString()),
    );
  }
}

// ================= DASHBOARD PAGE =================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Item> items = [];
  final String baseUrl = "http://127.0.0.1:8000/api/barang";

  // ================= API GET =================
  Future<void> fetchBarang() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      setState(() {
        items = data.map((e) => Item.fromJson(e)).toList();
      });
    }
  }

  // ================= API POST =================
  Future<void> createBarang(String nama, String harga) async {
    await http.post(
      Uri.parse(baseUrl),
      body: {
        "nama": nama,
        "harga": harga,
      },
    );
    fetchBarang();
  }

  // ================= API UPDATE =================
  Future<void> updateBarang(int id, String nama, String harga) async {
    await http.put(
      Uri.parse("$baseUrl/$id"),
      body: {
        "nama": nama,
        "harga": harga,
      },
    );
    fetchBarang();
  }

  // ================= API DELETE =================
  Future<void> deleteBarang(int id) async {
    await http.delete(Uri.parse("$baseUrl/$id"));
    fetchBarang();
  }

  @override
  void initState() {
    super.initState();
    fetchBarang();
  }

  // ================= FORMAT RUPIAH =================
  String rupiah(double number) {
    return "Rp ${number.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => "${m[1]}.",
    )}";
  }

  // ================= FORM TAMBAH & EDIT =================
  void showForm({Item? item}) {
    final namaController = TextEditingController(text: item?.nama ?? "");
    final hargaController =
        TextEditingController(text: item?.harga.toString() ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          item == null ? "Tambah Barang Baru" : "Edit Barang",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: InputDecoration(
                labelText: "Nama Barang",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: hargaController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Harga Barang",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Batal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text(item == null ? "Tambah" : "Update"),
            onPressed: () {
              if (item == null) {
                createBarang(namaController.text, hargaController.text);
              } else {
                updateBarang(item.id, namaController.text, hargaController.text);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ================= DELETE CONFIRM =================
  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Konfirmasi Hapus"),
        content: Text("Yakin ingin menghapus barang ini?"),
        actions: [
          TextButton(
            child: Text("Batal"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Hapus"),
            onPressed: () {
              deleteBarang(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard Barang"),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginPage()),
              );
            },
          )
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
        onPressed: () => showForm(),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      "Tidak ada data",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor:
                        WidgetStateProperty.all(Colors.grey.shade300),
                    columns: const [
                      DataColumn(label: Text("No")),
                      DataColumn(label: Text("Nama Barang")),
                      DataColumn(label: Text("Harga")),
                      DataColumn(label: Text("Aksi")),
                    ],
                    rows: items.asMap().entries.map((entry) {
                      final index = entry.key + 1;
                      final item = entry.value;

                      return DataRow(
                        cells: [
                          DataCell(Text(index.toString())),
                          DataCell(Text(item.nama)),
                          DataCell(Text(rupiah(item.harga))),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => showForm(item: item),
                                ),
                                IconButton(
                                  icon:
                                      Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => confirmDelete(item.id),
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ),
    );
  }
}
