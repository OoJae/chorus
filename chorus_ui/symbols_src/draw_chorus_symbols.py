"""Original Chorus symbols in the Mulberry visual style. CC BY-SA 4.0.

Usage: python3 -I draw.py <out_dir>
"""
import math
import os
import sys

out = sys.argv[1]
INK = '#231f20'
SKIN = '#ffeec8'
SHIRT = '#a9d7f3'
TROUSERS = '#797878'
DOT = '#5668af'
LILAC = '#efdcef'
RED = '#ed1d31'
HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" width="850" height="850" '
        'viewBox="0 0 850 850">')
TAIL = '<path fill="none" d="M0 0h850v850H0z"/></svg>'


def f(v):
    return ('%.1f' % v).rstrip('0').rstrip('.')


def dotted_square(x, y, side, r=14.3, n=5):
    """Mulberry's 'a thing' mark: a square outlined in dots."""
    pts = set()
    step = side / (n - 1)
    for i in range(n):
        for (px, py) in [(x + i * step, y), (x + i * step, y + side),
                         (x, y + i * step), (x + side, y + i * step)]:
            pts.add((round(px, 1), round(py, 1)))
    return ''.join(f'<circle cx="{f(px)}" cy="{f(py)}" r="{f(r)}" fill="{DOT}"/>'
                   for px, py in sorted(pts))


def dotted_circle(cx, cy, rad, count=20, r=14.3):
    return ''.join(
        f'<circle cx="{f(cx + rad * math.cos(2 * math.pi * k / count))}" '
        f'cy="{f(cy + rad * math.sin(2 * math.pi * k / count))}" r="{f(r)}" '
        f'fill="{DOT}"/>' for k in range(count))


def arrow(x1, y1, x2, y2, w=32, head=120, spread=0.72):
    """A straight line with an open arrowhead at (x2, y2), as in 'up'."""
    a = math.atan2(y2 - y1, x2 - x1)
    l = (x2 - head * math.cos(a - spread), y2 - head * math.sin(a - spread))
    r = (x2 - head * math.cos(a + spread), y2 - head * math.sin(a + spread))
    return (f'<g fill="none" stroke="{INK}" stroke-width="{w}" '
            f'stroke-linecap="round" stroke-linejoin="round">'
            f'<path d="M{f(x1)} {f(y1)}L{f(x2)} {f(y2)}"/>'
            f'<path d="M{f(l[0])} {f(l[1])}L{f(x2)} {f(y2)}L{f(r[0])} {f(r[1])}"/></g>')


