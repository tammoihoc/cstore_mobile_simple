#!/usr/bin/env python3
"""Runs Android E2E with QA accounts, selects a real gallery image and injects emulator GPS.
Requires scripts/test-live.py first. Does not use static API responses.
"""
from pathlib import Path
import subprocess,secrets,time,json,re,xml.etree.ElementTree as E,os,sys,shutil,codecs
from datetime import datetime
from zoneinfo import ZoneInfo

def executable(variable,default):
 value=os.environ.get(variable) or default
 resolved=shutil.which(value)
 if resolved is None:
  raise SystemExit(f'Cannot find executable {value!r}. Set {variable} to its executable path or add {default} to PATH.')
 return resolved

flutter=executable('FLUTTER','flutter')
adb=executable('ADB','adb')
serial=os.environ.get('ANDROID_SERIAL') or 'emulator-5554'
adb_command=[adb,'-s',serial]
root=Path(__file__).resolve().parents[1]
accounts=json.loads((root/'.local/qa-accounts.json').read_text());report=json.loads((root/'.local/qa-report.json').read_text())
admin_mode='--admin' in sys.argv
profile_mode='--profile' in sys.argv
refinements_mode='--refinements' in sys.argv
mode='admin' if admin_mode else 'profile' if profile_mode else 'refinements' if refinements_mode else 'commerce'
config=dict(line.split('=',1) for line in (root/'.env').read_text().splitlines() if '=' in line and not line.startswith('#'))
logpath=root/('.local/android-'+mode+'-test.log')
command=[flutter,'test',('integration_test/create_partner_test.dart' if admin_mode else 'integration_test/profile_test.dart' if profile_mode else 'integration_test/ui_refinements_test.dart' if refinements_mode else 'integration_test/live_commerce_test.dart'),'-d',serial]
for name,value in {'QA_STORE_EMAIL':accounts['store']['email'],'QA_STORE_PASSWORD':accounts['store']['password'],'QA_CUSTOMER_EMAIL':accounts['customer']['email'],'QA_CUSTOMER_PASSWORD':accounts['customer']['password'],'QA_SHIPPER_EMAIL':accounts['shipper']['email'],'QA_SHIPPER_PASSWORD':accounts['shipper']['password'],'QA_OTHER_SHIPPER_EMAIL':accounts['otherShipper']['email'],'QA_OTHER_SHIPPER_PASSWORD':accounts['otherShipper']['password'],'QA_BRANCH_ID':report['branchId'],'QA_ADMIN_EMAIL':config['ADMIN_EMAIL'],'QA_ADMIN_PASSWORD':config['ADMIN_PASSWORD'],'QA_PARTNER_PASSWORD':secrets.token_urlsafe(18),'QA_PROFILE_PASSWORD':secrets.token_urlsafe(18)}.items():command.append('--dart-define='+name+'='+str(value))
picked=0;lastPicker=0;lastGeo=0
gallery_path='/sdcard/Download/cstore-qa-'+str(time.time_ns())+'.png'
subprocess.run([*adb_command,'push',str(root/'mobile/assets/images/cstore-logo.png'),gallery_path],capture_output=True,check=True)
subprocess.run([*adb_command,'shell','touch',gallery_path],capture_output=True,check=True)
subprocess.run([*adb_command,'shell','am','broadcast','-a','android.intent.action.MEDIA_SCANNER_SCAN_FILE','-d','file://'+gallery_path],capture_output=True,check=True)
for permission in ['android.permission.ACCESS_COARSE_LOCATION','android.permission.ACCESS_FINE_LOCATION']:subprocess.run([*adb_command,'shell','pm','grant','com.example.cstore_mobile',permission],capture_output=True)

def run(args,timeout=8):return subprocess.run([*adb_command,*args],capture_output=True,text=True,timeout=timeout)
location_state=run(['shell','dumpsys','location']).stdout
original_position=re.search(r'last location=Location\[(?:gps|fused) (-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',location_state)
if original_position is None:
 original_position=re.search(r'Location\[gps (-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',location_state)
