initial_pos(position(H1,H2)):-
	PawnWhite = [8,9,10,11,12,13,14,15],
	H1 = half_position(PawnWhite,[0,7],[1,6],[2,5],[3],[4],[queenside,kingside],[]),
	PawnBlack = [48,49,50,51,52,53,54,55],
	H2 = half_position(PawnBlack,[56,63],[57,62],[58,61],[59],[60],[queenside,kingside],[]).

set_position(begin) :-
	retractall(board(_,_)),
	initial_pos(Position),
	asserta(board(Position,white)),
	init_history(Position,white),!.
	
set_position(Position,Color) :- 
	retractall(board(_,_)),
	asserta(board(Position,Color)),
	init_history(Position,Color),!.

skip_turn:- board(Position, Color),invert(Color, NextColor),
		retract(board(Position, Color)),
	    asserta(board(Position, NextColor)), !.

reset:-	retractall(human(_)),
		retractall(board(_,_)),
		retractall(state(_)),
		retractall(history(_)).
		
% check current game status
check_game_status(Position,Color) :-
	(   is_checkmate(Color, Position) ->
	    write('CHECKMATE'), nl
	;   is_stalemate(Color, Position) ->
	    write('STALEMATE'), nl
	;   in_check(Color, Position) ->
	    write('CHECK'), nl
	;	is_threefold_repetition(Position, Color) ->
		write('DRAW'), nl
	;	write('SAFE'), nl
	).