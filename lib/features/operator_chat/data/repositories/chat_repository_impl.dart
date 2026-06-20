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
  Future<Either<Failure, List<ChatMessageEntity>>> getMessages(int roomId) async {
    try {
      return Right(await dataSource.getMessages(roomId));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Xabarlarni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required int roomId,
    required String text,
  }) async {
    try {
      return Right(await dataSource.sendMessage(roomId: roomId, text: text));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Xabar yuborishda xatolik'));
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
  Future<Either<Failure, List<ChatProductEntity>>> searchProducts(String query, {int page = 1}) async {
    try {
      return Right(await dataSource.searchProducts(query, page: page));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure('Mahsulotlarni yuklashda xatolik'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasMoreProducts(String query, int page) async {
    try {
      return Right(await dataSource.hasMoreProducts(query, page));
    } on Failure catch (e) {
      return Left(e);
    } catch (_) {
      return Right(false);
    }
  }
}
