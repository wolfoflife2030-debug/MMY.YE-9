package ye.mmy.platform;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import androidx.activity.result.ActivityResult;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * يفتح نافذة «حفظ باسم» الخاصة بنظام أندرويد (Storage Access Framework) ليختار المستخدم
 * أي مكان: ذاكرة الهاتف، بطاقة SD، فلاشة USB (OTG)، Google Drive ... ثم ينسخ الملف إليه مباشرة.
 * الملف المصدر يجب أن يكون داخل مجلد الكاش الخاص بالتطبيق (يكتبه المكوّن Filesystem).
 */
@CapacitorPlugin(name = "SaveAs")
public class SaveAsPlugin extends Plugin {

    @PluginMethod
    public void saveFile(PluginCall call) {
        String name = call.getString("name", "mmy-file");
        String mime = call.getString("mime", "application/octet-stream");
        String src = call.getString("path");
        if (src == null || src.isEmpty()) { call.reject("path is required"); return; }
        try {
            File f = resolveCacheFile(src);
            if (f == null || !f.isFile()) { call.reject("source file not found"); return; }
        } catch (Exception e) { call.reject("bad source: " + e.getMessage()); return; }

        Intent intent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType(mime);
        intent.putExtra(Intent.EXTRA_TITLE, name);
        startActivityForResult(call, intent, "saveResult");
    }

    @ActivityCallback
    private void saveResult(final PluginCall call, ActivityResult result) {
        if (call == null) return;
        Intent data = result == null ? null : result.getData();
        if (result == null || result.getResultCode() != Activity.RESULT_OK || data == null || data.getData() == null) {
            JSObject r = new JSObject();
            r.put("saved", false);
            call.resolve(r);
            return;
        }
        final Uri dest = data.getData();
        final String src = call.getString("path");
        new Thread(new Runnable() {
            @Override public void run() {
                InputStream in = null;
                OutputStream out = null;
                try {
                    File f = resolveCacheFile(src);
                    in = new FileInputStream(f);
                    out = getContext().getContentResolver().openOutputStream(dest, "wt");
                    if (out == null) throw new Exception("cannot open destination");
                    byte[] buf = new byte[256 * 1024];
                    int n;
                    while ((n = in.read(buf)) > 0) out.write(buf, 0, n);
                    out.flush();
                    out.close(); out = null;
                    try { f.delete(); } catch (Exception ignore) {}
                    JSObject r = new JSObject();
                    r.put("saved", true);
                    r.put("uri", dest.toString());
                    call.resolve(r);
                } catch (Exception e) {
                    call.reject("save failed: " + e.getMessage());
                } finally {
                    try { if (in != null) in.close(); } catch (Exception ignore) {}
                    try { if (out != null) out.close(); } catch (Exception ignore) {}
                }
            }
        }).start();
    }

    /** يقبل file:///... أو مساراً عادياً، ويرفض أي ملف خارج مجلد كاش التطبيق. */
    private File resolveCacheFile(String src) throws Exception {
        String path = src;
        if (src.startsWith("file:")) path = Uri.parse(src).getPath();
        if (path == null) return null;
        File f = new File(path).getCanonicalFile();
        String root = getContext().getCacheDir().getCanonicalPath();
        if (!f.getPath().startsWith(root + File.separator)) throw new Exception("path outside cache");
        return f;
    }
}
