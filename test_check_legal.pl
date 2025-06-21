:- [chess].

test_check_legal :-
    % Initialize board
    init,
    
    % Set up a position where black king is in check
    retract(board(_, _, _)),
    asserta(board(position(
        half_position([], [], [], [], [5], [4], [kingside, queenside], []),  % White: queen at f1, king at e1
        half_position([], [], [], [], [], [60], [kingside, queenside], [])    % Black: king at e8
    ), black, 0)),
    
    % Test if black king is in check
    write('Testing if black king is in check...'), nl,
    (in_check(black, position(
        half_position([], [], [], [], [5], [4], [kingside, queenside], []),
        half_position([], [], [], [], [], [60], [kingside, queenside], [])
    )) ->
        write('Yes, black king is in check'), nl
    ;   write('No, black king is not in check'), nl
    ),
    
    % Test legal moves for black king
    write('Testing legal moves for black king...'), nl,
    pick_piece(60, LegalMoves),
    write('Legal moves for black king: '), write(LegalMoves), nl,
    
    % Test if any move can save the king
    (LegalMoves = [] ->
        write('No legal moves available - checkmate!'), nl
    ;   write('Legal moves available to escape check'), nl
    ). 