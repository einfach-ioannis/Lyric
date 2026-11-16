# dmgbuild settings for Lyric's drag-and-drop installer. Used by scripts/make-dmg.sh.
import os

app = defines["app"]  # noqa: F821 (provided by dmgbuild)
format = "UDZO"
filesystem = "HFS+"
files = [app]
symlinks = {"Applications": "/Applications"}
background = defines["background"]  # noqa: F821
icon = defines.get("volume_icon")  # noqa: F821
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
window_rect = ((200, 120), (660, 420))
default_view = "icon-view"
show_icon_preview = False
icon_size = 112
text_size = 13
icon_locations = {
    os.path.basename(app): (165, 210),
    "Applications": (495, 210),
}
hide_extension = [os.path.basename(app)]
