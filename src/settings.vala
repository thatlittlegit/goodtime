/* window.vala
 *
 * Copyright 2019 thatlittlegit
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace GoodTime {
	[GtkTemplate (ui = "/tk/thatlittlegit/goodtime/settings.ui")]
	class Settings : Gtk.Box {
		private GLib.Settings settings = new GLib.Settings("tk.thatlittlegit.goodtime");
		private AlarmMode _alarm_mode;
		private bool updating_alarm_mode = false;
		private AlarmMode alarm_mode {
			get {
				return _alarm_mode;
			}
			set {
				updating_alarm_mode = true;
				_alarm_mode = value;
				fs_opt.active = value == AlarmMode.FILESYSTEM;
				net_opt.active = value == AlarmMode.NETWORKED;
				updating_alarm_mode = false;

				if (settings.get_enum("alarm-mode") != value) {
					settings.set_enum("alarm-mode", value);
				}
			}
		}
		[GtkChild]
		private Gtk.CheckButton sound_notify_checkbox;
		[GtkChild]
		private Gtk.RadioButton fs_opt;
		[GtkChild]
		private Gtk.RadioButton net_opt;
		[GtkChild]
		private Gtk.FileChooserButton fs_path;
		[GtkChild]
		private Gtk.Entry net_uri;

		private void set_sensitivity_of_alarm_options(bool sensitive) {
			fs_opt.set_sensitive(sensitive);
			net_opt.set_sensitive(sensitive);
		}

		construct {
			sound_notify_checkbox.clicked.connect(() => {
				set_sensitivity_of_alarm_options(sound_notify_checkbox.active);
			});

			alarm_mode = (AlarmMode)settings.get_enum("alarm-mode");
			settings.changed.connect((key) => {
				if (key == "alarm-mode") {
					var new_alarm_mode = (AlarmMode)settings.get_enum("alarm-mode");

					if (new_alarm_mode != alarm_mode) {
						alarm_mode = new_alarm_mode;
					}
				}
			});
			settings.bind("alarm-enabled", sound_notify_checkbox, "active", SettingsBindFlags.DEFAULT);
			settings.bind("alarm-net-uri", net_uri, "text", SettingsBindFlags.DEFAULT);
			set_sensitivity_of_alarm_options(sound_notify_checkbox.active);
		}

		[GtkCallback]
		private void update_alarm_mode() {
			if (updating_alarm_mode) {
				return;
			} else if (fs_opt.active) {
				alarm_mode = AlarmMode.FILESYSTEM;
			} else if (net_opt.active) {
				alarm_mode = AlarmMode.NETWORKED;
			}
		}
	}
}
