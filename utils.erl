-module(utils).
-include("config.hrl").
-export([delete_n/1, get_file_info/1, send_file/4, send_file_binary/3, wait_for_file/2]).

delete_n(Str) ->
  string:substr(Str, 1, string:len(Str) - 1).

get_file_info(Packet) ->
  Filename = delete_n(binary_to_list(Packet)),
  [Filename, filelib:file_size(?SERVER_FOLDER ++ Filename)].

send_file(Socket, Filename, Offset, HostFolder) ->
  case file:open(HostFolder ++ Filename, [read, binary]) of
    {ok, IoDevice} ->
      utils:send_file_binary(Socket, IoDevice, Offset);
    {error, enoent} ->
      io:format("File does not exist.~n"),
      gen_tcp:send(Socket, <<?FILE_NOT_EXIST:8/integer>>)
  end.

send_file_binary(Socket, IoDevice, Offset) ->
  case file:pread(IoDevice, Offset, ?CHUNK_SIZE) of
    {ok, Data} ->
      io:format("~B bytes were sent.~n", [Offset + ?CHUNK_SIZE]),
      gen_tcp:send(Socket, <<?SENDING:8/integer, Data/binary>>),
      send_file_binary(Socket, IoDevice, Offset + ?CHUNK_SIZE);
    eof ->
      io:format("File was sent.~n"),
      gen_tcp:send(Socket, <<?DOWNLOADED:8/integer>>)
  end.

wait_for_file(Socket, IoDevice) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, <<?SENDING:8/integer, Packet/binary>>} ->
      file:write(IoDevice, Packet),
      wait_for_file(Socket, IoDevice);
    {ok, <<?DOWNLOADED:8/integer>>} ->
      io:format("File was downloaded.~n");
    {ok, <<?FILE_NOT_EXIST:8/integer>>} ->
      io:format("File does not exist.~n")
  end.
