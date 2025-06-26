:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/3, % board state, color, fifty-move counter
	state/1, % picking piece or placing piece
	history/1, % moves history
	depth/1.

	
:- [history].
:- [board].
:- [attack].
:- [movement].
:- [helper].
:- [minimax].
:- [test].

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


% returns list of all legal moves for piece at Pos
pick_piece(Pos, LegalMoves) :-
	board(Position, CurrentColor, _),
	(   find_piece_color(Pos, PieceColor, Position) ->
	    % There is a piece at this position
	    (   PieceColor = CurrentColor ->
	        % It's the current player's piece, find legal moves
	        findall(To, is_legal_move(Pos, To, PieceColor, Position, _PromotionPiece), LegalMoves)
	    ;   % It's the opponent's piece
	        LegalMoves = []
	    )
	;   % No piece at this position
	    LegalMoves = []
	).
% move piece from From to To with full validation
place_piece(From, To, Status, PromotionPiece) :-
	board(Position, Color, Counter),

	% Check if it's a legal move
	is_legal_move(From, To, Color, Position, PromotionPiece),
	
	% Make the move, wrap this with state(place) to make sure only this allow to print to screen
	asserta(state(place)),
	simulate_move(From, To, Color, Position, NewPosition, PromotionPiece),
	retract(state(place)),
	
	% Update fifty-move counter
	update_fifty_move_counter(From, To, Position, Color, Counter, NewCounter),
	
	% Switch to opposite player's turn
	invert(Color, NextColor),
	add_to_history(NewPosition, NextColor, NewCounter),
	% Check for game ending conditions
	check_game_status(NewPosition, NextColor, NewCounter, Status),
	
	retract(board(Position, Color, Counter)),
	asserta(board(NewPosition, NextColor, NewCounter)).

init :-
	retractall(human(_)),
	retractall(board(_,_,_)),
	retractall(state(_)),
	retractall(history(_)),
	retractall(depth(_)),
	set_position(begin),
	% Initialize default depth if not set
	asserta(depth(3)),
	% Set game mode (human vs computer by default)
	asserta(human(white)).
