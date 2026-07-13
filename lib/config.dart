
class AppConfig {
  // Geliştirme yapırken localhost (PC) adresiniz
  // Eğer emülatör kullanırsanız localhost yerine '10.0.2.2' yazmanız gerekebilir.
  // Canlıya geçince sadece buradaki URL'leri değiştirmeniz yetecek!
  
  static const String apiBaseUrl = "http://localhost:8000/api";
  static const String webSocketUrl = "ws://localhost:8000/ws/game";
} 