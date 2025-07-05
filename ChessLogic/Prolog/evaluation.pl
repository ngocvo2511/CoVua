% =================================
%	Position Evaluation
% =================================

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

position_value(pawn, Pos, EndgamePhaseWeight, Value) :-
    get_row_col(Pos, Row, Col),
    (
        Row = 7 -> RowEarlyValue = [  0,  0,  0,  0,  0,  0,  0,  0 ], RowLateValue = [  0,  0,  0,  0,  0,  0,  0,  0 ]
    ;   Row = 6 -> RowEarlyValue = [ 50, 50, 50, 50, 50, 50, 50, 50 ], RowLateValue = [ 80, 80, 80, 80, 80, 80, 80, 80 ]
    ;   Row = 5 -> RowEarlyValue = [ 10, 10, 20, 30, 30, 20, 10, 10 ], RowLateValue = [ 50, 50, 50, 50, 50, 50, 50, 50 ]
    ;   Row = 4 -> RowEarlyValue = [  5,  5, 10, 25, 25, 10,  5,  5 ], RowLateValue = [ 30, 30, 30, 30, 30, 30, 30, 30 ]
    ;   Row = 3 -> RowEarlyValue = [  0,  0,  0, 20, 20,  0,  0,  0 ], RowLateValue = [ 20, 20, 20, 20, 20, 20, 20, 20 ]
    ;   Row = 2 -> RowEarlyValue = [  5, -5,-10,  0,  0,-10, -5,  5 ], RowLateValue = [ 10, 10, 10, 10, 10, 10, 10, 10 ]
    ;   Row = 1 -> RowEarlyValue = [  5, 10, 10,-20,-20, 10, 10,  5 ], RowLateValue = [ 10, 10, 10, 10, 10, 10, 10, 10 ]
    ;   Row = 0 -> RowEarlyValue = [  0,  0,  0,  0,  0,  0,  0,  0 ], RowLateValue = [  0,  0,  0,  0,  0,  0,  0,  0 ]
    ),
    nth0(Col, RowEarlyValue, EarlyValue),
    nth0(Col, RowLateValue, LateValue),
    Value is (1-EndgamePhaseWeight)*EarlyValue + EndgamePhaseWeight*LateValue.


position_value(king, Pos, EndgamePhaseWeight, Value) :-
    get_row_col(Pos, Row, Col),
    (
        Row = 7 -> RowEarlyValue = [ -50,-40,-30,-20,-20,-30,-40,-50 ], RowLateValue = [ -30,-40,-40,-50,-50,-40,-40,-30 ]
    ;   Row = 6 -> RowEarlyValue = [ -30,-30, -10, 0, 0, -10,-30,-30 ], RowLateValue = [ -30,-40,-40,-50,-50,-40,-40,-30 ]
    ;   Row = 5 -> RowEarlyValue = [ -30,-10, 20, 30, 30, 20,-10,-30 ], RowLateValue = [ -30,-40,-40,-50,-50,-40,-40,-30 ]
    ;   Row = 4 -> RowEarlyValue = [ -30,-10, 30, 40, 40, 30,-10,-30 ], RowLateValue = [ -30,-40,-40,-50,-50,-40,-40,-30 ]
    ;   Row = 3 -> RowEarlyValue = [ -30,-10, 30, 40, 40, 30,-10,-30 ], RowLateValue = [ -20,-30,-30,-40,-40,-30,-30,-20 ]
    ;   Row = 2 -> RowEarlyValue = [ -30,-10, 20, 30, 30, 20,-10,-30 ], RowLateValue = [ -10,-20,-20,-20,-20,-20,-20,-10 ]
    ;   Row = 1 -> RowEarlyValue = [ -30,-30,  0,  0,  0,  0,-30,-30 ], RowLateValue = [  20, 20,  0,  0,  0,  0, 20, 20 ]
    ;   Row = 0 -> RowEarlyValue = [ -50,-30,-30,-30,-30,-30,-30,-50 ], RowLateValue = [  20, 30, 10,  0,  0, 10, 30, 20 ]
    ),
    nth0(Col, RowEarlyValue, EarlyValue),
    nth0(Col, RowLateValue, LateValue),
    Value is (1-EndgamePhaseWeight)*EarlyValue + EndgamePhaseWeight*LateValue.

