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
				var fd = File.new_for_path(settings.get_string("alarm-fs-path"));
				var uri = fd.get_uri();
				play_gstreamer(uri);
				g_free(uri); // This is necessary according to the docs
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
