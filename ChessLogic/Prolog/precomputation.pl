% ============================================
% Precomputed move tables for chess pieces
% ============================================

% Dynamic predicate to store precomputed attack maps
:- dynamic attack_bitboard/3.
:- dynamic attack_bitboard/4.
:- dynamic move_direction/2.
% Dynamic predicates to store precomputed distances
:- dynamic king_distance/3.
:- dynamic orthogonal_distance/3.
:- dynamic centre_manhattan_distance/2.

% can be used to check if a square can be arrived
opposite_direction(1, -1).
opposite_direction(-1, 1).
opposite_direction(8, -8).
opposite_direction(-8, 8).
opposite_direction(9, -9).
opposite_direction(-9, 9).
opposite_direction(7, -7).
opposite_direction(-7, 7).

calculate_knights_bitboard :-
    retractall(attack_bitboard(_, knight, _)),
    calculate_knights_for_all_squares.

calculate_knights_for_all_squares :-
    between(0, 63, Square),
    calculate_knight_bitboard_for_square(Square),
    fail.
calculate_knights_for_all_squares.

calculate_knight_bitboard_for_square(Square) :-
    KnightMoves = [-17, -15, -10, -6, 6, 10, 15, 17],
    findall(To, (
        member(Move, KnightMoves),
        To is Square + Move,
        valid_field(To),
        not(crosses_edge(Square, To, Move))
    ), ValidMoves),
    moves_to_bitboard(ValidMoves, Bitboard),
    asserta(attack_bitboard(Square, knight, Bitboard)).

calculate_kings_bitboard :-
    retractall(attack_bitboard(_, king, _)),
    calculate_kings_for_all_squares.

calculate_kings_for_all_squares :-
    between(0, 63, Square),
    calculate_king_bitboard_for_square(Square),
    fail.
calculate_kings_for_all_squares.

calculate_king_bitboard_for_square(Square) :-
    KingMoves = [-9, -8, -7, -1, 1, 7, 8, 9],
    findall(To, (
        member(Move, KingMoves),
        To is Square + Move,
        valid_field(To),
        not(crosses_edge(Square, To, Move))
    ), ValidMoves),
    moves_to_bitboard(ValidMoves, Bitboard),
    asserta(attack_bitboard(Square, king, Bitboard)).

calculate_pawns_bitboard :-
    retractall(attack_bitboard(_, pawn, _, _)),
    calculate_pawns_for_all_squares.

calculate_pawns_for_all_squares :-
    between(0, 63, Square),
    calculate_pawn_bitboard_for_square(Square, white),
    calculate_pawn_bitboard_for_square(Square, black),
    fail.
calculate_pawns_for_all_squares.

calculate_pawn_bitboard_for_square(Square, Color) :-
    (   Color = white ->
        PawnMoves = [9, 7]  % White pawns attack diagonally up
    ;   Color = black ->
        PawnMoves = [-7, -9]    % Black pawns attack diagonally down
    ),
    findall(To, (
        member(Move, PawnMoves),
        To is Square + Move,
        valid_field(To),
        not(crosses_edge(Square, To, Move))
    ), ValidMoves),
    moves_to_bitboard(ValidMoves, Bitboard),
    asserta(attack_bitboard(Square, pawn, Color, Bitboard)).

% Convert list of square indices to bitboard (tail recursive)
moves_to_bitboard(Squares, Bitboard) :-
    moves_to_bitboard(Squares, 0, Bitboard).
moves_to_bitboard([], Acc, Acc).
moves_to_bitboard([Square|Rest], Acc, Bitboard) :-
    NewAcc is Acc \/ (1 << Square),
    moves_to_bitboard(Rest, NewAcc, Bitboard).
% ============================================
% Precomputed move directions
% ============================================

precompute_move :-

    precompute_direction,
    calculate_knights_bitboard,
    calculate_kings_bitboard,
    calculate_pawns_bitboard,
    calculate_distances.

% which directions can be used to move on a square
precompute_direction :-
    retractall(move_direction(_, _)),
    between(0, 63, Square),
    get_row_col(Square, Row, Col),
    (Row =\= 0 -> asserta(move_direction(Square, -8)) ; true),
    (Row =\= 7 -> asserta(move_direction(Square, 8)) ; true),
    (Col =\= 0 -> asserta(move_direction(Square, -1)) ; true),
    (Col =\= 7 -> asserta(move_direction(Square, 1)) ; true), 
    (Row =\= 0, Col =\= 0 -> asserta(move_direction(Square, -9)) ; true),
    (Row =\= 7, Col =\= 7 -> asserta(move_direction(Square, 9)) ; true),
    (Row =\= 0, Col =\= 7 -> asserta(move_direction(Square, -7)) ; true),
    (Row =\= 7, Col =\= 0 -> asserta(move_direction(Square, 7)) ; true),
    fail.
precompute_direction.

% ============================================
% Precomputed distance
% ============================================

% Calculate all distance tables
calculate_distances :-
    calculate_centre_manhattan_distances,
    calculate_king_distances,
    calculate_orthogonal_distances.

% Calculate centre Manhattan distance for all squares
calculate_centre_manhattan_distances :-
    retractall(centre_manhattan_distance(_, _)),
    between(0, 63, Square),
    get_row_col(Square, Row, Col),
    FileDstFromCentre is max(3 - Col, Col - 4),
    RankDstFromCentre is max(3 - Row, Row - 4),
    CentreManhattanDist is FileDstFromCentre + RankDstFromCentre,
    asserta(centre_manhattan_distance(Square, CentreManhattanDist)),
    fail.
calculate_centre_manhattan_distances.

% Calculate king distance between all square pairs
calculate_king_distances :-
    retractall(king_distance(_, _, _)),
    between(0, 63, SquareA),
    between(0, 63, SquareB),
    get_row_col(SquareA, RowA, ColA),
    get_row_col(SquareB, RowB, ColB),
    RankDistance is abs(RowA - RowB),
    FileDistance is abs(ColA - ColB),
    KingDist is max(FileDistance, RankDistance),
    asserta(king_distance(SquareA, SquareB, KingDist)),
    fail.
calculate_king_distances.

% Calculate orthogonal distance between all square pairs
calculate_orthogonal_distances :-
    retractall(orthogonal_distance(_, _, _)),
    between(0, 63, SquareA),
    between(0, 63, SquareB),
    get_row_col(SquareA, RowA, ColA),
    get_row_col(SquareB, RowB, ColB),
    RankDistance is abs(RowA - RowB),
    FileDistance is abs(ColA - ColB),
    OrthogonalDist is FileDistance + RankDistance,
    asserta(orthogonal_distance(SquareA, SquareB, OrthogonalDist)),
    fail.
calculate_orthogonal_distances.
