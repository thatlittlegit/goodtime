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
	[GtkTemplate (ui = "/tk/thatlittlegit/goodtime/window.ui")]
	public class Window : Gtk.ApplicationWindow {
		[GtkChild]
		private Gtk.Label output;
		[GtkChild]
		private Gtk.HeaderBar headerbar;
		[GtkChild]
		private Gtk.Popover time_select_popover;
		[GtkChild]
		private Gtk.SpinButton minute_spin;
		[GtkChild]
		private Gtk.SpinButton hour_spin;
		[GtkChild]
		private Gtk.Stack stack;
		[GtkChild]
		private Gtk.Box settings_box;

		private DateTime time = null;

		public Window (Gtk.Application app) {
			Object (application: app);
		}

		construct {
			settings_box.add(new GoodTime.Settings());
			Timeout.add_seconds(1, () => {
				update_time();
				return true;
			});
		}

		[GtkCallback]
		public void update_headerbar() {
			time = datetime_from_hm(hour_spin.get_value_as_int(), minute_spin.get_value_as_int());

			var format = (new GLib.Settings("tk.thatlittlegit.goodtime").get_boolean("twenty-four-hour")) ? "%R" : "%r";
			headerbar.set_subtitle("time until %s".printf(time.format(format)));
		}

		[GtkCallback]
		public void show_time_selector() {
			time_select_popover.popup();
		}

		public void update_time() {
			if (time == null) {
				output.set_text("+??:??:??");
				return;
			}

			var time_remaining = time.difference(new DateTime.now_local());
			output.set_text(timespan_to_string(time_remaining));

			if (time_remaining < 0 && time_remaining > -TimeSpan.SECOND) {
				try {
					AudioSystem.alert_async();
				} catch(Error err) { }
			}
		}

		[GtkCallback]
		public void toggle_settings() {
			if (stack.get_visible_child() == output) {
				stack.set_visible_child(settings_box);
			} else {
				stack.set_visible_child(output);
			}
		}
	}
}
