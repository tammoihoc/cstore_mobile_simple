#!/usr/bin/env python3
"""Create isolated QA records through real REST APIs; never resets existing data."""
import concurrent.futures, hashlib, json, math, os, secrets, urllib.request, urllib.error
from pathlib import Path
from datetime import datetime
from zoneinfo import ZoneInfo
ROOT=Path(__file__).resolve().parents[1]
BASE=os.environ.get('CSTORE_API_URL','http://127.0.0.1:8080')
config=dict(line.split('=',1) for line in (ROOT/'.env').read_text().splitlines() if '=' in line and not line.startswith('#'))
checks=[]
def safe_error(content):
 def redact(value):
  if isinstance(value,dict):return {key:'[redacted]' if key.lower() in ('token','password','passwordhash') else redact(item) for key,item in value.items()}
  if isinstance(value,list):return [redact(item) for item in value]
  return value
 try:return json.dumps(redact(json.loads(content)),ensure_ascii=False)[:250]
 except (ValueError,TypeError):return 'Nội dung phản hồi không phải JSON ('+str(len(content))+' byte)'
def request(path,body=None,token=None,method=None,expected=200,raw=False,headers=None):
 data=None if body is None else json.dumps(body,ensure_ascii=False).encode()
 req=urllib.request.Request(BASE+'/api'+path,data=data,method=method or ('GET' if body is None else 'POST'),headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {}),**(headers or {})})
 try:
  with urllib.request.urlopen(req,timeout=45) as res:code=res.status;content=res.read()
 except urllib.error.HTTPError as err:code=err.code;content=err.read()
 assert code==expected,(path,'expected',expected,'received',code,safe_error(content))
 return content if raw else json.loads(content) if content else None

def login(email,password):return request('/auth/login',{'email':email,'password':password})['token']
def register(role,stamp):
 email='qa.'+role.lower()+'.'+stamp+'@cstore.local';password=secrets.token_urlsafe(18)
 request('/auth/register',{'email':email,'password':password,'fullName':'QA '+role,'role':role},expected=201)
 return {'email':email,'password':password,'token':login(email,password)}

