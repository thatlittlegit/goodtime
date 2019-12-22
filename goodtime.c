#include <granite/granite.h>
#include <gtk/gtk.h>

#define CLEAR_SECONDS_IN_GDATETIME(gdt) g_date_time_new_from_unix_local(g_date_time_to_unix(gdt) - g_date_time_get_second(gdt))

GDateTime* set_time = NULL;

// Implemented here
gboolean update(GtkLabel* label);
void update_time(GraniteWidgetsTimePicker* picker, GtkHeaderBar* headerbar);

// Implemented in Vala
void gt_activate(GApplication* application, gpointer IGNORED);
gpointer play_sound(gpointer IGNORED);
char* timespan_to_string(GTimeSpan);

gboolean update(GtkLabel* label)
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
