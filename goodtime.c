#include <granite/granite.h>
#include <gtk/gtk.h>

#define GLADEOBJ(x) gtk_builder_get_object(builder, x)
#define GraniteTimePicker GraniteWidgetsTimePicker
#define GTCLAMP(x, y) (x > y ? y : x)

#define CLEAR_SECONDS_IN_GDATETIME(gdt) g_date_time_new_from_unix_local(g_date_time_to_unix(gdt) - g_date_time_get_second(gdt))
#define UNUSED(x) (void)(x)
#define MICROSECONDS_IN_DECADE 315576000000000

GtkWindow* window;
GraniteTimePicker* picker;

char* times_to_string(GTimeSpan span)
{
    char neg = '+';
    if (span < 0) {
        neg = '-';
        span = -span;
    }

    int hour = span / G_TIME_SPAN_HOUR;
    span %= G_TIME_SPAN_HOUR;
    int minute = span / G_TIME_SPAN_MINUTE;
    span %= G_TIME_SPAN_MINUTE;
    int second = span / G_TIME_SPAN_SECOND;

    // Assuming 2⁶⁴-1 is passed to us, then we know there will be a maximum of
    // 2⁶⁴ / G_TIME_SPAN_HOUR hours (2562047788).
    //
    // With this upper bound, we know there is no way that the number of digits
    // can be larger than 10 for the hours and 2 each for the minute/second. We allocate
    // one extra for the nullbyte, and two extras for the colons.
    //
    // For the curious: I believe that 2⁶⁴ is 2562047788:00:54.
#define TTS_ALLOCATED (10 + 2 + 2 + 1 + 2) // = 17
    char* date = malloc(TTS_ALLOCATED);
    snprintf(date, TTS_ALLOCATED, "%c%02d:%02d:%02d", neg, hour, minute, second);
    return date;
#undef TTS_ALLOCATED
}

static void update(GraniteTimePicker* _, gpointer __)
{
    UNUSED(_);
    UNUSED(__);

    char newSubtitle[32];
    GDateTime* time = CLEAR_SECONDS_IN_GDATETIME(granite_widgets_time_picker_get_time(picker));
    snprintf(newSubtitle, 31, "time until %s", g_date_time_format(time, "%R"));
    GtkWidget* headerbar = gtk_window_get_titlebar(window);
    gtk_header_bar_set_subtitle(GTK_HEADER_BAR(headerbar), newSubtitle);

    char* timeuntil = times_to_string(g_date_time_difference(time, g_date_time_new_now_local()));
    gtk_label_set_text(GTK_LABEL(gtk_bin_get_child(GTK_BIN(window))), timeuntil);
    free(timeuntil);
}

static gboolean routine_update(gpointer _)
{
    UNUSED(_);
    update(picker, window);
    return TRUE;
}

static void activate(GApplication* app, gpointer userdata)
{
    UNUSED(userdata);

    GtkBuilder* builder = gtk_builder_new_from_file("goodtime.glade");
    GObject* _window = GLADEOBJ("window");
    window = GTK_WINDOW(_window);
    gtk_application_add_window(GTK_APPLICATION(app), window);

    picker = granite_widgets_time_picker_new();
    gtk_header_bar_pack_start(GTK_HEADER_BAR(GLADEOBJ("headerbar")), GTK_WIDGET(picker));
    g_signal_connect(picker, "time_changed", G_CALLBACK(update), window);
    gtk_widget_show(GTK_WIDGET(picker));
    gtk_widget_show(GTK_WIDGET(window));

    g_timeout_add_seconds(1, routine_update, NULL);
}

int main(int argc, char** argv)
{
    GtkApplication* app = gtk_application_new("tk.thatlittlegit.goodtime", G_APPLICATION_FLAGS_NONE);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return status;
}
