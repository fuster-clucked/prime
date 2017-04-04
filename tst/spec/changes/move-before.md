[from]: (changes/add-first)

	$ mv main.c main.b
	
	$ prime status
	+ main.b
	- main.c

	$ prime commit
	
	$ prime status
	
	$ prime list
	Makefile
	main.b
