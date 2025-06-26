:- [chess].

test_ai :-
    % Initialize board
    init,
    
    % Set up a simple position
    retract(board(_, _, _)),
    asserta(board(position(
        half_position([8,9,10,11,12,13,14,15], [0,7], [1,6], [2,5], [3], [4], [kingside, queenside], []),  % White pieces
        half_position([48,49,50,51,52,53,54,55], [56,63], [57,62], [58,61], [59], [60], [kingside, queenside], [])  % Black pieces
    ), black, 0)),
    
    % Test if AI can find a move
    write('Testing AI move...'), nl,
    (bot_move(From, To, Status) ->
        write('AI found move: '), write(From), write(' to '), write(To), nl,
        write('Status: '), write(Status), nl
    ;   write('AI failed to find a move'), nl
    ). 