#? replace( sub = "\t", by = " " )

from package import nil

package_name = package.name
version      = package.version
author       = package.author
description  = package.description
license      = package.license

requires "lmdb >= 0.0.0"

bin     = @[ package_name ]
bin_dir = ".obj"
src_dir = "src"

include tasks
