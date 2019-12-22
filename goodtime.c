#include <granite/granite.h>
#include <gtk/gtk.h>
#include <stdbool.h>

#define CLEAR_SECONDS_IN_GDATETIME(gdt) g_date_time_new_from_unix_local(g_date_time_to_unix(gdt) - g_date_time_get_second(gdt))

bool stillopen = true;
GDateTime* set_time = NULL;

// Implemented here
bool update(GtkLabel* label);
bool get_still_open();
void update_time(GraniteWidgetsTimePicker* picker, GtkHeaderBar* headerbar);

// Implemented in Vala
void gt_activate(GApplication* application, gpointer IGNORED);
gpointer play_sound(gpointer IGNORED);
char* timespan_to_string(GTimeSpan);

// HACK This code provides the stillopen variable to Vala. This should be
// removed in future.
bool get_still_open()
{
    return stillopen;
}

bool update(GtkLabel* label)
{
    if (set_time == NULL) {
        gtk_label_set_text(label, "+??:??:??");
        return TRUE;
    }

    int span = g_date_time_difference(set_time, g_date_time_new_now_local());
    char* timeuntil = timespan_to_string(span);
    gtk_label_set_text(label, timeuntil);
    free(timeuntil);

    if (span < 0 && span >= -G_TIME_SPAN_SECOND) {
        g_thread_try_new("GStreamer player", play_sound, NULL, NULL);
    }

    return TRUE;
}

void update_time(GraniteWidgetsTimePicker* picker, GtkHeaderBar* headerbar)
{
    set_time = CLEAR_SECONDS_IN_GDATETIME(granite_widgets_time_picker_get_time(picker));

    char newSubtitle[32];
    snprintf(newSubtitle, 31, "time until %s", g_date_time_format(set_time, "%R"));
    gtk_header_bar_set_subtitle(headerbar, newSubtitle);
}
