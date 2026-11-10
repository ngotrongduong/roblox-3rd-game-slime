# The top of a Secret slime's painting (the owner's own art), enlarged three times, to read where its horns or ears
# stand and at what angle (skill slime-wear). The colours as in the Secret's id, in alphabetical order: navy-red for
# secret-navy-red (the paintings: reference/goo-lineage-web/assets/slime.secret.*.png).
#   python "C:\Roblox 3rd game\.claude\skills\slime-wear\paint_top.py" navy-red <out.png>
import sys
from PIL import Image

name, out = sys.argv[1], sys.argv[2]
im = Image.open(r"C:\Roblox 3rd game\reference\goo-lineage-web\assets\slime.secret." + name + ".png")
top = im.crop((0, 0, im.width, int(im.height * 0.45)))
top.resize((top.width * 3, top.height * 3), Image.LANCZOS).save(out)
print(name, im.size, "->", out)
