#!/usr/bin/env bash
# يُنسخ أيقونات أندرويد (خلفية بيضاء + حواف دائرية) إلى مشروع Capacitor
set -e
RES=android/app/src/main/res
for d in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  cp build/android/mipmap-$d/*.png $RES/mipmap-$d/
done
rm -f $RES/mipmap-anydpi-v26/ic_launcher*.xml
mkdir -p $RES/mipmap-anydpi-v26 $RES/values
cat > $RES/mipmap-anydpi-v26/ic_launcher.xml <<X
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
  <background android:drawable="@color/ic_launcher_background"/>
  <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
X
cp $RES/mipmap-anydpi-v26/ic_launcher.xml $RES/mipmap-anydpi-v26/ic_launcher_round.xml
cat > $RES/values/ic_launcher_background.xml <<X
<?xml version="1.0" encoding="utf-8"?>
<resources><color name="ic_launcher_background">#FFFFFF</color></resources>
X
