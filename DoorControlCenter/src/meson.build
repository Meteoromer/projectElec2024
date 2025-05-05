sources = files('main.vala')

sources += import( 'gnome' ).compile_resources(
    'project-resources',
    'org.Meteoromer.DoorControlCenter.gresource.xml',
    source_dir: 'src',
)

executable('DoorControlCenter', sources, dependencies: dependencies)