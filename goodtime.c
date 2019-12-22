#include <granite/granite.h>
#include <gtk/gtk.h>
#include <stdbool.h>
#include <time.h>

#define GLADEOBJ(x) gtk_builder_get_object(builder, x)
#define GraniteTimePicker GraniteWidgetsTimePicker
#define GTCLAMP(x, y) (x > y ? y : x)

#define CLEAR_SECONDS_IN_GDATETIME(gdt) g_date_time_new_from_unix_local(g_date_time_to_unix(gdt) - g_date_time_get_second(gdt))
#define UNUSED(x) (void)(x)
#define MICROSECONDS_IN_DECADE 315576000000000

const struct timespec poll_interval = { 0, 1000 };
GtkWindow* window;
GraniteTimePicker* picker;
bool stillopen = true;

// Implemented here
static void update(GraniteTimePicker* IGNORED, gpointer _IGNORED);
static gboolean routine_update(gpointer IGNORED);
void gt_activate(GApplication* application, gpointer IGNORED);
bool get_still_open();

// Implemented in Vala
gpointer play_sound(gpointer IGNORED);
char* timespan_to_string(GTimeSpan);

// HACK This code provides the stillopen variable to Vala. This should be
// removed in future.
bool get_still_open()
{
    return stillopen;
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

    int span = g_date_time_difference(time, g_date_time_new_now_local());
    char* timeuntil = timespan_to_string(span);
    gtk_label_set_text(GTK_LABEL(gtk_bin_get_child(GTK_BIN(window))), timeuntil);
    free(timeuntil);

    if (span < 0 && span >= -G_TIME_SPAN_SECOND) {
        g_thread_try_new("GStreamer player", play_sound, NULL, NULL);
    }
}

static gboolean routine_update(gpointer _)
{
    UNUSED(_);
    update(picker, window);
    return TRUE;
}

#define activate gt_activate
void gt_activate(GApplication* app, gpointer userdata)
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
