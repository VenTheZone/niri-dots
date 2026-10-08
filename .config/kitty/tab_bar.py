"""Lucy tab chip: Orbitron title, rounded caps — not a square, not powerline arrows."""

from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb, color_as_int

PUA = 0xE200
LEFT = ""   # U+E0B6 rounded
RIGHT = ""  # U+E0B4 rounded


def to_title_font(text: str) -> str:
    out: list[str] = []
    for ch in text:
        o = ord(ch)
        if 32 <= o <= 126:
            out.append(chr(PUA + (o - 32)))
        else:
            out.append(ch)
    return "".join(out)


def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_tab_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    tab_bg = screen.cursor.bg
    tab_fg = screen.cursor.fg
    default_bg = as_rgb(color_as_int(draw_data.default_bg))

    title = to_title_font(tab.title.strip() or "kitty")
    # caps (1+1) + padding spaces (1+1)
    budget = max(max_tab_length - 4, 2)
    if len(title) > budget:
        title = title[: max(budget - 1, 1)] + to_title_font("~")

    screen.cursor.fg = tab_bg
    screen.cursor.bg = default_bg
    screen.draw(LEFT)

    screen.cursor.fg = tab_fg
    screen.cursor.bg = tab_bg
    screen.draw(f" {title} ")

    screen.cursor.fg = tab_bg
    screen.cursor.bg = default_bg
    screen.draw(RIGHT)

    screen.cursor.fg = tab_fg
    screen.cursor.bg = default_bg
    if not is_last:
        screen.draw(" ")
    return screen.cursor.x
