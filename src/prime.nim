#? replace( sub = "\t", by = " " )

import parseopt2
import ../package, primepkg/repo

var
	command:      string        = nil
	options:      seq[ string ] = @[]
	args:         seq[ string ] = @[]
	show_help:    bool          = false
	show_version: bool          = false

for kind, key, _ in getopt():

	case kind

	of cmd_argument:

		if command == nil:
			command = key
		else:
			args.add key

	of cmd_short_option, cmd_long_option:

		case key
		of "?", "h", "help":
			show_help = true
		of "v", "version":
			show_version = true
		else:
			options.add key

	of cmd_end:
		discard

case command

of nil:

	if show_version:
		echo "$1 $2 $3" % [ title, version, description ]
		echo "Copyright (c) 2017 by $1" % author
		echo "License $1" % license
	elif show_help:
		echo "Usage: $1 [options ...] [command]" % name
		echo "Options:"
		echo "  --help     -h -?  Show program usage"
		echo "  --version  -v     Show program version"
		echo "Commands:"
		echo "  commit    ci  Save working directory into repo"
		echo "  stat[us]  st  Show status of working directory"
		echo "  list      ls  Show files in base repo revision"

of "ci", "commit":
	open().commit

of "st", "stat", "status":

	let repo = open()

	for kind, path in repo.status repo.current:
		if kind != '=':
			echo "$1 $2" % [ $kind, path ]

of "ls", "list":

	let repo = open()

	for path in repo.list repo.current:
		echo path

else:
	echo "Invalid command: $1" % command
