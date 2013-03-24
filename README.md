Collaborative Editing
=====================

To install the application
--------------------------

    $ bundle install


To run the application
----------------------

    $ LOG=recovery,warning,info,debug,color bundle exec thin --timeout 0 start

or 
	
	$ ./start.sh   	


You should now see the application running at http://0.0.0.0:3000 