original_coordinates=original_position.groups() if original_position else None
print('Android GPS trước kiểm thử: '+('đã lưu để khôi phục' if original_coordinates else 'chưa có tọa độ có thể khôi phục'),flush=True)
captured=set()
gps_restored=None
screenshot_dir=root/'.local/qa-screenshots';screenshot_dir.mkdir(exist_ok=True,mode=0o700)
with logpath.open('w') as log:
 logpath.chmod(0o600)
 with logpath.open('rb') as log_reader:
  decoder=codecs.getincrementaldecoder('utf-8')(errors='replace')
  def mirror_log(final=False):
   chunk=decoder.decode(log_reader.read(),final=final)
   if chunk:print(chunk,end='',flush=True)
   return chunk

  proc=subprocess.Popen(command,cwd=root/'mobile',stdout=log,stderr=subprocess.STDOUT)
  text=''
  try:
   while proc.poll() is None:
    text+=mirror_log();now=time.monotonic()
    if not refinements_mode and now-lastGeo>1:
     run(['emu','geo','fix',*(['106.7030','10.7731'] if admin_mode else ['106.7034','10.7736'])]);lastGeo=now
    if admin_mode or 'QA_GPS_READY' in text:
     for permission in ['android.permission.ACCESS_COARSE_LOCATION','android.permission.ACCESS_FINE_LOCATION']:run(['shell','pm','grant','com.example.cstore_mobile',permission])
    if text.count('QA_NATIVE_GALLERY_READY')>picked and now-lastPicker>3:
     lastPicker=now
     try:
      run(['shell','uiautomator','dump','/sdcard/cstore-picker.xml']);run(['pull','/sdcard/cstore-picker.xml','/tmp/cstore-picker.xml'])
      nodes=list(E.parse('/tmp/cstore-picker.xml').iter('node'))
      candidates=[n for n in nodes if any(k in n.get('resource-id','') for k in ['icon_thumbnail','media_thumbnail','image_thumbnail'])]
      if not candidates:candidates=[n for n in nodes if 'Photo taken' in n.get('content-desc','')]
      if candidates:
       bounds=list(map(int,re.findall(r'\d+',candidates[0].get('bounds',''))))
       if len(bounds)==4:
        run(['shell','input','tap',str((bounds[0]+bounds[2])//2),str((bounds[1]+bounds[3])//2)]);picked+=1;print('Selected native Android photo thumbnail.',flush=True)
     except (subprocess.TimeoutExpired,FileNotFoundError,E.ParseError):pass
    for label in set(re.findall(r'QA_SCREENSHOT_([A-Z_]+)',text))-captured:
     shot=subprocess.run([*adb_command,'exec-out','screencap','-p'],capture_output=True,timeout=8)
     if shot.returncode==0 and shot.stdout.startswith(b'\x89PNG'):
      image_path=screenshot_dir/(label.lower()+'.png');image_path.write_bytes(shot.stdout);image_path.chmod(0o600)
      captured.add(label);print('Ảnh kiểm tra giao diện: '+str(image_path),flush=True)
    time.sleep(.5)
  finally:
   if proc.poll() is None:
    proc.terminate()
    try:proc.wait(timeout=10)
    except subprocess.TimeoutExpired:
     proc.kill();proc.wait()
   text+=mirror_log(final=True)
   if original_coordinates:
    restored=run(['emu','geo','fix',original_coordinates[1],original_coordinates[0]])
    gps_restored=restored.returncode==0
    print('Đã khôi phục GPS máy ảo.' if restored.returncode==0 else 'Chưa khôi phục được GPS máy ảo.',flush=True)
result_path=root/('.local/android-'+mode+'-report.json')
summary={'date':datetime.now(ZoneInfo('Asia/Ho_Chi_Minh')).isoformat(),'result':'PASS' if proc.returncode==0 else 'FAIL','mode':mode,'device':serial,'gpsRestored':gps_restored,'screenshots':[str(screenshot_dir/(label.lower()+'.png')) for label in sorted(captured)]}
if not admin_mode and not profile_mode and not refinements_mode:summary['roadNavigationAndSimulatedPickupVerified']=proc.returncode==0 and 'simulatedPickup=true' in text
result_path.write_text(json.dumps(summary,ensure_ascii=False,indent=2));result_path.chmod(0o600)
print('Báo cáo Android: '+str(result_path),flush=True)
print('Android live integration exit code:',proc.returncode)
raise SystemExit(proc.returncode)
