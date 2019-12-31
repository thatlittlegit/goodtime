using Gst;

namespace GoodTime {
enum AlarmMode {
	SYSTEM = 0,
	FILESYSTEM = 1,
	NETWORKED = 2,
}

class AudioSystem {
	public static void play() {
		var settings = new GLib.Settings("tk.thatlittlegit.goodtime");
		switch ((AlarmMode)settings.get_enum("alarm-mode")) {
			case SYSTEM: // TODO libcanberra
			case FILESYSTEM:
				// TODO use GIO
				play_gstreamer("file://" + settings.get_string("alarm-fs-path"));
				return;
			case NETWORKED:
				play_gstreamer(settings.get_string("alarm-net-uri"));
				return;
		}
	}

	protected static void play_gstreamer(string alarm_uri) {
		Element pipeline;

		try {
			pipeline = parse_launch("playbin uri=%s".printf(alarm_uri));
			pipeline.set_state(State.PLAYING);
		} catch (GLib.Error err) {
			error("Failed to load GStreamer (error %d: %s)", err.code, err.message);
		}

		Gst.Bus bus = pipeline.get_bus();
		while (bus.pop_filtered(Gst.MessageType.ERROR | Gst.MessageType.EOS) == null) {
			GLib.Thread.@yield();
		}

		pipeline.set_state(State.NULL);
	}
}
}
