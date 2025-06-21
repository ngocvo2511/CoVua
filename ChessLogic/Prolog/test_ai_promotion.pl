:- [chess].

test_ai_promotion :-
    % Initialize board
    init,
    
    % Set up a position where black pawn can promote
    retract(board(_, _, _)),
    asserta(board(position(
        half_position([], [], [], [], [5], [4], [kingside, queenside], []),  % White: queen at f1, king at e1
        half_position([48], [], [], [], [], [60], [kingside, queenside], [])  % Black: pawn at a7, king at e8
    ), black, 0)),
    
    % Test if AI can find a promotion move
    write('Testing AI promotion move...'), nl,
    (bot_move(From, To, Status) ->
        write('AI found move: '), write(From), write(' to '), write(To), nl,
        write('Status: '), write(Status), nl,
        % Check if this was a promotion move
        (   (From = 48, To = 56) ->
            write('This was a promotion move!'), nl
        ;   write('This was a normal move.'), nl
        )
    ;   write('AI failed to find a move'), nl
    ). 