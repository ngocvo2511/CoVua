init :-
	retractall(board(_,_,_)),
	retractall(state(_)),
	retractall(history(_)),
	retractall(depth(_)),
	retractall(stack(_,_,_)),
	init_precomputed_move,
	set_position(begin),
	% Initialize default depth if not set
	asserta(depth(3)).

initial_pos(position(H1,H2)):-
	PawnWhite = [8,9,10,11,12,13,14,15],
	H1 = half_position(PawnWhite,[0,7],[1,6],[2,5],[3],[4],[queenside,kingside],[]),
	PawnBlack = [48,49,50,51,52,53,54,55],
	H2 = half_position(PawnBlack,[56,63],[57,62],[58,61],[59],[60],[queenside,kingside],[]).

set_position(begin) :-
	retractall(board(_,_,_)),
	initial_pos(Position),
	asserta(board(Position, white, 0)),
	init_history(Position, white),!.

set_position(Position, Color) :- 
	retractall(board(_,_,_)),
	asserta(board(Position,Color,0)),
	init_history(Position,Color),!.

skip_turn:- 
	board(Position, Color, Counter),
	invert(Color, NextColor),
	retract(board(Position, Color, Counter)),
	asserta(board(Position, NextColor, Counter)), !.

reset:-	
	retractall(human(_)),
	retractall(board(_,_,_)),
	retractall(history(_)).
		
check_game_status(Position, Color, Counter, Status) :-
	position_to_board_list(Position, BoardList),
    (   is_checkmate(Position, Color, BoardList) ->
        Status = checkmate
    ;   is_stalemate(Position, Color, BoardList) ->
        Status = stalemate
    ;   in_check(Position, Color, BoardList) ->
        Status = check
    ;	is_threefold_repetition(Position, Color) ->
        Status = draw
    ;	is_fifty_move(Counter) ->
        Status = draw
    ;	Status = safe
    ).

% Get the current board postion
get_current_board(Position, Color, Counter) :-
	board(TempPosition, Color, Counter),
	% Extract all the information from the position predicate in board to return only in list, no extra funtor
	TempPosition = position(H1, H2),
	% Convert the half positions to lists
	H1 = half_position(PawnWhite, RookWhite, KnightWhite, BishopWhite, QueenWhite, KingWhite, _CastlingWhite, _EnPassantWhite),
	H2 = half_position(PawnBlack, RookBlack, KnightBlack, BishopBlack, QueenBlack, KingBlack, _CastlingBlack, _EnPassantBlack),
	% Create the final position list
	Position = [[PawnWhite, RookWhite, KnightWhite, BishopWhite, QueenWhite, KingWhite],
	                    [PawnBlack, RookBlack, KnightBlack, BishopBlack, QueenBlack, KingBlack]].

debugging.