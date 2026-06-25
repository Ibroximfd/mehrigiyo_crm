import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/chat_entities.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatRoomEntity>> createRoom({
    required String phone,
    int? leadId,
  });

  Future<Either<Failure, List<ChatRoomEntity>>> getRooms();

  Future<Either<Failure, ChatMessagesPage>> getMessages(int roomId, {int? beforeId});

  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required int roomId,
    required String text,
    int? replyToId,
  });

  Future<Either<Failure, ChatMessageEntity>> sendMediaMessage({
    required int roomId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String messageType,
    int? replyToId,
  });

  Future<Either<Failure, ChatMessageEntity>> sendRecommendation({
    required int roomId,
    required List<int> productIds,
    int? leadId,
  });

  Future<Either<Failure, ChatProductsPage>> searchProducts(String query, {int page = 1});
  Future<Either<Failure, void>> markAsRead(int roomId);
}
