#!/usr/bin/env bash
# يستبدل شاشة البداية الافتراضية لـ Capacitor (شعار Capacitor) بشعار البرنامج.
# يُشغَّل بعد: npx cap add android
set -e
RES=android/app/src/main/res
test -d "$RES" || { echo "مشروع أندرويد غير موجود"; exit 1; }
for d in build/android-splash/drawable*/; do
  n=$(basename "$d")
  mkdir -p "$RES/$n"
  cp "$d/splash.png" "$RES/$n/splash.png"
done
cp build/android-splash/splash_icon.png "$RES/drawable/splash_icon.png"
python3 - "$RES/values/styles.xml" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p,encoding='utf-8').read()
if 'windowSplashScreenAnimatedIcon' not in s:
    m=re.search(r'(<style name="AppTheme\.NoActionBarLaunch"[^>]*>)',s)
    if not m: raise SystemExit('NoActionBarLaunch style not found')
    add=('\n        <item name="windowSplashScreenBackground">#060A07</item>'
         '\n        <item name="windowSplashScreenAnimatedIcon">@drawable/splash_icon</item>')
    s=s[:m.end()]+add+s[m.end():]
    open(p,'w',encoding='utf-8').write(s)
print('splash ok')
PY
grep -n "windowSplashScreen" "$RES/values/styles.xml"
