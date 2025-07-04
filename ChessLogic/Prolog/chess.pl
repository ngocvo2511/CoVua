:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/3, % board state, color, fifty-move counter
	history/2, % moves history
	depth/1,
	stack/3,
	count/1,
	history_board/3,
	move_direction/2.

:- [history].
:- [board].
:- [move_ordering].
:- [attack].
:- [movement].
:- [helper].
:- [minimax].
:- [fen].
:- [evaluation].
:- [precomputed_move].
:- [test].

% =================================
% player queries
% =================================

position_to_board_list(position(H1, H2), BoardList) :-
    % Create empty board list with 64 elements (all empty)
    length(BoardList, 64),
    
    H1 = half_position(PawnWhite, RookWhite, KnightWhite, BishopWhite,
                       QueenWhite, KingWhite, _CastlingWhite, _EnPassantWhite),
    H2 = half_position(PawnBlack, RookBlack, KnightBlack, BishopBlack,
                       QueenBlack, KingBlack, _CastlingBlack, _EnPassantBlack),

    % Add all white pieces
    add_pieces_to_list(PawnWhite, [pawn,white], BoardList),
    add_pieces_to_list(RookWhite, [rook,white], BoardList),
    add_pieces_to_list(KnightWhite, [knight,white], BoardList),
    add_pieces_to_list(BishopWhite, [bishop,white], BoardList),
    add_pieces_to_list(QueenWhite, [queen,white], BoardList),
    add_pieces_to_list(KingWhite, [king,white], BoardList),

    % Add all black pieces
    add_pieces_to_list(PawnBlack, [pawn,black], BoardList),
    add_pieces_to_list(RookBlack, [rook,black], BoardList),
    add_pieces_to_list(KnightBlack, [knight,black], BoardList),
    add_pieces_to_list(BishopBlack, [bishop,black], BoardList),
    add_pieces_to_list(QueenBlack, [queen,black], BoardList),
    add_pieces_to_list(KingBlack, [king,black], BoardList),

	fill_unbound_with_empty(BoardList), !.

add_pieces_to_list([], _, _BoardList).
add_pieces_to_list([Pos|Rest], Piece, BoardList) :-
    nth0(Pos, BoardList, Piece),
    add_pieces_to_list(Rest, Piece, BoardList).

fill_unbound_with_empty([]).
fill_unbound_with_empty([H|T]) :-
    ( H = empty ; true ),  % will bind H = empty if unbound, do nothing if already instantiated
    fill_unbound_with_empty(T).


% returns list of all legal moves for piece at Pos
pick_piece(Pos, LegalMoves) :-
	board(Position, CurrentColor, _),
	position_to_board_list(Position, BoardList),
	Board = board(Position, CurrentColor, 0),
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
	board(Position, Color, Counter),
	position_to_board_list(Position, BoardList),
	Board = board(Position, Color, Counter),
	generate_attack_data(Board, BoardList, AttackData),
	% Check if it's a legal move
	nth0(From, BoardList, [Type, _PieceColor]),
	legal_move_for_piece(Type, From, To, Color, Position, BoardList, AttackData),
	% Make the move, wrap this with state(place) to make sure only this allow to print to screen
	simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, BoardList, AttackData),

	position_to_board_list(NewPosition, NewBoardList),
	NewBoard = board(NewPosition, Color, Counter),
	generate_attack_data(NewBoard, NewBoardList, NewAttackData),
	not(in_check(NewPosition, Color, NewBoardList, NewAttackData)),

	% Update fifty-move counter
	update_fifty_move_counter(From, To, Position, Color, Counter, NewCounter, BoardList, AttackData),

	% Switch to opposite player's turn
	invert(Color, NextColor),
	add_to_history(NewPosition, NextColor, NewCounter, move(From, To, MovedPiece, CapturedPiece, PromotedPiece)),
	% Check for game ending conditions

	check_game_status(NewPosition, NextColor, NewCounter, Status),

	retract(board(Position, Color, Counter)),
	asserta(board(NewPosition, NextColor, NewCounter)).

invert(white, black).
invert(black, white).