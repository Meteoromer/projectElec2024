project('vala app', 'vala', 'c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
]

sources = files('main.vala')

sources += import( 'gnome' ).compile_resources(
    'project-resources',
    'data/org.Meteoromer.DoorControlCenter.gresource.xml',
    source_dir: 'data',
)

executable('DoorControlCenter', sources, dependencies: dependencies)
