import sys, os
from PIL import Image, ImageDraw
win_src, and_src, out = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(out, exist_ok=True)

def trim(im):
    bg = Image.new('RGBA', im.size, (255,255,255,255))
    flat = Image.alpha_composite(bg, im.convert('RGBA')).convert('RGB')
    from PIL import ImageChops
    diff = ImageChops.difference(flat, Image.new('RGB', flat.size, (255,255,255)))
    box = diff.getbbox()
    return im.crop(box) if box else im

def white_flat(im):
    bg = Image.new('RGBA', im.size, (255,255,255,255))
    return Image.alpha_composite(bg, im.convert('RGBA'))

def rounded_icon(src, size, radius_ratio, pad_ratio, circle=False):
    S = size*4
    base = Image.new('RGBA', (S,S), (0,0,0,0))
    mask = Image.new('L', (S,S), 0)
    d = ImageDraw.Draw(mask)
    if circle: d.ellipse((0,0,S-1,S-1), fill=255)
    else: d.rounded_rectangle((0,0,S-1,S-1), radius=int(S*radius_ratio), fill=255)
    white = Image.new('RGBA', (S,S), (255,255,255,255))
    base.paste(white, (0,0), mask)
    logo = trim(src)
    avail = int(S*(1-2*pad_ratio))
    sc = min(avail/logo.width, avail/logo.height)
    logo = logo.resize((max(1,int(logo.width*sc)), max(1,int(logo.height*sc))), Image.LANCZOS)
    layer = Image.new('RGBA', (S,S), (0,0,0,0))
    layer.paste(logo, ((S-logo.width)//2, (S-logo.height)//2), logo)
    base = Image.alpha_composite(base, layer)
    return base.resize((size,size), Image.LANCZOS)

win = Image.open(win_src); andr = Image.open(and_src)
# حجم الشعار داخل أيقونة أندرويد (كان 0.12 و0.56). زيادة PAD أو إنقاص LOGO = شعار أصغر.
ANDROID_PAD = 0.165     # الأيقونة العادية/القديمة
ADAPTIVE_LOGO = 0.50    # الأيقونة التكيفية (أندرويد 8+) نسبة الشعار من الإطار

# Windows / desktop
big = rounded_icon(win, 1024, 0.22, 0.12)
big.save(f'{out}/icon.png')
big.save(f'{out}/icon.ico', sizes=[(256,256),(128,128),(64,64),(48,48),(32,32),(24,24),(16,16)])
rounded_icon(win, 512, 0.22, 0.12).save(f'{out}/icon-512.png')

# Android launcher icons (legacy, round, adaptive foreground)
dens = {'mdpi':1,'hdpi':1.5,'xhdpi':2,'xxhdpi':3,'xxxhdpi':4}
for name,m in dens.items():
    d = f'{out}/android/mipmap-{name}'; os.makedirs(d, exist_ok=True)
    s = int(48*m)
    rounded_icon(andr, s, 0.22, ANDROID_PAD).save(f'{d}/ic_launcher.png')
    rounded_icon(andr, s, 0, ANDROID_PAD+0.02, circle=True).save(f'{d}/ic_launcher_round.png')
    # adaptive foreground: 108dp, logo inside safe zone (66dp of 108)
    fs = int(108*m); S = fs
    fg = Image.new('RGBA', (S,S), (0,0,0,0))
    logo = trim(andr); avail = int(S*ADAPTIVE_LOGO)
    sc = min(avail/logo.width, avail/logo.height)
    logo = logo.resize((int(logo.width*sc), int(logo.height*sc)), Image.LANCZOS)
    fg.paste(logo, ((S-logo.width)//2,(S-logo.height)//2), logo)
    fg.save(f'{d}/ic_launcher_foreground.png')
# in-app logo (default program logo) – white round-corner square
rounded_icon(andr, 512, 0.22, 0.10).convert('RGBA').save(f'{out}/logo-512.png')
Image.open(f'{out}/logo-512.png').save(f'{out}/logo.webp', quality=90)
print('ok')
