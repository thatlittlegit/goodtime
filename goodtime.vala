public string timespan_to_string(GLib.TimeSpan span) {
	var neg = '+';
	if (span < 0) {
		neg = '-';
		span = -span;
	}

	var hour = span / GLib.TimeSpan.HOUR;
	span %= GLib.TimeSpan.HOUR;
	var minute = span / GLib.TimeSpan.MINUTE;
	span %= GLib.TimeSpan.MINUTE;
	var second = span / GLib.TimeSpan.SECOND;

	return "%c%02d:%02d:%02d".printf(neg, (int) hour, (int) minute, (int) second);
}

public GLib.DateTime clear_gdatetime_seconds(GLib.DateTime old) {
	return new GLib.DateTime.from_unix_local(old.to_unix() - old.get_second());
}

class GoodTimeApplication : Gtk.Application {
	private GLib.DateTime? time;

	private void update_time(GLib.DateTime time, Gtk.HeaderBar headerbar) {
		this.time = clear_gdatetime_seconds(time);
		headerbar.subtitle = "time until %s".printf(time.format("%R"));
	}

	private void update(Gtk.Label label) {
		if (time == null) {
			label.set_text("+??:??:??");
			return;
		}

		GLib.TimeSpan span = time.difference(new GLib.DateTime.now_local());
		string timeuntil = timespan_to_string(span);
		label.set_text(timeuntil);

		if (span < 0 && span >= -GLib.TimeSpan.SECOND) {
			try {
				// HACK there has to be a better way than returning 'bool'...
				new GLib.Thread<bool>.try("GStreamer player", () => {
						AudioSystem.play();
						return true;
				});
			} catch (Error err) {
				// ignore
			}
		}
	}

	private void on_activate() {
		var window = new Gtk.ApplicationWindow(this);

		var time_until = new Gtk.Label("+??:??:??");
		var big_text_attrs = new Pango.AttrList();
		big_text_attrs.insert(Pango.attr_scale_new(8));
		big_text_attrs.insert(Pango.attr_family_new("monospace 10"));
		big_text_attrs.insert(Pango.attr_weight_new(Pango.Weight.HEAVY));
		time_until.set_attributes(big_text_attrs);

		var headerbar = new Gtk.HeaderBar();
		headerbar.set_title("GoodTime");
		headerbar.show_close_button = true;
		var show_alarm_picker = new Gtk.Button.from_icon_name("alarm-symbolic");
		var show_settings = new Gtk.Button.from_icon_name("preferences-system-symbolic");

		var popover = new Gtk.Popover(show_alarm_picker);
		var popover_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 8);
		var picker = new Granite.Widgets.TimePicker();
		var accept_new = new Gtk.Button.from_icon_name("object-select-symbolic");

		popover.add(popover_box);
		popover_box.pack_start(picker, true, true, 0);
		popover_box.pack_end(accept_new, false, false, 0);
		headerbar.pack_start(show_alarm_picker);
		headerbar.pack_start(show_settings);
		window.add(time_until);
		window.set_titlebar(headerbar);

		show_alarm_picker.clicked.connect(() => popover.popup());
		accept_new.clicked.connect(() => update_time(picker.time, headerbar));
		show_settings.clicked.connect(() => (new AudioSystem()).show());

		popover_box.show();
		picker.show();
		accept_new.show();
		show_settings.show();
		show_alarm_picker.show();
		headerbar.show();
		time_until.show();
		window.show();

		GLib.Timeout.add_seconds(1, () => {
				update(time_until);
				return true;
				});
	}

	static int main(string[] args) {
		Gst.init(ref args);
		var app = new GoodTimeApplication();
		app.activate.connect((application) => app.on_activate());
		return app.run(args);
	}
}