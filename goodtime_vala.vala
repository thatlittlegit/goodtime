using Gtk;
using Gst;
using Granite;

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
	public string alarm_uri {
		get {
			return "playbin uri=https://www.winhistory.de/more/winstart/down/ont5.wav";
		}
		// TODO setting
	}

	private GLib.DateTime? time;

	public static void play_sound() {
		Gst.Element pipeline;
		try {
			pipeline = Gst.parse_launch("playbin uri=https://www.winhistory.de/more/winstart/down/ont5.wav");
		} catch (GLib.Error err) {
			error("Failed to load GStreamer (error %d: %s)", err.code, err.message);
		}

		pipeline.set_state(Gst.State.PLAYING);

		Gst.Bus bus = pipeline.get_bus();
		Gst.Message message;
		while ((message = bus.pop_filtered(Gst.MessageType.ERROR | Gst.MessageType.EOS)) == null) {
			GLib.Thread.usleep(10);
		}

		pipeline.set_state(Gst.State.NULL);
		return;
	}

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
			// HACK there has to be a better way than returning 'bool'...
			new GLib.Thread<bool>.try("GStreamer player", () => {
					play_sound();
					return true;
			});
		}
	}

	private void on_activate() {
		var builder = new Gtk.Builder.from_file("goodtime.glade");

		var window = (Gtk.Window) builder.get_object("window");
		this.add_window(window);

		var picker = new Granite.Widgets.TimePicker();
		((Gtk.Box) builder.get_object("popover-container")).pack_start(picker, true, true, 0);
		picker.show();
		((Gtk.Button)builder.get_object("show-popover")).clicked.connect(() => ((Gtk.Popover)builder.get_object("popover")).popup());
		((Gtk.Button)builder.get_object("accept-new-time")).clicked.connect(() => update_time(picker.time, (Gtk.HeaderBar)window.get_titlebar()));

		window.show();

		GLib.Timeout.add_seconds(1, () => {
				update((Gtk.Label)builder.get_object("time-left"));
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
