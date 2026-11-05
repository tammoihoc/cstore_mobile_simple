// Tạo thương hiệu/chi nhánh: kiểm tra, ghim vị trí, tạo tài khoản rồi tải logo.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cstore_mobile/services/app_state.dart';
import 'package:cstore_mobile/widgets/common.dart';
import 'package:cstore_mobile/widgets/product_image.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_colors.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_ui.dart';
import 'package:cstore_mobile/screens/admin/models/brand_option.dart';
import 'package:cstore_mobile/screens/admin/widgets/admin_brand_logo.dart';
import 'package:cstore_mobile/screens/location_picker.dart';

class CreatePartner extends StatefulWidget {
  const CreatePartner({super.key, required this.state, this.initialBrand});
  final AppState state;
  final String? initialBrand;
  @override
  State<CreatePartner> createState() => _CreatePartnerState();
}

class _CreatePartnerState extends State<CreatePartner> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      owner = TextEditingController(),
      brand = TextEditingController(),
      branchName = TextEditingController();
  String? selectedBrandKey;
  PinnedLocation? pin;
  Uint8List? imageBytes;
  String? imageName;
  int? createdStoreId;
  bool busy = false;
  String? error;
  List<BrandOption> get options => brandOptions(widget.state.branchList);
  BrandOption? get selectedBrand =>
      options.where((b) => b.key == selectedBrandKey).firstOrNull;
  BrandOption? get duplicate =>
      options.where((b) => b.key == normalizeBrandName(brand.text)).firstOrNull;
  @override
  void initState() {
    super.initState();
    final selected = options
        .where((b) => b.key == normalizeBrandName(widget.initialBrand ?? ''))
        .firstOrNull;
    if (selected != null) {
      selectedBrandKey = selected.key;
      brand.text = selected.name;
    }
  }

  @override
  void dispose() {
    for (final c in [email, password, owner, brand, branchName]) {
      c.dispose();
    }
    super.dispose();
  }

  // Đổi thương hiệu thì bỏ dữ liệu logo và tên chi nhánh đang nhập trước đó.
  void selectBrand(String? key) {
    setState(() {
      selectedBrandKey = key == null || key.isEmpty ? null : key;
      brand.text = selectedBrand?.name ?? '';
      branchName.clear();
      imageBytes = null;
      imageName = null;
      error = null;
    });
  }

  Future<void> pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        throw StateError('Chọn ảnh JPEG/PNG nhỏ hơn 5 MB.');
      }
      if (mounted) {
        setState(() {
          imageBytes = bytes;
          imageName = image.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            error = e is StateError ? e.message : 'Chưa mở được thư viện ảnh.');
      }
    }
  }

  // Tạo bản ghi một lần. Nếu tải ảnh lỗi, giữ createdStoreId để chỉ thử lại ảnh.
  Future<void> save() async {
    if (busy) return;
    if (createdStoreId == null) {
      if (!form.currentState!.validate()) return;
      if (pin == null) {
        setState(() => error = 'Bắt buộc ghim vị trí chi nhánh trên bản đồ.');
        return;
      }
      if (imageBytes == null && (selectedBrand?.image.isEmpty ?? true)) {
        setState(() => error = 'Thêm logo thương hiệu trước khi tạo cửa hàng.');
        return;
      }
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (createdStoreId == null) {
        final label = branchName.text.trim();
        final created = await widget.state.api.createStore({
          'name': selectedBrand == null
              ? brand.text.trim()
              : '${selectedBrand!.name} · $label',
          'brand': selectedBrand?.name ?? brand.text.trim(),
          'branchName': selectedBrand == null ? null : label,
          'address': pin!.address,
          'latitude': pin!.lat,
          'longitude': pin!.lng,
          'pinConfirmed': true,
          'email': email.text.trim(),
          'fullName': owner.text.trim(),
          'password': password.text
        });
        createdStoreId = created['storeId'] as int;
      }
      if (imageBytes != null) {
        await widget.state.api.uploadStoreImage(
            createdStoreId!, imageBytes!, imageName ?? 'brand.jpg');
      }
      await widget.state.reloadBranches();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => error = createdStoreId != null
            ? 'Tài khoản đã tạo. Bấm thử tải logo lại để hoàn tất.'
            : e is StateError
                ? e.message
                : 'Không kết nối được máy chủ.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget option(BrandOption? value, {bool compact = false}) => Row(
        children: [
          value == null
              ? const CircleAvatar(
                  backgroundColor: adminLime,
                  radius: 19,
                  child: Icon(Icons.add_business_outlined, color: adminForest),
                )
              : AdminBrandLogo(name: value.name, path: value.image, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value == null
                      ? 'Tạo thương hiệu'
                      : 'Thêm chi nhánh · ${value.name}',
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: adminForest,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (!compact && value != null)
                  Text(
                    'Đang có ${value.branches.length} chi nhánh',
                    style: const TextStyle(color: adminMuted, fontSize: 11),
                  )
              ],
            ),
          )
        ],
      );

  @override
  Widget build(BuildContext context) {
    final choices = options, selected = selectedBrand;
    final locked = busy || createdStoreId != null;
    return Scaffold(
      backgroundColor: adminPaper,
      appBar: AppBar(
        backgroundColor: adminPaper,
        title: const Text('Tạo cửa hàng và tài khoản'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: FilledButton.icon(
            onPressed: busy ? null : save,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              busy
                  ? 'Đang tạo…'
                  : createdStoreId != null
                      ? 'Thử tải logo lại'
                      : selected == null
                          ? 'Tạo thương hiệu và tài khoản'
                          : 'Tạo chi nhánh và tài khoản',
            ),
          ),
        ),
      ),
      body: Form(
        key: form,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              adminStepHeading(1, 'Thương hiệu của bạn',
                  'Tạo thương hiệu mới hoặc mở thêm điểm bán cho thương hiệu đã đăng ký.'),
              DropdownButtonFormField<String>(
                  key: ValueKey(
                    'brand-mode-${selectedBrandKey ?? 'new'}',
                  ),
                  initialValue: selectedBrandKey ?? '',
                  isExpanded: true,
                  itemHeight: 80,
                  decoration: const InputDecoration(labelText: 'Hình thức tạo'),
                  selectedItemBuilder: (_) => [
                        option(null, compact: true),
                        for (final value in choices)
                          option(value, compact: true)
                      ],
                  items: [
                    DropdownMenuItem(value: '', child: option(null)),
                    for (final value in choices)
                      DropdownMenuItem(
                        value: value.key,
                        child: option(value),
                      )
                  ],
                  onChanged: locked ? null : selectBrand),
              const SizedBox(height: 18),
              TextFormField(
                controller: brand,
                readOnly: selected != null,
                enabled: !locked,
                decoration: InputDecoration(
                  labelText: 'Tên thương hiệu',
                  prefixIcon: const Icon(Icons.loyalty_outlined),
                  suffixIcon: selected != null
                      ? const Icon(
                          Icons.verified_outlined,
                          color: adminForest,
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Nhập tên thương hiệu'
                    : selected == null && duplicate != null
                        ? 'Thương hiệu đã có. Chọn Thêm chi nhánh.'
                        : null,
              ),
              if (selected == null && duplicate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: adminSage,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AdminBrandLogo(
                              name: duplicate!.name,
                              path: duplicate!.image,
                              size: 42,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${duplicate!.name} đã có ${duplicate!.branches.length} chi nhánh.',
                                style: const TextStyle(
                                  color: adminForest,
                                ),
                              ),
                            )
                          ],
                        ),
                        TextButton(
                          onPressed:
                              locked ? null : () => selectBrand(duplicate!.key),
                          child: const Text(
                            'Thêm chi nhánh cho thương hiệu này',
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              if (selected != null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: branchName,
                  enabled: !locked,
                  decoration: InputDecoration(
                    labelText: 'Tên chi nhánh',
                    hintText:
                        'Ví dụ: Chi nhánh ${selected.branches.length + 1}, Nguyễn Huệ',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nhập tên riêng cho chi nhánh mới.';
                    }
                    final full =
                        normalizeBrandName('${selected.name} · ${v.trim()}');
                    return selected.branches
                            .any((b) => normalizeBrandName(b.name) == full)
                        ? 'Tên chi nhánh đã tồn tại.'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 18),
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF0E6),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: orange,
                    ),
                  ),
                  title: Text(
                    pin?.address ?? 'Chưa ghim vị trí chi nhánh',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    pin == null
                        ? 'Chọn vị trí chính xác trên bản đồ'
                        : 'Đã ghim • Chạm để chỉnh vị trí',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: locked
                      ? null
                      : () async {
                          final result = await Navigator.push<PinnedLocation>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LocationPicker(
                                  title: 'Ghim vị trí chi nhánh',
                                  lat: pin?.lat ?? 10.7731,
                                  lng: pin?.lng ?? 106.7030,
                                  address: pin?.address ?? '',
                                  initialPinConfirmed: pin != null,
                                  branches: widget.state.branchList,
                                ),
                              ));
                          if (result != null && mounted) {
                            setState(() => pin = result);
                          }
                        },
                ),
              ),
              adminStepHeading(
                  2,
                  'Logo thương hiệu',
                  selected == null
                      ? 'Giúp khách nhận ra thương hiệu của bạn.'
                      : 'Chi nhánh mới dùng chung logo của ${selected.name}.'),
              Container(
                height: 160,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: imageBytes != null
                    ? Image.memory(imageBytes!, fit: BoxFit.contain)
                    : selected?.image.isNotEmpty == true
                        ? ProductImage(
                            path: selected!.image,
                            fit: BoxFit.contain,
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate_outlined,
                                color: adminForest,
                                size: 42,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Thêm ảnh nhận diện thương hiệu',
                                style: TextStyle(color: adminMuted),
                              )
                            ],
                          ),
              ),
              if (selected?.image.isNotEmpty != true || imageBytes != null) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: busy ? null : pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    imageBytes == null ? 'Chọn ảnh thương hiệu' : 'Đổi ảnh',
                  ),
                )
              ],
              const SizedBox(height: 8),
              const Text(
                'JPEG / PNG • Tối đa 5 MB',
                style: TextStyle(color: adminMuted, fontSize: 11),
              ),
              adminStepHeading(3, 'Tài khoản người phụ trách',
                  'Quản lý sản phẩm, đơn hàng và doanh thu của chi nhánh này.'),
              adminFormField(owner, 'Tên người phụ trách', enabled: !locked),
              adminFormField(email, 'Email đăng nhập',
                  enabled: !locked, email: true),
              adminFormField(password, 'Mật khẩu ban đầu',
                  enabled: !locked, secret: true),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20)
            ],
          ),
        ),
      ),
    );
  }
}
