:- [chess].

test_promotion_simple :-
    init,
    retract(board(_, _, _)),
    asserta(board(position(
        half_position([], [], [], [], [5], [4], [kingside, queenside], []),
        half_position([56], [], [], [], [], [60], [kingside, queenside], [])
    ), black, 0)),
    
    write('Testing promotion move...'), nl,
    (is_legal_move_with_promotion(56, 56, black, position(
        half_position([], [], [], [], [5], [4], [kingside, queenside], []),
        half_position([56], [], [], [], [], [60], [kingside, queenside], [])
    ), queen) ->
        write('Promotion move is legal'), nl
    ;   write('Promotion move is not legal'), nl
    ). 