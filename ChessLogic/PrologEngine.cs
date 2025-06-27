using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SbsSW.SwiPlCs;
using SbsSW.SwiPlCs.Exceptions;

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
                if (!PlQuery.PlCall("game_mode(hxc)."))
                {
                    throw new Exception("Không thể khởi tạo bàn cờ.");
                }

                if (color == Player.Black)
                {
                    if (!PlQuery.PlCall("set_first_player(black)."))
                    {
                        throw new Exception("Không thể khởi tạo bàn cờ cho người chơi đen.");
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
            if (!PlQuery.PlCall("init."))
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

        public static bool MakeMove(int fromPos, int toPos, out string status, out bool needsPromotion)
        {
            status = null;
            needsPromotion = false;
            try
            {
                using (var q = new PlQuery($"place_piece({fromPos}, {toPos}, Status)"))
                {
                    if (q.NextSolution())
                    {
                        status = q.Variables["Status"].ToString().ToUpper();
                        return true;
                    }
                }
            }
            catch (PlException ex)
            {
                // Kiểm tra xem có phải là lỗi phong cấp không
                if (ex.Message.Contains("promotion_required"))
                {
                    needsPromotion = true;
                    return false;
                }
            }

            return false;
        }

        public static bool MakeMoveWithPromotion(int fromPos, int toPos, string promotionPiece, out string status)
        {
            status = null;
            try
            {
                Console.WriteLine($"Attempting promotion: from={fromPos}, to={toPos}, piece={promotionPiece}");
                using (var q = new PlQuery($"place_piece_with_promotion({fromPos}, {toPos}, '{promotionPiece}', Status)"))
                {
                    if (q.NextSolution())
                    {
                        status = q.Variables["Status"].ToString().ToUpper();
                        Console.WriteLine($"Promotion successful: {status}");
                        using (var qq = new PlQuery("current_predicate(undo/0)."))
                        {
                            Console.WriteLine(qq.NextSolution()
                                ? "✅ undo/0 vẫn tồn tại."
                                : "❌ undo/0 không tồn tại sau khi phong cấp.");
                        }
                        return true;
                    }
                    else
                    {
                        Console.WriteLine("Promotion failed: No solution found");
                    }
                }


            }
            catch (PlException ex)
            {
                // Handle any Prolog errors
                Console.WriteLine($"Prolog error in promotion: {ex.Message}");
            }
            catch (Exception ex)
            {
                // Handle any other errors
                Console.WriteLine($"General error in promotion: {ex.Message}");
            }

            return false;
        }

        public static (string status, int fromPos, int toPos)? AiMove()
        {
            using (var q = new PlQuery("bot_move(FromPos, ToPos, Status)."))
            {
                if (q.NextSolution())
                {
                    string status = q.Variables["Status"].ToString().ToUpper(); // e.g. SAFE, CHECK
                    int fromPos = int.Parse(q.Variables["FromPos"].ToString());
                    int toPos = int.Parse(q.Variables["ToPos"].ToString());
                    return (status, fromPos, toPos);
                }
            }

            return null; // Nếu không có kết quả
        }

        public static bool Undo()
        {
            return PlQuery.PlCall("user:undo.");
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

        public static Dictionary<Player, Dictionary<PieceType, List<int>>> GetCurrentPosition()
        {
            var result = new Dictionary<Player, Dictionary<PieceType, List<int>>>
            {
                { Player.White, new Dictionary<PieceType, List<int>>() },
                { Player.Black, new Dictionary<PieceType, List<int>>() }
            };

            using (var q = new PlQuery("get_current_board(Position, _, _)"))
            {
                if (q.NextSolution())
                {
                    var position = q.Variables["Position"].ToString();
                    ParsePosition(position, result);
                }
            }

            return result;
        }

        private static void ParsePosition(string position, Dictionary<Player, Dictionary<PieceType, List<int>>> result)
        {
            // Bỏ phần "Position = " nếu có
            if (position.StartsWith("Position ="))
                position = position.Substring("Position =".Length).Trim();

            // Bỏ dấu [] ngoài cùng nếu có
            position = position.Trim();
            if (position.StartsWith("[["))
                position = position.Substring(1); // còn 1 dấu [
            if (position.EndsWith("]]"))
                position = position.Substring(0, position.Length - 1); // bỏ 1 dấu ]

            // Tách 2 phần của trắng và đen
            var halves = new List<string>();
            int bracket = 0;
            int lastSplit = 0;
            for (int i = 0; i < position.Length; i++)
            {
                char c = position[i];
                if (c == '[') bracket++;
                if (c == ']') bracket--;
                if (c == ',' && bracket == 0)
                {
                    halves.Add(position.Substring(lastSplit, i - lastSplit).Trim());
                    lastSplit = i + 1;
                }
            }
            halves.Add(position.Substring(lastSplit).Trim());

            // Parse từng phần
            ParseSimpleHalfPosition(halves[0], result[Player.White]);
            ParseSimpleHalfPosition(halves[1], result[Player.Black]);
        }

        private static void ParseSimpleHalfPosition(string half, Dictionary<PieceType, List<int>> pieces)
        {
            half = half.Trim();
            if (half.StartsWith("["))
                half = half.Substring(1);
            if (half.EndsWith("]"))
                half = half.Substring(0, half.Length - 1);

            var parts = new List<string>();
            int bracket = 0;
            int lastSplit = 0;
            for (int i = 0; i < half.Length; i++)
            {
                char c = half[i];
                if (c == '[') bracket++;
                if (c == ']') bracket--;
                if (c == ',' && bracket == 0)
                {
                    parts.Add(half.Substring(lastSplit, i - lastSplit).Trim());
                    lastSplit = i + 1;
                }
            }
            parts.Add(half.Substring(lastSplit).Trim());

            if (parts.Count > 0) pieces[PieceType.Pawn] = ParsePositions(parts[0]);
            if (parts.Count > 1) pieces[PieceType.Rook] = ParsePositions(parts[1]);
            if (parts.Count > 2) pieces[PieceType.Knight] = ParsePositions(parts[2]);
            if (parts.Count > 3) pieces[PieceType.Bishop] = ParsePositions(parts[3]);
            if (parts.Count > 4) pieces[PieceType.Queen] = ParsePositions(parts[4]);
            if (parts.Count > 5) pieces[PieceType.King] = ParsePositions(parts[5]);
        }

        private static List<int> ParsePositions(string positions)
        {
            if (string.IsNullOrWhiteSpace(positions))
                return new List<int>();

            var result = new List<int>();
            foreach (var p in positions.Split(','))
            {
                var s = p.Trim().Trim('[', ']');
                if (int.TryParse(s, out int value))
                {
                    result.Add(value);
                }
            }
            return result;
        }

        public static Player GetCurrentPlayer()
        {
            using (var q = new PlQuery("board(_, Color, _)"))
            {
                if (q.NextSolution())
                {
                    Debug.Print(q.Variables.ToString());
                    var color = q.Variables["Color"].ToString();
                    return color == "white" ? Player.White : Player.Black;
                }
            }
            throw new Exception("Không thể lấy được lượt đi hiện tại.");
        }

        public static string GetRawHistory()
        {
            using (var q = new PlQuery("history(H)"))
            {
                if (q.NextSolution())
                    return q.Variables["H"].ToString();
            }
            return null;
        }
        public static void setHistoryBoard(string rawHistory)
        {
            using( var q = new PlQuery($"set_new_history({rawHistory})"))
            {
                if (!q.NextSolution())
                {
                    throw new Exception("Không thể đặt lịch sử bàn cờ.");
                }
            }
        }
        public static int? GetDepth()
        {
            try
            {
                using (var q = new PlQuery("depth(D)"))
                {
                    if (q.NextSolution())
                    {
                        var dStr = q.Variables["D"].ToString();
                        if (int.TryParse(dStr, out int depth))
                            return depth;
                    }
                }
            }
            catch
            {

            }
            return null;
        }
        public static void SetDepth(int depth)
        {
            try
            {
                PlQuery.PlCall($"set_depth({depth})");
            }
            catch (PlException ex)
            {
                Console.WriteLine($"Lỗi khi đặt độ sâu: {ex.Message}");
            }
        }
    }
}
