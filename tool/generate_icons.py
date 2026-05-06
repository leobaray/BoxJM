"""
Gera os icones do app BOX JM (launcher + splash) a partir da logo oficial:
fundo branco com "JM" na fonte Owned Regular.

Saida:
  assets/icon/app_icon.png            — 1024x1024, fundo branco, "JM" preto
  assets/icon/app_icon_foreground.png — 1024x1024, transparente, "JM" preto (safe-zone)
  assets/icon/splash_logo.png         — 1024x1024, transparente, "JM" preto

Uso:
  python tool/generate_icons.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT_PATH = ROOT / "tool" / "fonts" / "owned.ttf"
OUT_DIR = ROOT / "assets" / "icon"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SIZE = 1024
TEXT = "JM"
INK = (255, 59, 59, 255)  # #FF3B3B — AppColors.ignition (brand red)
BLACK = (10, 10, 13, 255)  # #0A0A0D — obsidian do brand


def _render_ink(coverage: float, *, circle_fit: bool = False) -> Image.Image:
    """
    Renderiza "JM" e escala pro canvas final.

    Cuidado critico: o canvas de render tem que ser grande o suficiente
    pra caber o glifo INTEIRO — inclusive rabos/swashes que extrapolam o
    bbox oficial da fonte (comum em fonte hand-drawn como Owned Regular).
    Se cortar no render, o getbbox() so ve o que sobrou e a reescala fica
    assimetrica (foi o bug anterior: pe direito do M cortado).

    `coverage` = fracao da lateral do SIZE final que o glifo deve ocupar.
    `circle_fit=True` = caber dentro de um circulo de diametro coverage*SIZE.
    """
    font_size = 1024
    font = ImageFont.truetype(str(FONT_PATH), font_size)

    # Bbox oficial da fonte — serve de referencia de tamanho.
    fl, ft, fr, fb = font.getbbox(TEXT)
    fw, fh = fr - fl, fb - ft

    # Canvas com muita folga (3x em cada direcao) pra capturar qualquer
    # overhang que a fonte desenhe fora do bbox declarado.
    pad = max(fw, fh)
    canvas_w = fw + 2 * pad
    canvas_h = fh + 2 * pad
    raw = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(raw)
    # Desenha compensando o offset do bbox (fl, ft podem ser negativos).
    draw.text((pad - fl, pad - ft), TEXT, font=font, fill=INK)

    # Agora recorta no bbox REAL dos pixels desenhados.
    bbox = raw.getbbox()
    if bbox is None:
        return Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    glyph = raw.crop(bbox)

    gw, gh = glyph.size
    target = SIZE * coverage
    if circle_fit:
        diag = (gw * gw + gh * gh) ** 0.5
        scale = target / diag
    else:
        scale = min(target / gw, target / gh)

    nw, nh = max(1, int(gw * scale)), max(1, int(gh * scale))
    glyph = glyph.resize((nw, nh), Image.LANCZOS)

    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(glyph, ((SIZE - nw) // 2, (SIZE - nh) // 2), glyph)
    return out


def app_icon() -> Image.Image:
    """
    Legacy launcher icon (iOS + Android <8): canvas todo visivel,
    entao JM quase encosta nas bordas, sem medo de crop.
    """
    bg = Image.new("RGBA", (SIZE, SIZE), (255, 255, 255, 255))
    bg.alpha_composite(_render_ink(0.99))
    return bg


def foreground_icon() -> Image.Image:
    """
    Foreground do adaptive icon (Android 8+): launcher aplica mascara
    circular/squircle — safe-zone e um CIRCULO de ~66% de diametro.
    Usamos circle_fit a 0.80: a diagonal do glifo fica um pouco alem do
    safe-circle, mas como as "quinas" do bbox sao espaco vazio (JM e
    condensado), o ink real nao e cortado.
    """
    return _render_ink(0.80, circle_fit=True)


def _render_segment(text: str, color: tuple, font: ImageFont.FreeTypeFont) -> Image.Image:
    """Renderiza um segmento de texto e recorta no bbox real do ink."""
    fl, ft, fr, fb = font.getbbox(text)
    fw, fh = fr - fl, fb - ft
    pad = max(fw, fh)
    canvas = Image.new("RGBA", (fw + 2 * pad, fh + 2 * pad), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    draw.text((pad - fl, pad - ft), text, font=font, fill=color)
    bbox = canvas.getbbox()
    if bbox is None:
        return Image.new("RGBA", (1, 1), (0, 0, 0, 0))
    return canvas.crop(bbox)


def _compose_wordmark(box: Image.Image, jm: Image.Image) -> Image.Image:
    """Normaliza alturas e concatena horizontalmente. 'Box' vai pra altura do 'JM'."""
    target_h = jm.size[1]
    scale = target_h / box.size[1]
    new_w = max(1, int(box.size[0] * scale))
    box = box.resize((new_w, target_h), Image.LANCZOS)

    gap = int(target_h * 0.04)  # folga sutil entre as duas cores
    total_w = box.size[0] + gap + jm.size[0]
    out = Image.new("RGBA", (total_w, target_h), (0, 0, 0, 0))
    out.paste(box, (0, 0), box)
    out.paste(jm, (box.size[0] + gap, 0), jm)
    return out


def _compose_stacked(box: Image.Image, jm: Image.Image) -> Image.Image:
    """'Box' em cima, 'JM' embaixo, ambos com a mesma altura de ink."""
    target_h = jm.size[1]
    scale = target_h / box.size[1]
    box = box.resize((max(1, int(box.size[0] * scale)), target_h), Image.LANCZOS)

    gap = int(target_h * 0.12)
    total_w = max(box.size[0], jm.size[0])
    total_h = target_h + gap + target_h
    out = Image.new("RGBA", (total_w, total_h), (0, 0, 0, 0))
    out.paste(box, ((total_w - box.size[0]) // 2, 0), box)
    out.paste(jm, ((total_w - jm.size[0]) // 2, target_h + gap), jm)
    return out


def _place_on_canvas(glyph: Image.Image, coverage: float, *, circle_fit: bool) -> Image.Image:
    gw, gh = glyph.size
    target = SIZE * coverage
    if circle_fit:
        diag = (gw * gw + gh * gh) ** 0.5
        scale = target / diag
    else:
        scale = min(target / gw, target / gh)
    nw, nh = max(1, int(gw * scale)), max(1, int(gh * scale))
    glyph = glyph.resize((nw, nh), Image.LANCZOS)
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    out.paste(glyph, ((SIZE - nw) // 2, (SIZE - nh) // 2), glyph)
    return out


def splash_logo() -> Image.Image:
    """
    Splash horizontal (iOS + Android <12): 'Box' preto + 'JM' vermelho
    lado a lado, mesma altura. Usado em tela cheia, sem mascara circular.
    """
    font = ImageFont.truetype(str(FONT_PATH), 1024)
    box = _render_segment("Box", BLACK, font)
    jm = _render_segment("JM", INK, font)
    wordmark = _compose_wordmark(box, jm)
    return _place_on_canvas(wordmark, coverage=0.92, circle_fit=False)


def splash_logo_android12() -> Image.Image:
    """
    Splash do Android 12+: mesmo wordmark horizontal do splash principal,
    so que inscrito no circulo da safe-zone (~66% do canvas) — por isso
    fica visualmente menor que o splash_logo.png, mas 100% visivel sob
    a mascara circular que o sistema aplica.
    """
    font = ImageFont.truetype(str(FONT_PATH), 1024)
    box = _render_segment("Box", BLACK, font)
    jm = _render_segment("JM", INK, font)
    wordmark = _compose_wordmark(box, jm)
    return _place_on_canvas(wordmark, coverage=0.66, circle_fit=True)


def main() -> None:
    if not FONT_PATH.exists():
        raise SystemExit(f"Font not found: {FONT_PATH}")

    app_icon().save(OUT_DIR / "app_icon.png", "PNG", optimize=True)
    foreground_icon().save(OUT_DIR / "app_icon_foreground.png", "PNG", optimize=True)
    splash_logo().save(OUT_DIR / "splash_logo.png", "PNG", optimize=True)
    splash_logo_android12().save(OUT_DIR / "splash_logo_android12.png", "PNG", optimize=True)
    print(f"Icons written to {OUT_DIR}")


if __name__ == "__main__":
    main()