% Helper predicate to calculate position values with EndgamePhaseWeight (for pawn and king)
position_row_value(Color, pawn, [], EndgamePhaseWeight, 0).
position_row_value(Color, pawn, [PiecePos|RestPos], EndgamePhaseWeight, Value) :-
    (   
        Color = black ->
        get_row_col(PiecePos, Row, Col),
        NewRow is 7 - Row,
        Pos is NewRow * 8 + Col
    ;   Pos is PiecePos
    ),
    position_row_value(Color, pawn, RestPos, EndgamePhaseWeight, RestValue),
    position_value(pawn, Pos, EndgamePhaseWeight, CurValue),
    Value is CurValue + RestValue.

position_row_value(Color, king, [], EndgamePhaseWeight, 0).
position_row_value(Color, king, [PiecePos|RestPos], EndgamePhaseWeight, Value) :-
    (   
        Color = black ->
        get_row_col(PiecePos, Row, Col),
        NewRow is 7 - Row,
        Pos is NewRow * 8 + Col
    ;   Pos is PiecePos
    ),
    position_row_value(Color, king, RestPos, EndgamePhaseWeight, RestValue),
    position_value(king, Pos, EndgamePhaseWeight, CurValue),
    Value is CurValue + RestValue.

% Helper predicate to calculate position values (for other pieces)
position_row_value(_Color, _Type, [], 0).
position_row_value(Color, Type, [PiecePos|RestPos], Value) :-
    (   
        Color = black ->
        get_row_col(PiecePos, Row, Col),
        NewRow is 7 - Row,
        Pos is NewRow * 8 + Col
    ;   Pos is PiecePos
    ),
    position_row_value(Color, Type, RestPos, RestValue),
    position_value(Type, Pos, CurValue),
    Value is CurValue + RestValue.

piece_value(pawn, 100) :- !.
piece_value(knight, 300) :- !.
piece_value(bishop, 320) :- !.
piece_value(rook, 500) :- !.
piece_value(queen, 900) :- !.
piece_value(_, 0).

piece_list_value(Type, PieceList, Value) :-
    length(PieceList, Count),
    piece_value(Type, PieceValue),
    Value is Count * PieceValue.


% Main evaluation predicate - evaluates entire position
score(WhiteHalf, BlackHalf, Value) :-
    WhiteHalf = half_position(_, _, _, 
                            _, _, [WhiteKingPos], _, _),
    BlackHalf = half_position(_, _, _, 
                            _, _, [BlackKingPos], _, _),
    score_half(WhiteHalf, white, WhiteMaterialValue, WhiteEndgamePhaseWeight),
    score_half(BlackHalf, black, BlackMaterialValue, BlackEndgamePhaseWeight),
    
    % Add mop-up evaluation for endgame scenarios
    mop_up_value(WhiteKingPos, BlackKingPos, WhiteMaterialValue, BlackMaterialValue, BlackEndgamePhaseWeight, WhiteMopUpValue),
    mop_up_value(BlackKingPos, WhiteKingPos, BlackMaterialValue, WhiteMaterialValue, WhiteEndgamePhaseWeight, BlackMopUpValue),
    
    % Final evaluation
    Value is WhiteMaterialValue - BlackMaterialValue + WhiteMopUpValue - BlackMopUpValue.

