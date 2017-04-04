#? replace( sub = "\t", by = " " )

import os
import ../../package, db

type

	Repo = object
		conn: DbConn

	Change = tuple
		kind: char
		path: string

proc open*(): Repo =

	let root = ".$1" % name

	create_dir root

	# TODO: don't keep manually counting tables
	Repo( conn: db.open( "$1/repo" % root, 4 ) )

proc open_branches( this: Repo ): DbTable[ uint32, uint32 ] =

	open[ uint32, uint32 ] this.conn, "branches"

proc open_versions( this: Repo ): DbTableDup[ uint32, uint32 ] =

	open_dup[ uint32, uint32 ] this.conn, "versions"

proc open_tokens( this: Repo ): DbTable[ uint32, string ] =

	open[ uint32, string ] this.conn, "tokens"

proc open_tokens_idx( this: Repo ): DbTable[ string, uint32 ] =

	open[ string, uint32 ] this.conn, "tokens_idx"

proc current*( this: Repo ): uint32 =

	let branches = this.open_branches

	branches.get_or_put 0u32, 0u32

iterator list*( this: Repo, version_id: uint32 ): string {. closure .} =

	let
		tokens  = this.open_tokens
		versions = this.open_versions

	for path_id in versions.values version_id:
		yield tokens[ path_id ]

iterator status*( this: Repo, version_id: uint32 ): Change =

	let next = list

	var repo_path = next( this, version_id )

	for work_path in walk_files "*":
		while true:

			if repo_path == nil or work_path < repo_path:
				yield ( '+', work_path )
				break
			elif work_path == repo_path:
				yield ( '=', repo_path )
				repo_path = next( this, version_id )
				break

			yield ( '-', repo_path )
			repo_path = next( this, version_id )

	while repo_path != nil:
		yield ( '-', repo_path )
		repo_path = next( this, version_id )

proc intern( this: Repo, token: string ): uint32 =

	let
		tokens     = this.open_tokens
		tokens_idx = this.open_tokens_idx
		count      = uint32 tokens.len

	result = tokens_idx.get_or_put( token, count )

	if result == count:
		tokens[ result ] = token

proc commit*( this: Repo ) =

	let
		versions = this.open_versions
		current  = this.current

	for kind, path in this.status current:
		if kind == '-':
			continue

		versions[ current + 1 ] = intern( this, path )

	let branches = this.open_branches

	branches[ 0u32 ] = current + 1
	this.conn.exec
