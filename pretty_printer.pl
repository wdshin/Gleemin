% First saved: 12/03/2011
% Last saved: 12/03/2011
%
%	State:
%	matrices.pl required!

% Doing:
%
% Todo
%
% NOTES:

%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
	Pretty-printer for prolog. Written for LPA Win-Prolog 4.900
	  but should probably work with most Edinburgh-compatible
	  Prologs with a minimum amount of fuss.
	Data to be output should be given in the form of a table,
	  ie, a nested list, each of its elements an n-element list.
	The top-goal is not definitve and can be redefined to suit your
	  needs (for example, you may want to add a separate grid/3 call
	  to surround the title with a different border, or add a
	  print_rows/4 call to print a subtitle etc.
*/


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%         Swi Compatibility         %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	:- set_prolog_flag(backquoted_string,true).
	% Swi LPA backtic string compatibility.
	:- style_check(-singleton).
	% Stop Swi warning on singleton vars.
	:- style_check(-discontiguous).
	% Stop Swi warning on discontiguous clauses.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%           Pretty-printer          %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%pp_style/4 12/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* pp_style(+Style, +Header, +Body, +Footer). */
	% "Style" being the characters to output as borders

	pp_style('Simple',[+,-,+,+],[+,'|',+],[+,-,+,+]).
	pp_style('Box drawings', [╔,═,╦,╗],[║,║,║],[╚,═,╩,╝]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%pretty_print/6 12/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* pretty_print(+Title, +Data, +Margin, +Header, +Body, +Footer) */
	% Top-level goal for the printer

	% Margin: tabs from the start of the screen
	% Padding: space to the end of a column (from the end of the datum)
	pretty_print(Title, Data, Margin, Header, Body, Footer):-
		append([Title], Data, Full),
		column_lengths(Full, Column_lengths),
		% ^ The full length of a column takes the title into account!
		map(pad, 3, Column_lengths, Padded_lengths),
		% ^ grid col. lengths take separators into account
		tab(Margin),
		grid(Header, Padded_lengths, Header_row),
		write(Header_row),nl,
		% ^ Header
		print_rows([Title], Margin, Column_lengths, Body),
		tab(Margin),
		% ^ Title
		write(Header_row),nl,
		print_rows(Data, Margin, Column_lengths, Body),
		% ^ Data
		tab(Margin),
		grid(Footer, Padded_lengths, Footer_row),
		write(Footer_row),nl.
		% ^ Footer

% | ?- pretty_print([[`Name`, `Type`, `Mana_cost`]], [[abc,12,1234],[abcd,3,12345]],
%		5, [+,-,+,+], ['|','|','|'], [+,-,-,+]).


%%%%%%%%%%%%%%pad/3  12/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* pad(+Number, +Addend, +Result) */
	% Adds a number to another and returns the result. Duh.

	pad(A, Pad, Incr):-
		Incr is A + Pad.

%%%%%%%%%%%%%%map/4  12/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* map(+Functor, Arg, List_1, List_2) */
	% Maps the elements of a list to a predicate's arguments.
	% This version takes three arguments.
	% Based on an example from the Win-LPA documentation

%%%%%%%%%%%%%%map/4  (0) 12/03/11

	map(_Pred, _A, [], []).

%%%%%%%%%%%%%%map/4  (1) 12/03/11

	map(Pred, A, [X|Y], [X1|Y1]) :-
%		Pred(A, X, X1), %Swi, 18/06/11
		Map =.. [Pred, A, X, X1],
		% ^ constructs the term Pred(A, X, X1)
		Map,
		map(Pred, A, Y, Y1).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%column_lengths/2 12/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* column_lengths(+Data, -Column_lengths) */
	% Measures the length of the elements of in each "column" of a "table"
	% (ie, list of n-element lists).

	% To feed into grid/5 (Lengths = Tabs)
	column_lengths(Data, Col_lengths):-
		type(Data, 6), % data is a list
		columns(Data, Columns),
		max_lengths(Columns, [], Col_lengths).
	% each Col_lengths element must correspond to a Columns element,
	%  eg: [[abc,a,bc], [ab,a,b], [abcd,ab,abc]], [3,2,4]


%%%%%%%%%%%%%%max_lengths/3  12/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* max_lengths(+Columns, [], -Max) */
	% Finds the longest element in a column-list.

%%%%%%%%%%%%%%max_lengths/3  (0) 12/03/11

	max_lengths([], Max, Max).

%%%%%%%%%%%%%%max_lengths/3  (1) 12/03/11

	max_lengths([Column | Rest], Temp, Max):-
		findall(Length,
				(member(Element, Column),
				len(Element, Length)),
			 Lengths),
		sort(Lengths, Sorted),
		reverse(Sorted, [Longest | _Rest]),
		append(Temp, [Longest], New_temp),
		max_lengths(Rest, New_temp, Max).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%print_rows/4 12/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* print_rows(+Table, +Margin, +Column_lengths, +Formatting) */
	% Prints rows of data from a table-list. Each row is an n-element
	%  list, member of the table-list.

%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
	Table:
		data to print; a square matrix, in list form, ie a
		list of n-element lists, eg:
		[[abc, defg, h] [1, 2345, 67] [Monday, Tuesday, Wednesday]]
		Any deviation from the "square table" pattern will cause
		this to fail disracefully and it has a tendency to go infinite,
		so don't push it. Particularly, key-value pairs are not
		supported currently and large, complex data in tuples is
		not well accepted.
	Margin:
		How far to start the printing from the left side of the console
	Column_lengths:
		Data will be output in columns of a maximum length determined
		by this argument (which can be instantiated by a call to
		column_lengths/2)
	Fomratting:
		[Left_border, Separator, Right_border]
	Where:
		Left_border: symbol to print at the start of each row
		Separator: symbol to print at the end of each datum in a row
		Right_border: symbol to print at the end of each row
*/

%%%%%%%%%%%%%%print_rows/4  (0) 12/03/11

	% Print each row of data
	print_rows([], _Margin, _Column_lengths, [_L, _S, _R]).
	% Data : list of Datum; Datum : list of atoms.

%%%%%%%%%%%%%%print_rows/4  (1) 12/03/11

	print_rows([Row | Data], Margin, Column_lengths, [L, S, R]):-
		tab(Margin),
		write(L), %write(` `),
		print_datum(Row, S, Column_lengths),
		%write(` `),
		write(R), nl,
		print_rows(Data, Margin, Column_lengths, [L, S, R]).

%%%%%%%%%%%%%%print_rows/3  12/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* print_row(+Data, +Separator, +Column_lengths) */
	% Prints each datum in a row of data

%%%%%%%%%%%%%%print_rows/3  (0) 12/03/11

	print_datum([], _Separator, _Column_lengths).

%%%%%%%%%%%%%%print_rows/3  (1) 12/03/11

	% One last datum remaining
	print_datum([Datum | []], Separator, [Column_length | Lengths]):-
		write(` `),
		write(Datum),
		write(` `),
		len(Datum, Length),
		Padding is Column_length - Length + 1,
		tab(Padding),
		print_datum([], Separator, Lengths).

%%%%%%%%%%%%%%print_rows/4  (1) 12/03/11

	print_datum([Datum | Data], Separator, [Column_length | Lengths]):-
		write(` `),
		write(Datum),
		write(` `),
		len(Datum, Length),
		Padding is Column_length - Length + 1,
		tab(Padding),
		write(Separator),
		print_datum(Data, Separator, Lengths).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%grid/3 12/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* grid(+Borders, +Tabs, -Output) */
	% Composes a line of symbols to be used as a header or row
	%  for a pretty-printed table

%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
	Borders:
		[Left_border, Line, Separator, Right_border]
	Where:
		Left_border: the symbol to print at the start of the grid line
		Line: the symbol to print across the top of each column of the
		  table
		Separator: the symbol to print between columns
		Right_border: the symbol to print at the end of the grid line
	Tabs:
		Length of each column in the table (they don't have to be equal)
	Output:
		The completed line, ready for pretty-printing (or any printing)
*/

%%%%%%%%%%%%%%grid/3  (1) 12/03/11

	grid([L_char, Cntr_char, Separator, R_char], [Tab | Tabs], Row):-
		grid(Cntr_char, Separator, Tab, [Tab | Tabs], [], Row_1),
		append([L_char], Row_1, Temp),
		append(Temp, [R_char], List),
		atom_to_list(Row, List), !. %Green cut


%%%%%%%%%%%%%%grid/6  12/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* grid(+Line, +Separator, +Tab, +Tabs, [], -Output) */

%%%%%%%%%%%%%%grid/6  (0) 12/03/11

	grid(_Cntr_char, _Separator, 0, [], Row, Row).

%%%%%%%%%%%%%%grid/6  (1) 12/03/11

	% One last tab left
	grid(Cntr_char, Separator, 0, [Next_tab | []], Temp, Row):-
		Temp \= [],
		grid(Cntr_char, Separator, Next_tab, [], Temp, Row).

%%%%%%%%%%%%%%grid/6  (2) 12/03/11

	% Add a column separator
	grid(Cntr_char, Separator, 0, [_Tab | [Next_tab | Tabs]], Temp, Row):-
		Temp \= [],
		append(Temp, [Separator], New_temp),
		grid(Cntr_char, Separator, Next_tab, [_| Tabs], New_temp, Row).

%%%%%%%%%%%%%%grid/6  (3) 12/03/11

	% Write a cell's top character.
	grid(Character, Separator, Tab, Tabs, Temp, Row):-
		append(Temp, [Character], New_temp),
		New_tab is Tab - 1,
		grid(Character, Separator, New_tab, Tabs, New_temp, Row).


%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
Test with:
	grid([╔, ═ ,  ╦, ╗], [2,3,3,4,3,2], Row_1),
	write(Row_1), nl,
	grid([╠, ═ ,  ╬, ╣], [2,3,3,4,3,2], Row_2),
	write(Row_2), nl,
	grid([╚, ═ ,  ╩, ╝], [2,3,3,4,3,2], Row_3),
	write(Row_3), nl, nl.
*/







