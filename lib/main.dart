import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:share_plus/share_plus.dart';

void main() => runApp(DuppliFilterApp());

class DuppliFilterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DuppliFilter',
      home: DuppliFilterHome(),
    );
  }
}

class DuppliFilterHome extends StatefulWidget {
  @override
  _DuppliFilterHomeState createState() => _DuppliFilterHomeState();
}

class _DuppliFilterHomeState extends State<DuppliFilterHome> {
  List<PlatformFile> images = [];
  List<PlatformFile> filtered = [];
  final int phashThreshold = 8;
  final double pixelDiffThreshold = 100;

  Future<void> pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result != null) {
      setState(() => images = result.files);
      await analyze();
    }
  }

  Future<void> analyze() async {
    List<PlatformFile> uniques = [];
    List<PlatformFile> dups = [];

    for (final file in images) {
      final bytes1 = await File(file.path!).readAsBytes();
      final decoded1 = img.decodeImage(bytes1);
      if (decoded1 == null) continue;
      final resized1 = img.copyResize(decoded1, width: 64, height: 64);

      bool found = false;
      for (final other in uniques) {
        final bytes2 = await File(other.path!).readAsBytes();
        final decoded2 = img.decodeImage(bytes2);
        if (decoded2 == null) continue;
        final resized2 = img.copyResize(decoded2, width: 64, height: 64);

        final diff = compareImages(resized1, resized2);
        if (diff < pixelDiffThreshold) {
          found = true;
          break;
        }
      }
      if (found) {
        dups.add(file);
      } else {
        uniques.add(file);
      }
    }

    setState(() => filtered = uniques);
  }

  double compareImages(img.Image a, img.Image b) {
    int sum = 0;
    for (int y = 0; y < a.height; y++) {
      for (int x = 0; x < a.width; x++) {
        final p1 = a.getPixel(x, y);
        final p2 = b.getPixel(x, y);
        sum += (img.getLuminance(p1) - img.getLuminance(p2)).abs();
      }
    }
    return sum / (a.width * a.height);
  }

  void shareFiles(List<PlatformFile> files) {
    final paths = files.map((f) => f.path!).toList();
    Share.shareFiles(paths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DuppliFilter')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: pickImages,
              child: Text('Seleziona immagini'),
            ),
            if (images.isNotEmpty)
              Column(children: [
                SizedBox(height: 20),
                Text('Trovate ${images.length - filtered.length} immagini troppo simili.'),
                Text("Vuoi filtrare prima dell'invio?"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => shareFiles(images),
                      child: Text('Invia tutte'),
                    ),
                    TextButton(
                      onPressed: () => shareFiles(filtered),
                      child: Text('Filtra e invia'),
                    ),
                  ],
                )
              ])
          ],
        ),
      ),
    );
  }
}