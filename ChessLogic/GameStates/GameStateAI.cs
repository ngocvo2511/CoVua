using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

namespace ChessLogic.GameStates.GameState
{
    public class GameStateAI : GameState
    {
        public int depth { get; set; }
        private ValuePiece value;
        public Piece AiCapturedPiece { get; protected set; }
        public GameStateAI(Player player, Board board, int depth, int timeLimit) : base(player, board, timeLimit)
        {
            this.depth = depth;
            value = new ValuePiece();
        }
        public override void UndoMove()
        {
            if (Moved.Count <= 1 || CurrentPlayer == Player.Black) return;
            for (int i = 0; i < 2; i++)
            {
                UndoStateString();
                var undo = Moved.Pop();
                Move undoMove = new NormalMove(undo.Item1.ToPos, undo.Item1.FromPos);
                undoMove.Execute(Board);
                Board[undo.Item1.ToPos] = undo.Item2;
                if (undo.Item2 != null)
                {
                    if (undo.Item2.Color == Player.Black) CapturedBlackPiece.RemoveAt(CapturedBlackPiece.Count - 1);
                    else CapturedRedPiece.RemoveAt(CapturedRedPiece.Count - 1);
                }
                if (i == 0) AiCapturedPiece = undo.Item2;
                else CapturedPiece = undo.Item2;
                noCapture.Pop();
            }
            CurrentPlayer = Player.White;
        }
        #region MinMax Algorithm
        private void MakeTestMove(Move move)
        {
            Moved.Push(Tuple.Create(move, Board[move.ToPos]));
            move.Execute(Board);
            CurrentPlayer = CurrentPlayer.Opponent();
        }
        private void UndoTestMove()
        {
            if (!Moved.Any()) return;
            var undo = Moved.Pop();
            Move undoMove = new NormalMove(undo.Item1.ToPos, undo.Item1.FromPos);
            undoMove.Execute(Board);
            Board[undo.Item1.ToPos] = undo.Item2;
            CurrentPlayer = CurrentPlayer.Opponent();
        }
        public void AiMove(CancellationToken token)
        {
            IEnumerable<Move> moves = AllLegalMovesFor(CurrentPlayer);
            if (!moves.Any()) return;
            Move bestMove = null;
            int value;
            int bestValue = -10000;
            foreach (var move in moves)
            {
                MakeTestMove(move);
                value = AlphaBeta(depth - 1);
                UndoTestMove();
                if (value > bestValue)
                {
                    bestValue = value;
                    bestMove = move;
                }
                if (token.IsCancellationRequested) return;
            }
            if (bestMove != null) MakeMove(bestMove);
        }
        private int AlphaBeta(int depth, int alpha = -9999, int beta = 9999) // giá trị nước đi
        {
            IEnumerable<Move> moves = AllLegalMovesFor(CurrentPlayer);
            if (!moves.Any()) return (CurrentPlayer == Player.Black) ? -9999 : 9999;
            if (depth == 0) return value.GetValueBoard(Board);
            if (CurrentPlayer == Player.Black)
            {
                int bestValue = -9999;
                foreach (var move in moves)
                {
                    MakeTestMove(move);
                    int value = AlphaBeta(depth - 1, alpha, beta);
                    UndoTestMove();
                    bestValue = Math.Max(bestValue, value);
                    alpha = Math.Max(alpha, value);
                    if (alpha >= beta) return bestValue;
                }
                return bestValue;
            }
            else if (CurrentPlayer == Player.White)
            {
                int bestValue = 9999;
                foreach (var move in moves)
                {
                    MakeTestMove(move);
                    int value = AlphaBeta(depth - 1, alpha, beta);
                    UndoTestMove();
                    bestValue = Math.Min(bestValue, value);
                    beta = Math.Min(beta, value);
                    if (alpha >= beta) return bestValue;
                }
                return bestValue;
            }
            else return value.GetValueBoard(Board);
        }
        #endregion
    }
}
