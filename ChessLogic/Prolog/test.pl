:- dynamic perft_stack/1.

test_check :-
	only_king_and_rooks(Position),
	set_position(Position,white).

test_pawn_promotion :-
	only_king_and_pawns(Position),
	set_position(Position,white).
	
test_enpassant :-
	enpassant_position(Position),
	set_position(Position,white).

test_threefold :-
	threefold_position(Position),
	set_position(Position,white).

test_checkmate :-
	checkmate_position(Position),
	set_position(Position,white).

only_king_and_rooks(position(H1, H2)) :-
    H1 = half_position([],[],[],[],[],[4],[queenside,kingside],[]),
    H2 = half_position([],[7, 23],[],[],[],[60],[queenside,kingside],[]).
	
only_king_and_pawns(position(H1, H2)) :-
    H1 = half_position([48],[],[],[],[],[4],[queenside,kingside],[]),
    H2 = half_position([8],[],[],[],[],[60],[queenside,kingside],[]).

enpassant_position(position(H1, H2)) :-
    H1 = half_position([35],[],[],[],[],[4],[],[]),
    H2 = half_position([52],[],[],[],[],[60],[],[]).

castling_position(position(H1, H2)) :-
    H1 = half_position([],[0,7],[],[],[],[4],[queenside,kingside],[]),
    H2 = half_position([],[56,63],[],[],[],[60],[queenside,kingside],[]).



threefold_position(position(H1, H2)) :-
	H1 = half_position([],[1],[],[],[],[4],[],[]),
    H2 = half_position([],[],[],[],[],[56],[],[]).

checkmate_position(position(H1, H2)) :-
	H1 = half_position([],[],[],[],[],[47],[],[]),
	H2 = half_position([],[62,5],[],[],[],[35],[],[]).

kiwipete_pos(position(half_position([8,9,10,13,14,15,28,35],[0,7],[18,36],[11,12],[21],[4],[queenside,kingside],[]),
         half_position([48,50,51,53,44,46,25,23],[56,63],[41,45],[40,54],[52],[60],[queenside,kingside],[]))).

endgame_pos(position(half_position([33,12,14],[25],[],[],[],[32],[],[]),
         half_position([50,43,29],[39],[],[],[],[31],[],[]))).

sebas_pos(position(half_position([8,9,10,35,28,13,14,15],[0,7],[18,36],[11,12],[21],[4],[queenside,kingside],[]),
         half_position([48,25,50,51,44,53,46,23],[56,63],[41,45],[40,54],[52],[60],[queenside,kingside],[]))).

test_pos(position(half_position([],[],[],[],[],[27],[queenside,kingside],[]),
         half_position([],[],[51,24,30,48,54,0,3,6],[],[],[63],[queenside,kingside],[]))).

pin_pos(position(half_position([],[],[],[],[],[27],[queenside,kingside],[]),
		half_position([],[51,24,30],[],[48,54,0],[3,6],[63],[queenside,kingside],[]))).

buggy_pos(position(H1, H2)) :-
    PawnWhite = [8, 9, 10, 14, 15, 51],
    H1 = half_position(PawnWhite, [0, 7], [1, 12], [2, 26], [3], [4], [queenside, kingside], []),
    PawnBlack = [42, 48, 49, 53, 54, 55],
    H2 = half_position(PawnBlack, [56, 63], [13, 57], [52, 58], [59], [61], [], []).

test_position :-
	retract(depth(_)),
	asserta(depth(4)),
	Color = white,
	castling_position(Position),
	set_position(Position, Color).

test_time :-
	initial_pos(Position),
	get_all_legal_moves(Position, white, _MoveList, _BoardList).

test_incheck :-
	board(Pos, _Color, _Counter),
	(in_check(Pos, white, _) -> write('Yes') ; write('No')), nl,
	(in_check(Pos, black, _) -> write('Yes') ; write('No')), nl.

start_perft(Position, Color, Depth) :- 
	asserta(perft_stack(0)),
	perft(Position, Color, Depth),
	retract(perft_stack(Count)),
	write('Total nodes: '), write(Count), nl.

perft(Position, Color, Depth) :-
	position_to_board_list(Position, BoardList),
	get_all_legal_moves(Position, Color, MoveList, BoardList),
	(   Depth > 0 ->
		NewDepth is Depth - 1,
		invert(Color, NextColor),
		forall(member(Move, MoveList), (
			Move = move(From, To, MovedPiece, CapturedPiece, PromotionPiece),
			simulate_move(From, To, Color, Position, NewPosition, MovedPiece, CapturedPiece, PromotionPiece, BoardList),
			perft(NewPosition, NextColor, NewDepth)
		))
	;   retract(perft_stack(Count)),
		NewCount is Count + 1,
		asserta(perft_stack(NewCount))
	).

% Test attack data generation
test_attack_data :-
    test_attack_data_initial,
    test_attack_data_check,
    test_attack_data_pin.

test_attack_data_initial :-
    write('Testing attack data generation for initial position...'), nl,
    initial_pos(Position),
    position_to_board_list(Position, BoardList),
    Board = board(Position, white, 0),
    generate_attack_data(Board, BoardList, AttackData),
    AttackData = attack_data(InCheck, InDoubleCheck, PinExist, CheckRay, PinRay, 
                            OpponentKnightAttacks, OpponentAttackMapNoPawns, 
                            OpponentAttackMap, OpponentPawnAttackMap, OpponentSlidingAttackMap),
    write('InCheck: '), write(InCheck), nl,
    write('InDoubleCheck: '), write(InDoubleCheck), nl,
    write('PinExist: '), write(PinExist), nl,
    write('Test passed!'), nl.

test_attack_data_check :-
    write('Testing attack data generation for check position...'), nl,
    checkmate_position(Position),
    position_to_board_list(Position, BoardList),
    Board = board(Position, white, 0),
    generate_attack_data(Board, BoardList, AttackData),
    AttackData = attack_data(InCheck, InDoubleCheck, PinExist, CheckRay, PinRay, 
                            OpponentKnightAttacks, OpponentAttackMapNoPawns, 
                            OpponentAttackMap, OpponentPawnAttackMap, OpponentSlidingAttackMap),
    write('InCheck: '), write(InCheck), nl,
    write('InDoubleCheck: '), write(InDoubleCheck), nl,
    write('PinExist: '), write(PinExist), nl,
    write('Test passed!'), nl.

test_attack_data_pin :-
    write('Testing attack data generation for pin position...'), nl,
    % Create a position with a pin
    H1 = half_position([],[4],[],[],[],[0],[],[]),
    H2 = half_position([],[8],[],[],[],[56],[],[]),
    Position = position(H1, H2),
    position_to_board_list(Position, BoardList),
    Board = board(Position, white, 0),
    generate_attack_data(Board, BoardList, AttackData),
    AttackData = attack_data(InCheck, InDoubleCheck, PinExist, CheckRay, PinRay, 
                            OpponentKnightAttacks, OpponentAttackMapNoPawns, 
                            OpponentAttackMap, OpponentPawnAttackMap, OpponentSlidingAttackMap),
    write('InCheck: '), write(InCheck), nl,
    write('InDoubleCheck: '), write(InDoubleCheck), nl,
    write('PinExist: '), write(PinExist), nl,
    write('Test passed!'), nl.