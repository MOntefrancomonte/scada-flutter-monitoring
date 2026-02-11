// post_cubit.dart - OPTIMIZADO
import 'dart:async';
import 'package:amplify_core/amplify_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'post_repository.dart';
import '../models/MiPrimerModeloDeDatos.dart';

// Estados optimizados con datos incrementales
abstract class PostState {}

class LoadingPosts extends PostState {}

class ListPostsSuccess extends PostState {
  final List<MiPrimerModeloDeDatos> posts;
  final MiPrimerModeloDeDatos? latestPost; // Último dato para vista en tiempo real

  ListPostsSuccess({
    required this.posts,
    this.latestPost,
  });

  // Método para actualizar solo el último post sin recargar todo
  ListPostsSuccess copyWithLatest(MiPrimerModeloDeDatos newLatest) {
    return ListPostsSuccess(
      posts: posts,
      latestPost: newLatest,
    );
  }
}

class ListPostsFailure extends PostState {
  final Exception exception;
  ListPostsFailure({required this.exception});
}

class PostCubit extends Cubit<PostState> {
  final _repo = PostRepository();
  StreamSubscription<dynamic>? _subscription;
  Timer? _refreshTimer;

  PostCubit() : super(LoadingPosts());

  // Obtener posts iniciales (con límite)
  Future<void> getPosts({
    bool silent = false,
    int limit = 1000,
  }) async {
    if (!silent) {
      emit(LoadingPosts());
    }

    try {
      final posts = await _repo.getPosts(limit: limit);
      final latest = posts.isNotEmpty ? posts.first : null;

      emit(ListPostsSuccess(posts: posts, latestPost: latest));
    } catch (e) {
      if (state is! ListPostsSuccess) {
        emit(ListPostsFailure(
            exception: e is Exception ? e : Exception(e.toString())
        ));
      }
    }
  }

  // Obtener posts por rango de fechas (CRÍTICO para filtros)
  Future<void> getPostsByDateRange({
    required int startTimestamp,
    required int endTimestamp,
    bool silent = false,
  }) async {
    if (!silent) {
      emit(LoadingPosts());
    }

    try {
      final posts = await _repo.getPostsByDateRange(
        startTimestamp: startTimestamp,
        endTimestamp: endTimestamp,
      );

      final latest = posts.isNotEmpty ? posts.first : null;
      emit(ListPostsSuccess(posts: posts, latestPost: latest));
    } catch (e) {
      if (state is! ListPostsSuccess) {
        emit(ListPostsFailure(
            exception: e is Exception ? e : Exception(e.toString())
        ));
      }
    }
  }

  // Actualizar SOLO el último valor (para tiempo real)
  Future<void> updateLatestPost() async {
    try {
      final latest = await _repo.getLatestPost();

      if (latest != null && state is ListPostsSuccess) {
        final currentState = state as ListPostsSuccess;

        // Solo emitir si el valor cambió
        if (currentState.latestPost?.id != latest.id) {
          emit(currentState.copyWithLatest(latest));
        }
      }
    } catch (e) {
      safePrint('Error actualizando último post: $e');
    }
  }

  // Observar cambios de manera eficiente
  void observePosts() {
    _subscription?.cancel();

    final stream = _repo.observePosts();
    _subscription = stream.listen(
          (event) {
        // Solo actualizar el último post, no toda la lista
        if (event.eventType == EventType.create ||
            event.eventType == EventType.update) {
          updateLatestPost();
        }
      },
      onError: (error) {
        safePrint('Error en observación: $error');
      },
    );
  }

  // Iniciar refresco automático cada X segundos (alternativa a observePosts)
  void startAutoRefresh({Duration interval = const Duration(seconds: 10)}) {
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(interval, (_) {
      updateLatestPost();
    });
  }

  // Detener refresco automático
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
  }

  Future<void> createPost({
    String? id,
    int? Agua,
    int? AguaR,
    int? Diesel,
    int? gLP,
  }) async {
    try {
      await _repo.createPost(
        id: id,
        timestamp: TemporalTimestamp.now(),
        Agua: Agua,
        AguaR: AguaR,
        Diesel: Diesel,
        gLP: gLP,
      );
    } catch (e) {
      safePrint('Error creando post: $e');
    }
  }

  Future<void> updatePost(MiPrimerModeloDeDatos post) async {
    try {
      await _repo.updatePost(post);
    } catch (e) {
      safePrint('Error actualizando post: $e');
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _refreshTimer?.cancel();
    return super.close();
  }
}