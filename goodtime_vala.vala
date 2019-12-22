using Gtk;
using Gst;
using Granite;

[CCode]
extern void update_time(Granite.Widgets.TimePicker picker, Gtk.HeaderBar headerbar);
[CCode]
extern bool update(Gtk.Label label);
[CCode]
extern bool get_still_open();

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

// HACK This code currently only exists for C FFI. When update() is translated,
// consider replacing this with a lambda.
public void* play_sound(void* userdata) {
	GoodTimeApplication.play_sound();
	return null;
}

class GoodTimeApplication : Gtk.Application {
	public string alarm_uri {
		get {
			return "playbin uri=https://www.winhistory.de/more/winstart/down/ont5.wav";
		}
		// TODO setting
	}

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
		while (get_still_open() && (message = bus.pop_filtered(Gst.MessageType.ERROR | Gst.MessageType.EOS)) == null) {
			GLib.Thread.usleep(10);
		}

		pipeline.set_state(Gst.State.NULL);
		return;
	}

	private void on_activate() {
		var builder = new Gtk.Builder.from_file("goodtime.glade");

		var window = (Gtk.Window) builder.get_object("window");
		this.add_window(window);

		var picker = new Granite.Widgets.TimePicker();
		((Gtk.Box) builder.get_object("popover-container")).pack_start(picker, true, true, 0);
		picker.show();
		((Gtk.Button)builder.get_object("show-popover")).clicked.connect(() => ((Gtk.Popover)builder.get_object("popover")).popup());
		((Gtk.Button)builder.get_object("accept-new-time")).clicked.connect(() => update_time(picker, (Gtk.HeaderBar)window.get_titlebar()));

		window.show();

		GLib.Timeout.add_seconds(1, () => update((Gtk.Label)builder.get_object("time-left")));
	}

	static int main(string[] args) {
		Gst.init(ref args);
		var app = new GoodTimeApplication();
		app.activate.connect((application) => app.on_activate());
		return app.run(args);
	}
}
