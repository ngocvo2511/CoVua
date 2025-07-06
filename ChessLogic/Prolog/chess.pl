:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/4, % board state, color, fifty-move counter, zobrist key
	depth/1,
	stack/4,
	count/1.

:- [history].
:- [board].
:- [move_ordering].
:- [attack].
:- [movement].
:- [helper].
:- [minimax].
:- [fen].
:- [evaluation].
:- [precomputation].
:- [transposition].
:- [zobrist].
:- [test].

% =================================
% player queries
% =================================

% returns list of all legal moves for piece at Pos
pick_piece(Pos, LegalMoves) :-
	board(Position, CurrentColor, _, _),
	position_to_board_list(Position, BoardList),
	Board = board(Position, CurrentColor, 0, 0),
	generate_attack_data(Board, BoardList, AttackData),
	(   nth0(Pos, BoardList, [_, PieceColor]) ->
	    % There is a piece at this position
	    (   PieceColor = CurrentColor ->
	        % It's the current player's piece, find legal moves
	        findall(To, is_legal_move(Pos, To, PieceColor, Position, BoardList, AttackData), LegalMoves)
	    ;   % It's the opponent's piece
	        LegalMoves = []
	    )
	;   % No piece at this position
	    LegalMoves = []
	).
% move piece from From to To with full validation
place_piece(From, To, Status, PromotedPiece) :-
	board(Position, Color, Counter, Key),
	position_to_board_list(Position, BoardList),
	Board = board(Position, Color, Counter, Key),
	generate_attack_data(Board, BoardList, AttackData),
	% Check if it's a legal move
	nth0(From, BoardList, [Type, _PieceColor]),
	legal_move_for_piece(Type, From, To, Color, Position, BoardList, AttackData),
	% Make the move, wrap this with state(place) to make sure only this allow to print to screen
	simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList, AttackData, Key, NewKey),

	position_to_board_list(NewPosition, NewBoardList),
	NewBoard = board(NewPosition, Color, Counter, NewKey),
	generate_attack_data(NewBoard, NewBoardList, NewAttackData),
	not(in_check(NewPosition, Color, NewBoardList, NewAttackData)),

	% Update fifty-move counter
	update_fifty_move_counter(From, To, Position, Color, Counter, NewCounter, BoardList, AttackData),

	% Switch to opposite player's turn
	invert(Color, NextColor),
	add_to_history(NewPosition, NextColor, NewCounter, NewKey, move(From, To, MovedPiece, CapturedPiece, PromotedPiece)),
	% Check for game ending conditions

	check_game_status(NewPosition, NextColor, NewCounter, NewKey, Status),

	retract(board(Position, Color, Counter, _)),
	asserta(board(NewPosition, NextColor, NewCounter, NewKey)).

invert(white, black).
invert(black, white).