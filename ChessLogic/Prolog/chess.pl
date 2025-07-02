:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/3, % board state, color, fifty-move counter
	history/2, % moves history
	depth/1,
	stack/3,
	count/1,
	history_board/3.

:- use_module(library(assoc)).
	
:- [history].
:- [board].
:- [move_ordering].
:- [attack].
:- [movement].
:- [helper].
:- [minimax].
:- [evaluation].
:- [test].

% =================================
% player queries
% =================================

position_to_assoc(position(H1, H2), AssocOut) :-
    empty_assoc(EmptyAssoc),
    H1 = half_position(PawnWhite, RookWhite, KnightWhite, BishopWhite,
                       QueenWhite, KingWhite, _CastlingWhite, _EnPassantWhite),
    H2 = half_position(PawnBlack, RookBlack, KnightBlack, BishopBlack,
                       QueenBlack, KingBlack, _CastlingBlack, _EnPassantBlack),

    % Add all white pieces
    add_pieces(PawnWhite, [pawn,white], EmptyAssoc, A1),
    add_pieces(RookWhite, [rook,white], A1, A2),
    add_pieces(KnightWhite, [knight,white], A2, A3),
    add_pieces(BishopWhite, [bishop,white], A3, A4),
    add_pieces(QueenWhite, [queen,white], A4, A5),
    add_pieces(KingWhite, [king,white], A5, A6),

    % Add all black pieces
    add_pieces(PawnBlack, [pawn,black], A6, B1),
    add_pieces(RookBlack, [rook,black], B1, B2),
    add_pieces(KnightBlack, [knight,black], B2, B3),
    add_pieces(BishopBlack, [bishop,black], B3, B4),
    add_pieces(QueenBlack, [queen,black], B4, B5),
    add_pieces(KingBlack, [king,black], B5, AssocOut).

add_pieces([], _, Assoc, Assoc).
add_pieces([Pos|Rest], Piece, AssocIn, AssocOut) :-
    put_assoc(Pos, AssocIn, Piece, NewAssoc),
    add_pieces(Rest, Piece, NewAssoc, AssocOut).

% returns list of all legal moves for piece at Pos
pick_piece(Pos, LegalMoves) :-
	board(Position, CurrentColor, _),
	position_to_assoc(Position, Assoc),
	(   find_piece_color(Pos, PieceColor, Position, Assoc) ->
	    % There is a piece at this position
	    (   PieceColor = CurrentColor ->
	        % It's the current player's piece, find legal moves
	        findall(To, is_legal_move(Pos, To, PieceColor, Position, Assoc), LegalMoves)
	    ;   % It's the opponent's piece
	        LegalMoves = []
	    )
	;   % No piece at this position
	    LegalMoves = []
	).
% move piece from From to To with full validation
place_piece(From, To, Status, PromotedPiece) :-
	board(Position, Color, Counter),
	position_to_assoc(Position, Assoc),
	% Check if it's a legal move
	get_assoc(From, Assoc, [Type, _PieceColor]),
	legal_move_for_piece(Type, From, To, Color, Position, Assoc),
	% Make the move, wrap this with state(place) to make sure only this allow to print to screen
	simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotedPiece, Assoc),

	not(in_check(NewPosition, Color, Assoc)),

	% Update fifty-move counter
	update_fifty_move_counter(From, To, Position, Color, Counter, NewCounter, Assoc),

	% Switch to opposite player's turn
	invert(Color, NextColor),
	add_to_history(NewPosition, NextColor, NewCounter, move(From, To, MovedPiece, CapturedPiece, PromotedPiece)),
	% Check for game ending conditions
	write('Legal move for piece: '), write(Type), nl,

	check_game_status(NewPosition, NextColor, NewCounter, Status),

	retract(board(Position, Color, Counter)),
	asserta(board(NewPosition, NextColor, NewCounter)).

