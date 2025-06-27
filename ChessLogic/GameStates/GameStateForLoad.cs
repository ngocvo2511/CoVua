using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ChessLogic.GameStates
{
    public class GameStateForLoad
    {
        public string GameType { get; set; }
        public int depth { get; set; }
        public Player CurrentPlayer { get; set; }
        public Stack<Tuple<Move, Piece>> Moved { get; set; }
        public int timeRemainingWhite { get; set; }
        public int timeRemainingBlack { get; set; }
        public string historyBoard { get; set; }
        public List<Piece> CapturedWhitePiece { get; set; }
        public List<Piece> CapturedBlackPiece { get; set; }
    }
}
