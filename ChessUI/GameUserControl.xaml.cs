using ChessLogic;
using ChessLogic.GameStates;
using ChessLogic.GameStates.GameState;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Threading;
using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Shapes;
using System.Windows.Threading;
using ChessUI.Menus;
using SbsSW.SwiPlCs;

namespace ChessUI
{
    /// <summary>
    /// Interaction logic for GameUserControl.xaml
    /// </summary>
    public partial class GameUserControl : UserControl
    {
        private readonly Image[,] pieceImages = new Image[8, 8];
        private readonly Rectangle[,] highlights = new Rectangle[8, 8];
        private readonly Rectangle[,] posMoved = new Rectangle[8, 8];
        private Dictionary<Position, Move> moveCache = new Dictionary<Position, Move>();
        public GameState gameState { get; set; }
        private Position selectedPos = null;
        private DispatcherTimer redTimer;
        private DispatcherTimer blackTimer;
        private bool isRedTurn = true;
        private Brush redBrush = new SolidColorBrush(Colors.Red);
        private Brush blackBrush = new SolidColorBrush(Colors.Black);
        private CancellationTokenSource cts = new CancellationTokenSource();
        private Stack<Tuple<Move, Tuple<Piece, string>>> moveList;
        private bool isReview = false;

        public GameUserControl(int timeLimit, bool isAI, int difficult = 1)
        {
            InitializeComponent();
            InitializeBoard();
            if (isAI == true) gameState = new GameStateAI(Player.White, Board.Initial(), difficult, timeLimit);
            else gameState = new GameState2P(Player.White, Board.Initial(), timeLimit);
            ShowGameInformation(difficult);
            if (timeLimit != 0)
            {
                InitializeTimer();
                SwitchTurn();
            }
        }
        public static GameUserControl Create(Player color, int timeLimit, bool isAI, int difficult = 1)
        {
            var control = new GameUserControl(timeLimit, isAI, difficult);
            string rootPath = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\.."));
            string prologPath = System.IO.Path.Combine(rootPath, "ChessLogic", "Prolog", "chess.pl");
            PrologEngine.Initialize(prologPath);
            control.gameState.Board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
            control.DrawBoard(control.gameState.Board);
            if (control.gameState is GameStateAI && color == Player.Black)
            {
                // Thêm delay để người chơi có thể thấy bàn cờ ban đầu trước khi máy đi
                Task.Delay(500).ContinueWith(_ =>
                {
                    control.Dispatcher.Invoke(() =>
                    {
                        var result = PrologEngine.AiMove();
                        if (result.HasValue)
                        {
                            var (status, from, to) = result.Value;
                            control.gameState.MakeMove(new NormalMove(Position.IntToPosition(from), Position.IntToPosition(to)));
                            control.gameState.Board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
                            control.isRedTurn = !control.isRedTurn;
                            if (control.redTimer != null) control.SwitchTurn();
                            control.WarningTextBlock.Text = status == "CHECK" ? "Chiếu tướng!" : null;
                            control.TurnTextBlock.Text = control.gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
                            control.DrawCapturedGrid(control.gameState.CapturedPiece);
                            control.DrawBoard(control.gameState.Board);
                            control.ShowPrevMove(control.gameState.Moved.First().Item1);
                            Sound.PlayMoveSound();
                        }
                        else
                        {
                            Console.WriteLine("Không thể thực hiện bot_move.");
                        }
                    });
                });
            }
            return control;
        }

