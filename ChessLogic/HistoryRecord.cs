using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ChessLogic
{
    public class HistoryRecord
    {
        public string GameMode {  get; set; }
        public string Reason {  get; set; }
        public string Winner {  get; set; }
        public string HistoryString {  get; set; }
        public int Depth {  get; set; }
        public bool isAIFirst { get; set; }
        public HistoryRecord() { }
        public HistoryRecord(string gameMode, Result result, string historyString, int depth, bool isAIFirst)
        {
            this.GameMode = gameMode;
            this.Reason = result.Reason.ToString();
            this.Winner = result.Winner.ToString();
            this.HistoryString = historyString;
            this.Depth = depth;
            this.isAIFirst = isAIFirst;
        }
    }
}
