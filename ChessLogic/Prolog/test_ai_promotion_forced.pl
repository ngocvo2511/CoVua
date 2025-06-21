:- [chess].

test_ai_promotion_forced :-
    % Initialize board
    init,
    
    % Set up a position where black pawn must promote (no other moves available)
    retract(board(_, _, _)),
    asserta(board(position(
        half_position([], [], [], [], [5], [4], [kingside, queenside], []),  % White: queen at f1, king at e1
        half_position([56], [], [], [], [], [60], [kingside, queenside], [])  % Black: pawn at a8 (ready to promote), king at e8
    ), black, 0)),
    
    % Test if AI can find a promotion move
    write('Testing AI forced promotion move...'), nl,
    (bot_move(From, To, Status) ->
        write('AI found move: '), write(From), write(' to '), write(To), nl,
        write('Status: '), write(Status), nl,
        % Check if this was a promotion move
        (   (From = 56, To = 56) ->
            write('This was a promotion move!'), nl
        ;   write('This was a normal move.'), nl
        )
    ;   write('AI failed to find a move'), nl
    ). 