using Gtk;
using Gst;

[CCode]
extern void gt_activate(GLib.Application application, void* userdata);

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

	static int main(string[] args) {
		Gst.init(ref args);
		var app = new GoodTimeApplication();
		app.activate.connect((application) => {
				gt_activate(application, null);
			});
		return app.run(args);
	}
}
