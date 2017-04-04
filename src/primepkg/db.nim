#? replace( sub = "\t", by = " " )

import lmdb

type

	DbConn* = object
		env: ptr Env
		txn: ptr Txn

	DbTable*[ K, V ] = object {. inheritable .}
		conn: DbConn
		dbi: Dbi

	DbTableDup*[ K, V ] = object of DbTable[ K, V ]

proc check( code: cint ) =

	if code != SUCCESS:
		echo strerror code
		raise

proc open*( path: string, maxdbs: uint ): DbConn =

	var
		env: ptr Env
		txn: ptr Txn

	check env_create( addr env )
	check env_set_max_dbs( env, Dbi maxdbs )
	check env_open( env, path, NOSUBDIR, 0c644 )
	check txn_begin( env, nil, 0, addr txn )

	DbConn( env: env, txn: txn )

proc open*[ K, V ]( this: DbConn, name: string ): DbTable[ K, V ] =

	var dbi: Dbi

	check dbi_open( this.txn, name, CREATE, addr dbi )

	DbTable[ K, V ]( conn: this, dbi: dbi )

proc open_dup*[ K, V ]( this: DbConn, name: string ): DbTableDup[ K, V ] =

	var dbi: Dbi

	check dbi_open( this.txn, name, CREATE or DUPSORT, addr dbi )

	check set_dupsort( this.txn, dbi, cast[ ptr CmpFunc ](
		# sort duplicates by insertion order
		proc ( a, b: ptr Val ): cint = 1
	) )

	DbTableDup[ K, V ]( conn: this, dbi: dbi )

proc exec*( this: DbConn ) =

	check txn_commit this.txn

proc len*[ K, V ]( this: DbTable[ K, V ] ): int =

	var stats: Stat

	check stat( this.conn.txn, this.dbi, addr stats )

	stats.ms_entries

proc `[]`*[ K, V ]( this: DbTable[ K, V ], key: K ): V =

	var
		key_data = key
		key_val  = Val( mv_size: sizeof K, mv_data: addr key_data )
		data_val: Val

	check get( this.conn.txn, this.dbi, addr key_val, addr data_val )

	when V is string:
		$ cast[ cstring ]( data_val.mv_data )
	else:
		cast[ ptr V ]( data_val.mv_data )[]

proc get_or_put*[ K, V ]( this: DbTable[ K, V ], key: K, val: V ): V =

	when K is string:
		var key_val = Val( mv_size: key.len + 1, mv_data: cstring key )
	else:
		var
			key_data = key
			key_val  = Val( mv_size: sizeof K, mv_data: addr key_data )

	var
		val_data = val
		data_val = Val( mv_size: sizeof V, mv_data: addr val_data )

	let code = put( this.conn.txn, this.dbi, addr key_val, addr data_val, NOOVERWRITE )

	if code == KEYEXIST:
		cast[ ptr V ]( data_val.mv_data )[]
	else:
		check code
		val

proc `[]=`*[ K, V ]( this: DbTable[ K, V ], key: K, val: V ) =

	var
		key_data = key
		key_val  = Val( mv_size: sizeof K, mv_data: addr key_data )

	when V is string:
		var data_val = Val( mv_size: val.len + 1, mv_data: cstring val )
	else:
		var
			val_data = val
			data_val = Val( mv_size: sizeof V, mv_data: addr val_data )

	check put( this.conn.txn, this.dbi, addr key_val, addr data_val, 0 )

iterator values*[ K, V ]( this: DbTableDup[ K, V ], key: K ): V =

	var
		cursor: ptr cursor
		key_data = key
		key_val  = Val( mv_size: sizeof K, mv_data: addr key_data )
		data_val: Val

	check cursor_open( this.conn.txn, this.dbi, addr cursor )

	var code = cursor_get( cursor, addr key_val, addr data_val, SET )

	while code != NOTFOUND:
		check code

		yield cast[ ptr V ]( data_val.mv_data )[]

		code = cursor_get( cursor, nil, addr data_val, NEXT_DUP )
