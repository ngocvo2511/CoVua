using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SbsSW.SwiPlCs;

namespace ChessLogic
{
    public class PrologEngine
    {
        private static bool _isInitialized = false;

        public static void Initialize(string prologFile, bool isAI, Player color)
        {
            if (!_isInitialized)
            {
                // Khởi tạo Prolog engine
                PlEngine.Initialize(new string[] { "-q", "-f", "none" });
                _isInitialized = true;
            }

            // Load file Prolog
            if (!PlQuery.PlCall($"consult('{prologFile.Replace("\\", "/")}')"))
            {
                throw new Exception("Không thể load file Prolog.");
            }

            if (isAI)
            {
                if(color == Player.White)
                {
                    if (!PlQuery.PlCall("game_mode(hxc)."))
                    {
                        throw new Exception("Không thể khởi tạo bàn cờ.");
                    }
                }
                else
                {
                    if (!PlQuery.PlCall("game_mode(cxh)."))
                    {
                        throw new Exception("Không thể khởi tạo bàn cờ.");
                    }
                }

            }
            else
            {
                if (!PlQuery.PlCall("game_mode(hxh)."))
                {
                    throw new Exception("Không thể khởi tạo bàn cờ.");
                }
            }


            // Khởi tạo bàn cờ
            if (!PlQuery.PlCall("start."))
            {
                throw new Exception("Không thể khởi tạo bàn cờ.");
            }
        }

        public static List<Move> GetLegalMoves(int fromPos)
        {
            var legalMoves = new List<Move>();

            using (var q = new PlQuery($"pick_piece({fromPos}, LegalMoves)"))
            {
                foreach (PlQueryVariables vars in q.SolutionVariables)
                {
                    string raw = vars["LegalMoves"].ToString().Trim('[', ']');

                    // Bỏ qua nếu danh sách rỗng
                    if (string.IsNullOrWhiteSpace(raw))
                        continue;

                    // Chuyển chuỗi kết quả thành danh sách số nguyên
                    var moves = raw
                        .Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                        .Select(s => int.Parse(s.Trim()))
                        .ToList();

                    int fromRow = 7 - fromPos / 8;
                    int fromCol = fromPos % 8;

                    foreach (var toPos in moves)
                    {
                        int toRow = 7 - toPos / 8;
                        int toCol = toPos % 8;
                        legalMoves.Add(new NormalMove(new Position(fromRow, fromCol), new Position(toRow, toCol)));
                    }
                }
            }

            return legalMoves;
        }

        public static bool MakeMove(int fromPos, int toPos, out string status)
        {
            status = null;
            try
            {
                using (var q = new PlQuery($"place_piece({fromPos}, {toPos}, Status)"))
                {
                    if (q.NextSolution())
                    {
                        status = q.Variables["Status"].ToString().ToUpper(); // SAFE, CHECK, ...
                        return true;
                    }
                }
            }
            catch
            {
                // Xử lý nếu có lỗi Prolog
            }
            return false;
        }

        public static bool IsGameOver()
        {
            // Kiểm tra xem ván cờ đã kết thúc chưa
            using (var q = new PlQuery("board(Position, Color), (is_checkmate(Color, Position) ; is_stalemate(Color, Position))"))
            {
                return q.NextSolution();
            }
        }

        public static string GetGameStatus()
        {
            // Kiểm tra trạng thái hiện tại của ván cờ
            using (var q = new PlQuery("board(Position, Color)"))
            {
                if (q.NextSolution())
                {
                    if (PlQuery.PlCall("board(Position, Color), is_checkmate(Color, Position)"))
                        return "CHECKMATE";
                    if (PlQuery.PlCall("board(Position, Color), is_stalemate(Color, Position)"))
                        return "STALEMATE";
                    if (PlQuery.PlCall("board(Position, Color), in_check(Color, Position)"))
                        return "CHECK";
                }
            }
            return "NORMAL";
        }

        public static void Reset()
        {
            // Reset trạng thái bàn cờ
            PlQuery.PlCall("reset");
            PlQuery.PlCall("set_position(begin)");
        }

        public static void Cleanup()
        {
            if (_isInitialized)
            {
                PlEngine.PlCleanup();
                _isInitialized = false;
            }
        }
    }
}
