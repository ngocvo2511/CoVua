:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/2, % board state, color
	state/1, % picking piece or placing piece
	history/1. % moves history

% =================================
% player queries
% =================================
% human vs human
% human vs computer
% computer vs human
% computer vs computer
game_mode(hxh) :- asserta(human(white)), asserta(human(black)) ,!.
game_mode(hxc) :- asserta(human(white)), !.
game_mode(cxh) :- asserta(human(black)), !.
game_mode(cxc) :- !.

% update the whole board, can be use for reset

:- [history].
:- [board].
:- [attack].
:- [movement].
:- [helper].

start :-
	set_position(begin).

% returns list of all legal moves for piece at Pos
pick_piece(Pos, LegalMoves) :-
	board(Position, Color),
	find_piece_color(Pos, Color, Position),
	% find_piece_type(Pos, Type, Position, Color),
	findall(To, is_legal_move(Pos, To, Color, Position), LegalMoves).

% move piece from From to To with full validation
place_piece(From, To) :-
	board(Position, Color),

	% Check if it's a legal move
	is_legal_move(From, To, Color, Position),
	
	% Make the move, wrap this with state(place) to make sure only this allow to print to screen
	asserta(state(place)),
	simulate_move(From, To, Color, Position, NewPosition),
	retract(state(place)),
	
	% Switch to opposite player's turn
	invert(Color, NextColor),
	add_to_history(NewPosition, NextColor),
	% Check for game ending conditions
	check_game_status(NewPosition, NextColor),
	
	retract(board(Position, Color)),
	asserta(board(NewPosition, NextColor)).
		    
	
:- [test].
