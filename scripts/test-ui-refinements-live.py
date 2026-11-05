#!/usr/bin/env python3
"""Verify real account timestamps and explicit avatar removal using isolated QA data."""
import importlib.util,json,secrets,urllib.request
from datetime import datetime,timezone
from pathlib import Path
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('live_api',root/'scripts/test-live.py')
api=importlib.util.module_from_spec(spec);spec.loader.exec_module(api)
a=api.register('CUSTOMER',datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')+secrets.token_hex(3))
user=api.request('/account/profile',token=a['token'])
created=user['createdAt'];assert created is not None
assert abs((datetime.now(timezone.utc)-datetime.fromisoformat(created.replace('Z','+00:00'))).total_seconds())<120
boundary='qa'+secrets.token_hex(12)
image=(root/'mobile/assets/images/cstore-logo.png').read_bytes()
body=(f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="qa.png"\r\nContent-Type: image/png\r\n\r\n').encode()+image+f'\r\n--{boundary}--\r\n'.encode()
req=urllib.request.Request(api.BASE+'/api/account/avatar',data=body,headers={'Authorization':'Bearer '+a['token'],'Content-Type':'multipart/form-data; boundary='+boundary})
with urllib.request.urlopen(req,timeout=25) as res:photo=json.load(res)['avatar']
for gender in ['MALE','FEMALE','MALE','FEMALE']:
 saved=api.request('/account/profile',{'name':'QA Avatar theo giới tính','phone':'0901234567','gender':gender,'createdAt':'2001-01-01T00:00:00Z'},a['token'],method='PUT')
 assert saved['avatar']==photo and saved['gender']==gender and saved['createdAt']==created
removed=api.request('/account/avatar',token=a['token'],method='DELETE');assert not removed['avatar'] and removed['gender']=='FEMALE'
admin=api.login(api.config['ADMIN_EMAIL'],api.config['ADMIN_PASSWORD'])
row=next(u for u in api.request('/admin/accounts',token=admin) if u['id']==user['id'])
assert row['createdAt']==created and row['role']=='CUSTOMER'
legacy=sum(1 for u in api.request('/admin/accounts',token=admin) if u.get('createdAt') is None)
api.request('/admin/accounts/'+str(user['id']),token=admin,method='DELETE',expected=204)
print(json.dumps({'result':'PASS','checks':['Ngày tạo mới chính xác, trả về cho admin và không bị sửa từ client','Đổi giới tính luân phiên giữ nguyên ảnh riêng','Xóa ảnh riêng giữ giới tính đã chọn để app hiển thị mặc định','Bản ghi QA riêng được xóa sau kiểm tra'],'legacyAccountsWithoutKnownCreationDate':legacy},ensure_ascii=False,indent=2))
