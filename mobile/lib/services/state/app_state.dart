import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/models.dart';
import '../account_api.dart';
import '../social_sign_in.dart';

part 'session_actions.dart';
part 'catalog_actions.dart';
part 'delivery_location_actions.dart';
part 'cart_order_actions.dart';
part 'profile_actions.dart';
part 'shipper_actions.dart';

/// Dữ liệu đang có trong RAM của ứng dụng, đồng thời là điểm gọi cho giao diện.
/// Màn hình gọi các hàm bên dưới; từng nhóm xử lý nằm ở các file `*_actions`.
/// `part` giữ các file trong cùng thư viện Dart, không tạo thêm bản sao trạng thái.
class AppState extends ChangeNotifier {
  AppState({AccountApi? accountApi, SocialSignIn? socialSignIn})
      : api = accountApi ?? AccountApi(),
        socialSignIn = socialSignIn ?? NativeSocialSignIn();
  // Các dịch vụ giao tiếp với backend và bộ chọn tài khoản Google/Facebook.
  final AccountApi api;
  final SocialSignIn socialSignIn;
  bool _socialLoginPending = false;
  // Dữ liệu nghiệp vụ của phiên hiện tại; không phải dữ liệu mẫu.
  Account? account;
  List<Branch> branchList = [];
  final products = <Product>[];
  final orders = <ShopOrder>[];
  final cart = <int, int>{};
  final _offers = <ShopOrder>[];
  Branch? selected;
  // Điểm giao của khách và tọa độ trực tuyến của shipper là hai dữ liệu khác nhau.
  double lat = 0;
  double lng = 0;
  double shipperLat = 0;
  double shipperLng = 0;
  String location = 'Chọn vị trí giao hàng';
  bool positionKnown = false;
  bool online = false;
  bool loading = false;
  bool shipperSimulated = false;
  bool nearbyLoading = false;
  final nearbyQuotes = <int, DeliveryQuote>{};
  String? nearbyError;
  int _nearbyRevision = 0;
  String? error;
  Timer? timer;
  // Getter tính từ dữ liệu đang có, không tự gọi mạng.
  int get storeBranchId => account?.storeId ?? -1;
  String get shipperId => '${account?.id}';
  int get maxDeliveries => 3;
  List<ShopOrder> get customerOrders =>
      orders.where((o) => o.customerId == '${account?.id}').toList();
  List<ShopOrder> get storeOrders =>
      orders.where((o) => o.branchId == storeBranchId).toList();
  List<ShopOrder> get deliveries =>
      orders.where((o) => o.shipperId == shipperId).toList();
  List<ShopOrder> get offers => _offers;
  Branch branch(int id) => branchList.firstWhere((b) => b.id == id);
  Product product(int id) => products.firstWhere((p) => p.id == id);
  List<Branch> get nearby => !positionKnown
      ? []
      : (branchList
          .where(
            (b) =>
                nearbyQuotes.containsKey(b.id) &&
                nearbyQuotes[b.id]!.distanceKm <= 10,
          )
          .toList()
        ..sort(
          (a, b) => nearbyQuotes[a.id]!
              .distanceKm
              .compareTo(nearbyQuotes[b.id]!.distanceKm),
        ));
  int get subtotal => cart.entries.fold(
        0,
        (sum, e) => sum + product(e.key).price * e.value,
      );

  // Mã phiên/bản tải: ngăn kết quả mạng cũ ghi đè dữ liệu mới.
  int _productsRevision = 0;
  int _accountEpoch = 0;

  // Mỗi nhóm nhận cùng `this`, vì vậy không có sáu bản sao giỏ hàng/tài khoản.
  late final _session = _SessionActions(this);
  late final _catalog = _CatalogActions(this);
  late final _deliveryLocation = _DeliveryLocationActions(this);
  late final _cartOrders = _CartOrderActions(this);
  late final _profile = _ProfileActions(this);
  late final _shipper = _ShipperActions(this);

  /// Báo cho các ListenableBuilder dựng lại phần giao diện phụ thuộc dữ liệu.
  void refresh() => notifyListeners();

  // Đăng nhập, đăng ký, nạp phiên và xóa dữ liệu khi đăng xuất.
  Future<void> login(
    String email,
    String password,
  ) {
    return _session.login(
      email,
      password,
    );
  }

  Future<bool> loginSocial(SocialProvider provider) {
    return _session.loginSocial(provider);
  }