% Evaluate position value for one side
score_half(half_position(Pawns, Rooks, Knights, Bishops, Queens, Kings, _, _), Color, Value, EndgamePhaseWeight) :-
    % Calculate material values
    calculate_material_values(Pawns, Rooks, Knights, Bishops, Queens, 
                            PawnMaterialValue, RookMaterialValue, KnightMaterialValue, 
                            BishopMaterialValue, QueenMaterialValue),
    
    % Calculate endgame phase weight
    MaterialWithoutPawns is RookMaterialValue + KnightMaterialValue + 
                           BishopMaterialValue + QueenMaterialValue,

    end_game_phase_weight(MaterialWithoutPawns, EndgamePhaseWeight),
    
    % Calculate position values
    calculate_position_values(Color, Pawns, Rooks, Knights, Bishops, Queens, Kings,
                            PawnPositionValue, RookPositionValue, KnightPositionValue, 
                            BishopPositionValue, QueenPositionValue, KingPositionValue, EndgamePhaseWeight),

    % Combine all evaluation components
    TotalMaterialValue is PawnMaterialValue + RookMaterialValue + KnightMaterialValue + 
                         BishopMaterialValue + QueenMaterialValue,
    TotalPositionValue is PawnPositionValue + RookPositionValue + KnightPositionValue + 
                         BishopPositionValue + QueenPositionValue + KingPositionValue,
    
    % Final evaluation (can be expanded with more components later)
    Value is TotalMaterialValue + TotalPositionValue.

% Helper predicate to calculate material values for all piece types
calculate_material_values(Pawns, Rooks, Knights, Bishops, Queens, 
                         PawnValue, RookValue, KnightValue, BishopValue, QueenValue) :-
    piece_list_value(pawn, Pawns, PawnValue),
    piece_list_value(rook, Rooks, RookValue),
    piece_list_value(knight, Knights, KnightValue),
    piece_list_value(bishop, Bishops, BishopValue),
    piece_list_value(queen, Queens, QueenValue).

% Helper predicate to calculate position values for all piece types
calculate_position_values(Color, Pawns, Rooks, Knights, Bishops, Queens, Kings,
                         PawnValue, RookValue, KnightValue, BishopValue, QueenValue, KingValue, EndgamePhaseWeight) :-
    position_row_value(Color, pawn, Pawns, EndgamePhaseWeight, PawnValue),
    position_row_value(Color, rook, Rooks, RookValue),
    position_row_value(Color, knight, Knights, KnightValue),
    position_row_value(Color, bishop, Bishops, BishopValue),
    position_row_value(Color, queen, Queens, QueenValue),
    position_row_value(Color, king, Kings, EndgamePhaseWeight, KingValue).

% 1620 is EndGameMaterialStart = rook*2 + bishop + knight
end_game_phase_weight(MaterialValue, Weight) :-
    EndGameMaterialStart = 1620.0,
    MaterialRatio is MaterialValue / EndGameMaterialStart,
    ClampedRatio is min(1.0, MaterialRatio),
    Weight is 1.0 - ClampedRatio.

% Mop-up evaluation for endgame scenarios where one side has significant material advantage
mop_up_value(FriendKingPos, OpponentKingPos, FriendMaterialValue, OpponentMaterialValue, EndgamePhaseWeight, Value) :-
    PawnValue = 100,
    OpponentMaterialAdvantage is OpponentMaterialValue + PawnValue * 2,
    (   FriendMaterialValue > OpponentMaterialAdvantage, EndgamePhaseWeight > 0 ->
        centre_manhattan_distance(OpponentKingPos, OpponentCentreDist),
        orthogonal_distance(FriendKingPos, OpponentKingPos, OpponentDist),
        Value is (OpponentCentreDist*10 + (14 - OpponentDist)*4) * EndgamePhaseWeight
    ;   
        % No significant material advantage or not in endgame
        Value = 0 
    ).
% Helper to get row and column from position 
get_row_col(Position, Row, Col) :-
    Row is Position // 8,
    Col is Position mod 8.

winning_value(white, 900000).
winning_value(black, -900000).

losing_value(white, -900000).
losing_value(black, 900000).

