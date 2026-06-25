import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/chat_entities.dart';
import '../models/chat_models.dart';

abstract class ChatRemoteDataSource {
  Future<ChatRoomModel> createRoom({required String phone, int? leadId});
  Future<List<ChatRoomModel>> getRooms();
  Future<ChatMessagesPage> getMessages(int roomId, {int? beforeId});
  Future<ChatMessageModel> sendMessage({required int roomId, required String text, int? replyToId});
  Future<ChatMessageModel> sendRecommendation({
    required int roomId,
    required List<int> productIds,
    int? leadId,
  });
  Future<ChatProductsPage> searchProducts(String query, {int page = 1});
  Future<void> markAsRead(int roomId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;
  ChatRemoteDataSourceImpl(this.apiClient);

  @override
  Future<ChatRoomModel> createRoom({required String phone, int? leadId}) async {
    try {
      final body = <String, dynamic>{'phone': phone};
      if (leadId != null) body['lead_id'] = leadId;
      final res = await apiClient.post(ApiConstants.chatCreateRoom, data: body);
      final raw = res.data as Map<String, dynamic>;
      final roomJson = raw.containsKey('room')
          ? raw['room'] as Map<String, dynamic>
          : raw;
      return ChatRoomModel.fromJson(roomJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final data = e.response?.data;
        final msg = data is Map
            ? (data['detail'] ?? data['message'] ?? 'Bu raqam bilan mijoz ilovada ro\'yxatdan o\'tmagan')
                .toString()
            : 'Bu raqam bilan mijoz ilovada ro\'yxatdan o\'tmagan';
        throw ServerFailure(msg);
      }
      throw dioFailure(e, 'Chat ochishda xatolik');
    }
  }

  @override
  Future<List<ChatRoomModel>> getRooms() async {
    try {
      final res = await apiClient.get(ApiConstants.chatRooms);
      final list = res.data is Map ? (res.data['results'] as List? ?? []) : (res.data as List? ?? []);
      return list.map((e) => ChatRoomModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw dioFailure(e, 'Chatlarni yuklashda xatolik');
    }
  }

  @override
  Future<ChatMessagesPage> getMessages(int roomId, {int? beforeId}) async {
    try {
      final params = <String, dynamic>{};
      if (beforeId != null) params['before'] = beforeId;
      final res = await apiClient.get(
        ApiConstants.chatMessages(roomId),
        queryParameters: params.isEmpty ? null : params,
      );
      final data = res.data as Map<String, dynamic>;
      final results = (data['results'] as List? ?? [])
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final hasMore = data['has_more'] as bool? ?? false;
      final oldestId = data['oldest_id'] as int?;
      return ChatMessagesPage(messages: results, hasMore: hasMore, oldestId: oldestId);
    } on DioException catch (e) {
      throw dioFailure(e, 'Xabarlarni yuklashda xatolik');
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({required int roomId, required String text, int? replyToId}) async {
    try {
      final body = <String, dynamic>{'room': roomId, 'text': text};
      if (replyToId != null) body['reply_to'] = replyToId;
      final res = await apiClient.post(ApiConstants.chatSendMessage, data: body);
      return ChatMessageModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Xabar yuborishda xatolik');
    }
  }

  @override
  Future<ChatMessageModel> sendRecommendation({
    required int roomId,
    required List<int> productIds,
    int? leadId,
  }) async {
    try {
      final body = <String, dynamic>{'product_ids': productIds};
      if (leadId != null) body['lead_id'] = leadId;
      final res = await apiClient.post(ApiConstants.chatRecommend(roomId), data: body);
      return ChatMessageModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw dioFailure(e, 'Tavsiya yuborishda xatolik');
    }
  }

  @override
  Future<ChatProductsPage> searchProducts(String query, {int page = 1}) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (query.isNotEmpty) params['search'] = query;
      final res = await apiClient.get(ApiConstants.shopMedicines, queryParameters: params);
      final data = res.data as Map<String, dynamic>;
      final list = (data['results'] as List? ?? [])
          .map((e) => ChatProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return ChatProductsPage(products: list, hasMore: data['next'] != null);
    } on DioException catch (e) {
      throw dioFailure(e, 'Mahsulotlarni yuklashda xatolik');
    }
  }

  @override
  Future<void> markAsRead(int roomId) async {
    try {
      await apiClient.post(ApiConstants.chatMarkAsRead(roomId));
    } on DioException catch (e) {
      throw dioFailure(e, 'Mark as read xatolik');
    }
  }
}
