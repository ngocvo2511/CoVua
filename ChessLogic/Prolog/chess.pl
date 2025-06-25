:- dynamic 
	human/1, % human player color, if predicate not exist then bot will play that turn
	board/3, % board state, color, fifty-move counter
	state/1, % picking piece or placing piece
	history/1, % moves history
	depth/1,
	stack/3.

	
:- [history].
:- [board].
:- [attack].
:- [movement].
:- [helper].
:- [minimax].
:- [evaluation].
:- [test].

% =================================
% player queries
% =================================
% human vs human
% human vs computer
% computer vs human
% computer vs computer
game_mode(hxh) :- asserta(human(white)), asserta(human(black)) ,!.
game_mode(hxc) :- asserta(human(white)), !.
game_mode(cxh) :- asserta(human(black)), !.
game_mode(cxc) :- !.


% returns list of all legal moves for piece at Pos
pick_piece(Pos, LegalMoves) :-
	board(Position, CurrentColor, _),
	(   find_piece_color(Pos, PieceColor, Position) ->
	    % There is a piece at this position
	    (   PieceColor = CurrentColor ->
	        % It's the current player's piece, find legal moves
	        findall(To, is_legal_move(Pos, To, PieceColor, Position), LegalMoves)
	    ;   % It's the opponent's piece
	        LegalMoves = []
	    )
	;   % No piece at this position
	    LegalMoves = []
	).

% move piece from From to To with full validation
place_piece(From, To) :-
	board(Position, Color, Counter),

	% Check if it's a legal move
	is_legal_move(From, To, Color, Position),
	
	% Make the move, wrap this with state(place) to make sure only this allow to print to screen
	asserta(state(place)),
	simulate_move(From, To, Color, Position, NewPosition),
	retract(state(place)),
	
	% Update fifty-move counter
	update_fifty_move_counter(From, To, Position, Color, Counter, NewCounter),
	
	% Switch to opposite player's turn
	invert(Color, NextColor),
	add_to_history(NewPosition, NextColor, NewCounter),
	% Check for game ending conditions
	check_game_status(NewPosition, NextColor, NewCounter),
	
	retract(board(Position, Color, Counter)),
	asserta(board(NewPosition, NextColor, NewCounter)).

start :- 
	(not(board(_, _, _)) -> init),
	game_mode(hxc),
	repeat,
	board(_, Color, _),
	(
		human(Color) -> 
			% Human player's turn
			read(Query),
			(   Query = pick_piece(Pos) ->
					(pick_piece(Pos, LegalMoves) ->
                        (LegalMoves = [] -> write('[]') ; write(LegalMoves))
                    ;   write('[]')
                    ), nl
			;   Query = place_piece(Pos, To) ->
					place_piece(Pos, To)
			; 	Query = skip_turn ->
					skip_turn
			; 	Query = reset ->
					reset
			; 	Query = undo ->
					(can_undo -> undo)
			; 	Query = get_position -> 
					get_current_board(Position, _Color, _Counter),
					write(Position), nl
			; 	Query = exit -> 
					write('Exiting...'), nl, !, fail
			; 	Query = game_mode(Mode) ->
					(   member(Mode, [hxh, hxc, cxh, cxc]) ->
						game_mode(Mode)
					;   write('Invalid game mode!'), nl
					)
			; Query = _ ->
					write('Invalid command!'), nl
			)
	;	% Computer player's turn
		bot_move
	), fail.

% Initialize the game for web interface
init :-
	retractall(human(_)),
	retractall(board(_,_,_)),
	retractall(state(_)),
	retractall(history(_)),
	retractall(depth(_)),
	set_position(begin),
	% Initialize default depth if not set
	asserta(depth(2)),
	% Set game mode (human vs computer by default)
	asserta(human(white)).


