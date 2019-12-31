namespace GoodTime {
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

	public DateTime datetime_from_hm(int hours, int minutes) {
		var current = new DateTime.now_local();

		return new DateTime.local(current.get_year(), current.get_month(), current.get_day_of_month(), hours, minutes, 0);
	}
}

