using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;

namespace ChessLogic.GameStates.GameState
{
    public class GameStateAI : GameState
    {
        public int depth { get; set; }
        public Piece AiCapturedPiece { get; protected set; }
        public GameStateAI(Player player, Board board, int depth, int timeLimit) : base(player, board, timeLimit)
        {
            this.depth = depth;
        }
        public GameStateAI(GameStateForLoad gameState, Board board) : base(gameState.CurrentPlayer, board, gameState.timeRemainingWhite, gameState.timeRemainingBlack,gameState.Moved,gameState.CapturedWhitePiece,gameState.CapturedBlackPiece)
        {
            this.depth = gameState.depth;
        }
        public override void UndoMove()
        {
            if (Moved.Count <= 1 || CurrentPlayer == Player.Black) return;
            for (int i = 0; i < 2; i++)
            {
                var undo = Moved.Pop();
                Move undoMove = new NormalMove(undo.Item1.ToPos, undo.Item1.FromPos);
                Board[undo.Item1.ToPos] = undo.Item2.Item1;
                if (undo.Item2.Item1 != null)
                {
                    if (undo.Item2.Item1.Color == Player.Black) CapturedBlackPiece.RemoveAt(CapturedBlackPiece.Count - 1);
                    else CapturedWhitePiece.RemoveAt(CapturedWhitePiece.Count - 1);
                }
                if (i == 0) AiCapturedPiece = undo.Item2.Item1;
                else CapturedPiece = undo.Item2.Item1;
                CurrentPlayer = CurrentPlayer.Opponent();
            }
            CurrentPlayer = Player.White;
        }
    }
}
