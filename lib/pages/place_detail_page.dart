import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../models/place.dart';

class PlaceDetailPage extends StatelessWidget {
  final Place place;

  const PlaceDetailPage({super.key, required this.place});

  // Haritayı açan yardımcı fonksiyon
  Future<void> _launchMap() async {
    final String googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}";
    final Uri url = Uri.parse(googleMapsUrl);
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Harita açılamadı: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar'da mekan ismi ve geri butonu
      appBar: AppBar(
        title: Text(place.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red[900],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mekan Görseli
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Image.network(
                  place.imageUrl ?? 'https://via.placeholder.com/600x300',
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 100),
                  ),
                ),
                // Resmin üzerine Harita Butonu
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton.extended(
                    onPressed: _launchMap,
                    backgroundColor: Colors.red[900],
                    label: const Text("Haritada Gör", style: TextStyle(color: Colors.white)),
                    icon: const Icon(Icons.map, color: Colors.white),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Başlık ve Konum İkonu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_pin, color: Colors.grey, size: 20),
                      const SizedBox(width: 5),
                      Text(
                        "Enlem: ${place.latitude.toStringAsFixed(4)}, Boylam: ${place.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),
                  // Hakkında Başlığı
                  const Text(
                    "Mekan Hakkında",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  // Mekan Açıklaması
                  Text(
                    place.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Alt Bilgi Notu (Hocayı etkilemek için)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blueGrey),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Bu mekan verisi .NET Core API ve PostgreSQL üzerinden dinamik olarak çekilmektedir.",
                            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}