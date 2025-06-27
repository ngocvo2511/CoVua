using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ChessLogic
{
    public class GameRecord
    {
        public string FilePath { get; set; }
        public string PlayTime { get; set; }
        public string GameMode { get; set; }
        public string Winner { get; set; }
        public string WinnerImagePath { get; set; }
    }

}
