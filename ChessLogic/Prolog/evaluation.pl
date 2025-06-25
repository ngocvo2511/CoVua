% =================================
%	Position Evaluation
% =================================

is_endgame :- false.

position_value(pawn, Pos, Value) :-
    get_row_col(Pos, Row, Col),
    (
        Row = 7 -> RowValue = [  0,  0,  0,  0,  0,  0,  0,  0 ]
    ;   Row = 6 -> RowValue = [ 50, 50, 50, 50, 50, 50, 50, 50 ]
    ;   Row = 5 -> RowValue = [ 10, 10, 20, 30, 30, 20, 10, 10 ]
    ;   Row = 4 -> RowValue = [  5,  5, 10, 25, 25, 10,  5,  5 ]
    ;   Row = 3 -> RowValue = [  0,  0,  0, 20, 20,  0,  0,  0 ]
    ;   Row = 2 -> RowValue = [  5, -5,-10,  0,  0,-10, -5,  5 ]
    ;   Row = 1 -> RowValue = [  5, 10, 10,-20,-20, 10, 10,  5 ]
    ;   Row = 0 -> RowValue = [  0,  0,  0,  0,  0,  0,  0,  0 ]
    ),
    nth0(Col, RowValue, Value).

position_value(knight, Pos, Value) :-
    get_row_col(Pos, Row, Col),
    (
        Row = 7 -> RowValue = [ -50,-40,-30,-30,-30,-30,-40,-50 ]
    ;   Row = 6 -> RowValue = [ -40,-20,  0,  0,  0,  0,-20,-40 ]
    ;   Row = 5 -> RowValue = [ -30,  0, 10, 15, 15, 10,  0,-30 ]
    ;   Row = 4 -> RowValue = [ -30,  5, 15, 20, 20, 15,  5,-30 ]
    ;   Row = 3 -> RowValue = [ -30,  0, 15, 20, 20, 15,  0,-30 ]
    ;   Row = 2 -> RowValue = [ -30,  5, 10, 15, 15, 10,  5,-30 ]
    ;   Row = 1 -> RowValue = [ -40,-20,  0,  5,  5,  0,-20,-40 ]
    ;   Row = 0 -> RowValue = [ -50,-40,-30,-30,-30,-30,-40,-50 ]
    ),
    nth0(Col, RowValue, Value).

position_value(bishop, Pos, Value) :-
    get_row_col(Pos, Row, Col),
    (
        Row = 7 -> RowValue = [ -20,-10,-10,-10,-10,-10,-10,-20 ]
    ;   Row = 6 -> RowValue = [ -10,  0,  0,  0,  0,  0,  0,-10 ]
    ;   Row = 5 -> RowValue = [ -10,  0,  5, 10, 10,  5,  0,-10 ]
    ;   Row = 4 -> RowValue = [ -10,  5,  5, 10, 10,  5,  5,-10 ]
    ;   Row = 3 -> RowValue = [ -10,  0, 10, 10, 10, 10,  0,-10 ]
    ;   Row = 2 -> RowValue = [ -10, 10, 10, 10, 10, 10, 10,-10 ]
    ;   Row = 1 -> RowValue = [ -10,  5,  0,  0,  0,  0,  5,-10 ]
    ;   Row = 0 -> RowValue = [ -20,-10,-10,-10,-10,-10,-10,-20 ]
    ),
    nth0(Col, RowValue, Value).

position_value(rook, Pos, Value) :-
    get_row_col(Pos, Row, Col),
    (
        Row = 7 -> RowValue = [  0,  0,  0,  0,  0,  0,  0,  0 ]
    ;   Row = 6 -> RowValue = [  5, 10, 10, 10, 10, 10, 10,  5 ]
    ;   Row = 5 -> RowValue = [ -5,  0,  0,  0,  0,  0,  0, -5 ]
    ;   Row = 4 -> RowValue = [ -5,  0,  0,  0,  0,  0,  0, -5 ]
    ;   Row = 3 -> RowValue = [ -5,  0,  0,  0,  0,  0,  0, -5 ]
    ;   Row = 2 -> RowValue = [ -5,  0,  0,  0,  0,  0,  0, -5 ]
    ;   Row = 1 -> RowValue = [ -5,  0,  0,  0,  0,  0,  0, -5 ]
    ;   Row = 0 -> RowValue = [  0,  0,  0,  5,  5,  0,  0,  0 ]
    ),
    nth0(Col, RowValue, Value).

position_value(queen, Pos, Value) :-
    get_row_col(Pos, Row, Col),
    (
        Row = 7 -> RowValue = [ -20,-10,-10, -5, -5,-10,-10,-20 ]
    ;   Row = 6 -> RowValue = [ -10,  0,  0,  0,  0,  0,  0,-10 ]
    ;   Row = 5 -> RowValue = [ -10,  0,  5,  5,  5,  5,  0,-10 ]
    ;   Row = 4 -> RowValue = [  -5,  0,  5,  5,  5,  5,  0, -5 ]
    ;   Row = 3 -> RowValue = [   0,  0,  5,  5,  5,  5,  0, -5 ]
    ;   Row = 2 -> RowValue = [ -10,  5,  5,  5,  5,  5,  0,-10 ]
    ;   Row = 1 -> RowValue = [ -10,  0,  5,  0,  0,  0,  0,-10 ]
    ;   Row = 0 -> RowValue = [ -20,-10,-10, -5, -5,-10,-10,-20 ]
    ),
    nth0(Col, RowValue, Value).

