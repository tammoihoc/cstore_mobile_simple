#!/usr/bin/env python3
"""Checks brand aggregation and removes only isolated QA stores created here."""
import importlib.util
import json
import secrets
import urllib.request
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('cstore_qa', ROOT / 'scripts/test-live.py')
qa = importlib.util.module_from_spec(spec)
spec.loader.exec_module(qa)
request = qa.request

def main():
    admin = qa.login(qa.config['ADMIN_EMAIL'], qa.config['ADMIN_PASSWORD'])
    summary = request('/admin/revenue', token=admin)
    amount = lambda value: Decimal(str(value))
    assert amount(summary['grossSales']) == sum((amount(b['grossSales']) for b in summary['brands']), Decimal(0))
    assert summary['brandCount'] == sum(bool(b['active']) for b in summary['brands'])
    assert summary['branchCount'] == sum(b['branchCount'] for b in summary['brands'])
    for brand in summary['brands']:
        assert amount(brand['grossSales']) == sum((amount(b['grossSales']) for b in brand['branches']), Decimal(0))
        assert amount(brand['platformRevenue']) == amount(brand['grossSales']) * Decimal('.15')
    if summary['topBrand']:
        assert amount(summary['topBrand']['grossSales']) == max(amount(b['grossSales']) for b in summary['brands'])
    brand = 'QA brand lifecycle ' + secrets.token_hex(6)
    password = secrets.token_urlsafe(18)
    def create(label=None):
        body = {'brand': brand, 'address': 'QA brand test', 'latitude': 10.7731,
                'longitude': 106.703, 'pinConfirmed': True, 'email': 'qa.brand.' + secrets.token_hex(8) + '@cstore.local',
                'fullName': 'QA brand owner', 'password': password}
        if label: body['branchName'] = label
        result = request('/admin/stores', body, admin, expected=201)
        return result, body
    first, first_body = create()
    boundary = 'brandqa' + secrets.token_hex(12)
    image = (ROOT / 'mobile/assets/images/cstore-logo.png').read_bytes()
    payload = (f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="brand.png"\r\nContent-Type: image/png\r\n\r\n').encode() + image + (f'\r\n--{boundary}--\r\n').encode()
    req = urllib.request.Request(qa.BASE + '/api/admin/stores/' + str(first['storeId']) + '/image', data=payload,
        headers={'Authorization': 'Bearer ' + admin, 'Content-Type': 'multipart/form-data; boundary=' + boundary})
    with urllib.request.urlopen(req, timeout=25) as response: logo = json.load(response)['image']
    second, _ = create('Chi nhánh 2')
    group = next(b for b in request('/admin/brands', token=admin) if b['name'] == brand)
    assert group['branchCount'] == 2 and group['image'] == logo
    assert all(b['image'] == logo for b in group['branches'])
    owner_token = qa.login(first_body['email'], password)
    product = request('/merchant/products', {'name': 'QA archived product', 'price': 10000, 'stock': 1, 'category': 'QA'}, owner_token)
    request('/admin/accounts/' + str(first['id']), token=admin, method='DELETE', expected=204)
    assert not any(b['id'] == first['storeId'] for b in request('/branches'))
    assert request('/products?storeId=' + str(first['storeId'])) == []
    request('/merchant/products', token=owner_token, expected=401)
    assert next(b for b in request('/admin/brands', token=admin) if b['name'] == brand)['branchCount'] == 1
    request('/admin/accounts/' + str(second['id']), token=admin, method='DELETE', expected=204)
    assert not any(b['name'] == brand for b in request('/admin/brands', token=admin))
    historical = next(b for b in request('/admin/revenue', token=admin)['brands'] if b['name'] == brand)
    assert not historical['active'] and historical['branchCount'] == 0 and historical['archivedBranchCount'] == 2
    fresh, _ = create()
    request('/admin/accounts/' + str(fresh['id']), token=admin, method='DELETE', expected=204)
    report = {'result': 'PASS', 'checks': ['Tổng doanh thu và 15% khớp tổng từng thương hiệu/chi nhánh',
        'Số thương hiệu khác số chi nhánh; thương hiệu dẫn đầu đúng doanh thu',
        'Chi nhánh mới tự nhận logo thương hiệu', 'Xóa quản lý chính ẩn cửa hàng, sản phẩm và chặn phiên cũ',
        'Xóa chi nhánh cuối bỏ thương hiệu khỏi lựa chọn tạo mới; giữ lịch sử',
        'Tạo lại thương hiệu đã xóa không vướng tên chi nhánh cũ'],
        'activeBrands': summary['brandCount'], 'activeBranches': summary['branchCount']}
    output = ROOT / '.local/admin-brand-report.json'
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2));output.chmod(0o600)
    print(json.dumps(report, ensure_ascii=False, indent=2))
if __name__ == '__main__': main()
