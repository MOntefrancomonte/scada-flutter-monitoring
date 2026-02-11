// post_repository.dart - OPTIMIZADO CON DATASTORE
import 'package:amplify_core/amplify_core.dart';
import '../models/MiPrimerModeloDeDatos.dart';

class PostRepository {
  // Caché local para evitar consultas innecesarias
  List<MiPrimerModeloDeDatos>? _cachedPosts;
  DateTime? _lastFetchTime;
  static const _cacheDuration = Duration(seconds: 30);

  // Obtener posts con paginación y límite usando DataStore
  Future<List<MiPrimerModeloDeDatos>> getPosts({
    int limit = 1000,
    int? lastTimestamp,
    bool forceRefresh = false,
  }) async {
    // Retornar caché si es reciente y no se fuerza refresh
    if (!forceRefresh &&
        _cachedPosts != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      safePrint('📦 Retornando desde caché (${_cachedPosts!.length} posts)');
      return _cachedPosts!;
    }

    try {
      // Usar DataStore.query en lugar de API.query
      final posts = await Amplify.DataStore.query(
        MiPrimerModeloDeDatos.classType,
        where: lastTimestamp != null
            ? MiPrimerModeloDeDatos.TIMESTAMP.lt(lastTimestamp)
            : null,
      );

      // Ordenar por timestamp descendente
      posts.sort((a, b) {
        final aTs = a.timestamp?.toSeconds() ?? 0;
        final bTs = b.timestamp?.toSeconds() ?? 0;
        return bTs.compareTo(aTs); // Descendente (más reciente primero)
      });

      // Limitar cantidad
      final limitedPosts = posts.take(limit).toList();

      // Actualizar caché
      _cachedPosts = limitedPosts;
      _lastFetchTime = DateTime.now();

      safePrint('✅ Posts obtenidos: ${limitedPosts.length}');
      return limitedPosts;
    } catch (e) {
      safePrint('❌ Error obteniendo posts: $e');
      return _cachedPosts ?? [];
    }
  }

  // Obtener solo posts en un rango de fechas
  Future<List<MiPrimerModeloDeDatos>> getPostsByDateRange({
    required int startTimestamp,
    required int endTimestamp,
    int limit = 5000,
  }) async {
    try {
      // Consulta con DataStore
      final allPosts = await Amplify.DataStore.query(
        MiPrimerModeloDeDatos.classType,
      );

      // Filtrar manualmente por rango de fechas
      final filteredPosts = allPosts.where((post) {
        final ts = post.timestamp?.toSeconds();
        if (ts == null) return false;
        return ts >= startTimestamp && ts <= endTimestamp;
      }).toList();

      // Ordenar por timestamp descendente
      filteredPosts.sort((a, b) {
        final aTs = a.timestamp?.toSeconds() ?? 0;
        final bTs = b.timestamp?.toSeconds() ?? 0;
        return bTs.compareTo(aTs);
      });

      // Limitar cantidad
      final limitedPosts = filteredPosts.take(limit).toList();

      safePrint('✅ Posts por rango obtenidos: ${limitedPosts.length}');
      safePrint('📅 Rango: $startTimestamp - $endTimestamp');

      return limitedPosts;
    } catch (e) {
      safePrint('❌ Error obteniendo posts por rango: $e');
      return [];
    }
  }

  // Obtener solo el último registro
  Future<MiPrimerModeloDeDatos?> getLatestPost() async {
    try {
      final posts = await Amplify.DataStore.query(
        MiPrimerModeloDeDatos.classType,
      );

      if (posts.isEmpty) return null;

      // Ordenar y obtener el más reciente
      posts.sort((a, b) {
        final aTs = a.timestamp?.toSeconds() ?? 0;
        final bTs = b.timestamp?.toSeconds() ?? 0;
        return bTs.compareTo(aTs);
      });

      safePrint('✅ Último post obtenido: ${posts.first.id}');
      return posts.first;
    } catch (e) {
      safePrint('❌ Error obteniendo último post: $e');
      return null;
    }
  }

  // Observar cambios en DataStore
  Stream<SubscriptionEvent<MiPrimerModeloDeDatos>> observePosts() {
    safePrint('👀 Iniciando observación de posts...');
    return Amplify.DataStore.observe(MiPrimerModeloDeDatos.classType);
  }

  // Crear post
  Future<void> createPost({
    String? id,
    required TemporalTimestamp timestamp,
    int? Agua,
    int? AguaR,
    int? Diesel,
    int? gLP,
  }) async {
    try {
      final newPost = MiPrimerModeloDeDatos(
        id: id,
        timestamp: timestamp,
        Agua: Agua,
        AguaR: AguaR,
        Diesel: Diesel,
        gLP: gLP,
      );

      await Amplify.DataStore.save(newPost);

      // Invalidar caché
      _cachedPosts = null;
      _lastFetchTime = null;

      safePrint('✅ Post creado: ${newPost.id}');
    } catch (e) {
      safePrint('❌ Error creando post: $e');
      rethrow;
    }
  }

  // Actualizar post
  Future<void> updatePost(MiPrimerModeloDeDatos post) async {
    try {
      await Amplify.DataStore.save(post);

      // Invalidar caché
      _cachedPosts = null;
      _lastFetchTime = null;

      safePrint('✅ Post actualizado: ${post.id}');
    } catch (e) {
      safePrint('❌ Error actualizando post: $e');
      rethrow;
    }
  }

  // Limpiar caché manualmente
  void clearCache() {
    _cachedPosts = null;
    _lastFetchTime = null;
    safePrint('🗑️ Caché limpiado');
  }
}
