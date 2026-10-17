#!/usr/bin/env bash
# يضيف مكوّن «SaveAs» (حفظ مباشر في أي مكان: فلاشة USB / بطاقة SD / ذاكرة الهاتف / Drive)
# ويسجّله في MainActivity. يُشغَّل بعد: npx cap add android
set -e
SRC_DIR="$(cd "$(dirname "$0")" && pwd)"
JAVA_DIR=$(dirname "$(find android/app/src/main/java -name MainActivity.java | head -n1)")
test -d "$JAVA_DIR" || { echo "MainActivity.java غير موجود"; exit 1; }
cp "$SRC_DIR/android/SaveAsPlugin.java" "$JAVA_DIR/SaveAsPlugin.java"
python3 - "$JAVA_DIR/MainActivity.java" <<'PY'
import sys,re
p=sys.argv[1]; s=open(p,encoding='utf-8').read()
if 'SaveAsPlugin' in s:
    print('MainActivity already patched'); raise SystemExit(0)
if 'import android.os.Bundle;' not in s:
    s=re.sub(r'(package [^;]+;)', r'\1\n\nimport android.os.Bundle;', s, count=1)
m=re.search(r'class\s+MainActivity\s+extends\s+BridgeActivity\s*\{', s)
if not m: raise SystemExit('MainActivity class not found')
add='\n    @Override\n    public void onCreate(Bundle savedInstanceState) {\n        registerPlugin(SaveAsPlugin.class);\n        super.onCreate(savedInstanceState);\n    }\n'
s=s[:m.end()]+add+s[m.end():]
open(p,'w',encoding='utf-8').write(s)
print('MainActivity patched')
PY
cat "$JAVA_DIR/MainActivity.java"
echo "saveas ok"
