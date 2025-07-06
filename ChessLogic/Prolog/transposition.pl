:- dynamic entry/6.

% Table size constant
table_size(100000).

% Clear the transposition table
clear_table :-
    retractall(entry(_, _, _, _, _, _)).

% Store an evaluation in the transposition table
% store_evaluation(+ZobristKey, +Depth, +Color, +Eval, +NodeType, +Move)
store_evaluation(ZobristKey, Depth, Color, Eval, NodeType, Move) :-
    table_size(Size),
    Index is ZobristKey mod Size,
    % Remove any existing entry at this index
    retractall(entry(Index, _, _, _, _, _)),
    % Store the new entry with color-aware node type
    assertz(entry(Index, ZobristKey, Eval, Move, Depth, NodeType)).

% Lookup evaluation from the transposition table
% lookup_evaluation(+ZobristKey, +Depth, +Color, +Alpha, +Beta, -Result, -Move)
% Returns the stored evaluation and move or 'none' if not found/not usable
lookup_evaluation(ZobristKey, Depth, Color, Alpha, Beta, Result, Move) :-
    table_size(Size),
    Index is ZobristKey mod Size,
    % Try to find an entry at this index
    entry(Index, StoredKey, StoredValue, StoredMove, StoredDepth, NodeType),
    % Verify the keys match
    StoredKey =:= ZobristKey,
    % Only use if searched to at least the same depth
    StoredDepth >= Depth,
    % Check if we can use this entry based on node type and color
    can_use_entry_with_color(NodeType, StoredValue, Color, Alpha, Beta),
    !,
    Result = StoredValue,
    Move = StoredMove.

% If lookup fails, return 'none'
lookup_evaluation(_, _, _, _, _, none, none).

% Get the stored move for a position
% get_stored_move(+ZobristKey, -Move)
% Returns the stored move or 'none' if not found
get_stored_move(ZobristKey, Move) :-
    table_size(Size),
    Index is ZobristKey mod Size,
    entry(Index, StoredKey, _Value, StoredMove, _Depth, _NodeType),
    StoredKey =:= ZobristKey,
    !,
    Move = StoredMove.

get_stored_move(_, fail).

% Helper predicate to determine if an entry can be used with color awareness
% can_use_entry_with_color(+NodeType, +StoredValue, +Color, +Alpha, +Beta)
can_use_entry_with_color(exact, _, _, _, _) :- !.

% For white (maximizing player)
can_use_entry_with_color(upper_bound, StoredValue, white, Alpha, _) :-
    StoredValue =< Alpha, !.
can_use_entry_with_color(lower_bound, StoredValue, white, _, Beta) :-
    StoredValue >= Beta, !.

% For black (minimizing player) 
can_use_entry_with_color(upper_bound, StoredValue, black, _, Beta) :-
    StoredValue >= Beta, !.
can_use_entry_with_color(lower_bound, StoredValue, black, Alpha, _) :-
    StoredValue =< Alpha, !.

% Legacy helper predicate (kept for compatibility)
% can_use_entry(+NodeType, +StoredValue, +Alpha, +Beta)
can_use_entry(exact, _, _, _) :- !.
can_use_entry(upper_bound, StoredValue, Alpha, _) :-
    StoredValue =< Alpha, !.
can_use_entry(lower_bound, StoredValue, _, Beta) :-
    StoredValue >= Beta, !.

% Get table statistics
table_stats(UsedEntries, TotalSize) :-
    table_size(TotalSize),
    findall(X, entry(X, _, _, _, _, _), Entries),
    length(Entries, UsedEntries).

% Check if a position exists in the table
% position_in_table(+ZobristKey)
position_in_table(ZobristKey) :-
    table_size(Size),
    Index is ZobristKey mod Size,
    entry(Index, StoredKey, _, _, _, _),
    StoredKey =:= ZobristKey.

% Print table entry for debugging
% print_entry(+ZobristKey)
print_entry(ZobristKey) :-
    table_size(Size),
    Index is ZobristKey mod Size,
    entry(Index, StoredKey, Value, Move, Depth, NodeType),
    StoredKey =:= ZobristKey,
    !,
    format('Entry for key ~w:~n', [ZobristKey]),
    format('  Index: ~w~n', [Index]),
    format('  Value: ~w~n', [Value]),
    format('  Move: ~w~n', [Move]),
    format('  Depth: ~w~n', [Depth]),
    format('  NodeType: ~w~n', [NodeType]).

print_entry(ZobristKey) :-
    format('No entry found for key ~w~n', [ZobristKey]).

% Helper predicates for determining evaluation types in traditional minimax
% determine_eval_type(+Color, +FinalValue, +OriginalAlpha, +OriginalBeta, +Alpha, +Beta, -EvalType)
determine_eval_type(Color, FinalValue, OriginalAlpha, OriginalBeta, Alpha, Beta, EvalType) :-
    (   Color = white ->
        % White maximizes
        (   FinalValue >= OriginalBeta ->
            EvalType = beta_cutoff  % Too good for white, opponent won't allow this
        ;   FinalValue =< OriginalAlpha ->
            EvalType = alpha_cutoff % Not good enough for white
        ;   EvalType = exact       % Exact evaluation within window
        )
    ;   Color = black ->
        % Black minimizes  
        (   FinalValue =< OriginalAlpha ->
            EvalType = alpha_cutoff % Too good for black (too low), opponent won't allow this
        ;   FinalValue >= OriginalBeta ->
            EvalType = beta_cutoff  % Not good enough for black (too high)
        ;   EvalType = exact       % Exact evaluation within window
        )
    ).

% Alternative helper for simple cutoff detection
% is_alpha_beta_cutoff(+Color, +Value, +Alpha, +Beta, -CutoffType)
is_alpha_beta_cutoff(white, Value, _Alpha, Beta, beta_cutoff) :-
    Value >= Beta, !.
is_alpha_beta_cutoff(black, Value, Alpha, _Beta, alpha_cutoff) :-
    Value =< Alpha, !.
is_alpha_beta_cutoff(_, _, _, _, no_cutoff).

% =================================
% TRANSPOSITION TABLE FOR COLOR-AWARE MINIMAX
% =================================
% This implementation is adapted for traditional minimax (not negamax).
% Key differences from negamax-based transposition tables:
%
% 1. Color-aware evaluation types:
%    - White (maximizing): alpha_cutoff -> lower_bound, beta_cutoff -> upper_bound
%    - Black (minimizing): alpha_cutoff -> upper_bound, beta_cutoff -> lower_bound
%
% 2. Lookup logic considers player color:
%    - White can use lower_bound if >= beta (cutoff)
%    - White can use upper_bound if <= alpha (no improvement)
%    - Black can use upper_bound if >= beta (cutoff for black means too high)
%    - Black can use lower_bound if <= alpha (no improvement for black means too low)
%
% 3. Storage requires color context to determine correct node type
%
% =================================