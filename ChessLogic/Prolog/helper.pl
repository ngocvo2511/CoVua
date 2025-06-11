skip_turn:- board(Position, Color),invert(Color, NextColor),
		retract(board(Position, Color)),
	    asserta(board(Position, NextColor)).

reset:-	retractall(human(_)),
		retractall(board(_,_)),
		retractall(state(_)).