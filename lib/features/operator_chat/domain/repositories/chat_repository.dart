import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/chat_entities.dart';

abstract class ChatRepository {
  Future<Either<Failure, ChatRoomEntity>> createRoom({
    required String phone,
    int? leadId,
  });

  Future<Either<Failure, List<ChatRoomEntity>>> getRooms();

  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(int roomId);

  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required int roomId,
    required String text,
  });

  Future<Either<Failure, ChatMessageEntity>> sendRecommendation({
    required int roomId,
    required List<int> productIds,
    int? leadId,
  });

  Future<Either<Failure, List<ChatProductEntity>>> searchProducts(String query, {int page = 1});
  Future<Either<Failure, bool>> hasMoreProducts(String query, int page);
}
