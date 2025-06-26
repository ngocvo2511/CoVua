:- [chess].

test_promotion :-
    % Initialize board
    init,
    
    % Set up a position where white pawn can promote
    retract(board(_, _, _)),
    asserta(board(position(
        half_position([48], [], [], [], [], [4], [kingside, queenside], []),  % White: pawn at a7, king at e1
        half_position([], [], [], [], [], [60], [kingside, queenside], [])    % Black: king at e8
    ), white, 0)),
    
    % Test promotion move from a7 to a8 with queen
    write('Testing promotion from a7 to a8 with queen...'), nl,
    (place_piece_with_promotion(48, 56, queen, Status) ->
        write('Success! Status: '), write(Status), nl
    ;   write('Failed!'), nl
    ),
    
    % Show final board
    board(Position, Color, Counter),
    write('Final position: '), write(Position), nl,
    write('Color: '), write(Color), nl,
    write('Counter: '), write(Counter), nl. 