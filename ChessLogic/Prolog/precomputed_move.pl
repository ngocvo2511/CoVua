% ============================================
% Precomputed move tables for chess pieces
% ============================================

% Dynamic predicate to store precomputed attack maps
:- dynamic attack_bitboard/3.
:- dynamic attack_bitboard/4.

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

init_precomputed_move :-
    precompute_direction,
    calculate_knights_bitboard,
    calculate_kings_bitboard,
    calculate_pawns_bitboard.

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