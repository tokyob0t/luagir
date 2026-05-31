#!/usr/bin/env lua

local luagir = require('luagir')

local argparse = require('argparse')

local parser = argparse('luagir', 'Autocompletion for lua lgi using *.gir files.')

parser:argument('GIR', 'GIR namespace(s) (e.g. Gtk-4.0) or path(s) to .gir file(s).'):args('*')

parser:flag('-d --disable-docs', 'Exclude documentation comments from generated output.')
parser:flag('-n --no-deps', 'Do not generate imported namespaces automatically.')

parser
    :option('-I --include-path', 'Add a directory to the GIR search path.')
    :argname('<dir>')
    :count('*')

parser
    :option(
        '-D --dest-directory',
        'Output directory for generated files.',
        string.format('%s/.cache/luagir/', os.getenv('HOME') or '/tmp')
    )
    :argname('<dir>')

local args = parser:parse()

luagir(args.GIR, {
    docs = not args.disable_docs,
    dependencies = not args.no_deps,
    include_paths = args.include_path or {},
    dest_directory = args.dest_directory,
})