def main():
 stamp=datetime.now(ZoneInfo('Asia/Vientiane')).strftime('%Y%m%d%H%M%S')+secrets.token_hex(2)
 admin=login(config['ADMIN_EMAIL'],config['ADMIN_PASSWORD'])
 store={'email':'qa.store.'+stamp+'@cstore.local','password':secrets.token_urlsafe(18)}
 branch=request('/admin/stores',{'name':'QA Nguyễn Huệ '+stamp,'branchName':'Nguyễn Huệ '+stamp,'address':'45 Nguyễn Huệ, Quận 1 (địa chỉ kiểm thử)','latitude':10.7731,'longitude':106.703,'pinConfirmed':True,'brand':'QA C-Store','email':store['email'],'fullName':'Đối tác QA','password':store['password']},admin,expected=201)['storeId']
 store['token']=login(store['email'],store['password'])
 buyer=register('CUSTOMER',stamp);shipper=register('SHIPPER',stamp);other=register('SHIPPER',stamp+'b')
 checks.append('ADMIN tạo chi nhánh và tài khoản; CUSTOMER/SHIPPER đăng ký và login thật')
 request('/admin/accounts',token=buyer['token'],expected=403)
 p=request('/merchant/products',{'name':'Sản phẩm kiểm thử API '+stamp,'price':25000,'stock':5,'category':'Đồ uống'},store['token'])
 image=(ROOT/'mobile/assets/images/cstore-logo.png').read_bytes();boundary='cstore'+secrets.token_hex(12)
 body=(f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="qa-logo.png"\r\nContent-Type: image/png\r\n\r\n').encode()+image+(f'\r\n--{boundary}--\r\n').encode()
 req=urllib.request.Request(BASE+'/api/merchant/products/'+str(p['id'])+'/image',data=body,headers={'Authorization':'Bearer '+store['token'],'Content-Type':'multipart/form-data; boundary='+boundary})
 with urllib.request.urlopen(req,timeout=25) as res:uploaded=json.load(res)
 img=request(uploaded['image'].removeprefix('/api'),raw=True);assert img.startswith(b'\x89PNG')
 brandreq=urllib.request.Request(BASE+'/api/admin/stores/'+str(branch)+'/image',data=body,headers={'Authorization':'Bearer '+admin,'Content-Type':'multipart/form-data; boundary='+boundary})
 with urllib.request.urlopen(brandreq,timeout=25) as res:brandimage=json.load(res)
 assert next(b for b in request('/branches') if b['id']==branch)['image']==brandimage['image']
 for person in (shipper,other):
  request('/shipper/location',{'online':True,'latitude':10.7725,'longitude':106.7045},person['token'],method='PUT',expected=400)
  portrait=urllib.request.Request(BASE+'/api/account/avatar',data=body,headers={'Authorization':'Bearer '+person['token'],'Content-Type':'multipart/form-data; boundary='+boundary})
  with urllib.request.urlopen(portrait,timeout=25) as res:profile=json.load(res)
  assert profile['avatar'].startswith('/api/images/') and not profile['photoRequired']
  person['avatar']=profile['avatar']
  request('/account/profile',{'name':'Tài xế QA','phone':'0901234567','gender':'UNSPECIFIED'},person['token'],method='PUT')
 assert request('/account/profile',token=store['token'])['avatar']==brandimage['image']
 checks.append('Multipart upload PNG thật; GET ảnh từ server thành công; logo tài khoản cửa hàng; shipper bắt buộc thêm ảnh trước online')
 def stock(pid=p['id']):return next(x['stock'] for x in request('/merchant/products',token=store['token']) if x['id']==pid)
 def make_order(pid=p['id'],quantity=1):return {'storeId':branch,'items':[{'productId':pid,'quantity':quantity}],'recipient':'Khách QA','phone':'0901234567','address':'Điểm giao QA Nguyễn Huệ','latitude':10.7736,'longitude':106.7034,'pinConfirmed':True}
 quote_input={'storeId':branch,'latitude':10.7736,'longitude':106.7034}
 quote=request('/customer/delivery-quote',quote_input,buyer['token'])
 route=quote['route']
 assert quote['storeId']==branch and 0<quote['distanceKm']<10
 assert route['provider']=='OSRM' and route['selection']=='SHORTEST_AVAILABLE'
 assert len(route['coordinates'])>=2 and route['steps'] and route['durationSeconds']>=0
 assert quote['distanceKm']==route['distanceKm'] and quote['durationSeconds']==route['durationSeconds']
 assert quote['fee']==15000+math.ceil(quote['distanceKm']*3000)
 nearby=request('/customer/nearby?latitude=10.7736&longitude=106.7034',token=buyer['token'])
 branch_quote=next(item for item in nearby if item['storeId']==branch)
 assert abs(branch_quote['distanceKm']-quote['distanceKm'])<.001
 request('/customer/delivery-quote',{**quote_input,'latitude':0,'longitude':0},buyer['token'],expected=400)
 o=request('/customer/orders',make_order(quantity=2),buyer['token']);assert stock()==3
 assert o['distanceSource']=='ROAD' and abs(o['distanceKm']-quote['distanceKm'])<.001
 assert o['fee']==quote['fee'] and o['durationSeconds']==quote['durationSeconds']
 assert o['items'][0]['image']==uploaded['image']
 savedpin={'address':'12 Đường khách đã sửa '+stamp,'latitude':10.7736,'longitude':106.7034,'pinConfirmed':True}
 request('/customer/location',savedpin,buyer['token'],method='PUT')
 assert request('/customer/location',token=login(buyer['email'],buyer['password']))==savedpin
 request('/customer/location',token=shipper['token'],expected=403)
 checks.append('Ảnh thương hiệu hiển thị trong branches; ảnh món được snapshot; địa chỉ đã sửa giữ qua đăng nhập lại')
 assert 0<o['distanceKm']<10
 request('/merchant/products/'+str(p['id']),{'name':p['name'],'price':35000,'stock':3,'category':'Đồ uống'},store['token'],method='PUT')
 assert request('/customer/orders',token=buyer['token'])[0]['items'][0]['unitPrice']==25000
 checks.append('Báo phí và danh sách gần đây dùng tuyến đường OSRM thật; km/phí/thời gian đơn khớp báo giá ROAD; snapshot giá không đổi')
 bad=make_order();bad['latitude']=0;bad['longitude']=0;request('/customer/orders',bad,buyer['token'],expected=400)
 request('/merchant/orders/'+str(o['id'])+'/status',{'status':'ACCEPTED'},store['token'],method='PUT')
 for s in (shipper,other):request('/shipper/location',{'online':True,'latitude':10.7725,'longitude':106.7045},s['token'],method='PUT')
 assert any(x['id']==o['id'] for x in request('/shipper/offers',token=shipper['token']))
 offer_route=request('/shipper/orders/'+str(o['id'])+'/route',token=shipper['token'])
 assert offer_route['stage']=='PICKUP' and not offer_route['simulated']
 assert offer_route['activeRoute']==offer_route['pickupRoute']
 assert offer_route['pickupRoute']['coordinates'] and offer_route['deliveryRoute']['coordinates']
 request('/shipper/orders/'+str(o['id'])+'/route',token=buyer['token'],expected=403)
 def claim(s):
  req=urllib.request.Request(BASE+'/api/shipper/orders/'+str(o['id'])+'/claim',method='POST',headers={'Authorization':'Bearer '+s['token']})
  try:
   with urllib.request.urlopen(req) as res:return res.status,s
  except urllib.error.HTTPError as err:return err.code,s
 with concurrent.futures.ThreadPoolExecutor(2) as pool:results=list(pool.map(claim,(shipper,other)))
 assert sorted(x[0] for x in results)==[200,409];winner=next(s for code,s in results if code==200)
 customer_order=next(x for x in request('/customer/orders',token=buyer['token']) if x['id']==o['id'])
 assert customer_order['shipperAvatar']==winner['avatar'] and customer_order['shipperPhone']=='0901234567'
 checks.append('Hai shipper nhận đồng thời: đúng một thành công, một 409; khách xem được ảnh và số điện thoại tài xế')
 path='/shipper/orders/'+str(o['id'])
 loser=next(s for code,s in results if code==409)
 request(path+'/route',token=loser['token'],expected=403)
 request(path+'/status',{'status':'DELIVERING'},winner['token'],method='PUT',expected=400)
 request(path+'/payment',token=winner['token'],method='PUT',expected=400)
 request(path+'/status',{'status':'PICKED_UP','simulateArrival':True},winner['token'],method='PUT')
 simulated=request('/shipper/state',token=winner['token'])
 assert simulated['simulated'] and simulated['latitude']==10.7731 and simulated['longitude']==106.703
 delivery_route=request(path+'/route',token=winner['token'])
 assert delivery_route['stage']=='DELIVERY' and delivery_route['simulated']
 assert delivery_route['shipperLatitude']==delivery_route['storeLatitude']==10.7731
 assert delivery_route['shipperLongitude']==delivery_route['storeLongitude']==106.703
 assert delivery_route['activeRoute']==delivery_route['deliveryRoute']
 assert abs(delivery_route['activeRoute']['distanceKm']-quote['distanceKm'])<.001
 real=request('/shipper/location',{'online':True,'latitude':10.7731,'longitude':106.703},winner['token'],method='PUT')
 assert real['simulated'] is False
 assert request('/shipper/state',token=winner['token'])['simulated'] is False
 request(path+'/status',{'status':'DELIVERING'},winner['token'],method='PUT')
 checks.append('Bản đồ shipper có chặng tới cửa hàng và tới khách; mô phỏng nhận hàng chuyển GPS tài xế tới shop; GPS thật tắt mô phỏng; chặn shipper khác xem tuyến đã nhận')
 request(path+'/status',{'status':'DELIVERED'},winner['token'],method='PUT',expected=400)
 request(path+'/payment',token=winner['token'],method='PUT');request(path+'/payment',token=winner['token'],method='PUT',expected=409)
 done=request(path+'/status',{'status':'DELIVERED'},winner['token'],method='PUT');assert done['paid'] and len(done['history'])==6
 checks.append('COD đầy đủ, chặn bỏ bước/chưa thu tiền/thanh toán trùng; đơn DELIVERED + PAID')
 cancel=request('/customer/orders',make_order(),buyer['token']);assert stock()==2
 request('/customer/orders/'+str(cancel['id'])+'/cancel',token=buyer['token'],method='PUT');assert stock()==3
 request('/customer/orders/'+str(cancel['id'])+'/cancel',token=buyer['token'],method='PUT',expected=400);assert stock()==3
 scarce=request('/merchant/products',{'name':'QA kiểm tra tồn đồng thời '+stamp,'price':10000,'stock':1,'category':'QA'},store['token'])
 def concurrent_checkout(_):
  req=urllib.request.Request(BASE+'/api/customer/orders',data=json.dumps(make_order(pid=scarce['id'])).encode(),headers={'Authorization':'Bearer '+buyer['token'],'Content-Type':'application/json'})
  try:
   with urllib.request.urlopen(req) as res:return res.status
  except urllib.error.HTTPError as err:return err.code
 with concurrent.futures.ThreadPoolExecutor(2) as pool:codes=list(pool.map(concurrent_checkout,range(2)))
 assert sorted(codes)==[200,409] and stock(scarce['id'])==0
 checks.append('MySQL hai checkout đồng thời: 200/409, tồn bằng 0; hủy hoàn tồn đúng một lần')
 revenue=request('/admin/revenue',token=admin)
 branchrevenue=next(b for b in revenue['branches'] if b['storeId']==branch)
 assert branchrevenue['completedOrders']==1 and branchrevenue['grossSales']==50000 and branchrevenue['platformRevenue']==7500
 managedemail='qa.managed.'+stamp+'@cstore.local';managedpassword=secrets.token_urlsafe(18)
 managed=request('/admin/accounts',{'fullName':'QA quản lý tài khoản','email':managedemail,'password':managedpassword,'role':'SHIPPER'},admin,expected=201)
 managedtoken=login(managedemail,managedpassword)
 request('/admin/accounts/'+str(managed['id'])+'/status',{'blocked':True},admin,method='PUT')
 request('/auth/login',{'email':managedemail,'password':managedpassword},expected=403)
 request('/shipper/state',token=managedtoken,expected=401)
 request('/admin/accounts/'+str(managed['id'])+'/status',{'blocked':False},admin,method='PUT')
 login(managedemail,managedpassword)
 request('/admin/accounts/'+str(managed['id']),token=admin,method='DELETE',expected=204)
 request('/auth/login',{'email':managedemail,'password':managedpassword},expected=403)
 checks.append('Doanh thu chi nhánh đúng 15% tiền hàng đã giao + thu tiền; tạo/khóa/mở khóa/xóa tài khoản QA và thu hồi quyền token')
 folder=ROOT/'.local';folder.mkdir(exist_ok=True);folder.chmod(0o700)
 accounts={name:{k:v for k,v in obj.items() if k!='token'} for name,obj in {'store':store,'customer':buyer,'shipper':shipper,'otherShipper':other}.items()}
 path=folder/'qa-accounts.json';path.write_text(json.dumps(accounts,ensure_ascii=False,indent=2));path.chmod(0o600)
 report={'date':datetime.now(ZoneInfo('Asia/Vientiane')).isoformat(),'api':BASE,'branchId':branch,'productId':p['id'],'orderId':o['id'],'imagePath':uploaded['image'],'distanceKm':done['distanceKm'],'distanceSource':done['distanceSource'],'durationSeconds':done['durationSeconds'],'roadCoordinates':route['coordinates'],'total':done['total'],'checks':checks}
 (folder/'qa-report.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
 print(json.dumps({'result':'PASS','checks':checks,'branchId':branch,'productId':p['id'],'orderId':o['id'],'distanceKm':done['distanceKm']},ensure_ascii=False,indent=2))
if __name__=='__main__':main()
