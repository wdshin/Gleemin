% First saved: 17/03/11
% Last saved: 25/04/11
%
%	Status:
%	matchup strategy is OK but rudimentary
%
% Doing:
%	Adding combat heuristic
%		Done for blocking.
%		...and just attacks with everything for now!
%	adding minimax
%		need to add active player information to moves/4
%			Done for land_set
%			Done for castable_set
%
% Todo
%	add game state evaluation -based tactics to strategy
%		early_game
%		mid_game
%		late_game
%	a.k.a The Plan
%
% NOTES:
/*
	matchup strategy follows deck strategy closely,
	  for now. The important thing is that the inference engine
	  does recognise the matchup properly, though that is not
	  yet apparent in its game choices. If there is time I'll
	  add some more obvious tactic.
*/
%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%         Swi Compatibility         %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	:- set_prolog_flag(backquoted_string,true).
	% Swi LPA backtic string compatibility.
	:- style_check(-singleton).
	% Stop Swi warning on singleton vars.
	:- style_check(-discontiguous).
	% Stop Swi warning on discontiguous clauses.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%             AI Facts              %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Inference engine operators
	:- dynamic(with/2).
	:- dynamic(present/1).
	:- dynamic minimaxing/0.
	:- dynamic blocks/2.

% Deck tactics:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%land_tactic/2 17/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* land_tactic(Deck, Tactic) */
	% land Tactic(s) for Deck.

	land_tactic('Raspberry', play_any_land).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%spell_tactic/2 ?/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* spell_tactic(Deck, Tactic) */
	% spell-casting Tactic(s) for Deck.

	spell_tactic('Raspberry', cast_any_creature).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%combat_tactic/2 24/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* combat_tactic(Deck, Tactic) */
	% combat Tactic(s) for Deck.

	% Simple tatctic to attack with everything except utility creatures.
	combat_tactic('Raspberry', conserve_utility).


% Matchup tactics:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%land_tactic/3 17/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* land_tactic(Matchup, Deck, Tactic) */
	% land Tactic(s) for Deck vs Matchup.

	% Undefined matchup- normally, beginning of game
	land_tactic( [], _,play_any_land).
	land_tactic('Raspberry', 'Raspberry', play_any_land).
	land_tactic('Pistachio', 'Raspberry', play_any_land).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%spell_tactic/3 ?/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* spell_tactic(Matchup, Deck, Tactic) */
	% spell-casting Tactic(s) for Deck vs Matchup.

	% Undefined matchup- normally, beginning of game
	spell_tactic([], _, cast_any_creature).
	spell_tactic('Raspberry', 'Raspberry', cast_any_creature).
	spell_tactic('Pistachio', 'Raspberry', cast_any_creature).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%combat_tactic/3 24/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* combat_tactic(Matchup, Deck, Tactic) */
	% combat Tactic(s) for Deck vs Matchup.

	% Undefined matchup- normally, beginning of game
	combat_tactic([], _, conserve_utility).
	combat_tactic('Raspberry', 'Raspberry', conserve_utility).
	combat_tactic('Pistachio', 'Raspberry', conserve_utility).


% General facts:

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%utility_creatures/2 26/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* utility_creatures(Deck, Utility) */
	% The utility creatures to avoid declaring as attackers or
	%  blockers with when employing the tactic "conserve_utility"

	utility_creatures('Raspberry', ['Prodigal Pyromancer']).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%             AI Rules              %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%glee_min/4 17/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% glee_min(combat, +Step, +Context, -Decision).
	% Combat decisions.
	glee_min(combat, Step, Context, Decision):-
		deck('Glee-min', Deck),
		strategy([combat, Deck, Step, Context], Decision).
		% ^ OK, better naming of this "context" business needed.

	% Non-combat decisions
	glee_min(Active, Step, Phase, Play):-
		deck('Glee-min', Deck),
		strategy([Deck, Active, Step, Phase], Action_context),
		action(Active, Step, Phase, Action_context, Play).
		% where Action_context: [Action_name, Context],
		%   eg [cast_spell, Context]


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%strategy 17/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* strategy(+Context, -Action) */
	% top-level decision-making goal for the computer opponent.

