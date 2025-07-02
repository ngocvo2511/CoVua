using System.Linq;

namespace ChessLogic.GameStates.GameState
{
    public class GameState2P : GameState
    {
        public GameState2P(Player player, Board board, int timeLimit = 0) : base(player, board, timeLimit) { }

        public GameState2P(GameStateForLoad gameState, Board board) : base(gameState.CurrentPlayer,board,gameState.timeRemainingWhite,gameState.timeRemainingBlack,gameState.Moved,gameState.CapturedWhitePiece,gameState.CapturedBlackPiece)
        {}
        public override void UndoMove()
        {
            if (!Moved.Any()) return;
            UndoStateString();
            var undo = Moved.Pop();
            //Move undoMove = new NormalMove(undo.Item1.ToPos, undo.Item1.FromPos);
            //undoMove.Execute(Board);
            //Board[undo.Item1.ToPos] = undo.Item2;
            if (undo.Item2 != null)
            {
                if (CurrentPlayer == Player.Black) CapturedBlackPiece.RemoveAt(CapturedBlackPiece.Count - 1);
                else CapturedWhitePiece.RemoveAt(CapturedWhitePiece.Count - 1);
            }
            CurrentPlayer = CurrentPlayer.Opponent();
            CapturedPiece = undo.Item2;
            //noCapture.Pop();
        }
    }
}
