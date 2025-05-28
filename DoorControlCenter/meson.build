project('vala app', 'vala', 'c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('gtk+-3.0'),
    dependency('gstreamer-1.0'),
]

message('Creating python virtual environment...')
r = run_command('python3.10', '-m', 'venv','./.venv', check:true)
message(r.stdout())
message('Installing Piper...')
r = run_command('.venv/bin/pip', 'install', '-r', 'requirements.txt', check:true)
message(r.stdout())

subdir('src')