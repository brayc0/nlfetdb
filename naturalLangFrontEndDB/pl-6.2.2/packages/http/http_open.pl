/*  $Id$

    Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        J.Wielemaker@cs.vu.nl
    WWW:           http://www.swi-prolog.org
    Copyright (C): 2008-2011, University of Amsterdam
			      VU University Amsterdam

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

    As a special exception, if you link this library with other files,
    compiled with a Free Software compiler, to produce an executable, this
    library does not by itself cause the resulting executable to be covered
    by the GNU General Public License. This exception does not however
    invalidate any other reasons why the executable file might be covered by
    the GNU General Public License.
*/


:- module(http_open,
	  [ http_open/3,		% +URL, -Stream, +Options
	    http_set_authorization/2	% +URL, +Authorization
	  ]).
:- use_module(library(uri)).
:- use_module(library(readutil)).
:- use_module(library(socket)).
:- use_module(library(lists)).
:- use_module(library(option)).
:- use_module(library(error)).
:- use_module(library(base64)).
:- use_module(library(debug)).

/** <module> Simple HTTP client

This library provides a light-weight HTTP client library to get the data
from a URL. The functionality of the  library can be extended by loading
two additional modules that acts as plugins:

    * library(http/http_chunked)
    Loading this library causes http_open/3 to support chunked
    transfer encoding.

    * library(http/http_header)
    Loading this library causes http_open/3 to support the =POST= method
    in addition to =GET= and =HEAD=.

Here is a simple example to fetch a web-page:

  ==
  ?- http_open('http://www.google.com/search?q=prolog', In, []),
     copy_stream_data(In, user_output),
     close(In).
  <!doctype html><head><title>prolog - Google Search</title><script>
  ...
  ==

The example below fetches the modification time of a web-page. Note that
Modified is '' if the web-server does not provide a time-stamp for the
resource. See also parse_time/2.

  ==
  modified(URL, Stamp) :-
	  http_open(URL, In,
		    [ method(head),
		      header(last_modified, Modified)
		    ]),
	  close(In),
	  Modified \== '',
	  parse_time(Modified, Stamp).
  ==

@see xpath/3
@see http_get/3
@see http_post/4
*/

:- multifile
	http:encoding_filter/3,		  % +Encoding, +In0,  -In
	http:current_transfer_encoding/1, % ?Encoding
	http:http_protocol_hook/7,	  % +Protocol, +Parts, +In, +Out,
					  % -NewIn, -NewOut, +Options
	http:open_options/2,		  % +Parts, -Options
	http:write_cookies/3,		  % +Out, +Parts, +Options
	http:update_cookies/3.		  % +CookieLine, +Parts, +Options

:- meta_predicate
	http_open(+,-,:).

:- predicate_options(http_open/3, 3,
		     [ authorization(compound),
		       final_url(-atom),
		       header(+atom, -atom),
		       method(oneof([get,head,post])),
		       size(-integer),
		       status_code(-integer),
		       timeout(number),
		       post(any),		    % library(http/http_header)
		       proxy(atom, integer),
		       proxy_authorization(compound),
		       request_header(any),
		       user_agent(atom),
		       pem_password_hook(callable), % if SSL is loaded
		       cert_verify_hook(callable)   % if SSL is loaded
		     ]).

%%	user_agent(-Agent) is det.
%
%	Default value for =|User-Agent|=,  can   be  overruled using the
%	option user_agent(Agent) of http_open/3.

user_agent('SWI-Prolog <http://www.swi-prolog.org>').

