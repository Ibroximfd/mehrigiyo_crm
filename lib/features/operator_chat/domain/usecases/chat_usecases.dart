import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/chat_entities.dart';
import '../repositories/chat_repository.dart';

class CreateChatRoomUseCase {
  final ChatRepository repo;
  CreateChatRoomUseCase(this.repo);
  Future<Either<Failure, ChatRoomEntity>> call({required String phone, int? leadId}) =>
      repo.createRoom(phone: phone, leadId: leadId);
}

class GetChatRoomsUseCase {
  final ChatRepository repo;
  GetChatRoomsUseCase(this.repo);
  Future<Either<Failure, List<ChatRoomEntity>>> call() => repo.getRooms();
}

class GetChatMessagesUseCase {
  final ChatRepository repo;
  GetChatMessagesUseCase(this.repo);
  Future<Either<Failure, ChatMessagesPage>> call(int roomId, {int? beforeId}) =>
      repo.getMessages(roomId, beforeId: beforeId);
}

class SendChatMessageUseCase {
  final ChatRepository repo;
  SendChatMessageUseCase(this.repo);
  Future<Either<Failure, ChatMessageEntity>> call({
    required int roomId,
    required String text,
    int? replyToId,
  }) =>
      repo.sendMessage(roomId: roomId, text: text, replyToId: replyToId);
}

class SendRecommendationUseCase {
  final ChatRepository repo;
  SendRecommendationUseCase(this.repo);
  Future<Either<Failure, ChatMessageEntity>> call({
    required int roomId,
    required List<int> productIds,
    int? leadId,
  }) =>
      repo.sendRecommendation(roomId: roomId, productIds: productIds, leadId: leadId);
}

class SearchProductsUseCase {
  final ChatRepository repo;
  SearchProductsUseCase(this.repo);
  Future<Either<Failure, ChatProductsPage>> call(String query, {int page = 1}) =>
      repo.searchProducts(query, page: page);
}

class MarkChatAsReadUseCase {
  final ChatRepository repo;
  MarkChatAsReadUseCase(this.repo);
  Future<Either<Failure, void>> call(int roomId) => repo.markAsRead(roomId);
}