        public GameUserControl(GameStateForLoad gameStateForLoad)
        {
            InitializeComponent();
            InitializeBoard();
        }
        public static GameUserControl Create(GameStateForLoad gameStateForLoad)
        {
            var control = new GameUserControl(gameStateForLoad);
            string rootPath = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\.."));
            string prologPath = System.IO.Path.Combine(rootPath, "ChessLogic", "Prolog", "chess.pl");
            PrologEngine.InitializeGameLoad(prologPath, gameStateForLoad);
            Board board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
            gameStateForLoad.Moved = PrologEngine.ParseHistory(gameStateForLoad.historyBoard);
            if (gameStateForLoad.GameType == "GameStateAI") control.gameState = new GameStateAI(gameStateForLoad, board);
            else control.gameState = new GameState2P(gameStateForLoad, board);
            control.ShowGameInformation(gameStateForLoad.depth);
            control.DrawBoard(control.gameState.Board);
            foreach (var piece in control.gameState.CapturedWhitePiece) control.DrawCapturedGrid(piece);
            foreach (var piece in control.gameState.CapturedBlackPiece) control.DrawCapturedGrid(piece);
            if (control.gameState.Moved.Any()) control.ShowPrevMove(control.gameState.Moved.First().Item1);
            if (control.gameState.timeRemainingBlack != 0)
            {
                control.InitializeTimer();
                control.SwitchTurn();
            }
            return control;
        }
        public GameUserControl(HistoryRecord historyRecord)
        {
            InitializeComponent();
            InitializeBoard();
        }
        public static GameUserControl Create(HistoryRecord historyRecord)
        {            
            var control = new GameUserControl(historyRecord);
            string rootPath = System.IO.Path.GetFullPath(System.IO.Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\.."));
            string prologPath = System.IO.Path.Combine(rootPath, "ChessLogic", "Prolog", "chess.pl");
            PrologEngine.Initialize(prologPath);
            Board board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
            control.moveList = new Stack<Tuple<Move, Tuple<Piece, string>>>(PrologEngine.ParseHistory(historyRecord.HistoryString));
            Piece piece = board[control.moveList.Peek().Item1.FromPos];
            Player startPlayer = piece.Color;
            if (historyRecord.GameMode == "2P")
            {
                control.gameState = new GameState2P(startPlayer, board);
            }
            else control.gameState = new GameStateAI(startPlayer, board, historyRecord.Depth,0);
            control.ShowGameInformation(historyRecord.Depth);
            control.DrawBoard(control.gameState.Board);
            control.isReview = true;
            control.SaveButton.IsEnabled = false;
            control.CellGrid.IsHitTestVisible = false;
            control.DoButton.Visibility = Visibility.Visible;
            control.PlayButton.Visibility = Visibility.Visible;
            if (control.moveList.Count == 0) control.PlayButton.IsEnabled = false;
            return control;
        }
        private void InitializeTimer()
        {
            int minutes = gameState.timeRemainingWhite / 60;
            int seconds = gameState.timeRemainingWhite % 60;
            redClock.Text = $"{minutes:D2}:{seconds:D2}";
            blackClock.Text = $"{minutes:D2}:{seconds:D2}";

            redTimer = new DispatcherTimer();
            redTimer.Interval = TimeSpan.FromSeconds(1);
            redTimer.Tick += RedTimer_Tick;
            blackTimer = new DispatcherTimer();
            blackTimer.Interval = TimeSpan.FromSeconds(1);
            blackTimer.Tick += BlackTimer_Tick;
        }
        private void RedTimer_Tick(object sender, EventArgs e)
        {
            gameState.timeRemainingWhite--;
            int minutes = gameState.timeRemainingWhite / 60;
            int seconds = gameState.timeRemainingWhite % 60;
            redClock.Text = $"{minutes:D2}:{seconds:D2}";
            if (gameState.timeRemainingWhite <= 0)
            {
                StopTimer();
                HideHighlights();
                CellGrid.IsEnabled = false;
                cts.Cancel();
                gameState.TimeForfeit();
                moveList = new Stack<Tuple<Move, Tuple<Piece, string>>>(gameState.Moved.ToArray());     
                SaveHistory.Save(gameState);
                RaiseGameOverEvent(gameState);
                return;
            }   
            if (gameState.timeRemainingWhite < 60)
            {
                redClock.Foreground = redBrush;
            }
        }
        private void BlackTimer_Tick(object sender, EventArgs e)
        {
            gameState.timeRemainingBlack--;
            int minutes = gameState.timeRemainingBlack / 60;
            int seconds = gameState.timeRemainingBlack % 60;
            blackClock.Text = $"{minutes:D2}:{seconds:D2}";
            if (gameState.timeRemainingBlack <= 0)
            {
                StopTimer();
                HideHighlights();
                CellGrid.IsEnabled = false;
                cts.Cancel();
                gameState.TimeForfeit();
                moveList = new Stack<Tuple<Move, Tuple<Piece, string>>>(gameState.Moved.ToArray());
                SaveHistory.Save(gameState);
                RaiseGameOverEvent(gameState);
                return;
            }
            if (gameState.timeRemainingBlack < 60)
            {
                blackClock.Foreground = redBrush;
            }
        }
        internal void StopTimer()
        {
            if (redTimer == null) return;
            redTimer.Stop();
            blackTimer.Stop();
        }
        internal void ContinueTimer()
        {
            if (redTimer == null) return;
            if (!gameState.IsGameOver())
            {
                if (isRedTurn)
                {
                    redTimer.Start();
                }
                else
                {
                    blackTimer.Start();
                }
            }
        }
        public void ResetTimer()
        {
            if (redTimer != null)
            {
                redTimer.Stop();
                redTimer.Tick -= RedTimer_Tick;
                redTimer = null;
            }
            if (blackTimer != null)
            {
                blackTimer.Stop();
                blackTimer.Tick -= BlackTimer_Tick;
                blackTimer = null;
            }
        }
        private void SwitchTurn()
        {
            redTimer.Stop();
            blackTimer.Stop();

            if (isRedTurn)
            {
                redTimer.Start();
            }
            else
            {
                blackTimer.Start();
            }
        }
        private void ShowGameInformation(int difficult)
        {
            switch (difficult)
            {
                case 2:
                    blackInfo.Text = "Máy (Độ khó: Dễ)";
                    break;
                case 3:
                    blackInfo.Text = "Máy (Độ khó: Thường)";
                    break;
                case 4:
                    blackInfo.Text = "Máy (Độ khó: Khó)";
                    break;
                default:
                    blackInfo.Text = "Người chơi 2";
                    break;
            }
            TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
        }


        private void UnableClick()
        {
            CellGrid.IsHitTestVisible = false;
            PauseButton.IsEnabled = false;
            UndoButton.IsEnabled = false;
            SaveButton.IsEnabled = false;
        }
        private void AbleClick()
        {
            CellGrid.IsHitTestVisible = true;
            PauseButton.IsEnabled = true;
            UndoButton.IsEnabled = true;
            SaveButton.IsEnabled = true;
        }
        private async void HandleMove(Move move, string status)
        {
            isRedTurn = !isRedTurn;
            if (redTimer != null) SwitchTurn();
            Sound.PlayMoveSound();
            UnableClick();
            if (gameState.Moved.Any()) HidePrevMove(gameState.Moved.First().Item1);
            gameState.MakeMove(move);
            gameState.Board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
            DrawBoard(gameState.Board);
            ShowPrevMove(move);
            DrawCapturedGrid(gameState.CapturedPiece);

            // Kiểm tra trạng thái ván cờ sau khi đi
            string gameStatus = status.ToUpper();
            WarningTextBlock.Text = gameStatus == "CHECK" || gameStatus == "CHECKMATE" ? "Chiếu tướng!" : null;
            TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";

            if (gameStatus == "CHECKMATE")
            {
                gameState.Result = Result.Win(gameState.CurrentPlayer.Opponent(), EndReason.Checkmate);
            }
            else if (gameStatus == "STALEMATE")
            {
                gameState.Result = Result.Draw(EndReason.Stalemate);
            }
            else if (gameStatus == "THREEFOLDREPETITION")
            {
                gameState.Result = Result.Draw(EndReason.ThreefoldRepetition);
            }
            else if (gameStatus == "FIFTYMOVERULE")
            {
                gameState.Result = Result.Draw(EndReason.FiftyMoveRule);
            }

            if (gameState.Result != null)
            {
                UnableClick();
                await Task.Delay(100);
                moveList = new Stack<Tuple<Move, Tuple<Piece, string>>>(gameState.Moved.ToArray());
                HideHighlights();
                CellGrid.IsEnabled = false;
                if (redTimer != null) StopTimer();
                SaveHistory.Save(gameState);
                RaiseGameOverEvent(gameState);
            }

            await Dispatcher.InvokeAsync(() => { }, System.Windows.Threading.DispatcherPriority.Render);
            if (gameState is GameStateAI AI)
            {
                await Task.Delay(500); // Delay to simulate thinking time
                Move prevMove = gameState.Moved.First().Item1;
                var result1 = PrologEngine.AiMove();
                if (result1.HasValue)
                {
                    var (status1, from, to) = result1.Value;
                    gameState.MakeMove(new NormalMove(Position.IntToPosition(from), Position.IntToPosition(to)));
                    gameState.Board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
                    isRedTurn = !isRedTurn;
                    if (redTimer != null) SwitchTurn();
                    DrawCapturedGrid(gameState.CapturedPiece);
                    DrawBoard(gameState.Board);
                    HidePrevMove(prevMove);
                    ShowPrevMove(gameState.Moved.First().Item1);
                    Sound.PlayMoveSound();

                    WarningTextBlock.Text = status1 == "CHECK" || status1 == "CHECKMATE" ? "Chiếu tướng!" : null;
                    TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";

                    if (status1 == "CHECKMATE")
                    {
                        gameState.Result = Result.Win(gameState.CurrentPlayer.Opponent(), EndReason.Checkmate);
                    }
                    else if (status1 == "STALEMATE")
                    {
                        gameState.Result = Result.Draw(EndReason.Stalemate);
                    }
                    else if (status1 == "THREEFOLDREPETITION")
                    {
                        gameState.Result = Result.Draw(EndReason.ThreefoldRepetition);
                    }
                    else if (status1 == "FIFTYMOVERULE")
                    {
                        gameState.Result = Result.Draw(EndReason.FiftyMoveRule);
                    }

                    if (gameState.Result != null)
                    {
                        UnableClick();
                        await Task.Delay(500);
                        moveList = new Stack<Tuple<Move, Tuple<Piece, string>>>(gameState.Moved.ToArray());
                        HideHighlights();
                        CellGrid.IsEnabled = false;
                        if (redTimer != null) StopTimer();
                        SaveHistory.Save(gameState);
                        RaiseGameOverEvent(gameState);
                    }
                }
                else
                {
                    Console.WriteLine("Không thể thực hiện bot_move.");
                }
            }

            AbleClick();
        }
        public void Review()
        {
            PrologEngine.Reset();
            isReview = true;
            Board newBoard = Board.Initial();
            Player startPlayer;
            if (newBoard[moveList.Peek().Item1.FromPos].Color == Player.Black) startPlayer = Player.Black;
            else startPlayer = Player.White;
            if(gameState.Moved.Count>0) HidePrevMove(gameState.Moved.Peek().Item1);
            if(gameState is GameStateAI AI) gameState = new GameStateAI(startPlayer, Board.Initial(), AI.depth, 0); 
            else gameState = new GameState2P(startPlayer, Board.Initial());
            TurnTextBlock.Text = (startPlayer == Player.Black) ? "Đen" : "Trắng";
            BlackCapturedGrid.Children.Clear();
            WhiteCapturedGrid.Children.Clear();
            HideHighlights();
            redClock.Text = null;
            blackClock.Text = null;
            WarningTextBlock.Text = null;
            moveCache.Clear();
            ResetTimer();
            DrawBoard(gameState.Board);
            AbleClick();
            SaveButton.IsEnabled = false;
            DoButton.Visibility = Visibility.Visible;
            PlayButton.Visibility = Visibility.Visible;
        }
        private void UndoButton_Click(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            if (gameState.Moved.Count != 0) HidePrevMove(gameState.Moved.First().Item1);
            OnToPositionSelected(selectedPos);
            if (isReview == true)
            {
                if (gameState.Moved.Count == 0) return;
                var move = gameState.Moved.Pop();
                PrologEngine.Undo();
                gameState.Board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
                DrawBoard(gameState.Board);
                if (gameState.Moved.Count != 0)
                {
                    ShowPrevMove(gameState.Moved.First().Item1);
                }
                gameState.CapturedPiece = move.Item2.Item1;
                if (move.Item2.Item1 != null)
                {
                    if (move.Item2.Item1.Color == Player.Black)
                    {
                        gameState.CapturedBlackPiece.RemoveAt(gameState.CapturedBlackPiece.Count - 1);
                    }
                    else
                    {
                        gameState.CapturedWhitePiece.RemoveAt(gameState.CapturedWhitePiece.Count - 1);
                    }
                }
                moveList.Push(move);
                gameState.CurrentPlayer = gameState.CurrentPlayer.Opponent();
                UndoCapturedGrid(gameState.CapturedPiece);
                string status = PrologEngine.GetGameStatus();
                WarningTextBlock.Text = status == "CHECK" ? "Chiếu tướng!" : null;
                TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
                if (moveList.Count != 0) PlayButton.IsEnabled = true;
                //gameState.noCapture.Pop();
            }
            else
            {
                PrologEngine.Undo();
                if (gameState is GameStateAI gs)
                {
                    PrologEngine.Undo();
                }
                gameState.UndoMove();
                gameState.Board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
                DrawBoard(gameState.Board);
                if (gameState.Moved.Count != 0)
                {
                    ShowPrevMove(gameState.Moved.First().Item1);
                }
                string status = PrologEngine.GetGameStatus();
                WarningTextBlock.Text = status == "CHECK" ? "Chiếu tướng!" : null;
                TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";

                UndoCapturedGrid(gameState.CapturedPiece);
                if (gameState is GameStateAI AI)
                    UndoAiCapturedGrid(AI.AiCapturedPiece);
                isRedTurn = gameState.CurrentPlayer == Player.White;
                if (redTimer != null) SwitchTurn();
            }
        }
        private void DoButton_Click(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            if (moveList.Count == 0) return;
            if (gameState.Moved.Count != 0) HidePrevMove(gameState.Moved.First().Item1);
            //bool capture = moveList.Peek().Item1.Execute(gameState.Board);

            //if (capture)
            //{
            //gameState.noCapture.Push(0);
            //}
            //else
            //{
            //if (gameState.noCapture.Count == 0) gameState.noCapture.Push(1);
            //else gameState.noCapture.Push(gameState.noCapture.Peek() + 1);
            //}
            var move = moveList.Pop();
            int fromPos = (7 - move.Item1.FromPos.Row) * 8 + move.Item1.FromPos.Column;
            int toPos = (7 - move.Item1.ToPos.Row) * 8 + move.Item1.ToPos.Column;

            if (PrologEngine.MakeMove(fromPos, toPos, out var status, out var needsPromotion))
            {
                WarningTextBlock.Text = (status == "CHECK" || status == "CHECKMATE" || status == "STALEMATE") ? "Chiếu tướng!" : null;
            }
            else if (needsPromotion)
            {
                Console.WriteLine("Piece: "+move.Item2.Item2);
                if (PrologEngine.MakeMoveWithPromotion(fromPos, toPos, move.Item2.Item2, out var PromotedStatus))
                {
                    WarningTextBlock.Text = (PromotedStatus == "CHECK" || PromotedStatus == "CHECKMATE" || PromotedStatus == "STALEMATE") ? "Chiếu tướng!" : null;
                }
            }
            if (move.Item2.Item1 != null)
            {
                if (move.Item2.Item1.Color == Player.Black) gameState.CapturedBlackPiece.Add(move.Item2.Item1);
                else gameState.CapturedWhitePiece.Add(move.Item2.Item1);
            }
            gameState.Moved.Push(move);         
            gameState.Board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
            DrawBoard(gameState.Board);
            ShowPrevMove(move.Item1);
            if (gameState.Moved.Count != 0)
            {
                ShowPrevMove(gameState.Moved.First().Item1);
            }
            DrawCapturedGrid(move.Item2.Item1);
            gameState.CurrentPlayer = gameState.CurrentPlayer.Opponent();
            if (moveList.Count == 0) PlayButton.IsEnabled = false;
            TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";
        }
        private async void PlayButton_Click(object sender, RoutedEventArgs e)
        {
            Sound.PlayButtonClickSound();
            if (isReview == true)
            {
                isReview = false;
                DoButton.Visibility = Visibility.Collapsed;
                PlayButton.Visibility = Visibility.Collapsed;
                SaveButton.IsEnabled = true;            
                CellGrid.IsEnabled = true;
                if(gameState is GameStateAI AI && gameState.CurrentPlayer == Player.Black)
                {
                    UnableClick();
                    await Task.Delay(500); // Delay to simulate thinking time
                    Move prevMove = gameState.Moved.First().Item1;
                    var result1 = PrologEngine.AiMove();
                    if (result1.HasValue)
                    {
                        var (status1, from, to) = result1.Value;
                        gameState.MakeMove(new NormalMove(Position.IntToPosition(from), Position.IntToPosition(to)));
                        gameState.Board = Board.FromPrologPosition(PrologEngine.GetCurrentPosition());
                        isRedTurn = !isRedTurn;
                        if (redTimer != null) SwitchTurn();
                        DrawCapturedGrid(gameState.CapturedPiece);
                        DrawBoard(gameState.Board);
                        HidePrevMove(prevMove);
                        ShowPrevMove(gameState.Moved.First().Item1);
                        Sound.PlayMoveSound();

                        WarningTextBlock.Text = status1 == "CHECK" || status1 == "CHECKMATE" ? "Chiếu tướng!" : null;
                        TurnTextBlock.Text = gameState.CurrentPlayer == Player.White ? "Trắng" : "Đen";

                        if (status1 == "CHECKMATE")
                        {
                            gameState.Result = Result.Win(gameState.CurrentPlayer.Opponent(), EndReason.Checkmate);
                        }
                        else if (status1 == "STALEMATE")
                        {
                            gameState.Result = Result.Draw(EndReason.Stalemate);
                        }
                        else if (status1 == "THREEFOLDREPETITION")
                        {
                            gameState.Result = Result.Draw(EndReason.ThreefoldRepetition);
                        }
                        else if (status1 == "FIFTYMOVERULE")
                        {
                            gameState.Result = Result.Draw(EndReason.FiftyMoveRule);
                        }

                        if (gameState.Result != null)
                        {
                            UnableClick();
                            await Task.Delay(500);
                            moveList = new Stack<Tuple<Move, Tuple<Piece, string>>>(gameState.Moved.ToArray());
                            HideHighlights();
                            CellGrid.IsEnabled = false;
                            if (redTimer != null) StopTimer();
                            SaveHistory.Save(gameState);
                            RaiseGameOverEvent(gameState);
                        }
                    }
                    else
                    {
                        Console.WriteLine("Không thể thực hiện bot_move.");
                    }
                    AbleClick();
                }
            }
        }
        private void InitializeBoard()
        {
            for (int r = 0; r < 8; r++)
            {
                for (int c = 0; c < 8; c++)
                {
                    Image image = new Image();
                    pieceImages[r, c] = image;
                    PieceGrid.Children.Add(image);

                    Rectangle highlight = new Rectangle();
                    highlights[r, c] = highlight;
                    HighlightGrid.Children.Add(highlight);

                    Rectangle pos = new Rectangle() { };
                    posMoved[r, c] = pos;
                    PosMovedGrid.Children.Add(pos);
                }
            }
        }

        public void DrawBoard(Board board)
        {
            for (int r = 0; r < 8; r++)
            {
                for (int c = 0; c < 8; c++)
                {
                    Piece piece = board[r, c];
                    pieceImages[r, c].Source = Images.GetImage(piece);
                }
            }
        }

        private void CacheMoves(IEnumerable<Move> moves)
        {
            moveCache.Clear();
            foreach (Move move in moves)
            {
                // Phân loại lại move: nếu là tốt đi chéo tới ô trống thì là EnPassant
                var from = move.FromPos;
                var to = move.ToPos;
                Piece piece = gameState.Board[from];
                Move realMove;
                if (piece != null && piece.Type == PieceType.Pawn && from.Column != to.Column && gameState.Board[to] == null)
                {
                    realMove = new EnPassant(from, to);
                }
                else
                {
                    realMove = new NormalMove(from, to);
                }
                moveCache[to] = realMove;
            }
        }

        private void ShowHighlights()
        {
            Color color = Color.FromArgb(150, 25, 255, 125);
            foreach (Position to in moveCache.Keys)
            {
                if (gameState.Board[to] != null)
                {
                    highlights[to.Row, to.Column].Fill = new SolidColorBrush(Color.FromArgb(225, 255, 0, 0));
                }
                else highlights[to.Row, to.Column].Fill = new SolidColorBrush(color);
            }
        }

        private void HideHighlights()
        {
            foreach (Position to in moveCache.Keys)
            {
                highlights[to.Row, to.Column].Fill = Brushes.Transparent;
            }
        }

        private void BoardGrid_MouseDown(object sender, MouseEventArgs e)
        {
            Point point = e.GetPosition(BoardGrid);
            Position pos = ToSquarePosition(point);

            if (selectedPos == null)
            {
                OnFromPositionSelected(pos);
            }
            else
            {
                OnToPositionSelected(pos);
            }
        }

        private Position ToSquarePosition(Point point)
        {
            double squareSize = BoardGrid.ActualWidth / 8;

            int row = (int)(point.Y / squareSize);
            int col = (int)(point.X / squareSize);

            return new Position(row, col);
        }

        private void OnFromPositionSelected(Position pos)
        {
            // Chuyển đổi tọa độ bàn cờ sang số 0-63
            int fromPos = (7 - pos.Row) * 8 + pos.Column;

            // Lấy các nước đi hợp lệ từ Prolog (async)
            List<Move> legalMoves = PrologEngine.GetLegalMoves(fromPos);

            if (legalMoves.Any())
            {
                selectedPos = pos;
                CacheMoves(legalMoves);
                ShowHighlights();
            }
        }

        private void OnToPositionSelected(Position pos)
        {
            selectedPos = null;
            HideHighlights();

            if (pos == null) return;
            if (moveCache.TryGetValue(pos, out Move move))
            {
                // Chuyển đổi tọa độ bàn cờ sang số 0-63
                int fromPos = (7 - move.FromPos.Row) * 8 + move.FromPos.Column;
                int toPos = (7 - move.ToPos.Row) * 8 + move.ToPos.Column;

                // Thực hiện nước đi trong Prolog
                if (PrologEngine.MakeMove(fromPos, toPos, out var status, out var needsPromotion))
                {
                    HandleMove(move, status);
                }
                else if (needsPromotion)
                {
                    // Prolog đã xác định đây là nước đi phong cấp, gọi UI phong cấp
                    HandlePromotion(move.FromPos, move.ToPos);
                }
            }
        }

        private void HandlePromotion(Position from, Position to)
        {
            pieceImages[to.Row, to.Column].Source = Images.GetImage(gameState.CurrentPlayer, PieceType.Pawn);
            pieceImages[from.Row, from.Column].Source = null;

            PromotionMenu promMenu = new PromotionMenu(gameState.CurrentPlayer);
            MenuContainer.Content = promMenu;

            promMenu.PieceSelected += type =>
            {
                MenuContainer.Content = null;

                // Gửi lựa chọn phong cấp vào Prolog (async)
                string prologType;
                switch (type)
                {
                    case PieceType.Queen:
                        prologType = "queen";
                        break;
                    case PieceType.Rook:
                        prologType = "rook";
                        break;
                    case PieceType.Bishop:
                        prologType = "bishop";
                        break;
                    case PieceType.Knight:
                        prologType = "knight";
                        break;
                    default:
                        prologType = "queen";
                        break;
                }

                int fromPos = (7 - from.Row) * 8 + from.Column;
                int toPos = (7 - to.Row) * 8 + to.Column;

                if (PrologEngine.MakeMoveWithPromotion(fromPos, toPos, prologType, out var status))
                {
                    // Cập nhật lại bàn cờ và giao diện
                    Move promMove = new PawnPromotion(from, to, type);
                    HandleMove(promMove, status);

                    WarningTextBlock.Text = status == "CHECK" ? "Chiếu tướng!" : null;

                    if (status == "CHECKMATE" || status == "STALEMATE")
                    {
                        UnableClick();
                        moveList = new Stack<Tuple<Move, Tuple<Piece, string>>>(gameState.Moved.ToArray());
                        HideHighlights();
                        CellGrid.IsEnabled = false;
                        if (redTimer != null) StopTimer();
                        SaveHistory.Save(gameState);
                        RaiseGameOverEvent(gameState);
                        return;
                    }
                }
            };
        }


        private void DrawCapturedGrid(Piece piece)
        {
            if (piece == null) return;
            Image image = new Image();
            image.Source = Images.GetImage(piece);
            if (piece.Color == Player.White)
            {
                BlackCapturedGrid.Children.Add(image);
            }
            else
            {
                WhiteCapturedGrid.Children.Add(image);
            }
        }
        private void UndoCapturedGrid(Piece piece)
        {
            if (piece == null) return;
            if (piece.Color == Player.White)
            {
                int count = BlackCapturedGrid.Children.Count;
                if (count > 0)
                    BlackCapturedGrid.Children.RemoveAt(count - 1);
            }
            else
            {
                int count = WhiteCapturedGrid.Children.Count;
                if (count > 0)
                    WhiteCapturedGrid.Children.RemoveAt(count - 1);
            }
        }
        private void UndoAiCapturedGrid(Piece piece)
        {
            if (piece == null) return;
            int count = BlackCapturedGrid.Children.Count;
            if (count > 0)
                BlackCapturedGrid.Children.RemoveAt(count - 1);
        }
        public void ShowPrevMove(Move move)
        {
            Color color = Color.FromArgb(155, 207, 255, 112);
            posMoved[move.FromPos.Row, move.FromPos.Column].Fill = new SolidColorBrush(color);
            posMoved[move.ToPos.Row, move.ToPos.Column].Fill = new SolidColorBrush(color);
        }
        public void HidePrevMove(Move move)
        {
            posMoved[move.FromPos.Row, move.FromPos.Column].Fill = Brushes.Transparent;
            posMoved[move.ToPos.Row, move.ToPos.Column].Fill = Brushes.Transparent;
        }
        #region event
        public event RoutedEventHandler PauseButtonClicked
        {
            add { AddHandler(PauseButtonClickedEvent, value); }
            remove { RemoveHandler(PauseButtonClickedEvent, value); }
        }
        public static readonly RoutedEvent PauseButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "PauseButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(GameUserControl)
        );
        private void PauseButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(PauseButtonClickedEvent));
        }
        public event RoutedEventHandler SaveButtonClicked
        {
            add { AddHandler(SaveButtonClickedEvent, value); }
            remove { RemoveHandler(SaveButtonClickedEvent, value); }
        }
        public static readonly RoutedEvent SaveButtonClickedEvent = EventManager.RegisterRoutedEvent(
             "SaveButtonClicked",
             RoutingStrategy.Bubble,
             typeof(RoutedEventHandler),
             typeof(GameUserControl)
        );
        private void SaveButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(SaveButtonClickedEvent));
        }

        public static readonly RoutedEvent CloseAppButtonClickedEvent = EventManager.RegisterRoutedEvent(
            "CloseAppButtonClicked",
            RoutingStrategy.Bubble,
            typeof(RoutedEventHandler),
            typeof(GameUserControl)
        );
        public event RoutedEventHandler CloseAppButtonClicked
        {
            add { AddHandler(CloseAppButtonClickedEvent, value); }
            remove { RemoveHandler(CloseAppButtonClickedEvent, value); }
        }

        private void CloseAppButton_Click(object sender, RoutedEventArgs e)
        {
            RaiseEvent(new RoutedEventArgs(CloseAppButtonClickedEvent));
        }

        private void MinimizeAppButton_Click(object sender, RoutedEventArgs e)
        {
            Application.Current.MainWindow.WindowState = WindowState.Minimized;
        }

        private void MaximizeAppButton_Click(object sender, RoutedEventArgs e)
        {
            if (Application.Current.MainWindow.WindowState == WindowState.Maximized)
            {
                Application.Current.MainWindow.WindowState = WindowState.Normal;
            }
            else Application.Current.MainWindow.WindowState = WindowState.Maximized;
        }

        private void TitleBar_MouseDown(object sender, MouseButtonEventArgs e)
        {
            if (e.LeftButton == MouseButtonState.Pressed)
            {
                Application.Current.MainWindow.DragMove();
            }
        }


        public static readonly RoutedEvent GameOverEvent = EventManager.RegisterRoutedEvent(
        "GameOver", RoutingStrategy.Bubble, typeof(RoutedEventHandler), typeof(GameUserControl));

        public event RoutedEventHandler GameOver
        {
            add { AddHandler(GameOverEvent, value); }
            remove { RemoveHandler(GameOverEvent, value); }
        }

        protected void RaiseGameOverEvent(GameState gameState)
        {
            RoutedEventArgs args = new RoutedPropertyChangedEventArgs<GameState>(null, gameState, GameOverEvent);
            RaiseEvent(args);
        }

        public static readonly RoutedEvent PawnPromotionEvent = EventManager.RegisterRoutedEvent(
"PawnPromotion", RoutingStrategy.Bubble, typeof(RoutedEventHandler), typeof(GameUserControl));

        public event RoutedEventHandler PawnPromotion
        {
            add { AddHandler(PawnPromotionEvent, value); }
            remove { RemoveHandler(PawnPromotionEvent, value); }
        }

        protected void RaisePawnPromotionEvent()
        {
            RaiseEvent(new RoutedEventArgs(PawnPromotionEvent));
        }
        #endregion
    }
}
