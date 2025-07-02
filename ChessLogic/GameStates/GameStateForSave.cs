using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ChessLogic.GameStates
{
    public class GameStateForSave
    {
        public string GameType { get; set; }
        public int depth { get; set; }
        public string CurrentPlayer { get; set; }
        public int timeRemainingWhite { get; set; }
        public int timeRemainingBlack { get; set; }
        public string historyBoard { get; set; }
        public List<string> CapturedWhitePiece { get; set; } = new List<string>();
        public List<string> CapturedBlackPiece { get; set; } = new List<string>();
    }
}
