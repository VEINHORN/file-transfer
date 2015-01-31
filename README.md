##START SERVER
1. Create server folder in source folder.
2. erlc *.erl; escript server.erl

##START CLIENT
1. Create client folder in source folder.
2. Change HOST macros in config.hrl. (setup your server ip address)
3. erlc *.erl; escript client.erl

##DOWNLOAD
DOWNLOAD filename(with extension)

##UPLOAD
UPLOAD filename(with extension)

##EXIT(on client side)
Just type EXIT.

##EXAMPLES
1. DOWNLOAD movie.mp4
2. UPLOAD movie.mp4

##DIRECTORY STRUCTURE
```sh
file-transfer
  ├── server.erl
  ├── client.erl
  ├── utils.erl
  ├── config.hrl
  ├── client
  │   ├── movie.mp4
  └── server
      └── movie.mp4
```
