import 'package:dio/dio.dart';

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/business_model.dart';
import '../models/category_model.dart';

/// Dados do formulário de criação/edição da página de negócio.
class BusinessInput {
  BusinessInput({
    required this.type,
    required this.name,
    required this.description,
    required this.categoryIds,
    this.province,
    this.district,
    this.address,
    this.latitude,
    this.longitude,
    this.phone,
    this.whatsapp,
    this.email,
    this.website,
    this.hours,
    this.logoPath,
    this.coverPath,
    this.galleryPaths = const [],
  });

  final String type;
  final String name;
  final String description;
  final List<String> categoryIds;
  final String? province;
  final String? district;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? whatsapp;
  final String? email;
  final String? website;
  final String? hours;
  final String? logoPath; // caminho local da imagem escolhida
  final String? coverPath;
  final List<String> galleryPaths;

  Future<FormData> toFormData() async {
    final form = FormData.fromMap({
      'type': type,
      'name': name,
      'description': description,
      'categories': categoryIds.join(','),
      if (province != null) 'province': province,
      if (district != null) 'district': district,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (phone != null) 'phone': phone,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (email != null) 'email': email,
      if (website != null) 'website': website,
      if (hours != null) 'hours': hours,
    });
    if (logoPath != null) {
      form.files.add(MapEntry('logo', await MultipartFile.fromFile(logoPath!)));
    }
    if (coverPath != null) {
      form.files
          .add(MapEntry('cover', await MultipartFile.fromFile(coverPath!)));
    }
    for (final p in galleryPaths) {
      form.files.add(MapEntry('gallery[]', await MultipartFile.fromFile(p)));
    }
    return form;
  }
}

/// Dados do formulário de produto do vendedor.
class ProductInput {
  ProductInput({
    required this.name,
    this.categoryId,
    this.description,
    this.price, // null → "sob consulta"
    this.unit,
    this.availability = 'disponivel',
    this.featured = false,
    this.imagePath,
    this.tipoCiclo = 'nenhum',
    this.estadoCiclo,
    this.dataDisponivel,
    this.quantidade,
  });

  final String name;
  final String? categoryId;
  final String? description;
  final double? price;
  final String? unit;
  final String availability;
  final bool featured;
  final String? imagePath;
  final String tipoCiclo;
  final String? estadoCiclo;
  final String? dataDisponivel;
  final int? quantidade;

  Future<FormData> toFormData() async {
    final form = FormData.fromMap({
      'name': name,
      if (categoryId != null) 'category_id': categoryId,
      if (description != null) 'description': description,
      'price': price?.toString() ?? '',
      if (unit != null) 'unit': unit,
      'availability': availability,
      'featured': featured ? '1' : '',
      'tipo_ciclo': tipoCiclo,
      if (estadoCiclo != null) 'estado_ciclo': estadoCiclo,
      if (dataDisponivel != null) 'data_disponivel': dataDisponivel,
      if (quantidade != null) 'quantidade': quantidade.toString(),
    });
    if (imagePath != null) {
      form.files
          .add(MapEntry('image', await MultipartFile.fromFile(imagePath!)));
    }
    return form;
  }
}

class BusinessRepository {
  BusinessRepository({ApiClient? client})
      : _client = client ?? ApiClient.instance;
  final ApiClient _client;

  /// A minha empresa — null se ainda não criei (API devolve 404).
  Future<BusinessModel?> fetchMyBusiness() async {
    try {
      final data =
          await _client.get<Map<String, dynamic>>(ApiEndpoints.business);
      return BusinessModel.fromJson(
        (data['data'] ?? data) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<BusinessTypeModel>> fetchTypes() async {
    final data =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.businessTypes);
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(BusinessTypeModel.fromJson)
        .toList();
  }

  Future<List<CategoryModel>> fetchCategoriesForType(String type) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.categories,
      query: {'type': type},
    );
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }

  Future<BusinessModel> createBusiness(BusinessInput input) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.business,
      data: await input.toFormData(),
    );
    return BusinessModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<BusinessModel> updateBusiness(BusinessInput input) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.businessUpdate,
      data: await input.toFormData(),
    );
    return BusinessModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<BusinessStatsModel> fetchStats() async {
    final data =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.businessStats);
    return BusinessStatsModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<OwnProductModel>> fetchMyProducts() async {
    final data =
        await _client.get<Map<String, dynamic>>(ApiEndpoints.businessProducts);
    return (data['data'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(OwnProductModel.fromJson)
        .toList();
  }

  Future<OwnProductModel> createProduct(ProductInput input) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.businessProducts,
      data: await input.toFormData(),
    );
    return OwnProductModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Gera uma descrição de produto por IA (o servidor chama o Claude).
  Future<String> generateDescription({
    required String name,
    String? category,
    String? province,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.businessGenerateDescription,
      data: {
        'name': name,
        if (category != null) 'category': category,
        if (province != null) 'province': province,
      },
    );
    return (data['data']?['description'] as String? ?? '').trim();
  }

  Future<OwnProductModel> updateProduct(String id, ProductInput input) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.businessProduct(id),
      data: await input.toFormData(),
    );
    return OwnProductModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<OwnProductModel> setAvailability(String id, String availability) async {
    final data = await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.businessProductAvailability(id),
      data: {'availability': availability},
    );
    return OwnProductModel.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) =>
      _client.delete<void>(ApiEndpoints.productDetail(id));
}
