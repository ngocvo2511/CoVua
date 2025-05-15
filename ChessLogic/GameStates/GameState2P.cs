using System.Linq;

namespace ChessLogic.GameStates.GameState
{
    public class GameState2P : GameState
    {
        public GameState2P(Player player, Board board, int timeLimit = 0) : base(player, board, timeLimit) { }

        public override void UndoMove()
        {
            if (!Moved.Any()) return;
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
            CurrentPlayer = CurrentPlayer.Opponent();
            CapturedPiece = undo.Item2;
            noCapture.Pop();
        }
    }
}
