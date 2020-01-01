using Gst;

namespace GoodTime {
enum AlarmMode {
	FILESYSTEM = 0,
	NETWORKED = 1,
}

class AudioSystem {
	public static void play() {
		var settings = new GLib.Settings("tk.thatlittlegit.goodtime");
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
}
}
