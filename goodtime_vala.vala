using Gtk;
using Gst;

[CCode]
extern void gt_activate(GLib.Application application, void* userdata);

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

class GoodTimeApplication : Gtk.Application {
	static int main(string[] args) {
		Gst.init(ref args);
		var app = new GoodTimeApplication();
		app.activate.connect((application) => {
				gt_activate(application, null);
			});
		return app.run(args);
	}
}
