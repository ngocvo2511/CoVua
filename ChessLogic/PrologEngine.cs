using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using ChessLogic.GameStates;
using ChessLogic.Pieces;
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

            // Khởi tạo bàn cờ
            if (!PlQuery.PlCall("init."))
            {
                throw new Exception("Không thể khởi tạo bàn cờ.");
            }
        }
        public static Task InitializeGameLoadAsync(string prologFile, GameStateForLoad gameStateForLoad)
        {
            return PrologThread.Instance.Enqueue(() => {
                if (!_isInitialized)
                {
                    PlEngine.Initialize(new string[] { "-q", "-f", "none" });
                    _isInitialized = true;
                }
                if (!PlQuery.PlCall($"consult('{prologFile.Replace("\\", "/")}')"))
                {
                    throw new Exception("Không thể load file Prolog.");
                }
                setHistoryMove(gameStateForLoad.historyBoard);
                if (gameStateForLoad.depth != 0) SetDepth(gameStateForLoad.depth);
                return true;
            });
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
                using (var q = new PlQuery($"place_piece({fromPos}, {toPos}, Status, 'none')"))
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
                using (var q = new PlQuery($"place_piece({fromPos}, {toPos}, Status, '{promotionPiece}')"))
                {
                    if (q.NextSolution())
                    {
                        status = q.Variables["Status"].ToString().ToUpper();
                        Console.WriteLine($"Promotion successful: {status}");
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
            using (var q = new PlQuery("board(Position,Color,Counter), check_game_status(Position, Color, Counter, Status)"))
            {
                if (q.NextSolution())
                {
                    string status = q.Variables["Status"].ToString().ToUpper();
                    return status;
                }
                return "";
            }
        }

        public static void Reset()
        {
            if (_isInitialized == false) return;
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
            using (var q = new PlQuery("get_history_moves(H)"))
            {
                if (q.NextSolution())
                    return q.Variables["H"].ToString();
            }
            return null;
        }
        public static void setHistoryMove(string rawHistory)
        {
            using( var q = new PlQuery($"set_history_moves({rawHistory})"))
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

        public static Stack<Tuple<Move,Piece>> ParseHistory(string historyString)
        {
            var stack = new Stack<Tuple<Move, Piece>>();

            var clean = historyString.Trim('[', ']');
            var moveRegex = new Regex(@"move\((\d+),(\d+),(\w+),(\w+),\w+\)");

            foreach (Match match in moveRegex.Matches(clean))
            {
                int from = int.Parse(match.Groups[1].Value);
                if (from == 64) continue;
                int to = int.Parse(match.Groups[2].Value);
                string capturedPieceStr = match.Groups[4].Value;

                Move move = new NormalMove(Position.IntToPosition(from),Position.IntToPosition(to));
                var captured = ParsePiece(capturedPieceStr);

                stack.Push(Tuple.Create(move, captured));
            }
            return stack;
        }
        private static Piece ParsePiece(string pieceStr)
        {
            switch (pieceStr)
            {
                case "king": return new King(Player.Black);
                case "pawn": return new Pawn(Player.Black);
                case "rook": return new Rook(Player.Black);
                case "bishop": return new Bishop(Player.Black);
                case "queen": return new Queen(Player.Black);
                case "knight": return new Knight(Player.Black);
                default: return null;
            }
        }

        // ASYNC WRAPPERS FOR PROLOG THREAD
        public static Task<List<Move>> GetLegalMovesAsync(int fromPos)
            => PrologThread.Instance.Enqueue(() => GetLegalMoves(fromPos));

        public class MakeMoveResult { public bool Success; public string Status; public bool NeedsPromotion; }
        public static Task<MakeMoveResult> MakeMoveAsync(int fromPos, int toPos)
            => PrologThread.Instance.Enqueue(() => {
                var result = new MakeMoveResult();
                result.Success = MakeMove(fromPos, toPos, out result.Status, out result.NeedsPromotion);
                return result;
            });

        public static Task<MakeMoveResult> MakeMoveWithPromotionAsync(int fromPos, int toPos, string promotionPiece)
            => PrologThread.Instance.Enqueue(() => {
                var result = new MakeMoveResult();
                result.Success = MakeMoveWithPromotion(fromPos, toPos, promotionPiece, out result.Status);
                return result;
            });

        public static Task<(string status, int fromPos, int toPos)?> AiMoveAsync()
            => PrologThread.Instance.Enqueue(() => AiMove());

        public static Task<bool> UndoAsync()
            => PrologThread.Instance.Enqueue(() => Undo());

        public static Task<bool> IsGameOverAsync()
            => PrologThread.Instance.Enqueue(() => IsGameOver());

        public static Task<string> GetGameStatusAsync()
            => PrologThread.Instance.Enqueue(() => GetGameStatus());

        public static Task ResetAsync()
            => PrologThread.Instance.Enqueue(() => { Reset(); return true; });

        public static Task CleanupAsync()
            => PrologThread.Instance.Enqueue(() => { Cleanup(); return true; });

        public static Task<Dictionary<Player, Dictionary<PieceType, List<int>>>> GetCurrentPositionAsync()
            => PrologThread.Instance.Enqueue(() => GetCurrentPosition());

        public static Task<Player> GetCurrentPlayerAsync()
            => PrologThread.Instance.Enqueue(() => GetCurrentPlayer());

        public static Task<string> GetRawHistoryAsync()
            => PrologThread.Instance.Enqueue(() => GetRawHistory());

        public static Task SetHistoryMoveAsync(string rawHistory)
            => PrologThread.Instance.Enqueue(() => { setHistoryMove(rawHistory); return true; });

        public static Task<int?> GetDepthAsync()
            => PrologThread.Instance.Enqueue(() => GetDepth());

        public static Task SetDepthAsync(int depth)
            => PrologThread.Instance.Enqueue(() => { SetDepth(depth); return true; });

        public static Task InitializeAsync(string prologFile, bool isAI, Player color)
            => PrologThread.Instance.Enqueue(() => { Initialize(prologFile, isAI, color); return true; });
    }
}
