#include <granite/granite.h>
#include <gtk/gtk.h>
#include <stdbool.h>
#include <time.h>

#define GLADEOBJ(x) gtk_builder_get_object(builder, x)
#define GraniteTimePicker GraniteWidgetsTimePicker

#define CLEAR_SECONDS_IN_GDATETIME(gdt) g_date_time_new_from_unix_local(g_date_time_to_unix(gdt) - g_date_time_get_second(gdt))
#define UNUSED(x) (void)(x)

bool stillopen = true;
GDateTime* set_time = NULL;

struct widget_picker_pair {
    GtkWidget* widget;
    GraniteTimePicker* picker;
};

// Implemented here
static void update(GraniteTimePicker* IGNORED, GtkWindow* window);
static gboolean routine_update(gpointer window);
void gt_activate(GApplication* application, gpointer IGNORED);
bool get_still_open();
static void update_time(GtkButton* IGNORED, gpointer window_picker_pair);
static void show_popover(GtkButton* IGNORED, gpointer popover);

// Implemented in Vala
gpointer play_sound(gpointer IGNORED);
char* timespan_to_string(GTimeSpan);

// HACK This code provides the stillopen variable to Vala. This should be
// removed in future.
bool get_still_open()
{
    return stillopen;
}

static void update(GraniteTimePicker* _, GtkWindow* window)
{
    UNUSED(_);
    GtkLabel* label = GTK_LABEL(gtk_bin_get_child(GTK_BIN(window)));
    if (set_time == NULL) {
        gtk_label_set_text(label, "+??:??:??");
        return;
    }

    int span = g_date_time_difference(set_time, g_date_time_new_now_local());
    char* timeuntil = timespan_to_string(span);
    gtk_label_set_text(label, timeuntil);
    free(timeuntil);

    if (span < 0 && span >= -G_TIME_SPAN_SECOND) {
        g_thread_try_new("GStreamer player", play_sound, NULL, NULL);
    }
}

static gboolean routine_update(gpointer window)
{
    update(NULL, GTK_WINDOW(window));
    return TRUE;
}

static void update_time(GtkButton* _, gpointer _wpp)
{
    struct widget_picker_pair* wpp = _wpp;
    UNUSED(_);
    set_time = CLEAR_SECONDS_IN_GDATETIME(granite_widgets_time_picker_get_time(wpp->picker));

    char newSubtitle[32];
    GDateTime* time = CLEAR_SECONDS_IN_GDATETIME(granite_widgets_time_picker_get_time(wpp->picker));
    snprintf(newSubtitle, 31, "time until %s", g_date_time_format(time, "%R"));
    gtk_header_bar_set_subtitle(GTK_HEADER_BAR(wpp->widget), newSubtitle);
}

static void show_popover(GtkButton* _, gpointer popover)
{
    UNUSED(_);
    gtk_popover_popup(GTK_POPOVER(popover));
}

void gt_activate(GApplication* app, gpointer userdata)
{
    UNUSED(userdata);

    GtkBuilder* builder = gtk_builder_new_from_file("goodtime.glade");
    GtkWindow* window = GTK_WINDOW(GLADEOBJ("window"));
    gtk_application_add_window(GTK_APPLICATION(app), window);

    GraniteTimePicker* picker = granite_widgets_time_picker_new();
    gtk_box_pack_start(GTK_BOX(GLADEOBJ("popover-container")), GTK_WIDGET(picker), TRUE, TRUE, 0);
    g_signal_connect(GLADEOBJ("show-popover"), "clicked", G_CALLBACK(show_popover), GLADEOBJ("popover"));
    gtk_widget_show(GTK_WIDGET(picker));
    gtk_widget_show(GTK_WIDGET(window));

    struct widget_picker_pair* wpp = malloc(sizeof(struct widget_picker_pair));
    wpp->widget = GTK_WIDGET(GLADEOBJ("headerbar"));
    wpp->picker = picker;
    g_signal_connect(GLADEOBJ("accept-new-time"), "clicked", G_CALLBACK(update_time), wpp);

    g_timeout_add_seconds(1, routine_update, window);
}
