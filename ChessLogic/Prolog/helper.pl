initial_pos(position(H1,H2)):-
	PawnWhite = [8,9,10,11,12,13,14,15],
	H1 = half_position(PawnWhite,[0,7],[1,6],[2,5],[3],[4],[queenside,kingside],[]),
	PawnBlack = [48,49,50,51,52,53,54,55],
	H2 = half_position(PawnBlack,[56,63],[57,62],[58,61],[59],[60],[queenside,kingside],[]).

kiwipete_pos(position(half_position([8,9,10,13,14,15,28,35],[0,7],[18,36],[11,12],[21],[4],[queenside,kingside],[]),
         half_position([48,50,51,53,44,46,25,23],[56,63],[41,45],[40,54],[52],[60],[queenside,kingside],[]))).

endgame_pos(position(half_position([33,12,14],[25],[],[],[],[32],[],[]),
         half_position([50,43,29],[39],[],[],[],[31],[],[]))).

buggy_pos(position(H1, H2)) :-
    PawnWhite = [8, 9, 10, 14, 15, 51],
    H1 = half_position(PawnWhite, [0, 7], [1, 12], [2, 26], [3], [4], [queenside, kingside], []),

    PawnBlack = [42, 48, 49, 53, 54, 55],
    H2 = half_position(PawnBlack, [56, 63], [13, 57], [52, 58], [59], [61], [], []).

set_position(begin) :-
	retractall(board(_,_,_)),
	initial_pos(Position),
	asserta(board(Position, white, 0)),
	init_history(Position, white),!.

set_position(Position, Color) :- 
	retractall(board(_,_,_)),
	asserta(board(Position,Color,0)),
	init_history(Position,Color),!.

skip_turn:- 
	board(Position, Color, Counter),
	invert(Color, NextColor),
	retract(board(Position, Color, Counter)),
	asserta(board(Position, NextColor, Counter)), !.

reset:-	
	retractall(human(_)),
	retractall(board(_,_,_)),
	retractall(history(_)).
		
check_game_status(Position, Color, Counter, Status) :-
    (   is_checkmate(Position, Color) ->
        Status = checkmate
    ;   is_stalemate(Position, Color) ->
        Status = stalemate
    ;   in_check(Position, Color) ->
        Status = check
    ;	is_threefold_repetition(Position, Color) ->
        Status = draw
    ;	is_fifty_move(Counter) ->
        Status = draw
    ;	Status = safe
    ).

% Get the current board postion
get_current_board(Position, Color, Counter) :-
	board(TempPosition, Color, Counter),
	% Extract all the information from the position predicate in board to return only in list, no extra funtor
	TempPosition = position(H1, H2),
	% Convert the half positions to lists
	H1 = half_position(PawnWhite, RookWhite, KnightWhite, BishopWhite, QueenWhite, KingWhite, _CastlingWhite, _EnPassantWhite),
	H2 = half_position(PawnBlack, RookBlack, KnightBlack, BishopBlack, QueenBlack, KingBlack, _CastlingBlack, _EnPassantBlack),
	% Create the final position list
	Position = [[PawnWhite, RookWhite, KnightWhite, BishopWhite, QueenWhite, KingWhite],
	                    [PawnBlack, RookBlack, KnightBlack, BishopBlack, QueenBlack, KingBlack]].

% Helper to get piece at a position
get_piece_at(position(WhiteHalf, BlackHalf), Pos, Piece) :-
    WhiteHalf = half_position(WhitePawns, WhiteRooks, WhiteKnights, WhiteBishops, WhiteQueens, WhiteKings, _, _),
    BlackHalf = half_position(BlackPawns, BlackRooks, BlackKnights, BlackBishops, BlackQueens, BlackKings, _, _),
    
    (   member(Pos, WhitePawns) -> Piece = pawn
    ;   member(Pos, WhiteRooks) -> Piece = rook
    ;   member(Pos, WhiteKnights) -> Piece = knight
    ;   member(Pos, WhiteBishops) -> Piece = bishop
    ;   member(Pos, WhiteQueens) -> Piece = queen
    ;   member(Pos, WhiteKings) -> Piece = king
    ;   member(Pos, BlackPawns) -> Piece = pawn
    ;   member(Pos, BlackRooks) -> Piece = rook
    ;   member(Pos, BlackKnights) -> Piece = knight
    ;   member(Pos, BlackBishops) -> Piece = bishop
    ;   member(Pos, BlackQueens) -> Piece = queen
    ;   member(Pos, BlackKings) -> Piece = king
    ;   Piece = empty
    ).

