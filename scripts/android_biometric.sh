#!/usr/bin/env bash
# يضيف صلاحيات البصمة إلى AndroidManifest.xml في مشروع Capacitor (يُشغَّل بعد: npx cap add android)
set -e
M=android/app/src/main/AndroidManifest.xml
test -f "$M" || { echo "AndroidManifest.xml غير موجود"; exit 1; }
python3 - "$M" <<'PY'
import sys
p=sys.argv[1]
s=open(p,encoding='utf-8').read()
perms=['<uses-permission android:name="android.permission.USE_BIOMETRIC" />',
       '<uses-permission android:name="android.permission.USE_FINGERPRINT" android:maxSdkVersion="28" />']
add=''.join('\n    '+x for x in perms if x.split('"')[1] not in s)
if add:
    i=s.rindex('</manifest>')
    s=s[:i].rstrip()+add+'\n\n'+s[i:]
    open(p,'w',encoding='utf-8').write(s)
print('permissions ok')
PY
grep -n "USE_BIOMETRIC" "$M"
