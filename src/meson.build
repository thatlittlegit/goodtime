goodtime_sources = [
  'main.vala',
  'window.vala',
  'alarm.vala',
  'date-utils.vala',
  'settings.vala',
]

goodtime_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  # I have no clue what version works, if someone reading this does know please
  # submit a PR.
  dependency('gstreamer-1.0', version: '>= 1.0'),
]

gnome = import('gnome')
goodtime_sources += gnome.compile_resources('goodtime-resources',
  'goodtime.gresource.xml',
  c_name: 'goodtime'
)

executable('goodtime', goodtime_sources,
  vala_args: '--target-glib=2.50',  dependencies: goodtime_deps,
  install: true,
)
