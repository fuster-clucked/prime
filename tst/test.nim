#? replace( sub = "\t", by = " " )

let
	root     = this_dir()
	spec_dir = "tst/spec"

proc test( spec: string ) =

	let
		name = spec.rsplit( { '.' }, 1 )[ 0 ]
		temp = "$1/.tmp/$2" % [ root, name ]

	if dir_exists temp:
		return

	mk_dir temp

	var
		output = new_string_of_cap 4096
		base : string = nil

	for line in split_lines static_exec """
		sed -nr 's/^(\t(\$$)\s*|\[([^]]*)\]:\s*\(([^)]*)\))/\2\3:\4/p' $1/$2/$3
	""" % [ root, spec_dir, spec ]:

		let
			command = line.split( { ':' }, 1 )
			subject = command[ 1 ]

		case command[ 0 ]:

		of "from":

			base = "$1/.tmp/$2" % [ root, subject ]

			if not dir_exists base:
				test "$1.md" % subject

			output.add "[from]: ($1)\n" % subject
			exec "cp -RT $1 $2" % [ base, temp ]

		of "add":

			output.add "[add]: ($1)\n" % subject

			for file in subject.split( { ' ' } ):
				cp_file "$1/tst/share/$2" % [ root, file ], "$1/$2" % [ temp, file ]

		of "$":

			var len = 0

			output.add "\n\t$$ $1" % subject

			for line in split_lines static_exec "cd $2 && PATH=$$PATH:$1/.obj $3" % [ root, temp, subject ]:
				output.add "\n\t$1" % line
				len = line.len

			if len > 0:
				output.add "\n"

	let repo = "$1/.prime/repo" % temp

	if file_exists repo:
		exec "mdb_dump -npa $1 > $2/.prime/dump" % [ repo, temp ]

	let diff = "$1.diff" % name

	if base != nil:
		discard static_exec "diff -u -L '' -L '' -F ^database= $1/.prime/dump $2/.prime/dump > $3/$4/$5" % [ base, temp, root, spec_dir, diff ]

	write_file "$1/.tmp/out.md" % root, output
	mv_file "$1/.tmp/out.md" % root, "$1/$2/$3" % [ root, spec_dir, spec ]

	exec "git diff HEAD -- $1/$2/$3" % [ root, spec_dir, spec ]
	exec "git diff HEAD -- $1/$2/$3" % [ root, spec_dir, diff ]

proc test_dir( dir: string ) =

	for path in list_files dir:
		if path.rsplit( { '/' }, 1 )[ 1 ].ends_with ".md":
			test path.substr spec_dir.len + 1

	for path in list_dirs dir:
		test_dir path

test_dir spec_dir
