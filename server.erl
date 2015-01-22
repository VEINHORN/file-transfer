-module(server).
-include("config.hrl").
-mode(compile).
-export([main/1]).

main(_) ->
  listen().

listen() ->
  {ok, LSock} = gen_tcp:listen(?PORT, ?OPTIONS),
  accept(LSock).

accept(LSock) ->
  {ok, Sock} = gen_tcp:accept(LSock),
  handle(Sock),
  accept(LSock).

handle(Socket) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, <<"DOWNLOAD ", Packet/binary>>} ->
      io:format("~s", [Packet]),
      handle(Socket);
    {ok, <<"UPLOAD ", Packet/binary>>} ->
      io:format("~p", [Packet]),
      Filename = delete_n(binary_to_list(Packet)),
      Offset = filelib:file_size("server/" ++ Filename),
      gen_tcp:send(Socket, [<<Offset:32/integer>>, Filename]),
      io:format("file was succesfully received."),
      handle(Socket);
    {<<Flag:32/integer, Packet/binary>>} ->
      io:format("wait for file");
    {<<Flag:32/integer>>} ->
      io:format("~B file received", [Flag]);
    {error, closed} ->
      handle(Socket)
   % _ ->
   %   handle(Socket)
  end.

delete_n(Str) ->
  string:substr(Str, 1, string:len(Str) - 1).
