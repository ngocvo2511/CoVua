:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/2, % board state, color
	state/1. % picking piece or placing piece

initial_pos(position(H1,H2,0)):-
	PawnWhite = [9,10,12,13,14,15],
	H1 = half_position(PawnWhite,[0,7],[1,6],[2,5],[3],[4],notmoved),
	PawnBlack = [48,49,50,51,52,53,54,55],
	H2 = half_position(PawnBlack,[56,63],[57,62],[58,61],[59],[60],notmoved).

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
set_position(begin) :-
	retractall(board(_,_)),
	initial_pos(Position),
	asserta(board(Position,white)),!.
set_position(Position,Color) :- 
	retractall(board(_,_)), 
	asserta(board(Position,Color)),!.

:- [board].
:- [attack].
:- [movement].

% returns list of all legal moves for piece at Pos
pick_piece(Pos, LegalMoves) :-
	asserta(state(pick)),
	board(Position, Color),
	find_piece_color(Pos, Color, Position),
	% find_piece_type(Pos, Type, Position, Color),
	findall(To, is_legal_move(Pos, To, Color, Position), LegalMoves),
	retract(state(pick)).

% move piece from From to To with full validation
place_piece(From, To) :-
	board(Position, Color),

	% Check if it's a legal move
	is_legal_move(From, To, Color, Position),
	
	% Make the move
	asserta(state(place)),
	simulate_move(From, To, Color, Position, NewPosition),
	retract(state(place)),
	
	% Switch to opposite player's turn
	invert(Color, NextColor),
	
	% Check for game ending conditions
	(   is_checkmate(NextColor, NewPosition) ->
	    % Current player wins by checkmate
	    write('CHECKMATE'), nl,
	    reset
	;   is_stalemate(NextColor, NewPosition) ->
	    % Game ends in stalemate
	    write('STALEMATE'), nl,
	    reset
	;   % Game continues normally
	    (   in_check(NextColor, NewPosition) ->
	        write('CHECK'), nl
	    ;   true
	    ),
		% Update the board
		retract(board(Position, Color)),
		asserta(board(NewPosition, NextColor))
	).
		    
	
:- [test].
:- [helper].
