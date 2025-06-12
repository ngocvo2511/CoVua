initial_pos(position(H1,H2,0)):-
	PawnWhite = [8,9,10,11,12,13,14,15],
	H1 = half_position(PawnWhite,[0,7],[1,6],[2,5],[3],[4],[queenside,kingside],[],notmoved),
	PawnBlack = [48,49,50,51,52,53,54,55],
	H2 = half_position(PawnBlack,[56,63],[57,62],[58,61],[59],[60],[queenside,kingside],[],notmoved).

set_position(begin) :-
	retractall(board(_,_)),
	initial_pos(Position),
	asserta(board(Position,white)),!.
	
set_position(Position,Color) :- 
	retractall(board(_,_)), 
	asserta(board(Position,Color)),!.

skip_turn:- board(Position, Color),invert(Color, NextColor),
		retract(board(Position, Color)),
	    asserta(board(Position, NextColor)).

reset:-	retractall(human(_)),
		retractall(board(_,_)),
		retractall(state(_)).
		
% check current game status
check_game_status(Position,Color) :-
	(   is_checkmate(Color, Position) ->
	    % Current player wins by checkmate
	    write('CHECKMATE'), nl
	;   is_stalemate(Color, Position) ->
	    % Game ends in stalemate
	    write('STALEMATE'), nl
	;   in_check(Color, Position) ->
		% Game continues normally
	    write('CHECK'), nl
	;   write('SAFE'), nl
	).