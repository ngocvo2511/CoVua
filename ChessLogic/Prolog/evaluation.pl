% ***************************************************************
%	Position Evaluation
% ***************************************************************

% Main position evaluation
evaluate_position(Position, Color, Value) :-
    % Check for game ending conditions
    (   is_checkmate(Color, Position) ->
        losing_value(Color, Value)
    ;   invert(Color, OpponentColor),
        is_checkmate(OpponentColor, Position) ->
        winning_value(Color, Value)
    ;   % Normal position evaluation
        Position = position(WhiteHalf, BlackHalf),
        evaluate_material(WhiteHalf, white, WhiteValue),
        evaluate_material(BlackHalf, black, BlackValue),
        evaluate_position_bonus(Position, Color, PositionBonus),
        TotalValue is WhiteValue - BlackValue + PositionBonus,
        Value = TotalValue
    ).

% Evaluate material for one side
evaluate_material(half_position(Pawns, Rooks, Knights, Bishops, Queens, Kings, _, _), Color, Value) :-
    piece_count_value(pawn, Pawns, Color, PawnValue),
    piece_count_value(rook, Rooks, Color, RookValue),
    piece_count_value(knight, Knights, Color, KnightValue),
    piece_count_value(bishop, Bishops, Color, BishopValue),
    piece_count_value(queen, Queens, Color, QueenValue),
    piece_count_value(king, Kings, Color, KingValue),
    
    % Bonus for having pairs of pieces
    pair_bonus(Rooks, RookBonus),
    pair_bonus(Knights, KnightBonus),
    pair_bonus(Bishops, BishopBonus),
    
    Value is PawnValue + RookValue + KnightValue + BishopValue + 
             QueenValue + KingValue + 30 * (RookBonus + KnightBonus + BishopBonus).

% Count and evaluate pieces of a specific type
piece_count_value(_, [], _, 0) :- !.
piece_count_value(Type, [Position|Rest], Color, Value) :-
    piece_count_value(Type, Rest, Color, RestValue),
    piece_position_value(Type, Position, Color, PositionValue),
    Value is RestValue + PositionValue.

% Piece position values  
piece_position_value(Type, Position, black, Value) :-
    % Mirror position for black pieces (0-63 board)
    MirrorPosition is 63 - Position,
    piece_position_value(Type, MirrorPosition, white, Value), !.

% Pawn values (adapted for 0-63 board)
piece_position_value(pawn, Position, white, 127) :-
    member(Position, [18, 19]), !.  % central pawns advanced
piece_position_value(pawn, Position, white, 131) :-
    member(Position, [26, 27, 34, 35]), !.  % good central control
piece_position_value(pawn, _, white, 100) :- !.

% King safety values (adapted for 0-63 board)
piece_position_value(king, Position, white, 30) :-
    member(Position, [0, 1, 2, 6, 7]), !.  % safe king positions
piece_position_value(king, _, white, 0) :- !.

% Rook values
piece_position_value(rook, _, white, 450) :- !.

% Knight values
piece_position_value(knight, Position, white, Value) :-
    get_row_col(Position, Row, Col),
    knight_row_value(Row, RowValue),
    knight_col_value(Col, ColValue),
    Value is RowValue + ColValue, !.

% Bishop values
piece_position_value(bishop, Position, white, Value) :-
    get_row_col(Position, Row, _),
    bishop_row_value(Row, Value), !.

% Queen values
piece_position_value(queen, Position, white, Value) :-
    get_row_col(Position, Row, _),
    queen_row_value(Row, Value), !.

% Knight position values (adapted for 0-63 board)
knight_row_value(1, 320) :- !.  % second rank
knight_row_value(2, 321) :- !.  % third rank
knight_row_value(Row, 348) :-
    member(Row, [3, 4]), !.     % fourth and fifth ranks
knight_row_value(Row, 376) :-
    member(Row, [5, 6]), !.     % sixth and seventh ranks
knight_row_value(_, 290) :- !.

knight_col_value(Col, 0) :-
    member(Col, [0, 7]), !.     % edge files
knight_col_value(_, 10) :- !.

% Bishop position values
bishop_row_value(0, 300) :- !.  % first rank
bishop_row_value(Row, 329) :-
    member(Row, [1, 2]), !.     % second and third ranks
bishop_row_value(_, 330) :- !.

% Queen position values
queen_row_value(0, 850) :- !.   % first rank
queen_row_value(_, 876) :- !.

% Pair bonus
pair_bonus([_, _], 1) :- !.
pair_bonus(_, 0).

% Position bonus evaluation
evaluate_position_bonus(_Position, Color, Bonus) :-
    compensate(Color, Bonus).

% Helper to get row and column from position (0-63 board)
get_row_col(Position, Row, Col) :-
    Row is Position // 8,
    Col is Position mod 8.

% Game result values
winning_value(white, 9000).
winning_value(black, -9000).

losing_value(white, -9000).
losing_value(black, 9000).

% Compensation values
compensate(white, 15).
compensate(black, -15).