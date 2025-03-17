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
    // Obtenemos las dimensiones de la pantalla para ajustar tamaños de forma responsiva
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.05; // 5% del ancho
    final verticalPadding = size.height * 0.02; // 2% del alto
    final imageSize = size.width * 0.2; // 20% del ancho para la imagen

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
          color: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Últimas Noticias',
                style: TextStyle(
                  fontSize: size.width * 0.07, // tamaño de fuente responsivo
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF33404F),
                ),
              ),
              SizedBox(height: verticalPadding * 2),
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
                                margin: EdgeInsets.only(
                                    bottom: verticalPadding * 2),
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
                                  contentPadding:
                                      EdgeInsets.all(horizontalPadding),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: article['image_url'] != null &&
                                            article['image_url']
                                                .toString()
                                                .isNotEmpty
                                        ? Image.network(
                                            article['image_url'],
                                            width: imageSize,
                                            height: imageSize,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                              size: imageSize,
                                            ),
                                          )
                                        : SizedBox(
                                            width: imageSize,
                                            height: imageSize,
                                          ),
                                  ),
                                  title: Text(
                                    article['title'] ?? 'Sin título',
                                    style: TextStyle(
                                      fontSize: size.width * 0.045,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF33404F),
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: EdgeInsets.only(
                                        top: verticalPadding * 0.5),
                                    child: Text(
                                      article['summary'] ??
                                          'Haz click para ir al enlace',
                                      style: TextStyle(
                                        fontSize: size.width * 0.035,
                                        color: const Color(0xFF5B5B5B),
                                      ),
                                    ),
                                  ),
                                  trailing: Container(
                                    padding:
                                        EdgeInsets.all(horizontalPadding * 0.3),
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
                                      if (await canLaunchUrl(Uri.parse(url))) {
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
    );
  }
}