  Future<void> _loadSession() {
    return _session._loadSession();
  }

  Future<void> register(
    String name,
    String email,
    String password,
    Role role,
  ) {
    return _session.register(
      name,
      email,
      password,
      role,
    );
  }

  void logout() {
    _session.logout();
  }

  // Đọc dữ liệu server, polling và quản lý sản phẩm theo chi nhánh.
  Future<void> reloadBranches() {
    return _catalog.reloadBranches();
  }

  Future<void> reload() {
    return _catalog.reload();
  }

  Future<void> loadOrders(String path) {
    return _catalog.loadOrders(path);
  }

  Future<void> loadProducts() {
    return _catalog.loadProducts();
  }

  Future<void> select(Branch? branch) {
    return _catalog.select(branch);
  }

  Future<Product> saveProduct(
    Product? product,
    String name,
    int price,
    int stock,
    String category,
  ) {
    return _catalog.saveProduct(
      product,
      name,
      price,
      stock,
      category,
    );
  }

  Future<void> removeProduct(Product product) {
    return _catalog.removeProduct(product);
  }

  Future<void> uploadImage(
    Product product,
    List<int> bytes,
    String name,
  ) {
    return _catalog.uploadImage(
      product,
      bytes,
      name,
    );
  }

  // Lưu điểm giao, kiểm tra tọa độ và đọc báo giá đường bộ.
  Future<void> setLocation(
    String address,
    double latitude,
    double longitude,
  ) {
    return _deliveryLocation.setLocation(
      address,
      latitude,
      longitude,
    );
  }

  Future<void> loadNearby() {
    return _deliveryLocation.loadNearby();
  }

  Future<DeliveryQuote> quoteDelivery(
    Branch store,
    double latitude,
    double longitude,
  ) {
    return _deliveryLocation.quoteDelivery(
      store,
      latitude,
      longitude,
    );
  }

  void _applyLocation(
    String address,
    double latitude,
    double longitude,
  ) {
    _deliveryLocation._applyLocation(
      address,
      latitude,
      longitude,
    );
  }

  bool validCoordinates(
    double latitude,
    double longitude,
  ) {
    return _deliveryLocation.validCoordinates(
      latitude,
      longitude,
    );
  }

  // Giỏ hàng và thao tác trên đơn; backend vẫn kiểm tra giá, tồn và quyền.
  void change(
    Product product,
    int delta,
  ) {
    _cartOrders.change(
      product,
      delta,
    );
  }

  Future<ShopOrder> checkout(
    String name,
    String phone,
    String address,
    double latitude,
    double longitude,
  ) {
    return _cartOrders.checkout(
      name,
      phone,
      address,
      latitude,
      longitude,
    );
  }

  Future<void> transition(
    ShopOrder order,
    OrderStatus next,
    Role role, {
    String reason = '',
    bool simulateArrival = false,
  }) {
    return _cartOrders.transition(
      order,
      next,
      role,
      reason: reason,
      simulateArrival: simulateArrival,
    );
  }

  Future<void> pay(
    ShopOrder order,
    Role role,
  ) {
    return _cartOrders.pay(
      order,
      role,
    );
  }

  // Thông tin cá nhân; bỏ kết quả cũ nếu người dùng đã đăng xuất.
  Future<void> refreshProfile() {
    return _profile.refreshProfile();
  }

  Future<void> updateProfile(
    String name,
    String phone,
    String gender,
  ) {
    return _profile.updateProfile(
      name,
      phone,
      gender,
    );
  }

  Future<void> uploadAvatar(
    List<int> bytes,
    String name,
  ) {
    return _profile.uploadAvatar(
      bytes,
      name,
    );
  }

  Future<void> removeAvatar() {
    return _profile.removeAvatar();
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) {
    return _profile.changePassword(
      currentPassword,
      newPassword,
    );
  }

  // Nhận đơn và cập nhật trực tuyến/vị trí của người giao hàng.
  Future<void> claim(ShopOrder order) {
    return _shipper.claim(order);
  }

  Future<void> setShipperPosition(
    bool ready,
    double latitude,
    double longitude, {
    bool preserveSimulation = false,
  }) {
    return _shipper.setShipperPosition(
      ready,
      latitude,
      longitude,
      preserveSimulation: preserveSimulation,
    );
  }

  @override
  void dispose() {
    _nearbyRevision++;
    timer?.cancel();
    api.close();
    super.dispose();
  }
}