position_value(king, Pos, Value) :-
    get_row_col(Pos, Row, Col),
    (
        is_endgame ->
        (
            Row = 7 -> RowValue = [ -50,-40,-30,-20,-20,-30,-40,-50 ]
        ;   Row = 6 -> RowValue = [ -30,-30, -10, 0, 0, -10,-30,-30 ]
        ;   Row = 5 -> RowValue = [ -30,-10, 20, 30, 30, 20,-10,-30 ]
        ;   Row = 4 -> RowValue = [ -30,-10, 30, 40, 40, 30,-10,-30 ]
        ;   Row = 3 -> RowValue = [ -30,-10, 30, 40, 40, 30,-10,-30 ]
        ;   Row = 2 -> RowValue = [ -30,-10, 20, 30, 30, 20,-10,-30 ]
        ;   Row = 1 -> RowValue = [ -30,-30,  0,  0,  0,  0,-30,-30 ]
        ;   Row = 0 -> RowValue = [ -50,-30,-30,-30,-30,-30,-30,-50 ]
        )
        ;
        (
            Row = 7 -> RowValue = [ -30,-40,-40,-50,-50,-40,-40,-30 ]
        ;   Row = 6 -> RowValue = [ -30,-40,-40,-50,-50,-40,-40,-30 ]
        ;   Row = 5 -> RowValue = [ -30,-40,-40,-50,-50,-40,-40,-30 ]
        ;   Row = 4 -> RowValue = [ -30,-40,-40,-50,-50,-40,-40,-30 ]
        ;   Row = 3 -> RowValue = [ -20,-30,-30,-40,-40,-30,-30,-20 ]
        ;   Row = 2 -> RowValue = [ -10,-20,-20,-20,-20,-20,-20,-10 ]
        ;   Row = 1 -> RowValue = [  20, 20,  0,  0,  0,  0, 20, 20 ]
        ;   Row = 0 -> RowValue = [  20, 30, 10,  0,  0, 10, 30, 20 ]
        )
    ),
    nth0(Col, RowValue, Value).

position_row_value(_Color,_Type, [], 0).
position_row_value(Color, Type, [PiecePos|RestPos], Value) :-
    (   
        Color = black ->
        Pos is 63 - PiecePos
    ;   Pos is PiecePos
    ),
    position_row_value(Color, Type, RestPos, RestValue),
    position_value(Type, Pos, CurValue),
    Value is CurValue + RestValue.


score_special(Position, Color, Counter, Value) :-
    % Use get_game_status to check for special conditions
    get_game_status(Position, Color, Counter, Status),
    (   Status = checkmate ->
        losing_value(Color, Value)
    ;   invert(Color, OpponentColor),
        get_game_status(Position, OpponentColor, Counter, OpponentStatus),
        OpponentStatus = checkmate ->
        winning_value(Color, Value)
    ;   Status = draw ->
        Value = 0
    ;   Status = stalemate ->
        Value = 0
    ;   % Normal position evaluation
        Value = null
    ).

piece_value(pawn, 100).
piece_value(knight, 300).
piece_value(bishop, 320).
piece_value(rook, 500).
piece_value(queen, 900).

piece_list_value(Type, PieceList, Value) :-
    length(PieceList, Count),
    piece_value(Type, PieceValue),
    Value is Count * PieceValue.


score(Position, _Color, _Counter, Value) :-
    Position = position(WhiteHalf, BlackHalf),
    % score_special(Position, Color, Counter, ValueSpecial), % too slow
    score_half(WhiteHalf, white, ValueWhite),
    score_half(BlackHalf, black, ValueBlack),
    Value is ValueWhite - ValueBlack, !.

% Evaluate position value
score_half(half_position(Pawns, Rooks, Knights, Bishops, Queens, Kings, _, _), Color, Value) :-
    % material values
    piece_list_value(pawn, Pawns, PawnMaterialValue),
    piece_list_value(rook, Rooks, RookMaterialValue),
    piece_list_value(knight, Knights, KnightMaterialValue),
    piece_list_value(bishop, Bishops, BishopMaterialValue),
    piece_list_value(queen, Queens, QueenMaterialValue),

    % position values
    position_row_value(Color, pawn, Pawns, PawnPositionValue),
    position_row_value(Color, rook, Rooks, RookPositionValue),
    position_row_value(Color, knight, Knights, KnightPositionValue),
    position_row_value(Color, bishop, Bishops, BishopPositionValue),
    position_row_value(Color, queen, Queens, QueenPositionValue),
    position_row_value(Color, king, Kings, KingPositionValue),

    % material values, position values, mop up values, pawn structure values, pawn shield values

    PositionValue is PawnPositionValue + RookPositionValue + KnightPositionValue + BishopPositionValue + 
             QueenPositionValue + KingPositionValue,
    MaterialValue is PawnMaterialValue + RookMaterialValue + KnightMaterialValue + 
             BishopMaterialValue + QueenMaterialValue,
    Value is PositionValue + MaterialValue.



% Helper to get row and column from position 
get_row_col(Position, Row, Col) :-
    Row is Position // 8,
    Col is Position mod 8.

winning_value(white, 9000).
winning_value(black, -9000).

losing_value(white, -9000).
losing_value(black, 9000).

