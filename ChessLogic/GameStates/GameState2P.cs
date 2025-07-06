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
            var undo = Moved.Pop();
            if (undo.Item2.Item1 != null)
            {
                if (undo.Item2.Item1.Color == Player.Black) CapturedBlackPiece.RemoveAt(CapturedBlackPiece.Count - 1);
                else CapturedWhitePiece.RemoveAt(CapturedWhitePiece.Count - 1);
            }
            CurrentPlayer = CurrentPlayer.Opponent();
            CapturedPiece = undo.Item2.Item1;
        }
    }
}
