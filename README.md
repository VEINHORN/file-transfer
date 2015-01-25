##START SERVER
erlc *.erl; escript server.erl

##START CLIENT
1. Change HOST macros in config.hrl. (setup your server ip address)
2. erlc *.erl; escript client.erl

##DOWNLOAD
DOWNLOAD filename(with extension)

##UPLOAD
UPLOAD filename(with extension)

##EXAMPLES
DOWNLOAD movie.mp4
UPLOAD movie.mp4
