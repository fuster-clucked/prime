#? replace( sub = "\t", by = " " )

import strutils

task clean, "Destroy build output":

	rm_dir ".obj"
	rm_dir ".tmp"

task test, "Execute test suite":

	rm_dir ".tmp"

	exec "nimble build"

	include tst/test

task pkgdeb, "Build Debian package":

	rm_dir ".obj/deb"

	exec "nimble build"

	mk_dir ".obj/deb/DEBIAN"

	exec unindent( """
		cat > .obj/deb/DEBIAN/control <<EOF
		Package:       $1
		Version:       $2
		Maintainer:    $3
		Description:   $4
		Architecture:  amd64
		Depends:       liblmdb0 (>= 0.9.17)
		EOF
	""" ) % [ package_name, version, author, description ]

	exec unindent( """
		cat > .obj/deb/DEBIAN/preinst <<EOF
		ln /usr/lib/x86_64-linux-gnu/liblmdb.so.0.0.0 /usr/lib/x86_64-linux-gnu/liblmdb.so
		EOF
	""" )

	exec "chmod =555 .obj/deb/DEBIAN/preinst"

	mk_dir ".obj/deb/usr/bin"
	cp_file ".obj/$1" % bin[0], ".obj/deb/usr/bin/$1" % bin[0]

	exec "chmod =755 .obj/deb/usr/bin/$1" % bin[0]

	exec "dpkg-deb -b .obj/deb .obj/$1.deb" % package_name
