using Gst;
using Gtk;

enum AlarmMode {
	SYSTEM,
	NETWORKED,
	FILESYSTEM,
}

class AudioSettings : Granite.SimpleSettingsPage {
	public AudioSettings() {
		GLib.Object(
			title: "Alarm",
			description: "GoodTime can warn you when time's up. Here, you can select how you want to be informed. This settings panel is currently not functional.",
			activatable: true,
			icon_name: "applications-multimedia-symbolic"
		);
	}

	construct {
		var container = new Gtk.Box(Orientation.VERTICAL, 8);

		var system = new Gtk.RadioButton.with_label(null, "System sounds");
		var fileloc = new Gtk.RadioButton.with_label(null, "File location...");
		var network = new Gtk.RadioButton.with_label(null, "Network URI...");

		system.set_sensitive(false);
		system.clicked.connect(() => AudioSystem.mode = AlarmMode.SYSTEM);
		fileloc.set_sensitive(false);
		fileloc.clicked.connect(() => AudioSystem.mode = AlarmMode.FILESYSTEM);
		network.set_sensitive(false);
		network.clicked.connect(() => AudioSystem.mode = AlarmMode.NETWORKED);

		fileloc.join_group(system);
		network.join_group(system);

		container.add(system);
		container.add(fileloc);
		container.add(network);

		content_area.add(container);
		container.show_all();
	}
}
class AudioSystem : Gtk.Window {
	public const string alarm_uri = "https://www.winhistory.de/more/winstart/down/ont5.wav";
	public static AlarmMode mode = AlarmMode.NETWORKED;

	public AudioSystem() {
		set_default_size(400, 300);
		title = "GoodTime Settings";
		var settings_page = new AudioSettings();
		add(settings_page);
		show_all();
	}

	public static void play() {
		switch (mode) {
			case SYSTEM: // TODO libcanberra
			case NETWORKED:
			case FILESYSTEM:
				play_gstreamer();
				break;
			default:
				error("AlarmMode is not valid");
		}
	}

	protected static void play_gstreamer() {
		stdout.printf("playbin uri=%s".printf(alarm_uri));
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