def person(cx, top, arms='down', scale=1.0):
    """A standing figure: head, shirt, trousers, all outlined."""
    s = scale
    def X(v):
        return f(cx + v * s)
    def Y(v):
        return f(top + v * s)
    parts = []
    # Legs.
    parts.append(
        f'<path fill="{TROUSERS}" stroke="{INK}" stroke-width="14" '
        f'stroke-linejoin="round" d="M{X(-70)} {Y(300)}L{X(-62)} {Y(560)}'
        f'L{X(-8)} {Y(560)}L{X(0)} {Y(370)}L{X(8)} {Y(560)}L{X(62)} {Y(560)}'
        f'L{X(70)} {Y(300)}Z"/>')
    # Feet.
    for side in (-1, 1):
        parts.append(
            f'<path fill="{INK}" d="M{X(side * 8)} {Y(550)}L{X(side * 70)} {Y(550)}'
            f'Q{X(side * 92)} {Y(575)} {X(side * 62)} {Y(582)}L{X(side * 8)} {Y(582)}Z"/>')
    # Arms.
    if arms == 'down':
        arm = [(-88, 150, -112, 330), (88, 150, 112, 330)]
    elif arms == 'reach':
        arm = [(-88, 150, -112, 330), (88, 140, 250, 170)]
    else:
        arm = [(-88, 150, -112, 330), (88, 150, 112, 330)]
    for (x1, y1, x2, y2) in arm:
        parts.append(
            f'<path fill="none" stroke="{INK}" stroke-width="58" '
            f'stroke-linecap="round" d="M{X(x1)} {Y(y1)}L{X(x2)} {Y(y2)}"/>')
        parts.append(
            f'<path fill="none" stroke="{SHIRT}" stroke-width="32" '
            f'stroke-linecap="round" d="M{X(x1)} {Y(y1)}L{X(x1 + (x2 - x1) * 0.62)} '
            f'{Y(y1 + (y2 - y1) * 0.62)}"/>')
        parts.append(
            f'<circle cx="{X(x2)}" cy="{Y(y2)}" r="{f(22 * s)}" fill="{SKIN}" '
            f'stroke="{INK}" stroke-width="12"/>')
        parts.append(
            f'<path fill="none" stroke="{SKIN}" stroke-width="30" '
            f'stroke-linecap="round" d="M{X(x1 + (x2 - x1) * 0.66)} '
            f'{Y(y1 + (y2 - y1) * 0.66)}L{X(x2)} {Y(y2)}"/>')
    # Shirt.
    parts.append(
        f'<path fill="{SHIRT}" stroke="{INK}" stroke-width="14" '
        f'stroke-linejoin="round" d="M{X(-60)} {Y(115)}Q{X(0)} {Y(100)} {X(60)} {Y(115)}'
        f'Q{X(100)} {Y(125)} {X(96)} {Y(170)}L{X(78)} {Y(318)}L{X(-78)} {Y(318)}'
        f'L{X(-96)} {Y(170)}Q{X(-100)} {Y(125)} {X(-60)} {Y(115)}Z"/>')
    # Head.
    parts.append(
        f'<ellipse cx="{X(0)}" cy="{Y(48)}" rx="{f(46 * s)}" ry="{f(56 * s)}" '
        f'fill="{SKIN}" stroke="{INK}" stroke-width="14"/>')
    return ''.join(parts)


def rrect(x, y, w, h, r, fill, sw=18, extra=''):
    return (f'<rect x="{f(x)}" y="{f(y)}" width="{f(w)}" height="{f(h)}" rx="{f(r)}" '
            f'fill="{fill}" stroke="{INK}" stroke-width="{sw}"{extra}/>')


symbols = {}

# different: Mulberry's "same" turned round: a square is not a circle.
symbols['different'] = (
    dotted_square(95, 320, 230) +
    dotted_circle(640, 435, 118) +
    f'<g fill="none" stroke="{INK}" stroke-width="22" stroke-linecap="round">'
    f'<path d="M378 400h104M378 470h104M458 350l-56 170"/></g>')

# it: one thing, pointed at.
symbols['it'] = (
    arrow(425, 90, 425, 410) +
    dotted_square(300, 500, 250, r=15.5))

# that: a hand points at a thing over there.
hand_y = 380
symbols['that'] = (
    # Index finger, behind the fist.
    rrect(300, hand_y - 40, 250, 64, 32, SKIN) +
    # Wrist.
    f'<path fill="{SKIN}" stroke="{INK}" stroke-width="18" stroke-linejoin="round" '
    f'd="M60 {hand_y - 10}L170 {hand_y - 30}L170 {hand_y + 170}L60 {hand_y + 160}"/>' +
    # Fist.
    rrect(150, hand_y - 40, 220, 230, 70, SKIN) +
    # Curled fingers.
    f'<g fill="none" stroke="{INK}" stroke-width="16" stroke-linecap="round">'
    f'<path d="M290 {hand_y + 45}h80M290 {hand_y + 100}h78M290 {hand_y + 150}h66"/></g>' +
    # Thumb across the front.
    f'<path fill="{SKIN}" stroke="{INK}" stroke-width="18" stroke-linejoin="round" '
    f'stroke-linecap="round" d="M200 {hand_y + 20}Q260 {hand_y - 20} 330 {hand_y + 10}'
    f'Q352 {hand_y + 28} 330 {hand_y + 46}Q270 {hand_y + 40} 214 {hand_y + 70}"/>' +
    dotted_square(625, hand_y - 70, 150, r=13.5))

