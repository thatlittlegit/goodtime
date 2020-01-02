# GoodTime
GoodTime is a GNOME/GTK+ application for setting simple timers and counting
down. It might be useful if you're a person who says, *Ok, I'll start this at
4 o'clock...* and then looks at the time a while later and sees it's 6.

## Limitations
* Against the advice of the GNOME developers, something in the code modifies the
  GSettings as soon as the process is loaded. This could lead to worse
  performance at first start on some systems due to dconf being lazy-loaded.
* I could not for the life of me get `gettext` to work, so internationalization
  is not going to work. If you do know, send a PR!
* The code is probably subpar.

## License
This code is licensed under the GNU General Public License version 3. See the
[LICENSE](LICENSE) file.
