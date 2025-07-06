using System;
using System.Collections.Generic;
using System.Linq;

namespace ChessLogic.GameStates.GameState
{
    public abstract class GameState
    {
        public Board Board { get; set; }
        public Stack<Tuple<Move,Tuple<Piece,string>>> Moved { get; set; }
        public Player CurrentPlayer { get; set; }

        public Result Result { get; set; } = null;

        public Piece CapturedPiece { get; set; }
        public int timeRemainingWhite { get; set; }
        public int timeRemainingBlack { get; set; }
        public List<Piece> CapturedWhitePiece { get; set; }
        public List<Piece> CapturedBlackPiece { get; set; }


        public GameState(Player player, Board board, int timeLimit)
        {
            CurrentPlayer = player;
            Board = board;
            this.Moved = new Stack<Tuple<Move,Tuple<Piece, string>>>();
            this.CapturedBlackPiece = new List<Piece>();
            this.CapturedWhitePiece = new List<Piece>();
            timeRemainingBlack = timeLimit;
            timeRemainingWhite = timeLimit;
        }
        public GameState(Player player, Board board, int redTime, int blackTime, Stack<Tuple<Move,Tuple<Piece, string>>> Moved, List<Piece> CapturedWhitePiece, List<Piece> CapturedBlackPiece)
        {
            CurrentPlayer = player;
            Board = board;
            this.Moved = Moved;
            this.CapturedBlackPiece = CapturedBlackPiece;
            this.CapturedWhitePiece = CapturedWhitePiece;
            timeRemainingBlack = blackTime;
            timeRemainingWhite = redTime;
        }

        public void MakeMove(Move move)
        {
            if(move.Type == MoveType.EnPassant)
            {
                var capturePos = new Position(move.FromPos.Row, move.ToPos.Column);
                Moved.Push(Tuple.Create(move, Tuple.Create(Board[capturePos],"none")));
                CapturedPiece = Board[capturePos];
            }
            else
            {
                Moved.Push(Tuple.Create(move, Tuple.Create(Board[move.ToPos],"none")));
                CapturedPiece = Board[move.ToPos];
            }

            if (CapturedPiece != null)
            {
                if (CapturedPiece.Color == Player.Black) CapturedBlackPiece.Add(CapturedPiece);
                else CapturedWhitePiece.Add(CapturedPiece);
            }
            CurrentPlayer = CurrentPlayer.Opponent();
        }
        public abstract void UndoMove();

        public bool IsGameOver()
        {
            return Result != null;
        }

        public void TimeForfeit()
        {
            Result = Result.Win(CurrentPlayer.Opponent(), EndReason.TimeForfeit);
        }
    }
}
