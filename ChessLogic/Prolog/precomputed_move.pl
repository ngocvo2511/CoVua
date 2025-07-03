% ============================================
% Precomputed move tables for chess pieces
% ============================================

% Dynamic predicate to store precomputed attack maps
:- dynamic attack/3.

opposite_direction(1, -1).
opposite_direction(-1, 1).
opposite_direction(8, -8).
opposite_direction(-8, 8).
opposite_direction(9, -9).
opposite_direction(-9, 9).
opposite_direction(7, -7).
opposite_direction(-7, 7).

% % Generate all precomputed attack maps for knight and king pieces
% generate_precomputed_moves :-
%     % Clear any existing attack data
%     retractall(attack(_, _, _)),
    
%     % Generate attack maps for all squares (0-63)
%     generate_all_squares(0).

% % Generate attack maps for all squares starting from Square
% generate_all_squares(Square) :-
%     Square > 63, !.  % Base case: finished all squares
% generate_all_squares(Square) :-
%     Square =< 63,
    
%     % Generate knight attack map for this square
%     generate_knight_attack_map(Square, KnightBitboard),
%     assert(attack(knight, Square, KnightBitboard)),
    
%     % Generate king attack map for this square
%     generate_king_attack_map(Square, KingBitboard),
%     assert(attack(king, Square, KingBitboard)),
    
%     % Continue with next square
%     NextSquare is Square + 1,
%     generate_all_squares(NextSquare).

% % Generate knight attack bitboard for a given square
% generate_knight_attack_map(Square, KnightBitboard) :-
%     % Knight move offsets
%     KnightMoves = [15, 17, -15, -17, 6, 10, -6, -10],
%     generate_piece_attacks(Square, KnightMoves, 0, KnightBitboard).

% % Generate king attack bitboard for a given square
% generate_king_attack_map(Square, KingBitboard) :-
%     % King move offsets
%     KingMoves = [1, -1, 8, -8, 9, -9, 7, -7],
%     generate_piece_attacks(Square, KingMoves, 0, KingBitboard).

% % Generate attack bitboard for a piece from a given square with given move offsets
% generate_piece_attacks(_, [], Bitboard, Bitboard).
% generate_piece_attacks(Square, [Move|RestMoves], AccBitboard, FinalBitboard) :-
%     TargetSquare is Square + Move,
%     (   (valid_field(TargetSquare), not(crosses_edge(Square, TargetSquare, Move))) ->
%         % Valid target square - set bit in bitboard
%         NewBitboard is AccBitboard \/ (1 << TargetSquare)
%     ;   % Invalid target square - keep current bitboard
%         NewBitboard = AccBitboard
%     ),
%     generate_piece_attacks(Square, RestMoves, NewBitboard, FinalBitboard).

% % Edge crossing detection (using the one from movement.pl)
% % This predicate should be available from movement.pl when files are loaded

% % Utility predicate to display all precomputed moves (for debugging)
% show_all_attacks :-
%     forall(attack(Type, Square, Bitboard),
%            format('attack(~w, ~w, ~w)~n', [Type, Square, Bitboard])).

% % Utility predicate to get attack map for a specific piece and square
% get_attack_map(Type, Square, Bitboard) :-
%     attack(Type, Square, Bitboard).

% % Utility predicate to check if a square is attacked by a piece at a given position
% is_square_attacked(Type, FromSquare, ToSquare) :-
%     attack(Type, FromSquare, Bitboard),
%     AttackBit is 1 << ToSquare,
%     (Bitboard /\ AttackBit) =\= 0.

% % Initialize precomputed moves when file is loaded
% :- initialization(generate_precomputed_moves).


% ============================================
% Precomputed move directions
% ============================================

init_precomputed_move :-
    not(precomputed_move).

precomputed_move :- 
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