using Gst;

namespace GoodTime {
enum AlarmMode {
	FILESYSTEM = 0,
	NETWORKED = 1,
}

class AudioSystem {
	public static void alert_async() throws GLib.Error {
		// TODO don't use the bool type argument
		new Thread<bool>.try("alarm", () => {
			alert();
			return true;
		});
	}

	public static void alert() {
		var settings = new GLib.Settings("tk.thatlittlegit.goodtime");

		if (settings.get_boolean("notifications")) {
			show_notification();
		}

		if (!settings.get_boolean("alarm-enabled")) {
			return;
		}

		switch ((AlarmMode)settings.get_enum("alarm-mode")) {
			case FILESYSTEM:
				play_gstreamer(settings.get_string("alarm-fs-uri"));
				return;
			case NETWORKED:
				play_gstreamer(settings.get_string("alarm-net-uri"));
				return;
		}
	}

	private static void play_gstreamer(string alarm_uri) {
		Element pipeline;

		try {
			pipeline = parse_launch("playbin uri=%s".printf(alarm_uri));
			pipeline.set_state(State.PLAYING);
		} catch (GLib.Error err) {
			warning("Failed to load GStreamer (error %d: %s)", err.code, err.message);
			return;
		}

		Gst.Bus bus = pipeline.get_bus();
		while (bus.pop_filtered(Gst.MessageType.ERROR | Gst.MessageType.EOS) == null) {
			GLib.Thread.@yield();
		}

		pipeline.set_state(State.NULL);
	}

	private static void show_notification() {
		var notification = new Notification("Your GoodTime alarm has elapsed");
		notification.set_body("Time to get to work!");
		Application.get_default().send_notification(null, notification);
	}
}
}
