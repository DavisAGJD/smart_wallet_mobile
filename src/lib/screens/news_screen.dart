import 'package:flutter/material.dart';
import '../services/api_service_articles.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final ApiServiceArticles _apiService = ApiServiceArticles();
  List<dynamic> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    try {
      final articles = await _apiService.getArticles();
      setState(() {
        _articles = articles;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener las noticias: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF228B22),
      appBar: AppBar(
        backgroundColor: const Color(0xFF228B22),
        elevation: 0,
        title: const Text(
          'Noticias',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Últimas Noticias',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF33404F),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _articles.isEmpty
                          ? const Center(
                              child: Text(
                                'No hay noticias disponibles',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF5B5B5B),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _articles.length,
                              itemBuilder: (context, index) {
                                final article = _articles[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF7F5),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: article['image_url'] != null &&
                                              article['image_url']
                                                  .toString()
                                                  .isNotEmpty
                                          ? Image.network(
                                              article['image_url'],
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                                size: 80,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    title: Text(
                                      article['title'] ?? 'Sin título',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF33404F),
                                      ),
                                    ),
                                    subtitle: Text(
                                      article['summary'] ??
                                          'Haz click para ir al enlace',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF5B5B5B),
                                      ),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00DDA3),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    onTap: () async {
                                      final url = article['link'];
                                      if (url != null && url.isNotEmpty) {
                                        if (await canLaunchUrl(
                                            Uri.parse(url))) {
                                          await launchUrl(Uri.parse(url));
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'No se puede abrir el enlace'),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'El enlace no está disponible'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