# here: this spot, right here.
symbols['here'] = (
    arrow(425, 80, 425, 560) +
    f'<ellipse cx="425" cy="655" rx="175" ry="52" fill="{DOT}"/>' +
    f'<path fill="none" stroke="{INK}" stroke-width="21" stroke-linecap="round" '
    f'd="M110 745h630"/>')

# you: the person being spoken to.
symbols['you'] = (
    arrow(90, 420, 380, 420) +
    person(590, 130))

# do: someone acting on a thing.
symbols['do'] = (
    person(300, 130, arms='reach') +
    rrect(600, 230, 150, 150, 6, LILAC, sw=16) +
    f'<g fill="none" stroke="{INK}" stroke-width="16" stroke-linecap="round">'
    f'<path d="M585 175l35 -45M680 165v-55M748 182l38 -38M585 435l35 45M680 445v55M748 428l38 38"/></g>')

# can: able, strong.
symbols['can'] = (
    f'<path fill="{SKIN}" stroke="{INK}" stroke-width="20" stroke-linejoin="round" '
    f'stroke-linecap="round" d="M90 560C170 560 205 455 325 440C430 428 470 490 482 545'
    f'L470 300L615 300C628 430 650 580 610 668C585 720 530 712 480 712L90 712"/>' +
    rrect(430, 140, 225, 200, 72, SKIN, sw=20) +
    f'<g fill="none" stroke="{INK}" stroke-width="16" stroke-linecap="round">'
    f'<path d="M430 210h62M430 262h66M445 312h52"/>'
    f'<path d="M330 470C390 470 430 500 440 540"/></g>' +
    f'<g fill="none" stroke="{INK}" stroke-width="18" stroke-linecap="round">'
    f'<path d="M705 160l55 -35M720 240h70M705 320l55 35"/></g>')

# stop: the sign, with a hand held up.
octagon = ' '.join(
    f'{f(425 + 395 * math.cos(math.pi / 8 + k * math.pi / 4))},'
    f'{f(425 + 395 * math.sin(math.pi / 8 + k * math.pi / 4))}' for k in range(8))
inner = ' '.join(
    f'{f(425 + 350 * math.cos(math.pi / 8 + k * math.pi / 4))},'
    f'{f(425 + 350 * math.sin(math.pi / 8 + k * math.pi / 4))}' for k in range(8))
fingers = ''.join(
    rrect(x, y, 58, 330 - (y - 160), 29, '#fff', sw=16)
    for x, y in [(298, 200), (362, 160), (426, 178), (490, 228)])
symbols['stop'] = (
    f'<polygon points="{octagon}" fill="{RED}" stroke="{INK}" stroke-width="20" '
    f'stroke-linejoin="round"/>' +
    f'<polygon points="{inner}" fill="none" stroke="#fff" stroke-width="16" '
    f'stroke-linejoin="round"/>' +
    fingers +
    f'<path fill="#fff" stroke="{INK}" stroke-width="16" stroke-linejoin="round" '
    f'stroke-linecap="round" d="M300 440L250 380Q222 352 200 378Q186 398 205 428'
    f'L300 560"/>' +
    rrect(290, 400, 266, 260, 80, '#fff', sw=16) +
    # Cover the joins between the fingers and the palm.
    f'<rect x="306" y="392" width="234" height="40" fill="#fff"/>')

os.makedirs(out, exist_ok=True)
for word, body in symbols.items():
    with open(os.path.join(out, f'{word}.svg'), 'w', encoding='utf-8') as fh:
        fh.write(HEAD + body + TAIL + '\n')
print(sorted(symbols))