%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
	strategy/2 takes in a list of facts about the game state
	  and returns an action to be taken by the compupter opponent.
	The action is one of the actions available to players, ie, an
	  input to player_actions/5: play a land, cast a spell, activate
	  an ability, take a special action (other than playing a land),
	  pass the turn or inspect the state of the game- or concede!
	The decision-making process has two steps: first a deck_strategy
	  goal is evaluated and an optimal action is returned. Then a
	  matchup strategy goal is evaluated and an action returned. If the
	  two actions don't match, Prolog is allowed to backtrack into
	  the deck-strategy evaluation goal, to attempt to find a new action.
	  if that fails, a minimax function is called to attempt to
	  brute-force its way through the problem.
	In other words, the overall strategy can be described as a simple
	  implication relationship:
		A AND B -> C OR D
	  Where:
		A: the deck strategy rules
		B: the matchup strategy rules
		C: the action to be taken
		D: the statistical evaluation alternative
	That's the plan in any case!
	  (things that are likely to change: whether matchup_strategy
	  takes in the board position only as an input, or the deck_strategy
	  output too; whether the two strategy sub-clauses' output is
	  attemtped to be matched directly, or a further evaluation of their
	  combination is made).
	Context information:
		Own_deck 		(deck name)
		Opponent_deck 	(")
*/


%%%%%%%%%%%%%%strategy (1) 15/03/11

	strategy(Context, Action):-
		deck_strategy(Context, Action),
		matchup_strategy(Context, Action).

%%%%%%%%%%%%%%strategy (2) 15/03/11

	strategy(Context, Action):-
		minimax(Context, Action).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%deck_strategy 15/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* deck_strategy([+Deck_name, +Tactic | +Context], Play) */

	deck_strategy(Context, Action):-
		land_tactic(deck, Context, Action),
		spell_tactic(deck, Context, Action),
		/*activated_tactic,
		specials_tactic,*/
		combat_tactic(deck, Context, Action).


%%%%%%%%%%%%%%land_tactic/3 18/03/11
%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%land_tactic/3 (0) 19/03/11

	% During combat it's probably best to stop evaluation here.
	land_tactic(X, [combat | _rest], _Action):-
		X = deck ; X = matchup.
	% Made ^ explicit to distinguish from spell_tactic/3 fact

%%%%%%%%%%%%%%land_tactic/3 (0) 10/04/11

	% During combat it's probably best to stop evaluation here.
	land_tactic(X, [_Matchup, combat | _rest], _Action):-
		X = deck ; X = matchup.
	% Made ^ explicit to distinguish from spell_tactic/3 fact

%%%%%%%%%%%%%%land_tactic/3 (1) 19/03/11

	% Finds the land_tactic for the deck and calls it
	land_tactic(deck, [Deck_name | Context], Action):-
		land_tactic(Deck_name, Tactic),
		% ^ so that tactics for a deck can be specified separately
%		Tactic(Context, Action). % eg Tactic = always_play_land
		TActic =.. [Tactic, Context, Action],
		TActic.
		% ^ Note this separates the name of the deck from the rest
		%  of the contex, by the way

%%%%%%%%%%%%%%land_tactic/3 (2) 10/04/11

	% If the matchup could not be defined, leave Action unbound to
	%  follow deck tactics, ie: "goldfish"
	land_tactic(matchup, [ [], _Deck_name | _Context], _Action).
	% State as a rule to distinguish from spell_tactic/3 fact

%%%%%%%%%%%%%%land_tactic/3 (3) 10/04/11

	land_tactic(matchup, [Matchup, Deck_name | Context], Action):-
		land_tactic(Matchup, Deck_name, Tactic),
		%Tactic(Context, Action)
		TActic =.. [Tactic, Context, Action],
		TActic.


% eg [Map, Switches]:
%  [[cancel - c,'Forest' - 'F'],['[c]ancel','[F]orest']]


%%%%%%%%%%%%%%spell_tactic/3 19/03/11
%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%spell_tactic/3 (0) 19/03/11

	% ^ Proper tactics should play spells during combat
	spell_tactic(X, [combat | _rest], _Action):-
		X = deck ; X = matchup.

%%%%%%%%%%%%%%spell_tactic/3 (0) 19/03/11

	% Gleemin has chosen to play a land.
	spell_tactic(X, _Context, Action ):-
		(X = deck ; X = matchup),
		\+ type(Action, 0)/*,
		Action = 108*/.

%%%%%%%%%%%%%%spell_tactic/3 (1) 19/03/11

	% There's no choice of play yet.
	spell_tactic(deck, [Deck_name | Context], Action):-
		spell_tactic(Deck_name, Tactic),
		%Tactic(Context, Action)
		TActic =.. [Tactic, Context, Action],
		TActic.

%%%%%%%%%%%%%%spell_tactic/3 (2) 10/04/11

	% Matchup undefined: goldfish
	spell_tactic(matchup, [ [], _Deck_name | _Context], _Action).

%%%%%%%%%%%%%%spell_tactic/3 (3) 10/04/11

	spell_tactic(matchup, [Matchup, Deck_name | Context], Action):-
		spell_tactic(Matchup, Deck_name, Tactic),
		%Tactic(Context, Action),
		TActic =.. [Tactic, Context, Action],
		TActic.


%%%%%%%%%%%%%%combat_tactic/3 19/03/11
%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%combat_tactic/3 (0) 24/03/11

	% Stops evaluation here if a decision has been made already
	combat_tactic(X, _Context, Action ):-
		(X = deck ; X = matchup),
		\+ type(Action, 0).

%%%%%%%%%%%%%%combat_tactic/3 (1) 24/03/11

	combat_tactic(deck, [combat, Deck_name | Context], Action):-
		combat_tactic(Deck_name, Tactic),
		%Tactic(Context, Action)
		TActic =.. [Tactic, Context, Action],
		TActic.
		% Where Context = [Step, Identified]
		% Note that Step is only the name of the step,
		%  not its State(Name) because the State (begins/ongoing/ends)
		%  is not really needed...
	% I should really differentiate by Step also, because different
	%  tactics will need to apply to each combat step!

%%%%%%%%%%%%%%combat_tactic/3 (2) 10/04/11

	combat_tactic(matchup, [ [], combat, _Deck | _Context], _Action).

%%%%%%%%%%%%%%combat_tactic/3 (3) 10/04/11

	combat_tactic(matchup, [Matchup, combat, Deck_name | Context], Action):-
		combat_tactic(Matchup, Deck_name, Tactic),
		%Tactic(Context, Action)
		TActic =.. [Tactic, Context, Action],
		TActic.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%matchup_strategy 15/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Simply succeeds for now
	%matchup_strategy(_Context, _Action).

	matchup_strategy(Context, Action):-
		Observation = (_X-_Object present),
		Conclusion = (_Deck identified with _Factor certainty),
		% ^ Patterns to look for or clear from the db
		match_up(Observation, Conclusion, Matchup),
 		taunt(matchup_strategy, Matchup),
		append([Matchup], Context, Full_context),
		land_tactic(matchup, Full_context, Action),
		spell_tactic(matchup, Full_context, Action),
		/*activated_tactic,
		specials_tactic,*/
		combat_tactic(matchup, Full_context, Action).


%%%%%%%%%%%%%%match_up/3 10/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* match_up(+Observation, +Conclusion, -Deck) */
	% Initialised the database and calls the forward chaining
	%  inference engine that tries to figure out the matchup,
	%  ie the opponent's deck. Observation and Conclusion
	%  are patterns of facts to be found in or cleared from the db.

	% What deck is the opponent playing?
	match_up(Observation, Conclusion, DEck):-
		player(Player),
		Player \= 'Glee-min',
		database_primer(Player, Observation, Conclusion),
		forward_chaining(Observation),
		findall(X-Deck,
				( Deck identified with X:Z certainty,
				\+ Deck eliminated with _Y:Z certainty),
				Certainties),
		keysort(Certainties, Reverse), % get the highest factor
		reverse(Reverse, [_X- DEck | _Rest]).
	% ^ It should be possible to backtrack in here if there is
	%  no move agreement between deck and matchup strategy, and
	%  pick the next deck in the list of possibly identified matchups
	%  but only if there are no X:X certainties.

	% Deck not yet identifiable (no plays yet from opponent?)
	match_up(_Observation, _Conclusion, []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%action/5 17/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%action/5 (1.1) 17/03/11

	action(Active, Step, Phase, [play_land, Land_card], Play):-
		play_land(Active, ['Glee-min', Land_card], Step, Phase, Play).

%%%%%%%%%%%%%%action/5 (2.0) 17/03/11

	action('Glee-min',Step,Phase,[cast_spell, Context],Play ):-
		cast_spell('Glee-min', Context, Step, Phase, Play).

	action(_Active, _Step, _Phase, ['Glee-min' | [] ], _):- fail, !.
		% ^ not casting, fall to the do-nothing clause below

%%%%%%%%%%%%%%action/5 (0) 17/03/11

	action(_, _, _, _, 112):-
		tab(25),write(`Glee-min says: Go`), nl,
		tab(35), write(`* * *`), nl.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%resource_management/ 5 19/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* resource_management(+Resource, +Context) */
	% How to spend a resource, such as Life, Cards, Mana etc.
	% Currently only tapping permanents for mana is handled.

	resource_management(tap_for_mana, Context):-
		tap_any_sources(Context).


%%%%%%%%%%%%%%tap_any_sources/1 19/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* tap_any_sources(+Context) */
	% Simple tactic to tap any available source
	%  for its full mana.

	tap_any_sources(Context):-
		Context = ['Glee-min', Spell, _, _, Switches, Identified, Sources, Cost],
		mana_sources('Glee-min', Switches, Identified),
		card([card_name Spell, mana_cost Cost, _, _, _, _, _, _]),
		tap_each_source(Cost, Identified, [], [], Sources).


%%%%%%%%%%%%%%tap_each_source/5 19/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* tap_each_source(+Cost, +Identified, -Mana, [], -Sources ) */
	% Simple mana tactic, to tap all available sources until the mana
	%  required is acquired.
	% Cost: mana string; Mana: mana list; Sources: [Switch_1, ...]
	% eg Identified: ['Island' - 'I',3],['Island' - l,2],['Island' - a,1]

%%%%%%%%%%%%%%tap_each_source/5 (0) 19/03/11

	tap_each_source(_Cost, [], [], Sources, Sources).

%%%%%%%%%%%%%%tap_each_source/5 (1) 19/03/11

	% The total mana from tapping the sources chosen so far will not
	%  be enough to satisfy the cost. Go on.
	tap_each_source(Cost, [[Source - Switch, _Id] | Identified], Total, Temp, Sources):-
%		mana_ability(Source, _Ability, Mana), % To Swi 09/10/11
		mana_ability(Source, _Ability, Mana) -> 
		append(Total, [Mana], New_total),
		% ^ add the mana from the current source to the total
		atom_to_list(String, New_total),
		\+ match_cost(Cost, String),
		append(Temp, [Switch], New_temp),
		tap_each_source(Cost, Identified, New_total, New_temp, Sources).

%%%%%%%%%%%%%%tap_each_source/5 (2) 19/03/11

	% The total mana from tapping the sources chosen so far will be enough
	%  to satisfy the cost. Wrap things up.
	tap_each_source(Cost, [[Source - Switch, _Id] | _Identified], Total, Temp, Sources):-
		mana_ability(Source, _Ability, Mana),
		append(Total, [Mana], New_total),
		atom_to_list(String, New_total),
		match_cost(Cost, String),
		% ^ The mana total so far satisfies the cost
		append(Temp, [Switch], New_temp),
		tap_each_source(Cost, [], [], New_temp, Sources).

%%%%%%%%%%%%%%tap_each_source/5 (2) 19/03/11

	tap_each_source(Cost, _Identified, _Mana, _Temp, _Sources):-
		tab(25), write(`No mana sources to tap for ` - Cost), nl.
	% ^ This is OK (now that I fixed Goblin Balloon Brigade >_<
	%  It takes care of tap_for_mana. Now I need to fix spend_mana also.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%       Statistic Evaluation        %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%minimax/X 22/04/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/*	init_alphabeta:-
		reset_game,
		populate_libraries,
		shuffle_libraries,
		draw_starting_hand.
*/

%	minimax([combat, Deck, Step, Context], Action):-
	minimax([combat, _Deck, one_blocker, Identified], Switch):-
		\+ _X blocks _Y,
		attackers(Attackers),
		findall(Blocker-ID,
				member([Blocker - _Switch, ID], Identified),
			Blockers),
		combat_heuristic(Attackers, Blockers, [], Blocks),
		findall(X blocks Y,
				( member(X blocks Y, Blocks),
				asserta(X blocks Y) ),
				_Nevermind),
		Name-Id blocks _Attacker,
		member([Name - Switch, Id], Identified).

	minimax([combat, _Deck, one_blocker, Identified], Switch):-
		Name-Id blocks _Attacker,
		member([Name - Switch, Id], Identified).

	% We should only fall here when there are no more blockers
	%  to declare.
	minimax([combat, _Deck, one_blocker, _Identified], _Switch).


	minimax([combat, _Deck, one_attacker, [Object, Identified]], Switch):-
		%Object = object(NAme-ID, _State),
		object_handle(Object, Blocker),
		Blocker blocks (Name-Id),
		member([Name - Switch, Id], Identified),
		retract(Blocker blocks (Name-Id)).

	% We fall here if something went wrong and there is no
	%  suitable X blocks Y fact in the db
	minimax([combat, _Deck, one_attacker, Identified], _):-
		write(`Problem in one_attacker!`),nl, fail,!.


	%minimax([combat,'Tutorial Red',declare_attackers,[['Vulshok Berserker+' - 'V',1],['Goblin Balloon Brigade' - 'G',1]]],_489)

	% Currently, attack with everything. For the Emperor!
	minimax([combat, _Deck, declare_attackers, Identified], List_of_attackers):-
%	conserve_utility([declare_attackers, Identified], List_of_attackers):-
		findall(Switch,
				(member([Attacker - Switch, _Id], Identified)),
			List_of_attackers).


/*
	conserve_utility([one_blocker, Identified], Switch):-
		deck('Glee-min', Deck),
		utility_creatures(Deck, Utility),
		member([Blocker - Switch, _Id], Identified),
		\+ member(Blocker, Utility).
		% Identified: list of [Name - Switch, Id]
*/

%	minimax([_Deck, _Active, _State(_Step), Phase], 112):-
	minimax([_Deck, _Active, _Step, Phase], 112):-
		Phase \= 'First Main'.

	% ['Glee-min', State([]), 'First Main']
	% minimax(['Testdeck Blue','Glee-min',begins([]),'First Main'],_12133)
%	minimax([_Deck, Active, _State(_Step), Phase], Action):- %Swi, 18/06/11
	minimax([_Deck, Active, _Step, Phase], Action):-
		player(Next), Next \= 'Glee-min',
		minimax(Phase, Active, 'Glee-min', Next, Action, 2, 8, 7).

	minimax(Phase, Active, Playing, Next, BestMove, Depth, Alpha, Beta):-
		moves(Phase, Active, Playing, Next, Moves),
		save_player(Playing, Saved1),
		save_player(Next, Saved2),
		save_game(Game),
		asserta(minimaxing),
		evaluate_and_choose(Moves,[Phase,Active, Playing, Next],Depth,Alpha,Beta,112,(BestMove, _Value)),
		restore_player(Playing, Saved1),
		restore_player(Next, Saved2),
		restore_game(Game),
		retractall(minimaxing).
	% plays land, casts spells? May break spells now.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%evaluate_and_choose/7 18/04/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* evaluate_and_choose(+Moves, +Position, +Depth, +Alpha, +Beta, Record, -BestMove) */
	% Alphabeta minimax implementation from Sterling & Shapiro (1986), pg 301
/*
	Chooses the BestMove from the set of Moves from the current Position
	using the minimax algorithm with alpha-beta cutoff searching
	Depth ply ahead. Alpha and Beta are the parameters of the algorithm.
	Record records the current best move
*/

%%%%%%%%%%%%%%evaluate_and_choose/7 (1) 18/04/11

	% Choose a move; find the new position; evaluate it; stop evaluation
	%  if upper or lower evaluation bounds are reached.

	evaluate_and_choose( [Move_set | Moves ],Position,D,Alpha,Beta,Move1,BestMove):-
		move(Position,Move_set,Move,Position1),
		% ^ only need Move, not Move_set. Move_set is just one Move anyway.
		alpha_beta(D,Position1,Alpha,Beta,_MoveX,Value),
		Value1 is -Value,
		% ^ Ah, no. You need to take their strategic advantage, ie, tempo
		% if you're playing control, ca if you're playing beatdown.
		cutoff(Move,Value1,D,Alpha,Beta,Moves,Position,Move1,BestMove).

%%%%%%%%%%%%%%evaluate_and_choose/7 (1) 18/04/11

	% No more moves- "return" best move found so far.
	evaluate_and_choose([],_Position,_D,_Alpha,_Beta,Move,(Move,_Alpha)).


%%%%%%%%%%%%%%alpha_beta/6 18/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* alpha_beta(+D,+Position,+Alpha,+Beta,+Move,+Value) */

%%%%%%%%%%%%%%alpha_beta/6 (0) 18/04/11

	% Zero depth reached- evaluate position.
	alpha_beta(0,[_Phase,_Active, Playing, Next],_Alpha,_Beta,_Move,Value):-
		deck(Playing, Deck),
		deck_type(Deck, _Colour, Type),
		value(Playing, Next, Type, Value, _Their_value).


%%%%%%%%%%%%%%alpha_beta/6 (1) 18/04/11

	alpha_beta(D,Position,Alpha,Beta,Move,Value):-
		Position = [Phase, Active, Playing, Next],
		moves(Phase, Active, Playing, Next, Moves),
		Alpha1 is -Beta,
		Beta1 is -Alpha,
		D1 is D-1,
		evaluate_and_choose(Moves,Position,D1,Alpha1,Beta1,nil,(Move,Value)).


%%%%%%%%%%%%%%cutoff/6 18/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* cutoff(+Move,+Value,+D,+Alpha,+Beta,+Moves,+Position,+Move1,-BestMove) */

%%%%%%%%%%%%%%cutoff/6 (0) 18/04/11

	% Beta bound reached; stop evaluation
	cutoff(Move,Value,_D,_Alpha,Beta,_Moves,_Position,_Move1,(Move,Value)):-
		Value >= Beta.

%%%%%%%%%%%%%%cutoff/6 (1) 18/04/11

	% Move value within bounds; continue evaluating.
	cutoff(Move,Value,D,Alpha,Beta,Moves,Position,_Move1,BestMove):-
		Alpha < Value, Value < Beta,
		evaluate_and_choose(Moves,Position,D,Value,Beta,Move,BestMove).

%%%%%%%%%%%%%%cutoff/6 (2) 18/04/11

	% Alpha bound reached; evaluate new move
	cutoff(_Move,Value,D,Alpha,Beta,Moves,Position,Move1,BestMove):-
		Value =< Alpha,
		evaluate_and_choose(Moves,Position,D,Alpha,Beta,Move1,BestMove).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%move/4 18/04/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


	% move(Position, Move, Next_Position).
	% The active player plays land and passes priority
	move(['First Main', Playing, Playing, Next], Land, [play_land, Land], ['First Main', Playing, Next, Playing]):-
		check_type(Land, _Supertype, ['Land'], _Subtype),
		played_land('Glee-min', 'no'),
		action('Glee-min', _Step, 'First Main', [play_land, Land], _Play).
		%write(`Playing land`),nl,nl.

	move(['First Main', Playing, Playing, Next], Land, 112, ['First Main', Playing, Next, Playing]):-
		check_type(Land, _Supertype, ['Land'], _Subtype).

	% The active player casts a spell and passes priority
%		Context =   [_cast_spell, [_Gleemin, Spell, _Choices, _Targets, Switches, Identified, Sources, Payment] ] ,
	move(['First Main', Playing, Playing, Next], Context, Context, ['First Main', Playing, Next, Playing]):-
		action('Glee-min',_Step,_Phase, Context, _Play),
		zone('Stack', [Object | _rest]),
		generate_effect(Object, 'Glee-min').
		%write(`Casting spell`),nl,nl.

/*	eg spell context:
	[
		[cast_spell, ['Glee-min','Goblin Piker',_9980,_9986,
			[[cancel - c,skip - s,'Mountain' - 'M','Mountain' - o],
			['[c]ancel','[s]kip','[M]ountain','M[o]untain']],
			[['Mountain' - 'M',2],['Mountain' - o,1]],
		['M',o],'1r']]
	]
*/


	% The Nonactive player passes priority
	move([Phase, Active, Playing, Next], pass, 112, [Phase, Active, Next, Playing]).
%	write(`Passing` - Playing),nl,nl.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%moves/4 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* moves(+Position, +Acive_player, +Opponent, -Moves) */
	% Generates lists of legal moves (land to play, spells to cast,
	%  attackers and blockers order) at the current position
	% A Position is the current State(Step) (tuple) or Phase (atom)


	% Position: name of a phase, or a step-state,
	%  eg, 'First Main', begins('Upkeep'), 'Combat'
	moves(Position, Active, Playing, Opponent, Moves):-
		% ^ For combat, Position is implied by Active-Opponent relation
		land_set(Position, Active, Playing, Opponent, Land_set),
		castable_set(Position, Active, Playing, Opponent, Castable_set),
		% ^ Glee-min may be the non-active player but still need to cast
		attackers_set(Position, Active, Attackers),
		attackers_sets(Attackers, Attackers_sets),
		blockers_set(Position, Opponent, Blockers),
		blockers_sets(Blockers, Blockers_sets),
		blocking_sets(Attackers_sets, Blockers_sets, Blocking_sets),
		append(Land_set, Castable_set, Set1),
		append(Set1, Blocking_sets, Moves), !.
	% Adding Active player arg:
	/* 	land_set OK
		castable_set OK
		combat stuff broken- elsewhere?
		*/



%%%%%%%%%%%%%%land_set/4 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* land_set(+Position, +Active_player, +Opponent, -Lands_to_play) */
	% Generates a list of land that can be played
	%  by Active_player in this Position

	% Already played a land this turn.
	land_set('First Main', 'Glee-min', 'Glee-min', _Opponent, []):-
		played_land('Glee-min', yes).

%%%%%%%%%%%%%%land_set/4 (1) 14/04/11

	% Find all playable land:
	land_set('First Main', 'Glee-min', 'Glee-min', _Opponent, Land_set):-
		findall(Land,
				( zone('Glee-min', 'Hand', Cards),
				member(Land, Cards),
				check_type(Land, _,['Land'],_)  ),
				Land_set).

%%%%%%%%%%%%%%land_set/4 (0) 14/04/11

	% Not a main phase, or Gleemin is not the Active player.
	% However note that future inference may involve this
	land_set(_Position,_Active, _Playing, _Opponent, [pass]).


%%%%%%%%%%%%%%castable_set/4 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* castable_set(+Position, +Active_player, +Opponent, -Spells) */
	% Generates a list of spells that can be cast by Active_player or
	%  his or her Opponent at the current Position.

%%%%%%%%%%%%%%castable_set/4 (1) 14/04/11

	% This just finds the first castable creature for now.
	castable_set('First Main', 'Glee-min', 'Glee-min', _Opponent, Castable_set):-
	% ^ Player name needed for future inference of Hand contents
	findall( [cast_spell, Context],
%			( cast_any_creature(['Glee-min', _State([]), 'First Main'], [cast_spell, Context]),! ), Swi, ??/06/11
			( cast_any_creature(['Glee-min', _Step, 'First Main'], [cast_spell, Context]) ),			
			%Step =.. [_State, []],! ), % Swi, 04/07/11, no need to determine step for Main phases!
		Castable_set).
	% Context returns everything needed to call cast_spells directly:
	% Context = ['Glee-min', Spell, _Choices, _Targets, Switches, Identified, Sources, Payment].

%%%%%%%%%%%%%%castable_set/4 (0) 14/04/11

	% Not a main phase, or Gleemin is not the Active player.
	castable_set(_Position, _Active, _Playing, _Opponent, []).


%%%%%%%%%%%%%%attackers_set/3 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* attackers_set(+Position, +Active_player, -Attackers) */
	% Generates a list of Attackers controlled by Active_player

%%%%%%%%%%%%%%attackers_set/3 (1) 14/04/11

	% All legal attackers on Player's side of the Battlefield:
	attackers_set('Combat', Player, Permanents):-
		zone(Player, 'Battlefield', Objects),
		findall(Permanent - Id,
				(member(object(Permanent -Id,State), Objects),
				creature_type(Permanent),
				legal_attacker(State)),
			Permanents).

%%%%%%%%%%%%%%attackers_set/3 (0) 14/04/11

	attackers_set(_Position, _Player, []).
	% ^ No attacks outside of declare_attackers.


%%%%%%%%%%%%%%attackers_sets/2 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* attackers_sets(+Attackers, -Sets_of_attackers) */
	% Generates attack combinations

%%%%%%%%%%%%%%attackers_sets/2 (0) 14/04/11

	% No attackers declared.
	attackers_sets([], []).

%%%%%%%%%%%%%%attackers_sets/2 (1) 14/04/11

	% Generate all permutations of the attackers list
	attackers_sets(Attackers, Sets):-
		findall(Set, sublist(Set, Attackers), Sets).
%		register_attackers_sets(Sets).
		% ^ Why? I think it was to carry out minimax combat.
		% I don't think it's a good idea- I should run the combat
		%  heuristic instead.


%%%%%%%%%%%%%%register_attackers_sets/2 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* register_attackers_sets(+Attackers_sets) */
	% Adds each set of attackers to the database

	register_attackers_sets([]).
	register_attackers_sets([[] | Rest ]):-
		register_attackers_sets(Rest).
	register_attackers_sets([Attackers | Rest]):-
		asserta(attackers(Attackers)),
		% ^ There shouldn't be any duplicates at this point.
		register_attackers_sets(Rest).


%%%%%%%%%%%%%%blockers_set/3 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* blockers_set(+Position, +Defending_player, -Blockers) */
	% Generates a list of Blockers controlled by Defending_player

%%%%%%%%%%%%%%blockers_set/3 (1) 14/04/11

	% All legal blockers on Player's side of the battlefield:
	blockers_set('Combat', Player, Permanents):-
		zone(Player, 'Battlefield', Objects),
		findall(Permanent - Id,
				(member(object(Permanent - Id,State), Objects),
				creature_type(Permanent),
				legal_blocker(State)),
			Permanents).

%%%%%%%%%%%%%%blockers_set/3 (0) 14/04/11

	% Not a combat phase or step
	blockers_set(_Position, _Player, []).


%%%%%%%%%%%%%%blockers_sets/2 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* blockers_sets(+Blockers, -Sets_of_blockers) */
	% Generates blocking combinations

%%%%%%%%%%%%%%blockers_sets/2 (0) 14/04/11

	% No blockers declared.
	blockers_sets([], []).

%%%%%%%%%%%%%%blockers_sets/2 (1) 14/04/11

	% Generate all permutations of the blockers list:
	blockers_sets(Blockers, Sets):-
		findall(Set, sublist(Set, Blockers), Sets).
%		register_blockers_sets(Sets).


%%%%%%%%%%%%%%register_blockers_sets/2 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* register_blockers_sets(+Blockers_sets) */
	% Adds each set of blockers to the database

	register_blockers_sets([]).
	register_blockers_sets([[] | Rest ]):-
		register_blockers_sets(Rest).
	register_blockers_sets([Blockers | Rest]):-
		asserta(blockers(Blockers)),
		% ^ There shouldn't be any duplicates at this point.
		register_blockers_sets(Rest).


%%%%%%%%%%%%%%blocking_sets/3 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* blocking_sets(+Attackers_sets, +Blockers_sets, -Ordered_blockers) */
	% Generates combinations of attackers and their blockers,
	%  (currently only naivley) ordered for damage assignment

%%%%%%%%%%%%%%blocking_sets/3 (0) 14/04/11

	% No attackers were declared.
	blocking_sets([], _Blockers_sets, []).
	% ^ Well, if the first arg is [],
	%  then the second will be too so the next clause
	%  will never be checked

%%%%%%%%%%%%%%blocking_sets/3 (0) 14/04/11

	% ^ No blockers were declared
	blocking_sets(_Attackers_sets, [], []).

%%%%%%%%%%%%%%blocking_sets/3 (1) 14/04/11

	% Find all possible ordered blocks sets
	blocking_sets(Attackers_sets, Blockers_sets, Blocks):-
		findall(Set,
				(member( Attacker_set, Attackers_sets ),
				member(Blocker_set, Blockers_sets),
				permutation(Blockers, Blocker_set),
				member(Attacker, Attacker_set),
				append([Attacker], [Blockers], Set)),
				% ^ Takes the default order of blockers
				Sets),
		sort(Sets, Blocks).


%%%%%%%%%%%%%%attacking_sets/3 14/04/11
%%%%%%%%%%%%%%%%%%%%%%%

	attacking_sets([], Attacks, Attacks).
	attacking_sets([Blocking_set | Blocks], Temp, Attacks):-
		%member(Blocking_set, Blocks),
		Blocking_set = [Attacker, Blockers],
		findall( [ Blocker, [Attacker] ],
				( member( Blocker, Blockers ),
				Blocker \= [] ),
		 Orderings),
		append(Temp, Orderings, New_temp),
		attacking_sets(Blocks, New_temp, Attacks).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%value/5 13/04/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* value(+Us,+Them,+Deck_type,+Value_to_maximise,Value_to_minimise) */
	% Evaluates a board position according to a deck type, ie, whether its
	%  strategic objective is card advantage (control) or tempo (beatdown)
	% Combo decks are not currently supported.

%%%%%%%%%%%%%%value/5 (1) 13/04/11

	% Our side plays control, we maximise our card advantage
	% and minimise their tempo
	value(Us, Them, 'Control', Our_card_advantage, Their_tempo):-
		card_advantage(Us, Our_card_advantage, Them, _Their_advantage),
		tempo(Us, _Tempo, Them, Their_tempo).

%%%%%%%%%%%%%%value/5 (1) 13/04/11

	% Our side plays beatdown, we maximise our tempo
	%  and minimise their card advantage.
	value(Us, Them, 'Beatdown', Our_tempo, Their_card_advantage):-
		card_advantage(Us, _Our_card_Advantage, Them, Their_card_advantage),
		tempo(Us, Our_tempo, Them, _Their_tempo).


%%%%%%%%%%%%%%card_advantage/4 13/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* card_advantage(+Player, -Advantage, +Opponent, -Advantage_0) */
	% Evaluates each position's card advantage, ie counts cards in
	%  hand and the Battlefield.

	card_advantage(Player, Advantage, Opponent, Advantage_0):-
		findall(Object,
				( zone(Player, Zone, Objects),
				( Zone = 'Battlefield';
				Zone = 'Hand'), % no other zones for now
				member(Object, Objects) ),
			Our_objects),
		length(Our_objects, Advantage),
		findall(Object,
				( zone(Opponent, Zone, Objects),
				( Zone = 'Battlefield';
				Zone = 'Hand'),
				member(Object, Objects) ),
			Their_objects),
		length(Their_objects, Advantage_0).


%%%%%%%%%%%%%%tempo/4 13/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* tempo(+Us, -Beats, +Them, -Their_beats) */
	% Evaluates a side's tempo position, ie
	%  how close it is to ending the game.
	% Beats: how many turns before the side loses,
	%  ie "beats to go". Think heartbeats.

	tempo(_Us, Beats, Them, Their_beats):-
		life_total(Them, 0),
		deck_size(Them, Maximum1),
		Beats = Maximum1,
		Their_beats = 0.

	tempo(Us, Beats, _Them, Their_beats):-
		life_total(Us, 0),
		deck_size(Us, Maximum1),
		Their_beats = Maximum1,
		Beats = 0.

	tempo(Us, Beats, Them, Their_beats):-
		damage_per_turn(Us, Damage_per_turn, Them, Their_damage_per_turn),
		deck_size(Us, Maximum1),
		deck_size(Them, Maximum2),
		life_total(Us, Life),
		life_total(Them, Their_life),
		Beats1 is Damage_per_turn*Maximum2/Their_life,
%		round(Beats1, Beats),	% Swi, 04/06/11
		Beats is round(Beats1), 
		Their_beats1 is Their_damage_per_turn*Maximum1/Life,
		Their_beats is round(Their_beats1). 
%		round(Their_beats1, Their_beats).

	deck_size(Player, Size):-
		( zone(Player, 'Library', Cards),
		  length(Cards, Length),
		( order_of_play([Player | _Next]) ->
			Size is Length + 7 ;
			Size is Length + 8)).


%%%%%%%%%%%%%%damage_per_turn/4 13/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* damage_per_turn(+Us, -Damage, +Them, -Their_damage) */
	% Calculates the damage each side can do in a turn, currently
	%  only with creatures.

	damage_per_turn(Us, Damage, Them, Their_damage):-
		findall(Power,
				creature(_, _, _, _, _, Power, _, Us),
				Our_power),
		findall(Power,
				creature(_, _, _, _, _, Power, _, Them),
				Their_power),
		sum(Our_power, 0, Damage),
		sum(Their_power, 0, Their_damage).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%        Combat Heuristics          %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
	An algorithm to choose the best blockers assignment,
	  optimising for card advantage. It will find the best
	  combination of blockers so that each can block favourably
	  with an attacker ("favourably" as in "no worse than a 1-for-1
	  trade"). It will find cases where more than one blocker can
	  be assigned to block a single attacker- _as long as all blocks
	  remain favourable_. That means it will not block one attacker
	  with more than one blocker if that attacker would destroy more
	  than one blocker that way. In other words, it won't team-block
	  if that would result in a 2-for-1 or worse trade against it.
	Blocking is not optimised for tempo. Given the choice between
	  blocking an attacker with an n-powered blocker and an n+1-powered
	  blocker, it will choose the first it finds, therefore finding
	  sub-optimal blocker assignments for tempo-oriented decks.
	Then again, if you're playing beatdown and you're blocking, you're
	  losing already. Tough.
	Truth is there is no good reason to block with a stronger attacker
	  when there is a weaker one that can take one for the team. This
	  Needs Fixing™.

*/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%combat_heuristic/4 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* combat_heuristic(+Active_player, +Defending_player, dud, -Blocking_assignment) */
	% Finds the optimal set of blockers for a given set of attackers.
	% "Optimal" as in: the highest attack power is stopped and the most
	%  blockers remain alive at the end of combat.

	combat_heuristic(Attackers, Blockers, [], Flat):-
		append(Attackers, Blockers, All),
		store_PTs(All),
%		catch( _Code, combat_heuristic(Attackers, Blockers, Assignment) ),
%		Swi, 19/06/11
		combat_heuristic(Attackers, Blockers, Assignment),
		% Combat with about 6 creatures on each side can crash the engine
		% Fix etc.
		flatten_list(Assignment, Flat),
		% ^ Fun with brackets...
		clear_stored.


%%%%%%%%%%%%%%store_PTs/1 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* store_PTs(+Creatures) */
	% Write the P/Ts of creatures to the db
	% (to reduce overheads of finding them on the fly)

	store_PTs([]):-
		asserta(none:0/0).
		% ^ P/T of opponent of unblocked attacker.
	store_PTs([Creature | Rest]):-
		creature(Creature, _, _, _, _, P, T, _),
		asserta(Creature:P/T),
		store_PTs(Rest).


%%%%%%%%%%%%%%clear_stored/0 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	% Remove stored P/Ts from the db.

	clear_stored:- retractall(_Creature:_P/_T).


%%%%%%%%%%%%%%combat_heuristic/3 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* combat_heuristic(+Attackers, +Blockers, -Assignment) */
	% Buisness goal for combat_heuristic/3: this orders blockers
	%  and attackers by relative power; finds all likely blocking
	%  assignments; sorts them to remove duplicates and
	%  evaluates them to choose the best.

	% Should return a list of: [Attacker, [Blockers]],
	%  ie, a blocking set (blockers_order(Set).
	combat_heuristic(Attackers, Blockers, Assignment):-
		strongest_first(Attackers, Ordered_attackers),
		weakest_first(Blockers, Ordered_blockers),
		findall(Assignment,
				( assign_blockers(Ordered_attackers, Ordered_blockers, Assignment),
				Assignment \= []),
			Assignments),
		sort(Assignments, Sorted),
		heuristic_evaluation(Sorted, [], Assignment).


%%%%%%%%%%%%%%strongest_first/2 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* strongest_first(+Combatants, -Ordered) */
	% Order combatants by highest power/toughness first.

	% Only one creature- no ordering needed.
	strongest_first([Combatant], [Combatant]).
	strongest_first(Combatants, Ordered_combatants):-
		findall(Total-Creature,
				( member(Creature, Combatants),
				% Creature:P/T, % Swi, 04/07/11
				 clause(Creature:P/T, true), 
				Total is P + T),
			Creatures),
		keysort(Creatures, Sorted),
		reverse(Sorted, Detros),
		findall(Creature, member(_X- Creature, Detros), Ordered_combatants ).


%%%%%%%%%%%%%%weakest_first/2 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* weakest_first(+Combatants, -Ordered) */
	% Order combatants by lowest power/toughness first

	weakest_first([Combatant], [Combatant]).
	weakest_first(Combatants, Ordered_combatants):-
		findall(Total-Creature,
				( member(Creature, Combatants),
				% Creature:P/T, % Swi, 04/07/11
				clause(Creature:P/T, true), 
				Total is P + T),
			Creatures),
		keysort(Creatures, Sorted),
		findall(Creature, member(_X- Creature, Sorted), Ordered_combatants ).



%%%%%%%%%%%%%%assign_blockers/3 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* assign_blockers(Attackers, Blockers, [], -Assigned) */
	% Find a set of blockers and attackers so that each blocker
	%  is trading optimally with an attacker (ie, if it is
	%  destroyed at end of combat, the attacker is also)

	assign_blockers(Attackers, Blockers, Assigned):-
		assign_blockers(Attackers, Blockers, [], Single_assignments),
		findall(Attacker, (member(Attacker, Attackers),
					\+ member(_Y blocks Attacker, Single_assignments)),
			Unblocked),
		findall(Blocker, member(Blocker blocks none, Single_assignments), Not_blocking),
		team_blocking(Unblocked, Not_blocking, [], Team_assignments),
		removeall(_X blocks none, Single_assignments, No_unassigned_blockers),
		append(No_unassigned_blockers, Team_assignments, Assigned).
%		write(`Assigned:` - Assigned), nl.
/*		( \+ exists(Assigned) -> asserta( exists(Assigned) ),
		write(`Assigned:` - Assigned), nl;
		write(`Exists: ` - Assigned), nl).
*/

%%%%%%%%%%%%%%assign_blockers/4 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* assign_blockers(Attackers, Blockers, [], -Assigned) */
	% Assigns a blocker to each attacker, if there is a blocker
	%  that can trade favourably with that attacker.

	assign_blockers(_Attackers, [], Assigned, Assigned).

	% Find an attacker that the blocker can trade with favourably
	assign_blockers(Attackers, [Blocker | Rest], Temp, Assigned):-
		member(Attacker, Attackers),
		\+ unfavourable_trade(Attacker, Blocker),
		\+ member(_blocker blocks Attacker, Temp), % Attacker not yet blocked
		append(Temp, [Blocker blocks Attacker ], New_temp),
		%write(`Blocker - Attacker:` - Blocker - Attacker),nl,
		assign_blockers(Attackers, Rest, New_temp, Assigned).

	% Can't find an attacker for Blocker to trade with favourably
	assign_blockers(Attackers, [Blocker | Rest], Temp, Assigned):-
		append(Temp, [Blocker blocks none], New_temp),
		assign_blockers(Attackers, Rest, New_temp, Assigned).


%%%%%%%%%%%%%%team_blocking/4 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* team_blocking(+Attackers, +Blockers [], +Team_assignment) */
	% Assigns a team of blockers to an attacker, if there is a team
	%  that can block that attacker favourably

	team_blocking([], [_Blockers], _Assigned, []):- !.
	team_blocking([], _Blockers, Assigned, Assigned).
	team_blocking([Attacker | Rest], Blockers, Temp, Assigned):-
		team_blocking(Attacker, Blockers, 0/0, [], Team), !,
		( Team \= [] -> append(Temp, [Team], New_temp); Temp = New_temp ),
		% ^ Team must be in brackets because each list is one team. Otherwise
		%  appending them, combines the teams into one.
		%write(`Team: ` - Team), nl,
		team_blocking(Rest, Blockers, New_temp, Assigned).


%%%%%%%%%%%%%%team_blocking/5 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* team_blocking(+Attacker, +Defenders, +Strength, [], -Team) */
	% Assembles a team of blockers strong enough to block
	%  an Assailant favourably, ie, without more than one dying
	%  while the Assailant survives. Strength is their combined P/T

	% Call with:
	%team_blocking(Assailant, Defenders, 0/0, [], Team).
	%team_blocking(Assailant, Defenders, Strength, [], Team).


	% The team is not strong enough to bring the assailant down
	%  without suffering unfaffordable losses. Team members don't
	%  block the assailant in any configuration.
	team_blocking(Assailant, [], Team_P/Team_T, _Team, []):-
		% Assailant:Assailant_P/Assailant_T, % Swi, 04/07/11
		clause(Assailant:Assailant_P/Assailant_T, true), 
		(Team_T =< Assailant_P;
		Team_P < Assailant_T).

	% The team is strong enough to bring the assailant down without
	%  losing too many members.
	team_blocking(_Assailant, [], _Strength, Team, Team).

	team_blocking(Assailant, [Defender | _Rest], Team_P/Team_T, Temp, Team):-
		% Defender:Defender_P/Defender_T, % Swi, 04/07/11
		clause(Defender:Defender_P/Defender_T, true), 
		Total_P is Defender_P + Team_P,
		Total_T is Defender_T + Team_T,
		% ^ Team strength with new member
		% Assailant:Assailant_P/Assailant_T, % Swi, 04/07/11
		clause(Assailant:Assailant_P/Assailant_T, true),
		Total_T > Assailant_P,
		Total_P >= Assailant_T,
		% ^ Comparison of team's strengh to Assailant
		append(Temp, [Defender blocks Assailant], New_temp),
		%write(`Team 2: ` - Temp), nl,
		team_blocking(Assailant, [], Total_P/Total_T, New_temp, Team).
		% ^ The team is now strong enough- add the new member to it
		%  and stop adding new members to it.

	team_blocking(Assailant, [Defender | Rest], Team_P/Team_T, Temp, Team):-
		% Defender:Defender_P/Defender_T,	% Swi, 04/07/11
		clause(Defender:Defender_P/Defender_T, true),
		Total_P is Defender_P + Team_P,
		Total_T is Defender_T + Team_T,
		append(Temp, [Defender blocks Assailant], New_temp),
		team_blocking(Assailant, Rest, Total_P/Total_T, New_temp, Team).
		% ^ The team is not yet srong enough-  add more members to it.


%%%%%%%%%%%%%%unfavourable_trade/2 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* unfavourable_trade(+Assailant, +Defender) */
	% A Defender trades unfavourably with an Assailant if, in combat
	%  between the two, the Defender is destroyed and the Assailant isn't.

	% Assailant is the opponent's attacker or blocker, defender is our
	%  own creature - the one we want to survive the encounter.
	unfavourable_trade(Assailant, Defender):-
		% Assailant:Assailant_P/Assailant_T,	% Swi, 04/07/11
		% Defender:Defender_P/Defender_T,
		clause(Assailant:Assailant_P/Assailant_T, true), 
		clause(Defender:Defender_P/Defender_T, true), 
		Defender_P < Assailant_T, % The blocker can't destroy the attacker in combat
		Assailant_P >= Defender_T. % The attacker can destroy the blocker in combat

%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
	This doesn't take into account abilities such as
	  First Strike, Trample, etc. It should be updated later.
	Also, it makes the assumption that a blocker will always
	  want to trade with an attacker- this may not be the case
	  if the blocker is a utility creature, for example. That
	  sort of knowledge cannot really be evaluated statisically.
	  This heuristic should therefore be combined with a knowledge-
	  based analysis of a combat situation.
*/


%%%%%%%%%%%%%%heuristic_evaulation/3 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* heuristic_evaluation(+Moves, [], -Best_move:Value) */
	% Exhaustively evaluates a set of blocking assignments,
	%  and finds the one with the best value, ie, the one that
	%  leaves the most blockers alive and stops the highest
	%  total attackers' power.

	% This returns the full Move:Value; separate the value.

	% No more moves
	 heuristic_evaluation([], Best:_, Best).
	% Starting evaluation with no best move
	 heuristic_evaluation([Move | Rest], [], Best):-
		heuristic_evaluation(Move, Value),
		heuristic_evaluation(Rest, Move:Value, Best).
	% The new move is bestest than the current best.
	% Replace the current with the new and go on
	 heuristic_evaluation([Move | Rest], Current, Best):-
		%member(Current, Blocker blocks Attacker : Best_value),
		Current = _Best_move : Best_X/Best_Y,
		heuristic_evaluation(Move, X/Y),
		%X >= Best_X, Y >= Best_Y,
		Dif_X is X - Best_X, Dif_Y is Y - Best_Y,
		Dif is Dif_X + Dif_Y, Dif > 0,
		heuristic_evaluation(Rest, Move:X/Y, Best).
	% The new move is not bestest than the current best
	% Drop the new move, keep the current and go on.
	 heuristic_evaluation([_Move | Rest], Current, Best):-
		heuristic_evaluation(Rest, Current, Best).


%%%%%%%%%%%%%%heuristic_evaulation/2 23/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* heuristic_evaluation(+Blocking_assignment, -Attack_power/Survivors) */
	% Calculates the total attack power stopped by a set of blockers and
	%  the number of blockers that survive the encounter.

	heuristic_evaluation(Blocking_set, Value):-
		findall(Power, (member(_Blocker blocks Attacker , Blocking_set),
				% Attacker:Power/_Toughness),	% Swi, 04/07/11
				clause(Attacker:Power/_Toughness, true) ), 
			Attackers_power), % Total attack power
		sum(Attackers_power, 0, Attack_power),
		findall(Blocker1 : Attacker1,
				( member(Blocker1 blocks Attacker1 , Blocking_set),
				% Attacker1:Power1/_T,	% Swi, 04/07/11
				clause(Attacker1:Power1/_T, true), 
				% Blocker1:_Power/Toughness1, 
				clause(Blocker1:_Power/Toughness1, true), 
				Toughness1 > Power1),
			Blockers), % All surviving blockers
		length(Blockers, Survivors),
		Value = Attack_power/Survivors.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%              Tactics              %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
	update, 10/04/11: these should be stated as
	  production rules, eventually.

	All tactics are of the form:
		Name(Context, Action):-
	Where
		Name: functor name of the action
		Context: name of the active player followed by timing information,
		and any other information necessary
		Action: list of [action_name, Arguments]
		Where:
			action_name is one of: play_land, cast_spell,
				activate_ability, take_special, pass or concede
				(ie all player actions allowed)
			Arguments are any arguments necessary to call the
				relevant player_action predicate with.

	Tactics make their own timing checks before deciging what action to
	  take. In other words, Glee-min will not attempt to play a land out
	  of turn or for a second time in a turn, etc.
	Note that the same tactic can be used as a deck tactic and a matchup
	  tactic.
*/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%play_any_land/2 17/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Returns the first land in the AI player's hand.
	% Returns 112 (pass) if there is no land in hand, or the timing
	%  is illegal. s

%%%%%%%%%%%%%%play_any_land/2 (1) 17/03/11

	% Get the name of the first land in the computer player's hand
%	play_any_land(['Glee-min', State([]), 'First Main'], [play_land, Land]):-
%	Swi, 19/06/11
	play_any_land(['Glee-min', Step_state, 'First Main'], [play_land, Land]):-
		Step_state =.. [State, []],
		\+ played_land('Glee-min', 'yes'),
		zone('Glee-min', 'Hand', Cards),
		member(Land, Cards),
		check_type(Land, _,['Land'],_).

%%%%%%%%%%%%%%always_play_land/2 (0) 17/03/11

	% No land in hand or wrong timing- leave Action unbound to allow
	%  subsequent deck_strategy clauses to bind it.
	play_any_land([_Active, _Step, _Phase], _).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cast_any_creature/2 17/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Simple tactic t cast the first creature in hand.

%%%%%%%%%%%%%%cast_any_creature/2 (1) 17/03/11


	cast_any_creature(['Glee-min', Step, 'First Main'], [cast_spell, Context]):- %Swi, 09/06/11
		(Step =.. [begins, []];
		Step =.. [ongoing, []];
		Step =.. [ends, []]) -> 
		Context = ['Glee-min', Spell, _Choices, _Targets, Switches, Identified, Sources, Payment],
		zone('Stack', []),
		available_mana(Mana),
		castable_spells(Mana, Castable),
		member(Spell, Castable),
		check_type(Spell, _, ['Creature'], _),
		%spell_choices(Choices),
		%spell_targets(Targets),
		resource_management(tap_for_mana, ['Glee-min', Spell, _, _, Switches, Identified, Sources, Payment]).


/*
 * Remove after completing migration to Swi...
%	cast_any_creature(['Glee-min', _State([]), 'First Main'], [cast_spell, Context]):-
%	cast_any_creature(['Glee-min', STate, 'First Main'], [cast_spell, Context]):- %Swi, 18/06/11
	cast_any_creature(['Glee-min', Step_state, 'First Main'], [cast_spell, Context]):- %Swi, 09/06/11
		%STate =.. [_State, []], Swi, 04/07/11
%		(State = begins ; State = ongoing ; State = ends) -> 
%		STate =.. [State, []], 
		Step_state =.. [State, Step],
		Step = [], 
		(State = begins ; State = ongoing ; State = ends), % Swi 09/10/11, watch: may need cut 
		Context = ['Glee-min', Spell, _Choices, _Targets, Switches, Identified, Sources, Payment],
		zone('Stack', []),
		available_mana(Mana),
		castable_spells(Mana, Castable),
		member(Spell, Castable),
		check_type(Spell, _, ['Creature'], _),
		%spell_choices(Choices),
		%spell_targets(Targets),
		resource_management(tap_for_mana, ['Glee-min', Spell, _, _, Switches, Identified, Sources, Payment]).
*/


%%%%%%%%%%%%%%cast_any_creature/2 (0) 17/03/11

	% No castable creature spell in hand
	cast_any_creature(['Glee-min', _Step, _Phase], 112).

%%%%%%%%%%%%%%cast_any_creature/2 (0) 17/03/11

	% It's the human player's turn
	cast_any_creature([Player, _Step, _Phase], 112):-
		Player \= 'Glee-min'.


%%%%%%%%%%%%%%available_mana/1 16/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* available_mana(-Mana) */
	% Available mana is equal to the mana
	%  that all untapped mana sources can produce.
	% Naive but serviceable (add more clauses to deal with
	%  weird cases)

	available_mana(Mana_available):-
		zone('Glee-min', 'Battlefield', Permanents),
		findall(Mana,
				(member(Source, Permanents),
				Source = object(Name - _Id, State),
				\+ member(tapped, State),
				mana_ability(Name, _Ability, Mana)),
				% ^ Will only find single-mana producing
				%  sources for now
			Mana_production),
		atom_to_list(Mana_available, Mana_production).


%%%%%%%%%%%%%%castable_spells/1 16/03/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* castable_spells(+Mana, -Castable) */
	% All spells that cen be cast with available mana.

	castable_spells(Mana, Castable):-
	zone('Glee-min', 'Hand', Cards),
		findall(Spell,
				(member(Spell, Cards),
					card([card_name Spell, mana_cost Cost, _, _, _, _, _, _]),
					\+ check_type(Spell, _, ['Land'], _),
					match_cost(Cost, Mana)),
				Castable).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%conserve_utility/2 24/03/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Naive tactic: attack/block with everything but utility creatures:

%%%%%%%%%%%%%%conserve_utility/2 (1) 24/03/11

	conserve_utility([declare_attackers, Identified], List_of_attackers):-
		deck('Glee-min', Deck),
		utility_creatures(Deck, Utility),
		findall(Switch,
				(member([Attacker - Switch, _Id], Identified),
				\+ member(Attacker, Utility)),
			List_of_attackers).
		% Identified: list of [Name - Switch, Id]

		% Some redundancy here- The Deck name was known in combat_tactic
		%  but it was removed as not needed.
		% The alternative is to keep the deck name in combat_tactic but
		%  other combat tactics might not need it.

%%%%%%%%%%%%%%conserve_utility/2 (2) 24/03/11

	conserve_utility([one_blocker, Identified], Switch):-
		deck('Glee-min', Deck),
		utility_creatures(Deck, Utility),
		member([Blocker - Switch, _Id], Identified),
		\+ member(Blocker, Utility).
		% Identified: list of [Name - Switch, Id]

%%%%%%%%%%%%%%conserve_utility/2 (0) 24/03/11

	% Default blocking accepted (o: "ok")
	conserve_utility([one_blocker, _Identified], o).

%%%%%%%%%%%%%%conserve_utility/2 (3) 24/03/11

	% Naive blocking- choose the first attacking creature and block it.
	conserve_utility([one_attacker, [_Blocker, Identified]], Switch):-
		member([Attacker - Switch, Id], Identified),
		zone('Battlefield', Permanents),
		member(object(Attacker - Id, State), Permanents),
		\+ member(blocked_by(_blocker, _ID), State).
		% ^ No need to check that the Blocker is one of ours!
		% Identified: list of [Name - Switch, Id]

%%%%%%%%%%%%%%conserve_utility/2 (4) 24/03/11

	% accept the presented order of blockers; o: "ok"
	conserve_utility([order_blockers, [_Attacker, _Blockers, _Map]], Switch):-
		Switch = o.
	% Attacker: Name - Id
	% Blockers: list of [Name - Id]
	% Map = [Name - Switch]

%%%%%%%%%%%%%%conserve_utility/2 (5) 24/03/11

	% The bestower's power is enough to kill the recipient.
	conserve_utility([assign_lethal, [_Bestower, Recipient, Bestower_P]], Toughness):-
		creature(Recipient, _, _, _, Toughness, _),
		Bestower_P >= Toughness.

%%%%%%%%%%%%%%conserve_utility/2 (6) 24/03/11

	% The bestower's power is not enough to kill the recipient.
	% Assigns non-lethal damage equal to the bestower's power.
	conserve_utility([assign_lethal, [_Bestower, Recipient, Bestower_P]], Bestower_P):-
		creature(Recipient, _, _, _, Toughness, _),
		Bestower_P < Toughness.
	% This leaves damage unassigned (if the total toughness of blockers is
	%  less than the attacker's power.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%        Forward Chaining           %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Simple forward-chaining engine, adepted from Bratko, 1986, pg. 356

/*	5-'Forest' present.
	3-'Giant Growth' present.
	2-'Lightning Bolt' present.
	4-'Mountain' present.
*/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%database_primer/3 10/04/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* database_primer(+Observation, +Player, +Conclusion) */
	% Clears the database of all existing Observations and Conclusions
	%  about a Player's deck- so "primes" the database.

	database_primer(Player, Observation, Conclusion):-
		observer(Player, Observed),
		count(Observed, [], Counted),
		retractall(Observation),
		retractall(Conclusion),
		new_database(Counted).

%%%% Notes %%%%
%%%%%%%%%%%%%%%
/*
	call with:
	database_primer(_X-_Object present,
			'Player 1',
			_Conclusion with _Certainty).
*/

%%%%%%%%%%%%%%observer/2 10/04011
%%%%%%%%%%%%%%%%%%%%%%%
	/* observer(+Player, +Observed) */
	% Asserts Observations about  a player's deck to the db

	observer(Player, Observed):-
		findall(OBject,
				(zone(Player, Zone, OBjects),
				% ^ Everything the opponent has revealed
				Zone \= 'Hand',
				Zone  \= 'Library',
				member(OBject, OBjects)),
				Zones),
		findall(Name, (member(Object, Zones),
				object_handle_0(Object, Name-_Id)),
			Observed).


%%%%%%%%%%%%%%observer/2 10/04011
%%%%%%%%%%%%%%%%%%%%%%%
	/* count(+List, [], Counted) */
	% Counts the instances of one element in a list

	count([], Counted, Counted).
	count(Observed, Temp, Counted):-
		member(Name, Observed),
		findall(Name, member(Name, Observed), Names),
		length(Names, Length),
		append(Temp, [Length-Name], New_temp),
		removeall(Name, Observed, Remaining),
		count(Remaining, New_temp, Counted).


%%%%%%%%%%%%%%new_database/1 10/04011
%%%%%%%%%%%%%%%%%%%%%%%
	/* new_database(+Observations) */
	% Adds a new set of observations to the db

	new_database([]).
	new_database([Counted | Rest]):-
		asserta(Counted present),
		new_database(Rest).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%forward_chaining/1 10/04/11
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	/* forward_chaining(+Observation) */
	% forward-chaining inference engine
	% Observation is the pattern of facts to examine

	% eg Observation pattern: X-Object present
	forward_chaining(Observation):-
		observation(Observation, Observations),
		inference(Observations, [], Conclusions),
		accumulated_certainty(Conclusions).

%%%%%%%%%%%%%%observation/2 10/04011
%%%%%%%%%%%%%%%%%%%%%%%
	/* observation(+Observation, -Observations) */
	% gathers all relevant facts for inference/3

	observation(Observation, Observations):-
		findall(Observation,
				Observation,
			Observations). %,
		%inference(Observations).


%%%%%%%%%%%%%%inference/3 10/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* inference(+Observations) */
	% Draws all possible conclusions from a set of Observations

%%%%%%%%%%%%%%inference/1 (0) 10/04/11

	% No more obesrvations to draw conclusions from
	inference([], Conclusions, Conclusions).

%%%%%%%%%%%%%%inference/1 (1) 10/04/11

	% Inference begins (temporary Conclusion set is empty)
	inference([Observation | Observations], [], Conclusions):-
		if Condition then Conclusion with Certainty,
		match(Condition, Observation),
		append([], [Conclusion with Certainty], New_temp),
		inference([Observation | Observations], New_temp, Conclusions).

%%%%%%%%%%%%%%inference/1 (2) 10/04/11

	% The current observation matches a condtion for a conclusion
	inference([Observation | Observations], Temp, Conclusions):-
		if Condition then Conclusion with Certainty,
		match(Condition, Observation),
		\+ member(Conclusion with Certainty, Temp),
		% ^ Until the Observation matches a condition, the Conclusion
		%  has unbound variables, so this ordering is necessary.
		append(Temp, [Conclusion with Certainty], New_temp),
		inference([Observation | Observations], New_temp, Conclusions).

%%%%%%%%%%%%%%inference/1 (3) 10/04/11

	% There are more Observations to examine
	inference([_Observation | Observations], Temp, Conclusions):-
		inference(Observations, Temp, Conclusions).


%%%%%%%%%%%%%%match/2
%%%%%%%%%%%%%%%%%%%%%%%
	/* match(+Condition, +Observation) */
	% True if a given Condition matches an Observation

	match(Condition, Observation):-
		Condition =.. Full_condition,
		(member(Observation, Full_condition);
		Observation = Condition).


%%%%%%%%%%%%%%accumulated_certainty/1 10/04/11
%%%%%%%%%%%%%%%%%%%%%%%
	/* accumulated_certainty(+Conclusions) */
	% Combines the certainty factors of a set of Conclusions
	%  and asserts the new Conclusion to the db

%%%%%%%%%%%%%%accumulated_certainty/1 (0) 10/04/11

	accumulated_certainty([]).

%%%%%%%%%%%%%%accumulated_certainty/1 (1) 10/04/11

	accumulated_certainty([Conclusion | Conclusions]):-
		Conclusion = (Deck_xxxxxxxxed with X:Z certainty),
		% eg, 'Pistachio' identified with 16:40 certainty
		Deck_xxxxxxxxed with Y:Z certainty, % is a fact in the db
		Total is X+Y,
		retractall(Deck_xxxxxxxxed with Y:Z certainty),
		asserta(Deck_xxxxxxxxed with Total:Z certainty),
		accumulated_certainty(Conclusions).

%%%%%%%%%%%%%%accumulated_certainty/1 (2) 10/04/11

	accumulated_certainty([Conclusion with Certainty | Conclusions]):-
		asserta(Conclusion with Certainty),
		accumulated_certainty(Conclusions).



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%        Production Rules           %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Production rules for the forward chaining inference engine
	%  used to determine the matchup.

	if X-'Mountain' present and X >= 1 then 'Pistachio' eliminated with 40:40 certainty.
	if X-'Forest' present then 'Pistachio' identified with X:40 certainty.
	if X-'Giant Growth' present then 'Pistachio' identified with X:40 certainty.

	if X-'Forest' present and X >= 1 then 'Raspberry' eliminated with 40:40 certainty.
	if X-'Mountain' present then 'Raspberry' identified with X:40 certainty.
	if X-'Lightning Bolt' present then 'Raspberry' identified with X:40 certainty.

	if X-'Mountain' present and \+ _Y-'Forest' present then 'Frog in a Blender' identified with -X:40 certainty.
	if X-'Mountain' present then 'Frog in a Blender' identified with X:40 certainty.
	if X-'Forest' present then 'Frog in a Blender' identified with X:40 certainty.
	if X-'Giant Growth' present then 'Frog in a Blender' identified with X:40 certainty.
	if X-'Lightning Bolt' present  then 'Frog in a Blender' identified with X:40 certainty.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%               Taunts              %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% Taunts are used to communicate important information
	%  during debugging; at the moment, just that a matchup has
	%  been identified properly.

	:- dynamic(matchup_taunt/1).
	%:- asserta(matchup-taunt: []).

	taunt(matchup_strategy, Matchup):-
		\+ matchup_taunt(Matchup),
		output(taunt, [matchup_strategy, Matchup]),
		asserta(matchup_taunt(Matchup)).

	taunt(matchup_strategy, _Matchup).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%             AI Notes              %%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

/*
%%%%%%%%%%%%%%combat_tactic/3 (0) 24/03/11

	% Gleemin has chosen to play a land or cast a spell.
	combat_tactic(deck, _Context, Action ):-
		\+ type(Action, 0).

%%%%%%%%%%%%%%combat_tactic/3 (1) 24/03/11

	combat_tactic(deck, [Deck_name | Context], Action):-
		combat_tactic(Deck_name, Tactic),
		Tactic(Context, Action).
	% Where in this case Action = [Identified | List_of_attackers]
	%  Identified being input, List_of_attackers the output to return
	%  to declare_attackers/3 in creature_combat.pl

*/


