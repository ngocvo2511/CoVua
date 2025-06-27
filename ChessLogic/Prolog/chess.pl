:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/3, % board state, color, fifty-move counter
	history/1, % moves history
	depth/1,
	stack/3,
	count/1.

	
:- [history].
:- [board].
:- [attack].
:- [movement].
:- [helper].
:- [minimax].
:- [evaluation].
:- [test].

% =================================
% player queries
% =================================

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
	simulate_move(From, To, Color, Position, NewPosition, PromotionPiece),
	
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
	retractall(board(_,_,_)),
	retractall(state(_)),
	retractall(history(_)),
	retractall(depth(_)),
	set_position(begin),
	% Initialize default depth if not set
	asserta(depth(3)).
