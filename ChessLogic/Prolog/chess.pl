:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/3, % board state, color, fifty-move counter
	state/1, % picking piece or placing piece
	history/1, % moves history
	depth/1,
	first_player/1.

% Mặc định lượt đi đầu tiên là trắng
first_player(white).

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
	board(Position, Color, _),
	find_piece_color(Pos, Color, Position),
	find_piece_type(Pos, Type, Position, Color),
	findall(To, 
		(legal_move_for_piece(Pos, To, Type, Color, Position),
		 (   (Type = pawn, is_promotion_move(Pos, To, Color, Position)) ->
		     % For promotion moves, check if any promotion is legal
		     (is_legal_move_with_promotion(Pos, To, Color, Position, queen) ;
		      is_legal_move_with_promotion(Pos, To, Color, Position, rook) ;
		      is_legal_move_with_promotion(Pos, To, Color, Position, bishop) ;
		      is_legal_move_with_promotion(Pos, To, Color, Position, knight))
		 ;   % For normal moves
		     is_legal_move(Pos, To, Color, Position)
		 )), 
		LegalMoves).

% move piece from From to To with full validation
place_piece(From, To) :-
	board(Position, Color, Counter),

	% Check if it's a legal move
	is_legal_move(From, To, Color, Position),
	
	% Make the move, wrap this with state(place) to make sure only this allow to print to screen
	asserta(state(place)),
	simulate_move(From, To, Color, Position, NewPosition),
	retract(state(place)),
	
	% Update fifty-move counter
	update_fifty_move_counter(From, To, Position, Color, Counter, NewCounter),
	
	% Switch to opposite player's turn
	invert(Color, NextColor),
	add_to_history(NewPosition, NextColor, NewCounter),
	% Check for game ending conditions
	check_game_status(NewPosition, NextColor, NewCounter),
	
	retract(board(Position, Color, Counter)),
	asserta(board(NewPosition, NextColor, NewCounter)).

place_piece(From, To, Status) :-
	board(Position, Color, Counter),

	% Check if it's a legal move
	is_legal_move(From, To, Color, Position),
	
	% Check if this is a pawn promotion move
	(   (find_piece_type(From, pawn, Position, Color), is_promotion_move(From, To, Color, Position)) ->
	    % This is a promotion move, but we need the promotion piece choice
	    throw(error(promotion_required, context(place_piece, 'Pawn promotion requires piece choice')))
	;   % Normal move processing - continue with existing logic
	    true
	),
	
	% Make the move, wrap this with state(place) to make sure only this allow to print to screen
	asserta(state(place)),
	simulate_move(From, To, Color, Position, NewPosition),
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

% New predicate to handle pawn promotion with given piece type
place_piece_with_promotion(From, To, PromotionPiece, Status) :-
	board(Position, Color, Counter),

	% Check if it's a legal move with promotion
	is_legal_move_with_promotion(From, To, Color, Position, PromotionPiece),
	
	% Make the move with promotion
	asserta(state(place)),
	simulate_move_with_promotion(From, To, Color, Position, PromotionPiece, NewPosition),
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
	% Lấy lượt đi đầu tiên từ first_player/1
	first_player(Color),
	set_position(begin, Color),
	% Initialize default depth if not set
	(depth(_) -> true ; asserta(depth(3))).

% Đặt lượt đi đầu tiên
set_first_player(Color) :-
	retractall(first_player(_)),
	assertz(first_player(Color)).


