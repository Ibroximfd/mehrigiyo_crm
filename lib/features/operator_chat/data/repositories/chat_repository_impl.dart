import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/chat_entities.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource dataSource;
  ChatRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, ChatRoomEntity>> createRoom({
    required String phone,
    int? leadId,
  }) async {
    try {
      return Right(await dataSource.createRoom(phone: phone, leadId: leadId));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Chat ochishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, List<ChatRoomEntity>>> getRooms() async {
    try {
      return Right(await dataSource.getRooms());
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Chatlarni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, ChatMessagesPage>> getMessages(int roomId, {int? beforeId}) async {
    try {
      final result = await dataSource.getMessages(roomId, beforeId: beforeId);
      return Right(result);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required int roomId,
    required String text,
    int? replyToId,
  }) async {
    try {
      return Right(await dataSource.sendMessage(roomId: roomId, text: text, replyToId: replyToId));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Xabar yuborishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMediaMessage({
    required int roomId,
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String messageType,
    int? replyToId,
  }) async {
    try {
      return Right(await dataSource.sendMediaMessage(
        roomId: roomId,
        bytes: bytes,
        fileName: fileName,
        mimeType: mimeType,
        messageType: messageType,
        replyToId: replyToId,
      ));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Fayl yuborishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendRecommendation({
    required int roomId,
    required List<int> productIds,
    int? leadId,
  }) async {
    try {
      return Right(await dataSource.sendRecommendation(
        roomId: roomId,
        productIds: productIds,
        leadId: leadId,
      ));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Tavsiya yuborishda xatolik'));
    }
  }

  @override
  Future<Either<Failure, ChatProductsPage>> searchProducts(String query, {int page = 1}) async {
    try {
      return Right(await dataSource.searchProducts(query, page: page));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Mahsulotlarni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(int roomId) async {
    try {
      await dataSource.markAsRead(roomId);
      return const Right(null);
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Mark as read xatolik'));
    }
  }
}
