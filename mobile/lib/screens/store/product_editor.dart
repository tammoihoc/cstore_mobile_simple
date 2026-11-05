import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/models.dart';
import '../../services/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/product_image.dart';

class ProductEditor extends StatefulWidget {
  const ProductEditor({super.key, required this.state, this.product});
  final AppState state;
  final Product? product;
  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  final form = GlobalKey<FormState>();
  late final List<TextEditingController> inputs;
  Product? saved;
  XFile? image;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    saved = widget.product;
    final p = saved;
    inputs = [
      TextEditingController(text: p?.name ?? ''),
      TextEditingController(text: p == null ? '' : '${p.price}'),
      TextEditingController(text: p == null ? '' : '${p.stock}'),
      TextEditingController(text: p?.category ?? '')
    ];
    recover();
  }

  Future<void> recover() async {
    try {
      final result = await ImagePicker().retrieveLostData();
      if (result.files?.isNotEmpty == true && mounted) {
        setState(() => image = result.files!.first);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in inputs) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> pick(ImageSource source) async {
    try {
      final result = await ImagePicker().pickImage(
          source: source, maxWidth: 1600, maxHeight: 1600, imageQuality: 85);
      if (result != null && mounted) setState(() => image = result);
    } catch (_) {
      if (mounted) {
        setState(() =>
            error = 'Không mở được máy ảnh/thư viện. Kiểm tra quyền truy cập.');
      }
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    if (saved == null && image == null) {
      setState(() => error = 'Chọn ảnh sản phẩm trước khi lưu.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      saved = await widget.state.saveProduct(
          saved,
          inputs[0].text.trim(),
          int.parse(inputs[1].text),
          int.parse(inputs[2].text),
          inputs[3].text.trim());
      if (image != null) {
        final bytes = await image!.readAsBytes();
        if (bytes.length > 5 * 1024 * 1024) {
          throw StateError('Ảnh phải nhỏ hơn 5 MB');
        }
        await widget.state.uploadImage(saved!, bytes, image!.name);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => error = e is StateError
            ? e.message
            : 'Không lưu được dữ liệu. Vui lòng thử lại.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF7F8F4),
        appBar: AppBar(
            title: Text(saved == null ? 'Thêm sản phẩm' : 'Sửa sản phẩm')),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: FilledButton(
              onPressed: busy ? null : save,
              child: Text(busy ? 'Đang lưu dữ liệu…' : 'Lưu sản phẩm'),
            ),
          ),
        ),
        body: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              heading(saved == null ? 'Một sản phẩm mới' : 'Thông tin sản phẩm',
                  'Ảnh rõ ràng, giá bán và tồn kho khả dụng của chi nhánh.'),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: image != null
                    ? Image.file(
                        File(image!.path),
                        height: 190,
                        fit: BoxFit.cover,
                      )
                    : ProductImage(path: saved?.asset ?? '', height: 190),
              ),
              if (image != null)
                Text(
                  'Đã chọn: ${image!.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Thư viện ảnh'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : () => pick(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Chụp ảnh'),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < inputs.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: inputs[i],
                    enabled: !busy,
                    decoration: InputDecoration(
                      labelText: [
                        'Tên sản phẩm',
                        'Giá (đ)',
                        'Tồn kho khả dụng',
                        'Danh mục'
                      ][i],
                    ),
                    keyboardType:
                        [1, 2].contains(i) ? TextInputType.number : null,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Không được trống';
                      }
                      if ([1, 2].contains(i)) {
                        final n = int.tryParse(v);
                        if (n == null || n < (i == 1 ? 1 : 0)) {
                          return 'Giá/tồn kho không hợp lệ';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      Text(error!, style: const TextStyle(color: Colors.red)),
                ),
              if (saved != null)
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => attempt(context, () async {
                            await widget.state.removeProduct(saved!);
                            if (context.mounted) Navigator.pop(context);
                          }),
                  child: const Text('Ngừng kinh doanh'),
                )
            ],
          ),
        ),
      );
}
