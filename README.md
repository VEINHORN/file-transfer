# file-transfer

It's a simple example which illustrates file uploading/downloading implemented with Erlang language.

## Starting

There are 2 scripts called `run_client.sh` and `run_server.sh` which you can use to simplify process of starting client and server.

### Start server

1. erlc \*.erl; escript server.erl

### Start client

1. Change HOST macros in config.hrl. (setup your server ip address)
2. erlc \*.erl; escript client.erl

## Commands

### Download file

To download file, use below command:

```
DOWNLOAD \<filename\> (with extension)
```

### Upload file

To upload file, use below command:

```
UPLOAD \<filename\> (with extension)
```

### Exit (on client side)

Just type EXIT.

### Examples

1. DOWNLOAD movie.mp4
2. UPLOAD movie.mp4

### Directory structure

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
