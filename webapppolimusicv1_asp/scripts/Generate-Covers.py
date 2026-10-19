"""Create repo-native vector fallbacks for artwork absent from the supplied resources."""
from pathlib import Path

root = Path(__file__).resolve().parent.parent / 'assets'
covers = [
    ('#1c3437', '#8dc4a5', 'AFTER', 'HOURS', '<circle cx="180" cy="170" r="100" fill="none" stroke="#9ce1bc" stroke-width="26"/><path d="M0 310 350 70v140L0 450" fill="#f4dec5" opacity=".6"/>'),
    ('#58394a', '#eab29d', 'NEW', 'HORIZONS', '<circle cx="200" cy="175" r="113" fill="#eaa18b"/><path d="M0 210q100-90 200 0t200 0v200H0" fill="#8a5366"/><path d="M0 260q100-80 200 0t200 0v200H0" fill="#402f4b"/>'),
    ('#3f3361', '#d0b7f3', 'SLOW', 'MOTION', '<g fill="none" stroke="#bda1e8" stroke-width="18"><ellipse cx="200" cy="180" rx="170" ry="70" transform="rotate(-35 200 180)"/><ellipse cx="200" cy="180" rx="130" ry="53" transform="rotate(-35 200 180)"/><ellipse cx="200" cy="180" rx="88" ry="36" transform="rotate(-35 200 180)"/></g>'),
    ('#192f4e', '#9ac3d7', 'MIDNIGHT', 'RADIO', '<path d="M60 0v400m55-400v400m55-400v400m55-400v400m55-400v400m55-400v400" stroke="#458ea4" stroke-width="20"/><circle cx="195" cy="180" r="95" fill="#b4cbd3"/><path d="M0 280h400v120H0" fill="#162a42" opacity=".85"/>'),
    ('#85422d', '#f7d6a0', 'GOLDEN', 'DAYS', '<g fill="none" stroke="#e6b96e" stroke-width="16"><circle cx="200" cy="178" r="40"/><circle cx="200" cy="178" r="75"/><circle cx="200" cy="178" r="110"/><circle cx="200" cy="178" r="145"/></g><path d="M0 280h400v120H0" fill="#663025"/>'),
]
for i, (background, foreground, title, subtitle, shape) in enumerate(covers):
    svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 400"><rect width="400" height="400" fill="{background}"/>{shape}<text x="25" y="34" fill="{foreground}" font-family="Arial,sans-serif" font-size="9" letter-spacing="3">POLIMUSIC / COLLECTION 0{i+1}</text><text x="25" y="330" fill="{foreground}" font-family="Arial,sans-serif" font-weight="700" font-size="39" letter-spacing="-1">{title}</text><text x="25" y="372" fill="{foreground}" font-family="Arial,sans-serif" font-weight="700" font-size="39" letter-spacing="-1">{subtitle}</text></svg>'''
    (root / f'cover-{i}.svg').write_text(svg, encoding='utf-8')
print('Created five SVG fallback covers.')