%%	http_open(+URL, -Stream, +Options) is det.
%
%	Open the data at the HTTP  server   as  a  Prolog stream. URL is
%	either an atom  specifying  a  URL   or  a  list  representing a
%	broken-down  URL  as  specified  below.   After  this  predicate
%	succeeds the data can be read from Stream. After completion this
%	stream must be  closed  using   the  built-in  Prolog  predicate
%	close/1. Options provides additional options:
%
%	  * authorization(+Term)
%	  Send authorization.  Currently only supports basic(User,Password).
%	  See also http_set_authorization/2.
%
%	  * final_url(-FinalURL)
%	  Unify FinalURL with the final   destination. This differs from
%	  the  original  URL  if  the  returned  head  of  the  original
%	  indicates an HTTP redirect (codes 301,  302 or 303). Without a
%	  redirect, FinalURL is the same as URL if  URL is an atom, or a
%	  URL constructed from the parts.
%
%	  * header(Name, -AtomValue)
%	  If provided, AtomValue is  unified  with   the  value  of  the
%	  indicated  field  in  the  reply    header.  Name  is  matched
%	  case-insensitive and the underscore  (_)   matches  the hyphen
%	  (-). Multiple of these options  may   be  provided  to extract
%	  multiple  header  fields.  If  the  header  is  not  available
%	  AtomValue is unified to the empty atom ('').
%
%	  * method(+Method)
%	  One of =get= (default) or =head=.   The  =head= message can be
%	  used in combination with  the   header(Name,  Value) option to
%	  access information on the resource   without actually fetching
%	  the resource itself.  The  returned   stream  must  be  closed
%	  immediately.   If   library(http/http_header)     is   loaded,
%	  http_open/3 also supports =post=. See the post(Data) option.
%
%	  * size(-Size)
%	  Size is unified with the   integer value of =|Content-Length|=
%	  in the reply header.
%
%	  * status_code(-Code)
%	  If this option is  present  and   Code  unifies  with the HTTP
%	  status code, do *not* translate errors (4xx, 5xx) into an
%	  exception. Instead, http_open/3 behaves as if 200 (success) is
%	  returned, providing the application to read the error document
%	  from the returned stream.
%
%	  * timeout(+Timeout)
%	  If provided, set a timeout on   the stream using set_stream/2.
%	  With this option if no new data arrives within Timeout seconds
%	  the stream raises an exception.  Default   is  to wait forever
%	  (=infinite=).
%
%	  * post(+Data)
%	  Provided if library(http/http_header) is also loaded.  Data is
%	  handed to http_post_data/3.
%
%	  * proxy(+Host, +Port)
%	  Use an HTTP proxy to connect to the outside world.
%
%	  * proxy_authorization(+Authorization)
%	  Send authorization to the proxy.  Otherwise   the  same as the
%	  =authorization= option.
%
%	  * request_header(Name = Value)
%	  Additional  name-value  parts  are  added   in  the  order  of
%	  appearance to the HTTP request   header.  No interpretation is
%	  done.
%
%	  * user_agent(+Agent)
%	  Defines the value of the  =|User-Agent|=   field  of  the HTTP
%	  header. Default is =|SWI-Prolog (http://www.swi-prolog.org)|=.
%
%	The hook http:open_options/2 can be used to provide default
%	options based on the broken-down URL.
%
%	@param	URL is either an atom (url) or a list of _parts_.
%		If this list is provided, it may contain the fields
%		=scheme=, =user=, =password=, =host=, =port=, =path= and
%		=search= (where the argument of the latter is a list of
%		Name(Value) or Name=Value).  Only =host= is mandatory.
%		The following example below opens the URL
%		=|http://www.example.com/my/path?q=Hello%20World&lang=en|=.
%		Note that values must *not* be quoted because the
%		library inserts the required quites.
%
%		==
%		http_open([ host('www.example.com'),
%			    path('/my/path'),
%			    search([ q='Hello world',
%			             lang=en
%				   ])
%			  ])
%		==
%
%	@error existence_error(url, Id)

http_open(URL, Stream, QOptions) :-
	meta_options(is_meta, QOptions, Options),
	(   atom(URL)
	->  parse_url_ex(URL, Parts)
	;   Parts = URL
	),
	add_authorization(Parts, Options, Options1),
	(   http:open_options(Parts, HostOptions)
	->  merge_options(Options1, HostOptions, Options2)
	;   Options2 = Options1
	),
	http_open_parts(Parts, Stream, Options2).

is_meta(pem_password_hook).		% SSL plugin callbacks
is_meta(cert_verify_hook).

http_open_parts(Parts, Stream, Options0) :-
	memberchk(proxy(Host, ProxyPort), Options0), !,
	parts_uri(Parts, RequestURI),
	Options = [visited(Parts)|Options0],
	open_socket(Host:ProxyPort, In, Out, Options),
	parts_scheme(Parts, Scheme),
	default_port(Scheme, DefPort),
	url_part(port(Port), Parts, DefPort),
	host_and_port(Host, DefPort, Port, HostPort),
	send_rec_header(Out, In, Stream, HostPort, RequestURI, Parts, Options),
	return_final_url(Options).
http_open_parts(Parts, Stream, Options0) :-
	memberchk(host(Host), Parts),
	parts_scheme(Parts, Scheme),
	default_port(Scheme, DefPort),
	url_part(port(Port), Parts, DefPort),
	parts_request_uri(Parts, RequestURI),
	Options = [visited(Parts)|Options0],
	open_socket(Host:Port, SocketIn, SocketOut, Options),
        (   http:http_protocol_hook(Scheme, Parts,
				    SocketIn, SocketOut,
				    In, Out, Options)
        ->  true
        ;   In = SocketIn,
            Out = SocketOut
        ),
	host_and_port(Host, DefPort, Port, HostPort),
	send_rec_header(Out, In, Stream, HostPort, RequestURI, Parts, Options),
	return_final_url(Options).

http:http_protocol_hook(http, _, In, Out, In, Out, _).

default_port(https, 443) :- !.
default_port(_,	    80).

host_and_port(Host, DefPort, DefPort, Host) :- !.
host_and_port(Host, _,       Port,    Host:Port).

%%	send_rec_header(+Out, +In, -InStream,
%%			+Host, +RequestURI, +Parts, +Options) is det.
%
%	Send header to Out and process reply.  If there is an error or
%	failure, close In and Out and return the error or failure.

send_rec_header(Out, In, Stream, Host, RequestURI, Parts, Options) :-
	(   catch(guarded_send_rec_header(Out, In, Stream,
					  Host, RequestURI, Parts, Options),
		  E, true)
	->  (   var(E)
	    ->	close(Out)
	    ;	force_close(In, Out),
		throw(E)
	    )
	;   force_close(In, Out),
	    fail
	).

guarded_send_rec_header(Out, In, Stream, Host, RequestURI, Parts, Options) :-
	user_agent(Agent, Options),
	method(Options, MNAME),
	http_version(Version),
	format(Out,
	       '~w ~w HTTP/~w\r\n\c
	       Host: ~w\r\n\c
	       User-Agent: ~w\r\n\c
	       Connection: close\r\n',
	       [MNAME, RequestURI, Version, Host, Agent]),
	x_headers(Options, Out),
	write_cookies(Out, Parts, Options),
        (   option(post(PostData), Options)
        ->  http_header:http_post_data(PostData, Out, [])
        ;   format(Out, '\r\n', [])
        ),
	flush_output(Out),
					% read the reply header
	read_header(In, Code, Comment, Lines),
	update_cookies(Lines, Parts, Options),
	do_open(Code, Comment, Lines, Options, Parts, In, Stream).


%%	http_version(-Version:atom) is det.
%
%	HTTP version we publish. We  can  only   use  1.1  if we support
%	chunked encoding, which means http_chunked.pl must be loaded.

http_version('1.1') :-
	http:current_transfer_encoding(chunked), !.
http_version('1.0').

force_close(S1, S2) :-
	close(S1, [force(true)]),
	close(S2, [force(true)]).

method(Options, MNAME) :-
	option(post(_), Options), !,
	option(method(M), Options, post),
	(   map_method(M, MNAME0)
	->  MNAME = MNAME0
	;   domain_error(method, M)
	).
method(Options, MNAME) :-
	option(method(M), Options, get),
	(   map_method(M, MNAME0)
	->  MNAME = MNAME0
	;   domain_error(method, M)
	).

map_method(get,  'GET').
map_method(head, 'HEAD').
map_method(post, 'POST') :-
	current_predicate(http_header:http_post_data/3).


%%	x_headers(+Options, +Out) is det.
%
%	Emit extra headers from   request_header(Name=Value)  options in
%	Options.
%
%	@tbd Use user/password fields

x_headers([], _).
x_headers([H|T], Out) :- !,
	x_header(H, Out),
	x_headers(T, Out).

x_header(request_header(Name=Value), Out) :- !,
	format(Out, '~w: ~w\r\n', [Name, Value]).
x_header(proxy_authorization(ProxyAuthorization), Out) :- !,
	auth_header(ProxyAuthorization, 'Proxy-Authorization', Out).
x_header(authorization(Authorization), Out) :- !,
	auth_header(Authorization, 'Authorization', Out).
x_header(_, _).

auth_header(basic(User, Password), Header, Out) :- !,
	format(codes(Codes), '~w:~w', [User, Password]),
	phrase(base64(Codes), Base64Codes),
	format(Out, '~w: basic ~s\r\n', [Header, Base64Codes]).
auth_header(Auth, _, _) :-
	domain_error(authorization, Auth).

user_agent(Agent, Options) :-
	(   option(user_agent(Agent), Options)
	->  true
	;   user_agent(Agent)
	).

%%	do_open(+HTTPStatusCode, +HTTPStatusComment, +Header,
%%		+Options, +Parts, +In, -FinalIn) is det.
%
%	Handle the HTTP status. If 200, we   are ok. If a redirect, redo
%	the open, returning a new stream. Else issue an error.
%
%	@error	existence_error(url, URL)

					% Redirections
do_open(Code, _, Lines, Options0, Parts, In, Stream) :-
	redirect_code(Code),
	location(Lines, RequestURI), !,
	debug(http(redirect), 'http_open: redirecting to ~w', [RequestURI]),
	close(In),
	parts_uri(Parts, Base),
	uri_resolve(RequestURI, Base, Redirected),
	parse_url_ex(Redirected, RedirectedParts),
	(   redirect_loop(RedirectedParts, Options0)
	->  throw(error(permission_error(redirect, http, Redirected),
			context(_, 'Redirection loop')))
	;   true
	),
	redirect_options(Options0, Options),
	http_open(RedirectedParts, Stream, Options).
					% Accepted codes
do_open(Code, _, Lines, Options, Parts, In0, In) :-
	(   option(status_code(Code), Options)
	->  true
	;   Code == 200
	), !,
	return_size(Options, Lines),
	return_fields(Options, Lines),
	transfer_encoding_filter(Lines, In0, In),
					% properly re-initialise the stream
	parts_uri(Parts, URI),
	set_stream(In, file_name(URI)),
	set_stream(In, record_position(true)).
					% Handle redirections
					% report anything else as error
do_open(Code, Comment, _,  _, Parts, _, _) :-
	parts_uri(Parts, URI),
	(   map_error_code(Code, Error)
	->  Formal =.. [Error, url, URI]
	;   Formal = existence_error(url, URI)
	),
	throw(error(Formal, context(_, status(Code, Comment)))).

%%	redirect_loop(Parts, Options) is semidet.
%
%	True if we are in  a  redirection   loop.  Note  that some sites
%	redirect once to the same place using  cookies or similar, so we
%	allow for two tries. In fact,   we  should probably test whether
%	authorization or cookie headers have changed.

redirect_loop(Parts, Options) :-
	rloop(Options, visited(Parts), 0).

rloop([H|T], V, N) :-
	(   H == V
	->  (   N == 1
	    ->	true
	    ;	N2 is N + 1,
		rloop(T, V, N2)
	    )
	;   rloop(T, V, N)
	).


%%	redirect_options(+Options0, -Options) is det.
%
%	A redirect from a POST should do a GET on the returned URI. This
%	means we must remove  the   method(post)  and post(Data) options
%	from the original option-list.

redirect_options(Options0, Options) :-
	(   select_option(post(_), Options0, Options1)
	->  true
	;   Options1 = Options0
	),
	(   select_option(method(Method), Options1, Options),
	    \+ redirect_method(Method)
	->  true
	;   Options = Options1
	).

redirect_method(get).
redirect_method(head).


%%	map_error_code(+HTTPCode, -PrologError) is semidet.
%
%	Map HTTP error codes to Prolog errors.
%
%	@tbd	Many more maps. Unfortunately many have no sensible Prolog
%		counterpart.

map_error_code(401, permission_error).
map_error_code(403, permission_error).
map_error_code(404, existence_error).
map_error_code(405, permission_error).
map_error_code(407, permission_error).
map_error_code(410, existence_error).

redirect_code(301).			% moved permanently
redirect_code(302).			% moved temporary
redirect_code(303).			% see also

%%	open_socket(+Address, -In, -Out, +Options) is det.
%
%	Create and connect a client socket to Address.  Options
%
%	    * timeout(+Timeout)
%	    Sets timeout on the stream, *after* connecting the
%	    socket.
%
%	@tbd	Make timeout also work on tcp_connect/4.
%	@tbd	This is the same as do_connect/4 in http_client.pl

open_socket(Address, In, Out, Options) :-
	debug(http(open), 'http_open: Connecting to ~p ...', [Address]),
	tcp_socket(Socket),
	catch(tcp_connect(Socket, Address, In, Out),
	      E,
	      (	  tcp_close_socket(Socket),
		  throw(E)
	      )),
	debug(http(open), '\tok ~p --> ~p', [In, Out]),
	set_stream(In, record_position(false)),
	(   memberchk(timeout(Timeout), Options)
	->  set_stream(In, timeout(Timeout))
	;   true
	).


return_size(Options, Lines) :-
	memberchk(size(Size), Options), !,
	content_length(Lines, Size).
return_size(_, _).

return_fields([], _).
return_fields([header(Name, Value)|T], Lines) :- !,
	atom_codes(Name, Codes),
	(   member(Line, Lines),
	    phrase(atom_field(Codes, Value), Line)
	->  true
	;   Value = ''
	),
	return_fields(T, Lines).
return_fields([_|T], Lines) :-
	return_fields(T, Lines).


%%	return_final_url(+Options) is semidet.
%
%	If Options contains final_url(URL), unify URL with the final
%	URL after redirections.

return_final_url(Options) :-
	memberchk(final_url(URL), Options),
	var(URL), !,
	memberchk(visited(Parts), Options),
	parts_uri(Parts, URL).
return_final_url(_).


%%	transfer_encoding_filter(+Lines, +In0, -In) is det.
%
%	Install filters depending on the encoding.

transfer_encoding_filter(Lines, In0, In) :-
	transfer_encoding(Lines, Encoding), !,
	(   http:encoding_filter(Encoding, In0, In)
	->  true
	;   domain_error(http_encoding, Encoding)
	).
transfer_encoding_filter(_, In, In).


%%	transfer_encoding(+Lines, -Encoding) is semidet.
%
%	True if Encoding is the value of the =|Transfer-encoding|=
%	header.

transfer_encoding(Lines, Encoding) :-
	member(Line, Lines),
	phrase(transfer_encoding(Encoding0), Line), !,
	debug(http(transfer_encoding), 'Transfer-encoding: ~w', [Encoding0]),
	Encoding = Encoding0.

transfer_encoding(Encoding) -->
	field("transfer-encoding"),
	rest(Encoding).

%%	read_header(+In:stream, -Code:int, -Comment:atom, -Lines:list) is det.
%
%	Read the HTTP reply-header. If the replied header is invalid, it
%	simulates a 500 error with the comment =|Invalid reply header|=.
%
%	@param Code	Numeric HTTP reply-code
%	@param Comment	Comment of reply-code as atom
%	@param Lines	Remaining header lines as code-lists.

read_header(In, Code, Comment, Lines) :-
	read_line_to_codes(In, Line),
	phrase(first_line(Code, Comment), Line),
	debug(http(open), '~w ~w', [Code, Comment]),
	read_line_to_codes(In, Line2),
	rest_header(Line2, In, Lines), !,
	(   debugging(http(open))
	->  forall(member(HL, Lines),
		   debug(http(open), '~s', [HL]))
	;   true
	).
read_header(_, 500, 'Invalid reply header', []).

rest_header("", _, []) :- !.		% blank line: end of header
rest_header(L0, In, [L0|L]) :-
	read_line_to_codes(In, L1),
	rest_header(L1, In, L).

%%	content_length(+Header, -Length:int) is semidet.
%
%	Find the Content-Length in an HTTP reply-header.

content_length(Lines, Length) :-
	member(Line, Lines),
	phrase(content_length(Length0), Line), !,
	Length = Length0.

location(Lines, RequestURI) :-
	member(Line, Lines),
	phrase(atom_field("location", RequestURI), Line), !.

first_line(Code, Comment) -->
	"HTTP/", [_], ".", [_],
	skip_blanks,
	integer(Code),
	skip_blanks,
	rest(Comment).

atom_field(Name, Value) -->
	field(Name),
	rest(Value).

content_length(Len) -->
	field("content-length"),
	integer(Len).

field([]) -->
	":",
	skip_blanks.
field([H|T]) -->
	[C],
	{ match_header_char(H, C)
	},
	field(T).

match_header_char(C, C) :- !.
match_header_char(C, U) :-
	code_type(C, to_lower(U)), !.
match_header_char(0'_, 0'-).


skip_blanks -->
	[C],
	{ code_type(C, white)
	}, !,
	skip_blanks.
skip_blanks -->
	[].

%%	integer(-Int)//
%
%	Read 1 or more digits and return as integer.

integer(Code) -->
	digit(D0),
	digits(D),
	{ number_codes(Code, [D0|D])
	}.

digit(C) -->
	[C],
	{ code_type(C, digit)
	}.

digits([D0|D]) -->
	digit(D0), !,
	digits(D).
digits([]) -->
	[].

%%	rest(-Atom:atom)//
%
%	Get rest of input as an atom.

rest(A,L,[]) :-
	atom_codes(A, L).


		 /*******************************
		 *   AUTHORIZATION MANAGEMENT	*
		 *******************************/

%%	http_set_authorization(+URL, +Authorization) is det.
%
%	Set user/password to supply with URLs   that have URL as prefix.
%	If  Authorization  is  the   atom    =|-|=,   possibly   defined
%	authorization is cleared.  For example:
%
%	==
%	?- http_set_authorization('http://www.example.com/private/',
%				  basic('John', 'Secret'))
%	==
%
%	@tbd	Move to a separate module, so http_get/3, etc. can use this
%		too.

:- dynamic
	stored_authorization/2,
	cached_authorization/2.

http_set_authorization(URL, Authorization) :-
	must_be(atom, URL),
	retractall(stored_authorization(URL, _)),
	(   Authorization = (-)
	->  true
	;   check_authorization(Authorization),
	    assert(stored_authorization(URL, Authorization))
	),
	retractall(cached_authorization(_,_)).

check_authorization(Var) :-
	var(Var), !,
	instantiation_error(Var).
check_authorization(basic(User, Password)) :-
	must_be(atom, User),
	must_be(atom, Password).

%%	authorization(+URL, -Authorization) is semdet.
%
%	True if Authorization must be supplied for URL.
%
%	@tbd	Cleanup cache if it gets too big.

authorization(_, _) :-
	\+ stored_authorization(_, _), !,
	fail.
authorization(URL, Authorization) :-
	cached_authorization(URL, Authorization), !,
	Authorization \== (-).
authorization(URL, Authorization) :-
	(   stored_authorization(Prefix, Authorization),
	    sub_atom(URL, 0, _, _, Prefix)
	->  assert(cached_authorization(URL, Authorization))
	;   assert(cached_authorization(URL, -)),
	    fail
	).

add_authorization(_, Options, Options) :-
	option(authorization(_), Options), !.
add_authorization(Parts, Options0, Options) :-
	url_part(user(User), Parts),
	url_part(password(Passwd), Parts),
	Options = [authorization(basic(User,Passwd))|Options0].
add_authorization(Parts, Options0, Options) :-
	stored_authorization(_, _) ->	% quick test to avoid work
	parts_uri(Parts, URL),
	authorization(URL, Auth), !,
	Options = [authorization(Auth)|Options0].
add_authorization(_, Options, Options).


%%	parse_url_ex(+URL, -Parts)
%
%	Parts:  Schema,  Host,  Port,    User:Password,  RequestURI  (no
%	fragment).

parse_url_ex(URL, [uri(URL)|Parts]) :-
	uri_components(URL, Components),
	phrase(components(Components), Parts),
	(   memberchk(host(_), Parts)
	->  true
	;   domain_error(url, URL)
	).

components(Components) -->
	uri_scheme(Components),
	uri_authority(Components),
	uri_request_uri(Components).

uri_scheme(Components) -->
	{ uri_data(scheme, Components, Scheme), nonvar(Scheme) }, !,
	[ scheme(Scheme)
	].
uri_scheme(_) --> [].

uri_authority(Components) -->
	{ uri_data(authority, Components, Auth), nonvar(Auth), !,
	  uri_authority_components(Auth, Data)
	},
	[ authority(Auth) ],
	auth_field(user, Data),
	auth_field(password, Data),
	auth_field(host, Data),
	auth_field(port, Data).
uri_authority(_) --> [].

auth_field(Field, Data) -->
	{ uri_authority_data(Field, Data, EncValue), nonvar(EncValue), !,
	  (   atom(EncValue)
	  ->  uri_encoded(query_value, Value, EncValue)
	  ;   Value = EncValue
	  ),
	  Part =.. [Field,Value]
	},
	[ Part ].
auth_field(_, _) --> [].

uri_request_uri(Components) -->
	{ uri_data(path, Components, Path0),
	  uri_data(search, Components, Search),
	  (   Path0 == ''
	  ->  Path = (/)
	  ;   Path = Path0
	  ),
	  uri_data(path, Components2, Path),
	  uri_data(search, Components2, Search),
	  uri_components(RequestURI, Components2)
	},
	[ request_uri(RequestURI)
	].

%%	parts_scheme(+Parts, -Scheme) is det.
%%	parts_uri(+Parts, -URI) is det.
%%	parts_request_uri(+Parts, -RequestURI) is det.
%%	parts_search(+Parts, -Search) is det.
%%	parts_authority(+Parts, -Authority) is semidet.

parts_scheme(Parts, Scheme) :-
	url_part(scheme(Scheme), Parts), !.
parts_scheme(Parts, Scheme) :-		% compatibility with library(url)
	url_part(protocol(Scheme), Parts), !.
parts_scheme(_, http).

parts_authority(Parts, Auth) :-
	url_part(authority(Auth), Parts), !.
parts_authority(Parts, Auth) :-
	url_part(host(Host), Parts, _),
	url_part(port(Port), Parts, _),
	url_part(user(User), Parts, _),
	url_part(password(Password), Parts, _),
	uri_authority_components(Auth,
				 uri_authority(User, Password, Host, Port)).

parts_request_uri(Parts, RequestURI) :-
	memberchk(request_uri(RequestURI), Parts), !.
parts_request_uri(Parts, RequestURI) :-
	url_part(path(Path), Parts, /),
	ignore(parts_search(Parts, Search)),
	uri_data(path, Data, Path),
	uri_data(search, Data, Search),
	uri_components(RequestURI, Data).

parts_search(Parts, Search) :-
	memberchk(query_string(Search), Parts), !.
parts_search(Parts, Search) :-
	memberchk(search(Fields), Parts), !,
	uri_query_components(Search, Fields).


parts_uri(Parts, URI) :-
	memberchk(uri(URI), Parts), !.
parts_uri(Parts, URI) :-
	parts_scheme(Parts, Scheme),
	ignore(parts_authority(Parts, Auth)),
	parts_request_uri(Parts, RequestURI),
	uri_components(RequestURI, Data),
	uri_data(scheme, Data, Scheme),
	uri_data(authority, Data, Auth),
	uri_components(URI, Data).

url_part(Part, Parts) :-
	Part =.. [Name,Value],
	Gen =.. [Name,RawValue],
	memberchk(Gen, Parts), !,
	Value = RawValue.

url_part(Part, Parts, Default) :-
	Part =.. [Name,Value],
	Gen =.. [Name,RawValue],
	(   memberchk(Gen, Parts)
	->  Value = RawValue
	;   Value = Default
	).


		 /*******************************
		 *	      COOKIES		*
		 *******************************/

write_cookies(Out, Parts, Options) :-
	http:write_cookies(Out, Parts, Options), !.
write_cookies(_, _, _).

update_cookies(_, _, _) :-
	predicate_property(http:update_cookies(_,_,_), number_of_clauses(0)), !.
update_cookies(Lines, Parts, Options) :-
	(   member(Line, Lines),
	    phrase(atom_field("set_cookie", CookieData), Line),
	    http:update_cookies(CookieData, Parts, Options),
	    fail
	;   true
	).


		 /*******************************
		 *     HOOK DOCUMENTATION	*
		 *******************************/

%%	http:open_options(+Parts, -Options) is semidet.
%
%	This hook is used by the HTTP   client library to define default
%	options based on the the broken-down request-URL.  The following
%	example redirects all trafic, except for localhost over a proxy:
%
%	    ==
%	    :- multifile
%		http:open_options/2.
%
%	    http:open_options(Parts, Options) :-
%		memberchk(host(Host), Parts),
%		Host \== localhost,
%		Options = [proxy('proxy.local', 3128)].
%	    ==

%%	http:write_cookies(+Out, +Parts, +Options) is semidet.
%
%	Emit a =|Cookie:|= header for the  current connection. Out is an
%	open stream to the HTTP server, Parts is the broken-down request
%	(see uri_components/2) and Options is the list of options passed
%	to http_open.  The predicate is called as if using ignore/1.

%%	update_cookies(+CookieData, +Parts, +Options) is semidet.
%
%	Update the cookie database.  CookieData  is   the  value  of the
%	=|Set-Cookie|= field, Parts is  the   broken-down  request  (see
%	uri_components/2) and Options is the list   of options passed to
%	http_open.
